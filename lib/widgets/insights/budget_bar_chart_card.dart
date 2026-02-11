import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:pursenal/app/global/dimensions.dart';
import 'package:pursenal/app/extensions/currency.dart';
import 'package:pursenal/core/models/domain/account.dart';
import 'package:pursenal/viewmodels/insights_viewmodel.dart';
import 'package:pursenal/l10n/app_localizations.dart';
import 'package:pursenal/widgets/shared/progress_bar.dart';
import 'package:pursenal/widgets/shared/the_divider.dart';

class BudgetBarChartCard extends StatelessWidget {
  const BudgetBarChartCard({
    super.key,
    required this.viewmodel,
  });

  final InsightsViewmodel viewmodel;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(
        maxWidth: cardWidth,
      ),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(4.0),
          child: Column(
            children: [
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                child: Row(
                  children: [
                    const Expanded(child: TheDivider()),
                    Text(
                      AppLocalizations.of(context)!.budgetedExpenses,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const Expanded(child: TheDivider()),
                  ],
                ),
              ),
              const SizedBox(
                height: 6,
              ),
              if (viewmodel.budgets.length > 1)
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: DropdownMenu(
                      enableSearch: false,
                      width: cardWidth,
                      label: Text(AppLocalizations.of(context)!.myBudgets),
                      initialSelection: viewmodel.selectedBudget,
                      onSelected: (b) {
                        viewmodel.selectedBudget = b;
                      },
                      dropdownMenuEntries: [
                        ...viewmodel.budgets.map(
                          (b) => DropdownMenuEntry(
                              value: b,
                              label: b.name,
                              trailingIcon: Text(b.interval.label)),
                        )
                      ]),
                ),
              Visibility(
                visible: viewmodel.selectedBudget != null,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: Theme.of(context).scaffoldBackgroundColor),
                  child: Column(
                    children: [
                      ...viewmodel.selectedBudget!.expenses.entries
                          .mapIndexed((index, b) {
                        final Account acc = b.key;

                        int expA = viewmodel.expenseTotals.entries
                                .firstWhereOrNull((e) => e.key.dbID == acc.dbID)
                                ?.value ??
                            0;

                        int expB = viewmodel.selectedBudget?.expenses[acc] ?? 0;
                        return Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                acc.name,
                                style: Theme.of(context).textTheme.labelSmall,
                                textAlign: TextAlign.end,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Expanded(
                              flex: 5,
                              child: ProgressBar(
                                  currency: viewmodel.selectedProfile.currency,
                                  progress: (-expA).toCurrency(),
                                  max: (-expB).toCurrency()),
                            ),
                          ],
                        );
                      })
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
    )
        .animate(delay: 200.ms)
        .scale(begin: const Offset(1.02, 1.02), duration: 100.ms)
        .fade(curve: Curves.easeInOut, duration: 100.ms);
  }
}
