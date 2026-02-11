import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pursenal/core/abstracts/accounts_repository.dart';
import 'package:pursenal/core/abstracts/profiles_repository.dart';
import 'package:pursenal/core/repositories/proto/projects_proto_repository.dart';
import 'package:pursenal/core/repositories/proto/transactions_proto_repository.dart';
import 'package:pursenal/core/repositories/repository_registry.dart';
import 'package:pursenal/l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:pursenal/app/global/dimensions.dart';
import 'package:pursenal/core/models/domain/profile.dart';
import 'package:pursenal/core/models/domain/user.dart';
import 'package:pursenal/core/models/proto/models.pb.dart' as proto;
import 'package:pursenal/core/repositories/drift/accounts_drift_repository.dart';
import 'package:pursenal/core/repositories/drift/profiles_drift_repository.dart';
import 'package:pursenal/core/repositories/drift/user_drift_repository.dart';
import 'package:pursenal/providers/lan_server_provider.dart';
import 'package:pursenal/screens/dashboard_screen.dart';
import 'package:pursenal/screens/balances_screen.dart';
import 'package:pursenal/screens/insights_screen.dart';
import 'package:pursenal/screens/lan_devices_screen.dart';
import 'package:pursenal/screens/lan_server_screen.dart';
import 'package:pursenal/screens/transactions_screen.dart';
import 'package:pursenal/screens/user_edit_screen.dart';
import 'package:pursenal/utils/app_logger.dart';
import 'package:pursenal/utils/app_paths.dart';
import 'package:pursenal/utils/proto_http_client.dart';
import 'package:pursenal/utils/services/lan_discovery.dart';
import 'package:pursenal/viewmodels/main_viewmodel.dart';
import 'package:pursenal/widgets/main/the_drawer.dart';
import 'package:pursenal/widgets/shared/loading_body.dart';
import 'package:path/path.dart' as p;

class MainScreen extends StatelessWidget {
  const MainScreen({super.key, required this.profile});
  final Profile profile;

