import 'package:collection/collection.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:pursenal/app/global/colors.dart';
import 'package:pursenal/app/global/dimensions.dart';
import 'package:pursenal/app/extensions/currency.dart';
import 'package:pursenal/viewmodels/insights_viewmodel.dart';
import 'package:pursenal/l10n/app_localizations.dart';
import 'package:pursenal/widgets/shared/the_divider.dart';

class FundBalancesLineChartCard extends StatelessWidget {
  const FundBalancesLineChartCard({
    super.key,
    required this.viewmodel,
  });

  final InsightsViewmodel viewmodel;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        showDialog(
          context: context,
          builder: (_) => Builder(builder: (context) {
            return StatefulBuilder(builder: (context, setState) {
              return SimpleDialog(
                title: Text(AppLocalizations.of(context)!.funds),
                children: [
                  ...viewmodel.funds.mapIndexed((i, f) {
                    return CheckboxListTile(
                        title: Row(
                          children: [
                            Container(
                              margin: const EdgeInsets.symmetric(horizontal: 5),
                              width: 15,
                              height: 15,
                              decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: materialColors.reversed.toList()[i]),
                            ),
                            Text(f.name),
                          ],
                        ),
                        value: !viewmodel.selectedFundsForBalanceChart
                            .contains(f.dbID),
                        onChanged: (_) {
                          viewmodel.addToFilter(a: f.dbID);
                          setState(() {});
                        });
                  }),
                  const SizedBox(
                    height: 12,
                  )
                ],
              );
            });
          }),
        );
      },
      child: ConstrainedBox(
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
                        AppLocalizations.of(context)!.fundsBalance,
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
                          Theme.of(context)
                              .scaffoldBackgroundColor
                              .withAlpha(100)
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
                                    style:
                                        Theme.of(context).textTheme.labelSmall,
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
                        ...viewmodel.fundBalances.entries.mapIndexed(
                          (x, f) {
                            final mRevColors = materialColors.reversed.toList();
                            return LineChartBarData(
                              curveSmoothness: 0.05,
                              spots: [
                                ...f.value.mapIndexed((i, b) => FlSpot(
                                    i.toDouble(),
                                    b.toCurrency().roundToDouble()))
                              ],
                              isCurved: true,
                              gradient: LinearGradient(
                                colors: [
                                  mRevColors[x].withAlpha(150),
                                  mRevColors[x],
                                ],
                              ),
                              dotData: const FlDotData(show: false),
                              aboveBarData: BarAreaData(
                                show: true,
                                color: Colors.red.shade200,
                                applyCutOffY: true,
                              ),
                            );
                          },
                        )
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
        ),
      ),
    )
        .animate(delay: 100.ms)
        .scale(begin: const Offset(1.02, 1.02), duration: 100.ms)
        .fade(curve: Curves.easeInOut, duration: 100.ms);
  }
}
