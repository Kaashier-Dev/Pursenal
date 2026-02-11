import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:pursenal/app/extensions/currency.dart';
import 'package:pursenal/app/global/dimensions.dart';
import 'package:pursenal/core/models/domain/account.dart';
import 'package:pursenal/core/models/domain/profile.dart';
import 'package:pursenal/viewmodels/budget_viewmodel.dart';
import 'package:pursenal/widgets/shared/progress_bar.dart';
import 'package:pursenal/widgets/shared/the_divider.dart';
import 'package:pursenal/l10n/app_localizations.dart';

class BudgetedExpensesCard extends StatelessWidget {
  const BudgetedExpensesCard({
    super.key,
    required this.profile,
    required this.viewmodel,
  });

  final Profile profile;
  final BudgetViewmodel viewmodel;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Container(
        width: cardWidth,
        padding: const EdgeInsets.all(4.0),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
            Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: Theme.of(context).scaffoldBackgroundColor),
              child: Column(
                children: [
                  ...viewmodel.budget.expenses.entries.mapIndexed((index, b) {
                    final Account acc = b.key;

                    int expA = viewmodel.expenseTotals.entries
                            .firstWhereOrNull((e) => e.key.dbID == acc.dbID)
                            ?.value ??
                        0;

                    int expB = viewmodel.budget.expenses[acc] ?? 0;
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
                              currency: profile.currency,
                              progress: (-expA).toCurrency(),
                              max: (-expB).toCurrency()),
                        ),
                      ],
                    );
                  })
                ],
              ),
            ),
            const SizedBox(
              height: 12,
            )
          ],
        ),
      ),
    );
  }
}