  @override
  Widget build(BuildContext context) {
    final userRepository =
        Provider.of<UserDriftRepository>(context, listen: false);
    final lanServerProvider =
        Provider.of<LANServerProvider>(context, listen: false);
    const double barIconSize = 24.00;

    final profileDriftRepository =
        Provider.of<ProfilesDriftRepository>(context, listen: false);

    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Theme.of(context).primaryColor,
        systemNavigationBarColor:
            Theme.of(context).navigationBarTheme.backgroundColor,
      ),
    );

    final repositoryRegistry =
        Provider.of<RepositoryRegistry>(context, listen: false);
    return ChangeNotifierProvider<MainViewmodel>(
      create: (context) => MainViewmodel(
          repositoryRegistry, userRepository, profileDriftRepository,
          selectedProfile: profile)
        ..init(),
      builder: (context, child) => Consumer<MainViewmodel>(
        builder: (context, viewmodel, child) => LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth > smallWidth;
            final isVeryWide = constraints.maxWidth > mediumWidth;
            User? user =
                Provider.of<MainViewmodel>(context, listen: false).user;
            final String securePath = AppPaths.imagesDir;
            final String userPhotoPath =
                p.join(securePath, p.basename(user?.photoPath ?? ""));
            return Scaffold(
              appBar: AppBar(
                title: Text(AppLocalizations.of(context)!.pursenal),
                actions: [
                  IconButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const LANDevicesScreen(),
                          ),
                        );
                      },
                      icon: Icon(
                        Icons.cast_connected_sharp,
                        color: lanServerProvider.isRunning
                            ? Theme.of(context).primaryColor
                            : null,
                      )),
                  const SizedBox(width: 8),
                  IconButton(
                      onPressed: () async {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const LanServerScreen(),
                          ),
                        );
                      },
                      icon: Icon(
                        Icons.share_rounded,
                        color: lanServerProvider.isRunning
                            ? Theme.of(context).primaryColor
                            : null,
                      )),
                  const SizedBox(width: 8),
                  Padding(
                    padding: const EdgeInsets.only(right: 2.0),
                    child: SizedBox(
                        width: 36,
                        height: 36,
                        child: Hero(
                          tag: "user_photo",
                          child: InkWell(
                            borderRadius: BorderRadius.circular(4),
                            customBorder: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(4)),
                            onTap: () {
                              if (user != null) {
                                Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => UserEditScreen(
                                        user: user,
                                      ),
                                    )).then((_) {
                                  viewmodel.init();
                                });
                              }
                            },
                            child: user != null &&
                                    userPhotoPath.isNotEmpty &&
                                    userPhotoPath != "" &&
                                    File(userPhotoPath).existsSync()
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(4),
                                    child: Image.file(
                                      File(userPhotoPath),
                                      width: 36,
                                      height: 36,
                                      fit: BoxFit.cover,
                                      opacity: const AlwaysStoppedAnimation(.9),
                                    ),
                                  )
                                : const Icon(Icons.person),
                          ),
                        )),
                  ),
                  const SizedBox(
                    width: 16,
                  )
                ],
              ),
              body: Builder(builder: (context) {
                return LoadingBody(
                  loadingStatus: viewmodel.loadingStatus,
                  errorText: viewmodel.errorText,
                  resetErrorTextFn: () {
                    viewmodel.resetErrorText();
                  },
                  widget: Row(
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        width: isWide ? null : 0, // Hide when narrow
                        child: Visibility(
                          visible: isWide,
                          child: Container(
                            color: Theme.of(context)
                                .navigationBarTheme
                                .backgroundColor,
                            height: double.infinity,
                            width: isVeryWide ? 200 : null,
                            child: Padding(
                              padding:
                                  const EdgeInsets.only(right: 10, top: 18),
                              child: Column(
                                children: [
                                  Text(lanServerProvider.serverAddress ?? ""),
                                  const SizedBox(
                                    height: 50,
                                  ),
                                  ...List.generate(
                                    _labels.length, // Number of tabs
                                    (index) => MouseRegion(
                                      cursor: SystemMouseCursors.click,
                                      child: Tooltip(
                                        message: _labels[index],
                                        child: GestureDetector(
                                          onTap: () =>
                                              viewmodel.setIndex(index),
                                          child: Padding(
                                            padding: const EdgeInsets.all(2.0),
                                            child: AnimatedContainer(
                                              duration: const Duration(
                                                  milliseconds: 300),
                                              margin: const EdgeInsets.only(
                                                  left: 12),
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 10,
                                                      vertical: 8),
                                              decoration: BoxDecoration(
                                                color: viewmodel.currentIndex ==
                                                        index
                                                    ? Theme.of(context)
                                                        .colorScheme
                                                        .primary
                                                    : Theme.of(context)
                                                        .cardColor
                                                        .withAlpha(40),
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                              ),
                                              child: Row(
                                                children: [
                                                  Icon(
                                                    _icons[index],
                                                    color: viewmodel
                                                                .currentIndex ==
                                                            index
                                                        ? Colors.white
                                                        : null,
                                                    size: barIconSize,
                                                  ),
                                                  if (isVeryWide)
                                                    Padding(
                                                      padding:
                                                          const EdgeInsets.only(
                                                              left: 8),
                                                      child: Text(
                                                        _labels[index],
                                                        style: TextStyle(
                                                            fontSize: 16,
                                                            color: viewmodel
                                                                        .currentIndex ==
                                                                    index
                                                                ? Colors.white
                                                                : Theme.of(
                                                                        context)
                                                                    .textTheme
                                                                    .titleMedium
                                                                    ?.color),
                                                      ),
                                                    ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      Visibility(
                        visible: isWide,
                        child: const VerticalDivider(
                          width: .25,
                          thickness: .25,
                        ),
                      ),
                      Expanded(
                        child: MainScreenBody(
                          profile: viewmodel.selectedProfile,
                          viewmodel: viewmodel,
                        ),
                      )
                    ],
                  ),
                );
              }),
              bottomNavigationBar: isWide
                  ? null
                  : Container(
                      height: 70,
                      color:
                          Theme.of(context).navigationBarTheme.backgroundColor,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            ...List.generate(
                              _labels.length, // Number of tabs
                              (index) => GestureDetector(
                                onTap: () => viewmodel.setIndex(index),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 300),
                                  margin: const EdgeInsets.only(
                                      left: 12), // Spacing between items
                                  padding: EdgeInsets.symmetric(
                                      horizontal:
                                          viewmodel.currentIndex == index
                                              ? 16
                                              : 12,
                                      vertical: 8),
                                  decoration: BoxDecoration(
                                    color: viewmodel.currentIndex == index
                                        ? Theme.of(context).colorScheme.primary
                                        : null,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        _icons[index],
                                        color: viewmodel.currentIndex == index
                                            ? Colors.white
                                            : null,
                                        size: barIconSize,
                                      ),
                                      if (viewmodel.currentIndex == index)
                                        Padding(
                                          padding:
                                              const EdgeInsets.only(left: 8),
                                          child: Text(
                                            _labels[index],
                                            style: TextStyle(
                                                color: viewmodel.currentIndex ==
                                                        index
                                                    ? Colors.white
                                                    : null,
                                                fontSize: 18),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
              drawer: TheDrawer(
                viewmodel: viewmodel,
              ),
            );
          },
        ),
      ),
    );
  }
}

class MainScreenBody extends StatelessWidget {
  const MainScreenBody({
    super.key,
    required this.profile,
    required this.viewmodel,
  });

  final Profile profile;
  final MainViewmodel viewmodel;

  @override
  Widget build(BuildContext context) {
    // print(viewmodel.pageController.page);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (viewmodel.pageController.page?.round() != viewmodel.currentIndex) {
        viewmodel.pageController.jumpToPage(viewmodel.currentIndex);
      }
    });
    var pages = [
      DashboardScreen(profile: viewmodel.selectedProfile),
      BalancesScreen(profile: viewmodel.selectedProfile),
      TransactionsScreen(
        profile: viewmodel.selectedProfile,
      ),
      InsightsScreen(profile: viewmodel.selectedProfile)
    ];
    return Column(
      children: [
        Expanded(
          child: PageView.builder(
            itemCount: pages.length,
            itemBuilder: (context, index) => pages[index],
            controller: viewmodel.pageController,
            onPageChanged: (index) => viewmodel.setIndex(index),
          ),
        ),
      ],
    );
  }
}

final List<String> _labels = [
  "Dashboard",
  "Balances",
  "Transactions",
  "Insights"
];
final List<IconData> _icons = [
  Icons.dashboard,
  Icons.money,
  Icons.list,
  Icons.bar_chart_rounded
];
