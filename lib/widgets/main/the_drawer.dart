import 'package:adaptive_theme/adaptive_theme.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pursenal/app/global/values.dart';
import 'package:pursenal/screens/about_us_screen.dart';
import 'package:pursenal/screens/profile_entry_screen.dart';
import 'package:pursenal/screens/settings_screen.dart';
import 'package:pursenal/viewmodels/app_viewmodel.dart';
import 'package:pursenal/viewmodels/main_viewmodel.dart';
import 'package:pursenal/widgets/shared/the_divider.dart';
import 'package:pursenal/l10n/app_localizations.dart';
import 'package:url_launcher/url_launcher.dart';

class TheDrawer extends StatelessWidget {
  const TheDrawer({
    super.key,
    required this.viewmodel,
  });
  final MainViewmodel viewmodel;

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            Consumer<MainViewmodel>(
              builder: (context, viewmodel, child) => Padding(
                padding: const EdgeInsets.all(4.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Expanded(child: TheDivider()),
                        Text(
                          AppLocalizations.of(context)!.profile,
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        const Expanded(child: TheDivider()),
                      ],
                    ),
                    Card(
                      shape: RoundedRectangleBorder(
                          borderRadius:
                              const BorderRadius.all(Radius.circular(14)),
                          side: BorderSide(
                              color: Theme.of(context).primaryColor)),
                      child: ExpansionTile(
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.all(Radius.circular(14)),
                        ),
                        collapsedShape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        trailing: CircleAvatar(
                          minRadius: 12,
                          maxRadius: 24,
                          child: Text(
                            viewmodel.selectedProfile.currency.symbol,
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                        title: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(
                            viewmodel.selectedProfile.name,
                            overflow: TextOverflow.fade,
                            style: Theme.of(context).textTheme.titleLarge,
                            maxLines: 2,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                  vertical: 2.0, horizontal: 12),
                              child: Text(
                                AppLocalizations.of(context)!
                                    .cashAccounts(viewmodel.cashCountinProfile),
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                  vertical: 2.0, horizontal: 12),
                              child: Text(
                                AppLocalizations.of(context)!
                                    .bankAccounts(viewmodel.bankCountinProfile),
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ),
                          ],
                        ),
                        children: [
                          ListTile(
                            title: Text(
                              AppLocalizations.of(context)!.editThisProfile,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                            onTap: () {
                              Navigator.pop(context);
                              Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ProfileEntryScreen(
                                      profile: viewmodel.selectedProfile,
                                    ),
                                  )).then((_) async {
                                await viewmodel.setLastUpdatedTimeStamp();
                                await viewmodel.init();
                              });
                            },
                            trailing: const Icon(
                              Icons.edit,
                              size: 16,
                            ),
                          ),
                          ListTile(
                            title: Text(
                              AppLocalizations.of(context)!.newProfile,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                            onTap: () {
                              Navigator.pop(context);
                              Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const ProfileEntryScreen(),
                                  )).then((_) async {
                                await viewmodel.setLastUpdatedTimeStamp();
                                await viewmodel.init();
                              });
                            },
                            trailing: const Icon(
                              Icons.add,
                              size: 16,
                            ),
                          ),
                          ListTile(
                            title: Text(
                              AppLocalizations.of(context)!.allProfiles,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                            onTap: () {
                              Navigator.pop(context);
                              showDialog(
                                context: context,
                                builder: (context) => SimpleDialog(
                                  title: Text(
                                      AppLocalizations.of(context)!.myProfiles),
                                  children: [
                                    ...viewmodel.profiles.map((p) => ListTile(
                                          leading: Padding(
                                            padding: const EdgeInsets.all(8.0),
                                            child: CircleAvatar(
                                              child: Text(
                                                p.currency.symbol,
                                                style: const TextStyle(
                                                    color: Colors.white),
                                              ),
                                            ),
                                          ),
                                          title: Text(
                                            p.name,
                                            style: Theme.of(context)
                                                .textTheme
                                                .titleMedium
                                                ?.copyWith(fontSize: 28),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          onTap: () {
                                            viewmodel.selectedProfile = p;
                                            viewmodel.setIndex(0);
                                            Navigator.pop(context);
                                          },
                                        )),
                                    const SizedBox(
                                      height: 20,
                                    )
                                  ],
                                ),
                              ).then((_) async {
                                await viewmodel.setLastUpdatedTimeStamp();
                                await viewmodel.init();
                              });
                            },
                            trailing: const Icon(
                              Icons.people_rounded,
                              size: 16,
                            ),
                            shape: const Border(),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const Spacer(),
            Builder(builder: (context) {
              final AdaptiveThemeManager<ThemeData> adaptiveTheme =
                  AdaptiveTheme.of(context);
              final AppViewmodel appViewmodel =
                  Provider.of<AppViewmodel>(context);
              if (appViewmodel.isSystemDefaultTheme) {
                return const SizedBox.shrink();
              }
              return Material(
                color: Colors.transparent,
                child: ListTile(
                  title: Text(AppLocalizations.of(context)!.toggleTheme),
                  onTap: () async {
                    await AdaptiveTheme.getThemeMode() ==
                            AdaptiveThemeMode.light
                        ? adaptiveTheme.setDark()
                        : await AdaptiveTheme.getThemeMode() ==
                                AdaptiveThemeMode.dark
                            ? adaptiveTheme.setLight()
                            : adaptiveTheme.setDark();
                  },
                  trailing: ValueListenableBuilder(
                    valueListenable:
                        AdaptiveTheme.of(context).modeChangeNotifier,
                    builder: (_, mode, child) {
                      // update your UI

                      return mode == AdaptiveThemeMode.light
                          ? const Icon(Icons.light_mode)
                          : mode == AdaptiveThemeMode.dark
                              ? const Icon(Icons.dark_mode)
                              : const Icon(Icons.light_mode);
                    },
                  ),
                ),
              );
            }),
            Material(
              color: Colors.transparent,
              child: ListTile(
                  title: Text(AppLocalizations.of(context)!.settings),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const SettingsScreen(),
                        ));
                  },
                  trailing: const Icon(Icons.settings)),
            ),
            Material(
              color: Colors.transparent,
              child: ListTile(
                  title: Text(AppLocalizations.of(context)!.aboutUs),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AboutUsScreen(),
                        ));
                  },
                  trailing: const Icon(Icons.info_outline)),
            ),
            const SizedBox(
              height: 20,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onTap: () async {
                    final url = Uri.parse(gitHubURL);
                    if (!await launchUrl(url)) {
                      throw Exception('Could not launch $url');
                    }
                  },
                  child: const Text("GitHub"),
                ),
                VerticalDivider(
                  thickness: 5,
                  width: 5,
                  color: Theme.of(context).primaryColor,
                ),
                GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onTap: () async {
                    final url = Uri.parse(supportURL);
                    if (!await launchUrl(url)) {
                      throw Exception('Could not launch $url');
                    }
                  },
                  child: Text(AppLocalizations.of(context)!.supportUs),
                ),
              ],
            ),
            const SizedBox(
              height: 20,
            ),
          ],
        ),
      ),
    );
  }
}
