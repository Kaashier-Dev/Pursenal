import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:pursenal/app/global/dimensions.dart';
import 'package:pursenal/app/extensions/currency.dart';
import 'package:pursenal/core/enums/app_date_format.dart';
import 'package:pursenal/core/enums/loading_status.dart';
import 'package:pursenal/core/enums/voucher_type.dart';
import 'package:pursenal/core/models/domain/account.dart';
import 'package:pursenal/core/models/domain/bank.dart';
import 'package:pursenal/core/models/domain/credit_card.dart';
import 'package:pursenal/core/models/domain/loan.dart';
import 'package:pursenal/core/models/domain/profile.dart';
import 'package:pursenal/core/models/domain/wallet.dart';
import 'package:pursenal/core/repositories/drift/accounts_drift_repository.dart';
import 'package:pursenal/core/repositories/drift/balances_drift_repository.dart';
import 'package:pursenal/core/repositories/drift/transactions_drift_repository.dart';
import 'package:pursenal/core/repositories/repository_registry.dart';
import 'package:pursenal/screens/account_entry_screen.dart';
import 'package:pursenal/viewmodels/account_viewmodel.dart';
import 'package:pursenal/viewmodels/app_viewmodel.dart';
import 'package:pursenal/widgets/shared/empty_list.dart';
import 'package:pursenal/widgets/shared/transaction_options_dialog.dart';
import 'package:pursenal/widgets/shared/acc_type_icon.dart';
import 'package:pursenal/widgets/shared/export_button.dart';
import 'package:pursenal/widgets/shared/loading_body.dart';
import 'package:pursenal/widgets/shared/search_field.dart';
import 'package:pursenal/widgets/shared/the_date_picker.dart';
import 'package:pursenal/widgets/shared/the_divider.dart';
import 'package:pursenal/l10n/app_localizations.dart';
import 'package:pursenal/widgets/shared/transactions_list.dart';
import 'package:pursenal/widgets/shared/transactions_list_wide.dart';

class AccountScreen extends StatelessWidget {
  const AccountScreen(
      {super.key,
      required this.profile,
      required this.account,
      this.wallet,
      this.bank,
      this.cCard,
      this.loan});
  final Profile profile;
  final Account account;
  final Wallet? wallet;
  final Bank? bank;
  final CreditCard? cCard;
  final Loan? loan;

