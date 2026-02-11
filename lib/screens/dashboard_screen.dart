import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:pursenal/app/global/dimensions.dart';
import 'package:pursenal/core/abstracts/account_types_repository.dart';
import 'package:pursenal/core/abstracts/accounts_repository.dart';
import 'package:pursenal/core/abstracts/balances_repository.dart';
import 'package:pursenal/core/abstracts/profiles_repository.dart';
import 'package:pursenal/core/abstracts/transactions_repository.dart';
import 'package:pursenal/core/models/domain/profile.dart';
import 'package:pursenal/core/repositories/drift/account_types_drift_repository.dart';
import 'package:pursenal/core/repositories/drift/accounts_drift_repository.dart';
import 'package:pursenal/core/repositories/drift/balances_drift_repository.dart';
import 'package:pursenal/core/repositories/drift/profiles_drift_repository.dart';
import 'package:pursenal/core/repositories/drift/transactions_drift_repository.dart';
import 'package:pursenal/core/repositories/repository_registry.dart';
import 'package:pursenal/screens/accounts_screen.dart';
import 'package:pursenal/screens/budgets_screen.dart';
import 'package:pursenal/screens/payment_reminders_screen.dart';
import 'package:pursenal/screens/projects_screen.dart';
import 'package:pursenal/viewmodels/app_viewmodel.dart';
import 'package:pursenal/viewmodels/dashboard_viewmodel.dart';
import 'package:pursenal/widgets/dashboard/add_new_account_card.dart';
import 'package:pursenal/widgets/dashboard/add_transaction_card.dart';
import 'package:pursenal/widgets/dashboard/my_balance_card.dart';
import 'package:pursenal/widgets/dashboard/transactions_card.dart';
import 'package:pursenal/widgets/dashboard/nav_button1.dart';
import 'package:pursenal/widgets/shared/loading_body.dart';
import 'package:pursenal/l10n/app_localizations.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key, required this.profile});
  final Profile profile;

  @override
  Widget build(BuildContext context) {
    final repositoryRegistry =
        Provider.of<RepositoryRegistry>(context, listen: false);
    final profileDriftRepository =
        Provider.of<ProfilesDriftRepository>(context, listen: false);

    final appViewmodel = Provider.of<AppViewmodel>(context);
    return ChangeNotifierProvider<DashboardViewmodel>(
      create: (context) => DashboardViewmodel(
          repositoryRegistry, profileDriftRepository,
          profile: profile)
        ..init(),
      builder: (context, child) => Consumer<DashboardViewmodel>(
        builder: (context, viewmodel, child) =>
            LayoutBuilder(builder: (context, constraints) {
          final isWide = constraints.maxWidth > smallWidth;
          final isVeryWide = constraints.maxWidth > cardWidth * 2;
          return Scaffold(
            body: LoadingBody(
              loadingStatus: viewmodel.loadingStatus,
              isFirstScreen: true,
              errorText: viewmodel.errorText,
              widget: SingleChildScrollView(
                child: Column(
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        child: Text(
                          AppLocalizations.of(context)!.myDashboard,
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                      ),
                    ),
                    Wrap(
                      alignment: WrapAlignment.center,
                      runAlignment: WrapAlignment.center,
                      children: [
                        MyBalanceCard(
                          profile: profile,
                          viewmodel: viewmodel,
                          isWide: isVeryWide,
                        ),
                        Visibility(
                          visible: viewmodel.canAddTransaction & !isVeryWide,
                          child: AddTransactionCard(
                            appViewmodel: appViewmodel,
                            profile: profile,
                            viewmodel: viewmodel,
                          ),
                        ),
                        Visibility(
                          visible: isWide,
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            width: double.infinity,
                            height: 60,
                            child: Center(
                              child: SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    NavButton1(
                                      onTap: () {
                                        Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  BudgetsScreen(
                                                profile:
                                                    viewmodel.selectedProfile,
                                              ),
                                            ));
                                      },
                                      title:
                                          AppLocalizations.of(context)!.budgets,
                                      icon: Icons.calculate,
                                    ),
                                    NavButton1(
                                      onTap: () {
                                        Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  ProjectsScreen(
                                                profile:
                                                    viewmodel.selectedProfile,
                                              ),
                                            ));
                                      },
                                      title: AppLocalizations.of(context)!
                                          .projects,
                                      icon: Icons.assignment,
                                    ),
                                    NavButton1(
                                      onTap: () {
                                        Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                                builder: (context) =>
                                                    PaymentRemindersScreen(
                                                        profile: profile)));
                                      },
                                      title: AppLocalizations.of(context)!
                                          .reminders,
                                      icon: Icons.event_available,
                                    ),
                                    NavButton1(
                                      onTap: () {
                                        Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  AccountsScreen(
                                                profile:
                                                    viewmodel.selectedProfile,
                                              ),
                                            ));
                                      },
                                      title:
                                          "${AppLocalizations.of(context)!.expenses} & ${AppLocalizations.of(context)!.incomes}",
                                      icon: Icons.table_chart_outlined,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          )
                              .animate(delay: 100.ms)
                              .scale(
                                  begin: const Offset(1.02, 1.02),
                                  duration: 100.ms)
                              .fade(curve: Curves.easeInOut, duration: 100.ms),
                        ),
                        Visibility(
                          visible: !isWide,
                          child: Container(
                            padding: const EdgeInsets.only(
                                top: 2, left: 2, right: 2),
                            width: double.infinity,
                            height: 60,
                            child: Center(
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Expanded(
                                    child: NavButton1(
                                      onTap: () {
                                        Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  BudgetsScreen(
                                                profile:
                                                    viewmodel.selectedProfile,
                                              ),
                                            ));
                                      },
                                      title:
                                          AppLocalizations.of(context)!.budgets,
                                      icon: Icons.calculate,
                                    ),
                                  ),
                                  Expanded(
                                    child: NavButton1(
                                      onTap: () {
                                        Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  ProjectsScreen(
                                                profile:
                                                    viewmodel.selectedProfile,
                                              ),
                                            ));
                                      },
                                      title: AppLocalizations.of(context)!
                                          .projects,
                                      icon: Icons.assignment,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                              .animate(delay: 100.ms)
                              .scale(
                                  begin: const Offset(1.02, 1.02),
                                  duration: 100.ms)
                              .fade(curve: Curves.easeInOut, duration: 100.ms),
                        ),
                        Visibility(
                          visible: !isWide,
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            width: double.infinity,
                            height: 60,
                            child: Center(
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Expanded(
                                    child: NavButton1(
                                      onTap: () {
                                        Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                                builder: (context) =>
                                                    PaymentRemindersScreen(
                                                        profile: profile)));
                                      },
                                      title: AppLocalizations.of(context)!
                                          .reminders,
                                      icon: Icons.event_available,
                                    ),
                                  ),
                                  Expanded(
                                    child: NavButton1(
                                      onTap: () {
                                        Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  AccountsScreen(
                                                profile:
                                                    viewmodel.selectedProfile,
                                              ),
                                            ));
                                      },
                                      title: AppLocalizations.of(context)!
                                          .accounts,
                                      icon: Icons.table_chart_outlined,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                              .animate(delay: 100.ms)
                              .scale(
                                  begin: const Offset(1.02, 1.02),
                                  duration: 100.ms)
                              .fade(curve: Curves.easeInOut, duration: 100.ms),
                        ),
                        Visibility(
                            visible: viewmodel.recentTransactions.isNotEmpty,
                            child: TransactionsCard(
                              viewmodel: viewmodel,
                            )),
                        Visibility(
                            visible: viewmodel.fAccountTypes.isNotEmpty,
                            child: AddNewAccountCard(
                              viewmodel: viewmodel,
                            )),
                        const SizedBox(
                          height: 300,
                        )
                      ],
                    ),
                  ],
                ),
              ),
              resetErrorTextFn: () => viewmodel.resetErrorText(),
            ),
          );
        }),
      ),
    );
  }
}
