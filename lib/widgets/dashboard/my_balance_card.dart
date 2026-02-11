import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:pursenal/app/global/dimensions.dart';
import 'package:pursenal/app/extensions/currency.dart';
import 'package:pursenal/core/models/domain/profile.dart';
import 'package:pursenal/viewmodels/app_viewmodel.dart';
import 'package:pursenal/viewmodels/dashboard_viewmodel.dart';
import 'package:pursenal/viewmodels/main_viewmodel.dart';
import 'package:pursenal/widgets/dashboard/add_transaction_button_group.dart';
import 'package:pursenal/widgets/shared/the_divider.dart';
import 'package:pursenal/l10n/app_localizations.dart';

class MyBalanceCard extends StatelessWidget {
  const MyBalanceCard({
    super.key,
    required this.profile,
    required this.viewmodel,
    required this.isWide,
  });

  final Profile profile;
  final DashboardViewmodel viewmodel;
  final bool isWide;

  @override
  Widget build(BuildContext context) {
    final appViewmodel = Provider.of<AppViewmodel>(context);
    return ConstrainedBox(
      constraints: BoxConstraints(
          maxWidth: isWide ? cardWidth * 2 : cardWidth,
          minWidth: 300,
          minHeight: 200),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: cardWidth - 78,
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Expanded(child: TheDivider()),
                          Text(
                            AppLocalizations.of(context)!.myBalance,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const Expanded(child: TheDivider()),
                        ],
                      ),
                    ),
                    const SizedBox(
                      height: 10,
                    ),
                    SizedBox(
                      height: 100,
                      child: Stack(
                        children: [
                          Positioned.fill(
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Opacity(
                                opacity: 0.2, // Adjust transparency
                                child: IgnorePointer(
                                  child: LineChart(LineChartData(
                                    gridData: const FlGridData(show: false),
                                    titlesData: const FlTitlesData(show: false),
                                    borderData: FlBorderData(show: false),
                                    lineBarsData: [
                                      LineChartBarData(
                                        spots: List.generate(
                                            viewmodel.balances.length,
                                            (index) => FlSpot(
                                                index.toDouble(),
                                                viewmodel.balances[index]
                                                    .toCurrency())),
                                        isCurved: true,
                                        color: Colors.blue,
                                        dotData: const FlDotData(show: false),
                                        belowBarData: BarAreaData(),
                                      ),
                                    ],
                                  )),
                                ),
                              ),
                            ),
                          ),
                          Center(
                            child: Text(
                              viewmodel.closingBalance
                                  .toCurrencyStringWSymbol(profile.currency),
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineLarge
                                  ?.copyWith(fontSize: 44),
                              textScaler: const TextScaler.linear(.88),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: TextButton(
                          onPressed: () {
                            Provider.of<MainViewmodel>(context, listen: false)
                                .setIndex(1);
                          },
                          child: Text(AppLocalizations.of(context)!.details)),
                    )
                  ],
                ),
              ),
              Visibility(
                visible: isWide,
                child: SizedBox(
                  width: isWide ? cardWidth - 50 : 0,
                  child: Column(
                    children: [
                      AddTransactionButtonGroup(
                        appViewmodel: appViewmodel,
                        profile: profile,
                        viewmodel: viewmodel,
                        isWide: isWide,
                      )
                    ],
                  ),
                )
                    .animate(delay: 50.ms)
                    .scale(begin: const Offset(1.02, 1.02), duration: 100.ms)
                    .fade(curve: Curves.easeInOut, duration: 100.ms),
              )
            ],
          ),
        ),
      )
          .animate()
          .scale(begin: const Offset(1.02, 1.02), duration: 100.ms)
          .fade(curve: Curves.easeInOut, duration: 100.ms),
    );
  }
}
