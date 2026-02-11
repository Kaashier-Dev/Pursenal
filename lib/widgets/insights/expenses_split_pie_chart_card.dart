import 'package:collection/collection.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:pursenal/app/global/colors.dart';
import 'package:pursenal/app/global/dimensions.dart';
import 'package:pursenal/app/extensions/currency.dart';
import 'package:pursenal/viewmodels/insights_viewmodel.dart';
import 'package:pursenal/l10n/app_localizations.dart';
import 'package:pursenal/widgets/shared/dot_indicator.dart';
import 'package:pursenal/widgets/shared/the_divider.dart';

class ExpensesSplitPieChartCard extends StatelessWidget {
  const ExpensesSplitPieChartCard({
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
                      AppLocalizations.of(context)!.expensesSplit,
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
                height: 200,
                child: PageView(
                  controller: viewmodel.expCardpageController,
                  onPageChanged: (value) => viewmodel.setExpCardPage(value),
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: PieChart(
                            duration: const Duration(microseconds: 1500),
                            PieChartData(
                              startDegreeOffset: 180,
                              centerSpaceRadius: 0,
                              sections: viewmodel.expenseTotals.entries
                                  .mapIndexed((i, e) {
                                return PieChartSectionData(
                                  title:
                                      viewmodel.getExpensePercentage(e.value),
                                  titleStyle: const TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold),
                                  titlePositionPercentageOffset: 1.2,
                                  color: materialColors[i],
                                  gradient: LinearGradient(
                                    colors: [
                                      materialColors[i].withAlpha(200),
                                      materialColors[i],
                                    ],
                                  ),
                                  radius: 75,
                                  value: e.value.abs().toCurrency(),
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                        SizedBox(
                          width: 150,
                          child: ListView.builder(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            shrinkWrap: true,
                            itemCount: viewmodel.expenseTotals.length,
                            itemBuilder: (context, index) => IntrinsicHeight(
                              child: ListTile(
                                minTileHeight: 5,
                                dense: true,
                                horizontalTitleGap: 0,
                                shape: const Border(
                                  bottom: BorderSide(
                                      width: 0, color: Colors.transparent),
                                ),
                                leading: Container(
                                  width: 10,
                                  height: 10,
                                  decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: materialColors[index]),
                                ),
                                contentPadding: EdgeInsets.zero,
                                title: Text(
                                  "${viewmodel.expenseTotals.keys.elementAt(index).name} (${viewmodel.getExpensePercentage(viewmodel.expenseTotals.values.elementAt(index))})",
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context).textTheme.labelSmall,
                                ),
                              ),
                            ),
                          ),
                        )
                      ],
                    ),
                    ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      shrinkWrap: true,
                      itemCount: viewmodel.expenseTotals.length,
                      itemBuilder: (context, index) {
                        final acc =
                            viewmodel.expenseTotals.keys.elementAt(index);
                        final amt =
                            viewmodel.expenseTotals.values.elementAt(index);
                        return IntrinsicHeight(
                          child: ListTile(
                            minTileHeight: 32,
                            horizontalTitleGap: 5,
                            shape: const Border(
                              bottom: BorderSide(
                                  width: 0, color: Colors.transparent),
                            ),
                            leading: Container(
                              width: 16,
                              height: 16,
                              decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: materialColors[index]),
                            ),
                            contentPadding: EdgeInsets.zero,
                            title: Text(
                              "${acc.name} (${viewmodel.getExpensePercentage(amt)})",
                              overflow: TextOverflow.ellipsis,
                            ),
                            trailing: Text(
                              (amt * -1).toCurrencyStringWSymbol(
                                  viewmodel.selectedProfile.currency),
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(
                height: 4,
              ),
              SizedBox(
                height: 12,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    DotsIndicator(
                      isActive: viewmodel.expCardPage == 0,
                      onTap: () {
                        viewmodel.setExpCardPage(0);
                      },
                    ),
                    DotsIndicator(
                      isActive: viewmodel.expCardPage == 1,
                      onTap: () {
                        viewmodel.setExpCardPage(1);
                      },
                    ),
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    )
        .animate(delay: 0.ms)
        .scale(begin: const Offset(1.02, 1.02), duration: 100.ms)
        .fade(curve: Curves.easeInOut, duration: 100.ms);
  }
}
