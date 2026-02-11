import 'package:flutter/material.dart';
import 'package:pursenal/app/extensions/currency.dart';
import 'package:pursenal/app/global/dimensions.dart';
import 'package:pursenal/core/models/domain/profile.dart';
import 'package:pursenal/viewmodels/budget_viewmodel.dart';
import 'package:pursenal/widgets/shared/the_divider.dart';
import 'package:pursenal/l10n/app_localizations.dart';

class BudgetDetailsCard extends StatelessWidget {
  const BudgetDetailsCard({
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
        padding: const EdgeInsets.symmetric(horizontal: 24),
        width: cardWidth,
        child: Column(
          children: [
            const SizedBox(
              height: 12,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    AppLocalizations.of(context)!.incomes,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                Text(
                  viewmodel.aIncomeTotal.toCurrencyString(profile.currency),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppLocalizations.of(context)!.expected,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      Text(
                        viewmodel.expectedAvgInc
                            .toCurrencyString(profile.currency),
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppLocalizations.of(context)!.budgeted,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      Text(
                        viewmodel.bIncomeTotal
                            .toCurrencyString(profile.currency),
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 2.0),
              child: TheDivider(
                indent: 0,
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    AppLocalizations.of(context)!.expenses,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                Text(
                  viewmodel.aExpenseTotal.toCurrencyString(profile.currency),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppLocalizations.of(context)!.expected,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      Text(
                        viewmodel.expectedAvgExp
                            .toCurrencyString(profile.currency),
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppLocalizations.of(context)!.budgeted,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      Text(
                        viewmodel.bExpenseTotal
                            .toCurrencyString(profile.currency),
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 2.0),
              child: TheDivider(
                indent: 0,
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    AppLocalizations.of(context)!.savings,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                Text(
                  viewmodel.aDifference.toCurrencyString(profile.currency),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppLocalizations.of(context)!.expected,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      Text(
                        viewmodel.expectedAvgDif
                            .toCurrencyString(profile.currency),
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppLocalizations.of(context)!.budgeted,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      Text(
                        viewmodel.bDifference
                            .toCurrencyString(profile.currency),
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ],
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
