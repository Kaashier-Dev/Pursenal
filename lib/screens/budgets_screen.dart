import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:pursenal/app/global/dimensions.dart';
import 'package:pursenal/app/extensions/currency.dart';
import 'package:pursenal/core/enums/loading_status.dart';
import 'package:pursenal/core/models/domain/profile.dart';
import 'package:pursenal/core/repositories/drift/budgets_drift_repository.dart';
import 'package:pursenal/core/repositories/repository_registry.dart';
import 'package:pursenal/screens/budget_entry_screen.dart';
import 'package:pursenal/screens/budget_screen.dart';
import 'package:pursenal/viewmodels/budgets_viewmodel.dart';
import 'package:pursenal/widgets/shared/empty_list.dart';
import 'package:pursenal/widgets/shared/loading_body.dart';
import 'package:pursenal/widgets/shared/search_field.dart';
import 'package:pursenal/l10n/app_localizations.dart';
import 'package:pursenal/widgets/shared/the_divider.dart';

class BudgetsScreen extends StatelessWidget {
  const BudgetsScreen({
    super.key,
    required this.profile,
    this.accType,
  });
  final Profile profile;
  final int? accType;

  @override
  Widget build(BuildContext context) {
    final repositoryRegistry =
        Provider.of<RepositoryRegistry>(context, listen: false);
    return ChangeNotifierProvider<BudgetsViewmodel>(
      create: (context) => BudgetsViewmodel(
        repositoryRegistry,
        profile: profile,
      )..init(),
      builder: (context, child) => Scaffold(
        appBar: AppBar(),
        body: Consumer<BudgetsViewmodel>(
          builder: (context, viewmodel, child) {
            return LoadingBody(
              loadingStatus: viewmodel.loadingStatus,
              errorText: viewmodel.errorText,
              resetErrorTextFn: () {
                viewmodel.resetErrorText();
              },
              widget: LayoutBuilder(
                builder: (context, constraints) {
                  bool isWide = constraints.maxWidth > 800;

                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: BudgetsList(
                          viewmodel: viewmodel,
                          isWide: isWide,
                        ),
                      ),
                    ],
                  );
                },
              ),
            );
          },
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            final provider =
                Provider.of<BudgetsViewmodel>(context, listen: false);

            Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => BudgetEntryScreen(
                    profile: profile,
                  ),
                )).then((_) {
              provider.init();
            });
          },
          heroTag: "addBudget",
          child: const Icon(Icons.add),
        ),
      ),
    );
  }
}

class BudgetsList extends StatelessWidget {
  const BudgetsList({
    super.key,
    required this.viewmodel,
    required this.isWide,
  });

  final BudgetsViewmodel viewmodel;
  final bool isWide;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: smallWidth),
        child: Column(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              height: viewmodel.headerHeight,
              curve: Curves.easeInOut,
              child: Column(
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      child: Text(
                        AppLocalizations.of(context)!.myBudgets,
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                    ),
                  ),
                  SearchField(searchFn: (term) {
                    viewmodel.searchTerm = term;
                  }),
                ],
              ),
            ),
            Visibility(
              visible: viewmodel.fBudgets.isEmpty,
              child: Expanded(
                child: EmptyList(
                  items: AppLocalizations.of(context)!.budgets,
                  addFn: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              BudgetEntryScreen(profile: viewmodel.profile),
                        )).then((_) {
                      viewmodel.init();
                    });
                  },
                  isListFiltered: viewmodel.budgets.isNotEmpty ||
                      (viewmodel.budgets.isNotEmpty &&
                          viewmodel.fBudgets.length ==
                              viewmodel.budgets.length),
                ),
              ),
            ),
            Visibility(
              visible: viewmodel.fBudgets.isNotEmpty,
              child: Expanded(child: Builder(builder: (_) {
                if (viewmodel.searchLoadingStatus == LoadingStatus.completed) {
                  return ListView.builder(
                    controller: viewmodel.scrollController,
                    itemCount: viewmodel.fBudgets.length,
                    padding: const EdgeInsets.only(bottom: 70),
                    itemBuilder: (context, index) {
                      final b = viewmodel.fBudgets[index];
                      final difference = b.expenses.values.toList().sum +
                          b.incomes.values.toList().sum;
                      return SizedBox(
                        width: cardWidth,
                        child: Card(
                          child: InkWell(
                            borderRadius: BorderRadius.circular(14),
                            onTap: () {
                              Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => BudgetScreen(
                                      profile: viewmodel.profile,
                                      budget: b,
                                    ),
                                  )).then((_) => viewmodel.init());
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          b.name,
                                          style: Theme.of(context)
                                              .textTheme
                                              .headlineSmall,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      Chip(
                                          label: Text(
                                        b.interval.label,
                                        overflow: TextOverflow.ellipsis,
                                      ))
                                    ],
                                  ),
                                  Visibility(
                                    visible: b.details.isNotEmpty,
                                    child: Text(
                                      b.details,
                                      overflow: TextOverflow.ellipsis,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium,
                                    ),
                                  ),
                                  const SizedBox(
                                    height: 4,
                                  ),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        AppLocalizations.of(context)!.incomes,
                                        overflow: TextOverflow.ellipsis,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyLarge,
                                      ),
                                      Text(
                                        b.incomes.values.sum.toCurrencyString(
                                            viewmodel.profile.currency),
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyLarge,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                  const TheDivider(
                                    indent: 0,
                                  ),
                                  const SizedBox(
                                    height: 4,
                                  ),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        AppLocalizations.of(context)!.expenses,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyLarge,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      Text(
                                        b.expenses.values.sum.toCurrencyString(
                                            viewmodel.profile.currency),
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyLarge,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                  const TheDivider(
                                    indent: 0,
                                  ),
                                  const SizedBox(
                                    height: 4,
                                  ),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        AppLocalizations.of(context)!.savings,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyLarge
                                            ?.copyWith(
                                                fontWeight: FontWeight.bold),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      Text(
                                        difference.toCurrencyString(
                                            viewmodel.profile.currency),
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyLarge
                                            ?.copyWith(
                                              fontWeight: FontWeight.bold,
                                              color: difference < 0
                                                  ? Colors.red
                                                  : null,
                                            ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                  const SizedBox(
                                    height: 4,
                                  )
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
                      );
                    },
                  );
                } else {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }
              })),
            )
          ],
        ),
      ),
    );
  }
}
