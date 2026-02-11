import 'package:collection/collection.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:pursenal/app/extensions/currency.dart';
import 'package:pursenal/app/global/dimensions.dart';
import 'package:pursenal/viewmodels/app_viewmodel.dart';
import 'package:pursenal/viewmodels/budget_viewmodel.dart';
import 'package:pursenal/widgets/shared/the_divider.dart';
import 'package:pursenal/l10n/app_localizations.dart';

class IncomeVsExpenseCard extends StatelessWidget {
  const IncomeVsExpenseCard({
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
        width: cardWidth,
        padding: const EdgeInsets.symmetric(horizontal: 4.0),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              child: Row(
                children: [
                  const Expanded(child: TheDivider()),
                  Text(
                    "${AppLocalizations.of(context)!.incomes} V/s ${AppLocalizations.of(context)!.expenses}",
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
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: LineChart(LineChartData(
                  titlesData: FlTitlesData(
                    topTitles: const AxisTitles(),
                    leftTitles: const AxisTitles(),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (double value, TitleMeta meta) {
                          // Format date from your list
                          final dateIndex =
                              value.toInt(); // Convert X value to index
                          if (dateIndex >= 0 &&
                              dateIndex < viewmodel.rangeDates.length) {
                            final date = viewmodel.rangeDates[dateIndex];
                            return Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(
                                ("${date.day}"), // Use a formatter for your date
                                style: Theme.of(context).textTheme.labelSmall,
                              ),
                            );
                          }
                          return const SizedBox();
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      curveSmoothness: 0.02,
                      spots: [
                        ...viewmodel.dailyTotalTransactions.mapIndexed((i, t) =>
                            FlSpot(i.toDouble(),
                                t.paymentsTotal.toCurrency().roundToDouble()))
                      ],
                      isCurved: true,
                      color: appViewmodel.paymentColor,
                      dotData: const FlDotData(show: false),
                      aboveBarData: BarAreaData(
                        show: true,
                        color: Colors.red.shade200,
                        applyCutOffY: true,
                      ),
                    ),
                    LineChartBarData(
                      curveSmoothness: 0.02,
                      spots: [
                        ...viewmodel.dailyTotalTransactions.mapIndexed((i, t) =>
                            FlSpot(i.toDouble(),
                                t.receiptsTotal.toCurrency().roundToDouble()))
                      ],
                      isCurved: true,
                      color: appViewmodel.receiptColor,
                      dotData: const FlDotData(show: false),
                      aboveBarData: BarAreaData(
                        show: true,
                        color: Colors.red.shade200,
                        applyCutOffY: true,
                      ),
                    ),
                  ],
                )),
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
