import 'package:collection/collection.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:pursenal/app/global/dimensions.dart';
import 'package:pursenal/core/enums/week_days.dart';
import 'package:pursenal/viewmodels/insights_viewmodel.dart';
import 'package:pursenal/widgets/shared/the_divider.dart';
import 'package:pursenal/l10n/app_localizations.dart';

class AverageTransactionsBarChartCard extends StatelessWidget {
  const AverageTransactionsBarChartCard({
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
                      AppLocalizations.of(context)!.averageExpenses,
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
                  padding:
                      const EdgeInsets.symmetric(vertical: 8.0, horizontal: 24),
                  child: BarChart(BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      borderData: FlBorderData(show: false),
                      gridData: const FlGridData(drawVerticalLine: false),
                      titlesData: FlTitlesData(
                          leftTitles: const AxisTitles(),
                          topTitles: const AxisTitles(),
                          bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                  getTitlesWidget: (value, meta) => Text(
                                      WeekDays.values[value.toInt() - 1].short),
                                  reservedSize: 30,
                                  showTitles: true))),
                      barGroups: [
                        ...viewmodel.weeklyAvgExpenses.entries
                            .map((t) => BarChartGroupData(x: t.key, barRods: [
                                  BarChartRodData(
                                      borderRadius: const BorderRadius.only(
                                          topLeft: Radius.circular(6),
                                          topRight: Radius.circular(6),
                                          bottomLeft: Radius.circular(2),
                                          bottomRight: Radius.circular(2)),
                                      width: 20,
                                      gradient: const LinearGradient(
                                          colors: [
                                            Colors.lightBlueAccent,
                                            Colors.blue,
                                          ],
                                          begin: Alignment(0, 0),
                                          end: Alignment(1, 1)),
                                      toY: t.value.average.roundToDouble(),
                                      color: Colors.blue),
                                ]))
                      ])),
                ),
              ),
              const SizedBox(
                height: 16,
              )
            ],
          ),
        ),
      ),
    )
        .animate(delay: 150.ms)
        .scale(begin: const Offset(1.02, 1.02), duration: 100.ms)
        .fade(curve: Curves.easeInOut, duration: 100.ms);
  }
}
