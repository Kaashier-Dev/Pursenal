import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:pursenal/app/extensions/currency.dart';
import 'package:pursenal/app/global/dimensions.dart';
import 'package:pursenal/viewmodels/app_viewmodel.dart';
import 'package:pursenal/viewmodels/budget_viewmodel.dart';
import 'package:pursenal/widgets/shared/the_divider.dart';
import 'package:pursenal/l10n/app_localizations.dart';

class BudgetPerformanceCard extends StatelessWidget {
  const BudgetPerformanceCard({
    super.key,
    required this.appViewmodel,
    required this.viewmodel,
  });

  final AppViewmodel appViewmodel;
  final BudgetViewmodel viewmodel;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        width: cardWidth,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              child: Row(
                children: [
                  const Expanded(child: TheDivider()),
                  Text(
                    AppLocalizations.of(context)!.budgetPerformance,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const Expanded(child: TheDivider()),
                ],
              ),
            ),
            const SizedBox(
              height: 8,
            ),
            Container(
              height: 200,
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Theme.of(context).scaffoldBackgroundColor,
                      Theme.of(context).scaffoldBackgroundColor.withAlpha(100)
                    ]),
              ),
              child: Row(
                children: [
                  if (viewmodel.incomeTotals.isNotEmpty)
                    Expanded(
                      child: PieChart(
                        duration: const Duration(microseconds: 1500),
                        PieChartData(
                            sectionsSpace: 0.5,
                            startDegreeOffset: 180,
                            centerSpaceRadius: 0,
                            sections: [
                              PieChartSectionData(
                                title:
                                    "${AppLocalizations.of(context)!.incomes}\n${((viewmodel.aIncomeTotal / viewmodel.bIncomeTotal) * 100).round()}%",
                                titleStyle: const TextStyle(
                                    fontSize: 14,
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold),
                                color: appViewmodel.receiptColor,
                                radius: 70,
                                value:
                                    viewmodel.aIncomeTotal.abs().toCurrency(),
                              ),
                              if (viewmodel.aIncomeTotal.abs() <
                                  viewmodel.bIncomeTotal.abs())
                                PieChartSectionData(
                                  title: "",
                                  color: Colors.grey.withAlpha(110),
                                  radius: 70,
                                  value: (viewmodel.bIncomeTotal.abs() -
                                          viewmodel.aIncomeTotal.abs())
                                      .abs()
                                      .toCurrency(),
                                ),
                            ]),
                      ),
                    ),
                  if (viewmodel.expenseTotals.isNotEmpty)
                    Expanded(
                      child: PieChart(
                        duration: const Duration(microseconds: 1500),
                        PieChartData(
                            sectionsSpace: 0.5,
                            startDegreeOffset: 180,
                            centerSpaceRadius: 0,
                            sections: [
                              PieChartSectionData(
                                title:
                                    "${AppLocalizations.of(context)!.expenses}\n${((viewmodel.aExpenseTotal / viewmodel.bExpenseTotal) * 100).round()}%",
                                titleStyle: const TextStyle(
                                    fontSize: 14,
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold),
                                color: appViewmodel.paymentColor,
                                radius: 70,
                                value:
                                    viewmodel.aExpenseTotal.abs().toCurrency(),
                              ),
                              if (viewmodel.aExpenseTotal.abs() <
                                  viewmodel.bExpenseTotal.abs())
                                PieChartSectionData(
                                  title: "",
                                  color: Colors.grey.withAlpha(110),
                                  radius: 70,
                                  value: (viewmodel.bExpenseTotal -
                                          viewmodel.aExpenseTotal)
                                      .abs()
                                      .toCurrency(),
                                ),
                            ]),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(
              height: 16,
            )
          ],
        ),
      ),
    );
  }
}