  @override
  Widget build(BuildContext context) {
    final repositoryRegistry =
        Provider.of<RepositoryRegistry>(context, listen: false);

    final appViewmodel = Provider.of<AppViewmodel>(context);
    return ChangeNotifierProvider<AccountViewmodel>(
      create: (context) => AccountViewmodel(repositoryRegistry,
          profile: profile, account: account)
        ..init(),
      builder: (context, child) => Consumer<AccountViewmodel>(
        builder: (context, viewmodel, child) => Scaffold(
          appBar: AppBar(
            actions: [
              Padding(
                padding: const EdgeInsets.all(2.0),
                child: IconButton(
                    onPressed: () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => AccountEntryScreen(
                              profile: profile,
                              account: account,
                            ),
                          )).then((_) {
                        viewmodel.init();
                      });
                    },
                    icon: const Icon(Icons.edit)),
              ),
              Padding(
                padding: const EdgeInsets.all(2.0),
                child: IconButton(
                    onPressed: () async {
                      await showDialog(
                        context: context,
                        builder: (context) => TransactionOptionsDialog(
                          currency: profile.currency,
                          ledgers: viewmodel.allLedgers,
                          profile: profile,
                          vType: account.accountType == 5
                              ? VoucherType.payment
                              : VoucherType.receipt,
                          oAcc: account,
                          reloadFn: () async {
                            await viewmodel.init();
                          },
                        ),
                      );
                    },
                    icon: const Icon(Icons.add)),
              ),
              const SizedBox(
                width: 12,
              ),
            ],
          ),
          body: LoadingBody(
            loadingStatus: viewmodel.loadingStatus,
            errorText: viewmodel.errorText,
            resetErrorTextFn: () {
              viewmodel.resetErrorText();
            },
            widget: LayoutBuilder(builder: (context, constraints) {
              bool isWide = constraints.maxWidth > 800;

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Visibility(
                      visible: isWide,
                      child: SizedBox(
                        width: 300,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          child: Column(
                            spacing: 5,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: createFilterMenu(
                                viewmodel,
                                context,
                                appViewmodel.dateFormat.pattern ??
                                    AppDateFormat.date1.pattern),
                          ),
                        ),
                      )),
                  Visibility(
                      visible: isWide,
                      child: const VerticalDivider(
                        thickness: .10,
                        width: .10,
                      )),
                  Expanded(
                    child: TransactionsSection(
                      viewmodel: viewmodel,
                      isWide: isWide,
                      constraints: constraints,
                    ),
                  ),
                ],
              );
            }),
          ),
          endDrawer: Drawer(
            shape: const RoundedRectangleBorder(),
            child: SingleChildScrollView(
              child: Container(
                padding: const EdgeInsets.all(8),
                width: double.maxFinite,
                child: ListView(
                  shrinkWrap: true,
                  children: createFilterMenu(
                      viewmodel,
                      context,
                      appViewmodel.dateFormat.pattern ??
                          AppDateFormat.date1.pattern),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

List<Widget> createFilterMenu(
    AccountViewmodel viewmodel, BuildContext context, String datePattern) {
  return [
    Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      child: Text(
        AppLocalizations.of(context)!.filters,
        style: Theme.of(context).textTheme.titleLarge,
      ),
    ),
    Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          Text(
            AppLocalizations.of(context)!.dates,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const Expanded(child: TheDivider()),
        ],
      ),
    ),
    Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
          child: TheDatePicker(
            initialDate: viewmodel.startDate,
            onChanged: (d) {
              viewmodel.addToFilter(sDate: d);
            },
            label: AppLocalizations.of(context)!.startDate,
            needTime: false,
            datePattern: datePattern,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
          child: TheDatePicker(
            initialDate: viewmodel.endDate,
            onChanged: (d) {
              viewmodel.addToFilter(eDate: d);
            },
            label: AppLocalizations.of(context)!.endDate,
            needTime: false,
            datePattern: datePattern,
          ),
        ),
      ],
    )
        .animate()
        .scale(begin: const Offset(1.02, 1.02), duration: 100.ms)
        .fade(curve: Curves.easeInOut, duration: 100.ms),
    Visibility(
      visible: viewmodel.transactions.isNotEmpty,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          children: [
            Text(
              AppLocalizations.of(context)!.transactionTypes,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const Expanded(child: TheDivider()),
          ],
        ),
      ),
    ),
    Wrap(
      spacing: 4,
      runSpacing: 4,
      children: [
        ...viewmodel.voucherTypes.toList().map((v) => FilterChip(
            selected: !viewmodel.voucherTypeFilters.contains(v),
            label: Text(v.label),
            onSelected: (s) {
              viewmodel.addToFilter(voucherType: v);
            }))
      ],
    )
        .animate(delay: 50.ms)
        .scale(begin: const Offset(1.02, 1.02), duration: 100.ms)
        .fade(curve: Curves.easeInOut, duration: 100.ms),
    Visibility(
      visible: viewmodel.transactions.isNotEmpty,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          children: [
            Text(
              AppLocalizations.of(context)!.funds,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const Expanded(child: TheDivider()),
          ],
        ),
      ),
    ),
    Wrap(
      spacing: 4,
      runSpacing: 4,
      children: [
        ...viewmodel.otherAccounts.toList().map((v) => FilterChip(
            selected: !viewmodel.otherAccountFilters.contains(v.dbID),
            label: Text(v.name),
            onSelected: (s) {
              viewmodel.addToFilter(oAcc: v);
            }))
      ],
    )
        .animate(delay: 100.ms)
        .scale(begin: const Offset(1.02, 1.02), duration: 100.ms)
        .fade(curve: Curves.easeInOut, duration: 100.ms),
  ];
}

class TransactionsSection extends StatelessWidget {
  const TransactionsSection({
    super.key,
    required this.viewmodel,
    required this.isWide,
    required this.constraints,
  });

