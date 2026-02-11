import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pursenal/app/global/dimensions.dart';
import 'package:pursenal/core/enums/app_date_format.dart';
import 'package:pursenal/core/enums/date_filter_type.dart';
import 'package:pursenal/core/enums/loading_status.dart';
import 'package:pursenal/core/models/domain/profile.dart';
import 'package:pursenal/core/repositories/drift/accounts_drift_repository.dart';
import 'package:pursenal/core/repositories/drift/balances_drift_repository.dart';
import 'package:pursenal/core/repositories/drift/budgets_drift_repository.dart';
import 'package:pursenal/core/repositories/drift/profiles_drift_repository.dart';
import 'package:pursenal/core/repositories/drift/transactions_drift_repository.dart';
import 'package:pursenal/core/repositories/repository_registry.dart';
import 'package:pursenal/viewmodels/app_viewmodel.dart';
import 'package:pursenal/viewmodels/insights_viewmodel.dart';
import 'package:pursenal/widgets/insights/average_transactions_bar_chart_card.dart';
import 'package:pursenal/widgets/insights/daily_tranactions_bar_chart_card.dart';
import 'package:pursenal/widgets/insights/expenses_split_pie_chart_card.dart';
import 'package:pursenal/widgets/insights/fund_balances_line_chart_card.dart';
import 'package:pursenal/widgets/shared/loading_body.dart';
import 'package:pursenal/l10n/app_localizations.dart';
import 'package:pursenal/widgets/shared/the_date_picker.dart';

class InsightsScreen extends StatelessWidget {
  const InsightsScreen({super.key, required this.profile});

  final Profile profile;

  @override
  Widget build(BuildContext context) {
    final profilesDriftRepository =
        Provider.of<ProfilesDriftRepository>(context, listen: false);

    final repositoryRegistry =
        Provider.of<RepositoryRegistry>(context, listen: false);

    return Scaffold(
      body: ChangeNotifierProvider(
        create: (context) => InsightsViewmodel(
            repositoryRegistry, profilesDriftRepository,
            profile: profile)
          ..init(),
        builder: (context, child) => Consumer<InsightsViewmodel>(
          builder: (context, viewmodel, child) => LoadingBody(
              loadingStatus: viewmodel.loadingStatus,
              isFirstScreen: true,
              resetErrorTextFn: () {
                viewmodel.resetErrorText();
              },
              errorText: viewmodel.errorText,
              widget: InsightsList(
                viewmodel: viewmodel,
              )),
        ),
      ),
    );
  }
}

class InsightsList extends StatelessWidget {
  const InsightsList({
    super.key,
    required this.viewmodel,
  });

  final InsightsViewmodel viewmodel;

  @override
  Widget build(BuildContext context) {
    final appViewmodel = Provider.of<AppViewmodel>(context);
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                AppLocalizations.of(context)!.myInsights,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  ...DateFilterType.values.map((d) => Padding(
                        padding: const EdgeInsets.all(4.0),
                        child: ChoiceChip(
                            onSelected: (_) {
                              if (viewmodel.calculationStatus !=
                                  LoadingStatus.loading) {
                                viewmodel.dateFilterType = d;
                                if (d == DateFilterType.custom) {
                                  showDialog(
                                    context: context,
                                    builder: (context) => StatefulBuilder(
                                        builder: (context, setState) {
                                      return SimpleDialog(
                                        contentPadding: const EdgeInsets.all(8),
                                        title: Text(
                                            AppLocalizations.of(context)!
                                                .dates),
                                        children: [
                                          Container(
                                            width: cardWidth,
                                            padding: const EdgeInsets.all(4.0),
                                            child: TheDatePicker(
                                              initialDate: viewmodel.startDate,
                                              onChanged: (d) async {
                                                await viewmodel.addToFilter(
                                                    sDate: d);
                                                setState(() {});
                                              },
                                              label:
                                                  AppLocalizations.of(context)!
                                                      .startDate,
                                              needTime: false,
                                              datePattern: appViewmodel
                                                      .dateFormat.pattern ??
                                                  AppDateFormat.date1.pattern,
                                            ),
                                          ),
                                          Container(
                                            width: cardWidth,
                                            padding: const EdgeInsets.all(4.0),
                                            child: TheDatePicker(
                                              initialDate: viewmodel.endDate,
                                              onChanged: (d) async {
                                                await viewmodel.addToFilter(
                                                    eDate: d);
                                                setState(() {});
                                              },
                                              label:
                                                  AppLocalizations.of(context)!
                                                      .endDate,
                                              needTime: false,
                                              datePattern: appViewmodel
                                                      .dateFormat.pattern ??
                                                  AppDateFormat.date1.pattern,
                                            ),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.all(8.0),
                                            child: SizedBox(
                                              width: cardWidth,
                                              child: ElevatedButton(
                                                  onPressed: () {
                                                    Navigator.pop(context);
                                                  },
                                                  child: Text(
                                                      AppLocalizations.of(
                                                              context)!
                                                          .save)),
                                            ),
                                          ),
                                          const SizedBox(
                                            height: 12,
                                          )
                                        ],
                                      );
                                    }),
                                  );
                                }
                              }
                            },
                            label: Text(d.label),
                            selected: viewmodel.dateFilterType == d),
                      )),
                ],
              ),
            ),
          ),
          viewmodel.transactions.isNotEmpty
              ? viewmodel.calculationStatus == LoadingStatus.loading
                  ? const SizedBox(
                      height: 200,
                      child: Center(
                        child: CircularProgressIndicator(),
                      ))
                  : Wrap(
                      alignment: WrapAlignment.center,
                      runAlignment: WrapAlignment.center,
                      children: [
                        Visibility(
                          visible: viewmodel.expenseTotals.entries.isNotEmpty,
                          child:
                              ExpensesSplitPieChartCard(viewmodel: viewmodel),
                        ),
                        Visibility(
                          visible: viewmodel.dailyTotalTransactions.length > 1,
                          child: DailyTransactionsBarChartCard(
                              viewmodel: viewmodel),
                        ),
                        Visibility(
                          visible: viewmodel.fundBalances.isNotEmpty &&
                              viewmodel.fundBalances.values.first.length > 1,
                          child:
                              FundBalancesLineChartCard(viewmodel: viewmodel),
                        ),
                        Visibility(
                          visible: viewmodel.weeklyAvgExpenses.isNotEmpty &&
                              viewmodel.dateFilterType.index > 1 &&
                              viewmodel
                                  .weeklyAvgExpenses.values.first.isNotEmpty &&
                              viewmodel.dailyTotalTransactions.length > 14,
                          child: AverageTransactionsBarChartCard(
                              viewmodel: viewmodel),
                        ),
                      ],
                    )
              : SizedBox(
                  height: 200,
                  child: Center(
                      child: Text(
                    AppLocalizations.of(context)!.notEnoughData,
                    style: Theme.of(context).textTheme.titleMedium,
                  )),
                )
        ],
      ),
    );
  }
}
