import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:pursenal/app/global/dimensions.dart';
import 'package:pursenal/core/models/domain/budget.dart';
import 'package:pursenal/core/models/domain/profile.dart';
import 'package:pursenal/core/repositories/drift/accounts_drift_repository.dart';
import 'package:pursenal/core/repositories/drift/budgets_drift_repository.dart';
import 'package:pursenal/core/repositories/drift/transactions_drift_repository.dart';
import 'package:pursenal/core/repositories/repository_registry.dart';
import 'package:pursenal/screens/budget_entry_screen.dart';
import 'package:pursenal/viewmodels/app_viewmodel.dart';
import 'package:pursenal/viewmodels/budget_viewmodel.dart';
import 'package:pursenal/widgets/budget/budget_details_card.dart';
import 'package:pursenal/widgets/budget/budget_performance_card.dart';
import 'package:pursenal/widgets/budget/budgeted_expenses_card.dart';
import 'package:pursenal/widgets/budget/income_vs_expense_card.dart';
import 'package:pursenal/widgets/shared/acc_type_icon.dart';
import 'package:pursenal/widgets/shared/loading_body.dart';
import 'package:pursenal/l10n/app_localizations.dart';

class BudgetScreen extends StatelessWidget {
  const BudgetScreen({super.key, required this.profile, required this.budget});
  final Profile profile;
  final Budget budget;

  @override
  Widget build(BuildContext context) {
    final repositoryRegistry =
        Provider.of<RepositoryRegistry>(context, listen: false);

    final appViewmodel = Provider.of<AppViewmodel>(context);
    return ChangeNotifierProvider<BudgetViewmodel>(
      create: (context) =>
          BudgetViewmodel(repositoryRegistry, profile: profile, budget: budget)
            ..init(),
      builder: (context, child) => Consumer<BudgetViewmodel>(
        builder: (context, viewmodel, child) => Scaffold(
            appBar: AppBar(
              actions: [
                IconButton(
                    onPressed: () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => BudgetEntryScreen(
                              profile: profile,
                              budget: viewmodel.budget,
                            ),
                          )).then((_) => viewmodel.refetchBudget());
                    },
                    icon: const Icon(Icons.edit)),
                IconButton(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        content: Text(
                            AppLocalizations.of(context)!.deleteBudgetWarning),
                        actions: [
                          TextButton(
                              onPressed: () async {
                                final hasDeleted =
                                    await viewmodel.deleteBudget();
                                if (hasDeleted && context.mounted) {
                                  Navigator.pop(context);
                                  Navigator.pop(context);
                                }
                              },
                              child: Text(
                                AppLocalizations.of(context)!.delete,
                                style: const TextStyle(
                                    color: Colors.red,
                                    fontWeight: FontWeight.bold),
                              )),
                          TextButton(
                              onPressed: () {
                                Navigator.pop(context);
                              },
                              child: Text(AppLocalizations.of(context)!.cancel))
                        ],
                        title: Text(
                            AppLocalizations.of(context)!.deleteThisBudgetQn),
                      ),
                    );
                  },
                  icon: const Icon(Icons.delete),
                  color: Colors.red,
                ),
                const SizedBox(
                  width: 12,
                )
              ],
            ),
            body: LoadingBody(
                loadingStatus: viewmodel.loadingStatus,
                errorText: viewmodel.errorText,
                widget: SingleChildScrollView(
                  child: Column(
                    children: [
                      Center(
                        child: SizedBox(
                          width: smallWidth,
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 24, vertical: 4),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            viewmodel.budget.name,
                                            overflow: TextOverflow.ellipsis,
                                            style: Theme.of(context)
                                                .textTheme
                                                .headlineMedium,
                                          ),
                                          Text(
                                            viewmodel.budget.details,
                                            overflow: TextOverflow.ellipsis,
                                            style: Theme.of(context)
                                                .textTheme
                                                .titleMedium,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Chip(
                                        label: Text(
                                      viewmodel.budget.interval.label,
                                      overflow: TextOverflow.ellipsis,
                                    )),
                                  )
                                ],
                              ),
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 16),
                                child: SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: Row(
                                    children: [
                                      const Text("Tracked Funds : "),
                                      ...viewmodel.budget.funds.map(
                                        (f) => Padding(
                                          padding: const EdgeInsets.all(1.0),
                                          child: Chip(
                                            avatar: Icon(
                                              getAccTypeIcon(f.accountType),
                                              color: Colors.white,
                                            ),
                                            shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(5)),
                                            padding: const EdgeInsets.all(2),
                                            color: WidgetStatePropertyAll(
                                                Theme.of(context).primaryColor),
                                            label: Text(
                                              f.name,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ),
                                      )
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(
                                height: 12,
                              )
                            ],
                          ),
                        ),
                      ),
                      Wrap(
                        children: [
                          BudgetDetailsCard(
                            profile: profile,
                            viewmodel: viewmodel,
                          )
                              .animate(delay: 0.ms)
                              .scale(
                                  begin: const Offset(1.02, 1.02),
                                  duration: 100.ms)
                              .fade(curve: Curves.easeInOut, duration: 100.ms),
                          BudgetPerformanceCard(
                            appViewmodel: appViewmodel,
                            viewmodel: viewmodel,
                          )
                              .animate(delay: 50.ms)
                              .scale(
                                  begin: const Offset(1.02, 1.02),
                                  duration: 100.ms)
                              .fade(curve: Curves.easeInOut, duration: 100.ms),
                          IncomeVsExpenseCard(
                            appViewmodel: appViewmodel,
                            viewmodel: viewmodel,
                          )
                              .animate(delay: 100.ms)
                              .scale(
                                  begin: const Offset(1.02, 1.02),
                                  duration: 100.ms)
                              .fade(curve: Curves.easeInOut, duration: 100.ms),
                          BudgetedExpensesCard(
                            profile: profile,
                            viewmodel: viewmodel,
                          )
                              .animate(delay: 150.ms)
                              .scale(
                                  begin: const Offset(1.02, 1.02),
                                  duration: 100.ms)
                              .fade(curve: Curves.easeInOut, duration: 100.ms),
                        ],
                      ),
                      const SizedBox(
                        height: 24,
                      )
                    ],
                  ),
                ),
                resetErrorTextFn: () {
                  viewmodel.resetErrorText();
                })),
      ),
    );
  }
}