  final AccountViewmodel viewmodel;
  final bool isWide;
  final BoxConstraints constraints;

  @override
  Widget build(BuildContext context) {
    final appViewmodel = Provider.of<AppViewmodel>(context);
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(
            maxWidth: appViewmodel.isPhone ? smallWidth : double.maxFinite),
        child: Column(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              height: viewmodel.headerHeight,
              curve: Curves.easeInOut,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 16, top: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Text(
                              viewmodel.account.name,
                              style: Theme.of(context).textTheme.headlineMedium,
                            ),
                            const SizedBox(
                              width: 10,
                            ),
                            Icon(
                              getAccTypeIcon(viewmodel.account.accountType),
                              color: Theme.of(context)
                                  .textTheme
                                  .headlineMedium
                                  ?.color,
                            ),
                          ],
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0),
                          child: ExportButton(
                            pdfExportFn: () async {
                              await viewmodel.exportPDF();
                            },
                            xlsxExportFn: () async {
                              await viewmodel.exportXLSX();
                            },
                          ),
                        )
                      ],
                    ),
                  ),
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: GestureDetector(
                        child: Text(
                          AppLocalizations.of(context)!.fromToDate(
                              appViewmodel.dateFormat
                                  .format(viewmodel.startDate),
                              appViewmodel.dateFormat
                                  .format(viewmodel.endDate)),
                          style: Theme.of(context).textTheme.labelSmall,
                        ),
                        onTap: () {
                          if (!isWide) {
                            Scaffold.of(context).openEndDrawer();
                          }
                        },
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: SearchField(searchFn: (term) {
                          viewmodel.searchTerm = term;
                        }),
                      ),
                      Visibility(
                        visible: !isWide,
                        child: Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: IconButton(
                            onPressed: () {
                              Scaffold.of(context).openEndDrawer();
                            },
                            icon: const Icon(Icons.filter_list),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            ListTile(
              title: Text(
                AppLocalizations.of(context)!.openingBalance,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              trailing: Text(
                viewmodel.openBal.toCurrencyString(viewmodel.profile.currency),
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            Visibility(
              visible: viewmodel.fTransactions.isEmpty,
              child: Expanded(
                child: EmptyList(
                    items: AppLocalizations.of(context)!.transactions,
                    addFn: () async {
                      await showDialog(
                        context: context,
                        builder: (context) => TransactionOptionsDialog(
                          currency: viewmodel.profile.currency,
                          ledgers: viewmodel.allLedgers,
                          profile: viewmodel.profile,
                          vType: viewmodel.account.accountType == 5
                              ? VoucherType.payment
                              : VoucherType.receipt,
                          oAcc: viewmodel.account,
                          reloadFn: () async {
                            await viewmodel.init();
                          },
                        ),
                      );
                    },
                    isListFiltered: true),
              ),
            ),
            Visibility(
              visible: viewmodel.fTransactions.isNotEmpty,
              child: Expanded(
                child: Builder(builder: (_) {
                  if (viewmodel.searchLoadingStatus ==
                      LoadingStatus.completed) {
                    if (!appViewmodel.isPhone) {
                      return TransactionsListWide(
                          scrollController: viewmodel.scrollController,
                          fTransactions: viewmodel.fTransactions,
                          profile: viewmodel.profile,
                          account: viewmodel.account,
                          initFn: () {
                            viewmodel.init();
                          });
                    }
                    return TransactionsList(
                        scrollController: viewmodel.scrollController,
                        fDates: viewmodel.fDates,
                        fTransactions: viewmodel.fTransactions,
                        profile: viewmodel.profile,
                        account: viewmodel.account,
                        initFn: () {
                          viewmodel.init();
                        });
                  } else {
                    return const Expanded(
                      child: Center(
                        child: CircularProgressIndicator(),
                      ),
                    );
                  }
                }),
              ),
            ),
            ListTile(
              shape: Border(
                  top: BorderSide(
                      color: Theme.of(context).shadowColor, width: 0.10)),
              title: Text(
                AppLocalizations.of(context)!.closingBalance,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              trailing: Text(
                viewmodel.closeBal.toCurrencyString(viewmodel.profile.currency),
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
