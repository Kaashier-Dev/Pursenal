import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:pursenal/app/global/dimensions.dart';
import 'package:pursenal/app/global/values.dart';
import 'package:pursenal/app/extensions/currency.dart';
import 'package:pursenal/core/enums/app_date_format.dart';
import 'package:pursenal/core/models/domain/account.dart';
import 'package:pursenal/core/models/domain/profile.dart';
import 'package:pursenal/core/repositories/drift/accounts_drift_repository.dart';
import 'package:pursenal/core/repositories/drift/balances_drift_repository.dart';
import 'package:pursenal/core/repositories/drift/banks_drift_repository.dart';
import 'package:pursenal/core/repositories/drift/ccards_drift_repository.dart';
import 'package:pursenal/core/repositories/drift/loans_drift_repository.dart';
import 'package:pursenal/core/repositories/drift/people_drift_repository.dart';
import 'package:pursenal/core/repositories/drift/receivables_drift_repository.dart';
import 'package:pursenal/core/repositories/drift/transactions_drift_repository.dart';
import 'package:pursenal/core/repositories/repository_registry.dart';
import 'package:pursenal/screens/account_entry_screen.dart';
import 'package:pursenal/viewmodels/app_viewmodel.dart';
import 'package:pursenal/viewmodels/balance_account_viewmodel.dart';
import 'package:pursenal/widgets/shared/empty_list.dart';
import 'package:pursenal/widgets/shared/labeled_text.dart';
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

class BalanceAccountScreen extends StatelessWidget {
  const BalanceAccountScreen({
    super.key,
    required this.profile,
    required this.account,
  });
  final Profile profile;
  final Account account;

