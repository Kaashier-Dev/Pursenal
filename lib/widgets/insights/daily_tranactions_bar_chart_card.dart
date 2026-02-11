import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:pursenal/app/global/date_formats.dart';
import 'package:pursenal/app/global/dimensions.dart';
import 'package:pursenal/app/extensions/currency.dart';
import 'package:pursenal/viewmodels/app_viewmodel.dart';
import 'package:pursenal/viewmodels/insights_viewmodel.dart';
import 'package:pursenal/widgets/shared/dot_indicator.dart';
import 'package:pursenal/widgets/shared/the_divider.dart';
import 'package:pursenal/l10n/app_localizations.dart';

class DailyTransactionsBarChartCard extends StatelessWidget {
  const DailyTransactionsBarChartCard({
    super.key,
    required this.viewmodel,
  });

  final InsightsViewmodel viewmodel;

  @override
  Widget build(BuildContext context) {
    int noOfTransactions = viewmodel.dailyTotalTransactions.length;
    final appViewmodel = Provider.of<AppViewmodel>(context);
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
                      AppLocalizations.of(context)!.dailyTransactions,
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
                child: ClipRect(
                  clipper: HorizontalClipper(leftClip: -2, rightClip: -2),
                  child: PageView(
                    onPageChanged: (value) => viewmodel.setDailyCardPage(value),
                    controller: viewmodel.dailyCardpageController,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: BarChart(
                          BarChartData(
                            alignment: BarChartAlignment.center,
                            gridData: const FlGridData(drawVerticalLine: false),
                            borderData: FlBorderData(show: false),
                            barTouchData: BarTouchData(enabled: false),
                            titlesData: FlTitlesData(
                                leftTitles: const AxisTitles(),
                                topTitles: const AxisTitles(),
                                bottomTitles: noOfTransactions < 45
                                    ? AxisTitles(
                                        sideTitles: SideTitles(
                                            interval:
                                                noOfTransactions < 20 ? 1 : 2,
                                            reservedSize: 30,
                                            getTitlesWidget: (value, meta) =>
                                                Text(
                                                  value.toInt().toString(),
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .labelSmall,
                                                ),
                                            showTitles: true))
                                    : const AxisTitles()),
                            barGroups: [
                              ...viewmodel.dailyTotalTransactions.map((t) {
                                return BarChartGroupData(
                                    x: t.dateTime.day,
                                    groupVertically: true,
                                    barRods: [
                                      BarChartRodData(
                                        width: noOfTransactions > 100
                                            ? 2
                                            : noOfTransactions > 30
                                                ? 4
                                                : null,
                                        borderRadius: const BorderRadius.only(
                                            topLeft: Radius.circular(4),
                                            topRight: Radius.circular(4)),
                                        toY: t.receiptsTotal
                                            .toCurrency()
                                            .roundToDouble(),
                                        gradient: LinearGradient(
                                            colors: [
                                              appViewmodel.receiptColor,
                                              appViewmodel.receiptColor
                                                  .withAlpha(180),
                                            ],
                                            begin: const Alignment(0, 0),
                                            end: const Alignment(1, 1)),
                                      ),
                                      BarChartRodData(
                                        width: noOfTransactions > 100
                                            ? 2
                                            : noOfTransactions > 30
                                                ? 4
                                                : null,
                                        borderRadius: const BorderRadius.only(
                                            bottomLeft: Radius.circular(4),
                                            bottomRight: Radius.circular(4)),
                                        toY: -t.paymentsTotal
                                            .toCurrency()
                                            .roundToDouble(),
                                        gradient: LinearGradient(
                                            colors: [
                                              appViewmodel.paymentColor
                                                  .withAlpha(180),
                                              appViewmodel.paymentColor,
                                            ],
                                            begin: const Alignment(0, 0),
                                            end: const Alignment(1, 1)),
                                      ),
                                    ]);
                              }),
                            ],
                          ),
                        ),
                      ),
                      ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        shrinkWrap: true,
                        itemCount: noOfTransactions,
                        itemBuilder: (context, index) {
                          final date =
                              viewmodel.dailyTotalTransactions[index].dateTime;
                          final payment = viewmodel
                              .dailyTotalTransactions[index].paymentsTotal;
                          final receipt = viewmodel
                              .dailyTotalTransactions[index].receiptsTotal;
                          return IntrinsicHeight(
                            child: ListTile(
                              leading: Text(
                                dateOnlyString.format(date),
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.bodyLarge,
                              ),
                              minTileHeight: 32,
                              shape: const Border(
                                bottom: BorderSide(
                                    width: 0, color: Colors.transparent),
                              ),
                              contentPadding: EdgeInsets.zero,
                              title: SizedBox(
                                width: cardWidth,
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceEvenly,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        receipt > 0
                                            ? "+ ${receipt.toCurrencyString(viewmodel.selectedProfile.currency)}"
                                            : receipt.toCurrencyString(viewmodel
                                                .selectedProfile.currency),
                                        overflow: TextOverflow.ellipsis,
                                        textAlign: TextAlign.end,
                                        style: TextStyle(
                                            color: appViewmodel.receiptColor),
                                      ),
                                    ),
                                    Expanded(
                                      child: Text(
                                        payment > 0
                                            ? "- ${payment.toCurrencyString(viewmodel.selectedProfile.currency)}"
                                            : payment.toCurrencyString(viewmodel
                                                .selectedProfile.currency),
                                        overflow: TextOverflow.ellipsis,
                                        textAlign: TextAlign.end,
                                        style: TextStyle(
                                            color: appViewmodel.paymentColor),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
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
                      isActive: viewmodel.dailyCardPage == 0,
                      onTap: () {
                        viewmodel.setDailyCardPage(0);
                      },
                    ),
                    DotsIndicator(
                      isActive: viewmodel.dailyCardPage == 1,
                      onTap: () {
                        viewmodel.setDailyCardPage(1);
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
        .animate(delay: 50.ms)
        .scale(begin: const Offset(1.02, 1.02), duration: 100.ms)
        .fade(curve: Curves.easeInOut, duration: 100.ms);
  }
}

class HorizontalClipper extends CustomClipper<Rect> {
  final double leftClip;
  final double rightClip;

  HorizontalClipper({this.leftClip = 0, this.rightClip = 0});

  @override
  Rect getClip(Size size) {
    return Rect.fromLTRB(
      leftClip,
      0, // No clipping at the top
      size.width - rightClip,
      size.height, // No clipping at the bottom
    );
  }

  @override
  bool shouldReclip(covariant CustomClipper<Rect> oldClipper) {
    return true;
  }
}