  @override
  Widget build(BuildContext context) {
    final repositoryRegistry =
        Provider.of<RepositoryRegistry>(context, listen: false);

    final appViewmodel = Provider.of<AppViewmodel>(context);
    return ChangeNotifierProvider<BalanceAccountViewmodel>(
      create: (context) => BalanceAccountViewmodel(repositoryRegistry,
          profile: profile, account: account)
        ..init(),
      builder: (context, child) => Consumer<BalanceAccountViewmodel>(
        builder: (context, viewmodel, child) => Scaffold(
          appBar: AppBar(
            actions: [
              Visibility(
                visible: account.accountType != walletTypeID,
                child: Padding(
                  padding: const EdgeInsets.all(2.0),
                  child: IconButton(
                      onPressed: () {
                        showModalBottomSheet(
                          context: context,
                          clipBehavior: Clip.hardEdge,
                          backgroundColor:
                              Theme.of(context).scaffoldBackgroundColor,
                          constraints:
                              const BoxConstraints(maxWidth: smallWidth),
                          builder: (context) => SizedBox(
                            width: double.infinity,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  vertical: 18, horizontal: 2),
                              child: SingleChildScrollView(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 12),
                                      child: Text(
                                        viewmodel.account.name,
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleLarge,
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 12),
                                      child: Text(
                                        AppLocalizations.of(context)!.details,
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleMedium,
                                      ),
                                    ),
                                    if (account.accountType == bankTypeID &&
                                        viewmodel.bank != null) ...[
                                      // Show Bank specific fields
                                      LabeledText(
                                          label: AppLocalizations.of(context)!
                                              .accountNo,
                                          text: viewmodel.bank!.accountNo),
                                      LabeledText(
                                          label: AppLocalizations.of(context)!
                                              .holderName,
                                          text: viewmodel.bank!.holderName),
                                      LabeledText(
                                          label: AppLocalizations.of(context)!
                                              .institution,
                                          text: viewmodel.bank!.institution),
                                      LabeledText(
                                          label: AppLocalizations.of(context)!
                                              .branch,
                                          text: viewmodel.bank!.branch),
                                      LabeledText(
                                          label: AppLocalizations.of(context)!
                                              .branchCode,
                                          text: viewmodel.bank!.branchCode),
                                    ],
                                    if (account.accountType == cCardTypeID &&
                                        viewmodel.card != null) ...[
                                      // Show Card specific fields
                                      LabeledText(
                                          label: AppLocalizations.of(context)!
                                              .cardNo,
                                          text: viewmodel.card!.cardNo),
                                      LabeledText(
                                          label: AppLocalizations.of(context)!
                                              .institution,
                                          text: viewmodel.card!.institution),
                                      LabeledText(
                                          label: AppLocalizations.of(context)!
                                              .cardNetwork,
                                          text: viewmodel.card!.cardNetwork),

                                      LabeledText(
                                          label: AppLocalizations.of(context)!
                                              .statementDate,
                                          text: viewmodel.card!.statementDate
                                              .toString()),
                                    ],
                                    if (account.accountType == loanTypeID &&
                                        viewmodel.loan != null) ...[
                                      // Show Loan specific fields
                                      LabeledText(
                                          label: AppLocalizations.of(context)!
                                              .accountNo,
                                          text: viewmodel.loan!.accountNo),
                                      LabeledText(
                                          label: AppLocalizations.of(context)!
                                              .institution,
                                          text: viewmodel.loan!.institution),
                                      LabeledText(
                                          label: AppLocalizations.of(context)!
                                              .agreementNo,
                                          text: viewmodel.loan!.agreementNo),

                                      LabeledText(
                                          label: AppLocalizations.of(context)!
                                              .interestRate,
                                          text:
                                              "${viewmodel.loan!.interestRate.toString()}%"),

                                      Visibility(
                                        visible:
                                            viewmodel.loan!.startDate != null,
                                        child: LabeledText(
                                          label: AppLocalizations.of(context)!
                                              .startDate,
                                          text: appViewmodel.dateFormat.format(
                                              viewmodel.loan!.startDate!),
                                        ),
                                      ),
                                      Visibility(
                                        visible:
                                            viewmodel.loan!.endDate != null,
                                        child: LabeledText(
                                          label: AppLocalizations.of(context)!
                                              .endDate,
                                          text: appViewmodel.dateFormat
                                              .format(viewmodel.loan!.endDate!),
                                        ),
                                      ),
                                    ],
                                    if (account.accountType == advanceTypeID &&
                                        viewmodel.receivable != null) ...[
                                      // Show Receivable specific fields
                                      LabeledText(
                                          label: AppLocalizations.of(context)!
                                              .totalAdvancePaid,
                                          text: viewmodel
                                              .receivable!.totalAmount
                                              ?.toCurrencyString(
                                                  profile.currency)),
                                      Visibility(
                                        visible:
                                            viewmodel.receivable!.paidDate !=
                                                null,
                                        child: LabeledText(
                                            label: AppLocalizations.of(context)!
                                                .paidDate,
                                            text: appViewmodel.dateFormat
                                                .format(viewmodel
                                                    .receivable!.paidDate!)),
                                      ),
                                    ],
                                    if (account.accountType == peopleTypeID &&
                                        viewmodel.people != null) ...[
                                      // Show People specific fields
                                      LabeledText(
                                          label: AppLocalizations.of(context)!
                                              .address,
                                          text: viewmodel.people!.address),

                                      LabeledText(
                                          label:
                                              AppLocalizations.of(context)!.zip,
                                          text: viewmodel.people!.zip),
                                      LabeledText(
                                          label: AppLocalizations.of(context)!
                                              .email,
                                          text: viewmodel.people!.email),
                                      LabeledText(
                                          label: AppLocalizations.of(context)!
                                              .phone,
                                          text: viewmodel.people!.phone),
                                      LabeledText(
                                          label: "ID",
                                          text: viewmodel.people!.tin),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.info_outline)),
                ),
              ),
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
                          oAcc: (account.accountType == peopleTypeID ||
                                  account.accountType == advanceTypeID)
                              ? account
                              : null,
                          fAcc: fundingAccountIDs.contains(account.accountType)
                              ? account
                              : null,
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
            feedbackText: viewmodel.feedbackText,
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
                          child: SingleChildScrollView(
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

List<Widget> createFilterMenu(BalanceAccountViewmodel viewmodel,
    BuildContext context, String datePattern) {
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
          )
              .animate()
              .scale(begin: const Offset(1.02, 1.02), duration: 100.ms)
              .fade(curve: Curves.easeInOut, duration: 100.ms),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
          child: TheDatePicker(
            initialDate: viewmodel.endDate,
            onChanged: (d) {
              viewmodel.addToFilter(eDate: d);
            },
            label: AppLocalizations.of(context)!.endDate,
            datePattern: datePattern,
            needTime: false,
          )
              .animate()
              .scale(begin: const Offset(1.02, 1.02), duration: 100.ms)
              .fade(curve: Curves.easeInOut, duration: 100.ms),
        ),
      ],
    ),
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
              AppLocalizations.of(context)!.accounts,
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

  final BalanceAccountViewmodel viewmodel;
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
                          oAcc:
                              (viewmodel.account.accountType == peopleTypeID ||
                                      viewmodel.account.accountType ==
                                          advanceTypeID)
                                  ? viewmodel.account
                                  : null,
                          fAcc: fundingAccountIDs
                                  .contains(viewmodel.account.accountType)
                              ? viewmodel.account
                              : null,
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
                  if (!appViewmodel.isPhone) {
                    return TransactionsListWide(
                        scrollController: viewmodel.scrollController,
                        account: viewmodel.account,
                        fTransactions: viewmodel.fTransactions,
                        profile: viewmodel.profile,
                        initFn: () {
                          viewmodel.init();
                        });
                  }
                  return TransactionsList(
                      scrollController: viewmodel.scrollController,
                      fDates: viewmodel.fDates,
                      account: viewmodel.account,
                      fTransactions: viewmodel.fTransactions,
                      profile: viewmodel.profile,
                      initFn: () {
                        viewmodel.init();
                      });
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
