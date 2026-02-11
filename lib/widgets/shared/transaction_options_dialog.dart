import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pursenal/app/global/dimensions.dart';
import 'package:pursenal/app/global/values.dart';
import 'package:pursenal/app/extensions/currency.dart';
import 'package:pursenal/core/enums/currency.dart';
import 'package:pursenal/core/enums/voucher_type.dart';
import 'package:pursenal/core/models/domain/account.dart';
import 'package:pursenal/core/models/domain/ledger.dart';
import 'package:pursenal/core/models/domain/profile.dart';
import 'package:pursenal/screens/transaction_entry_screen.dart';
import 'package:pursenal/l10n/app_localizations.dart';
import 'package:pursenal/viewmodels/app_viewmodel.dart';
import 'package:pursenal/widgets/shared/search_field.dart';

class TransactionOptionsDialog extends StatefulWidget {
  /// Dialog with options that will prefill the transaction entry screen
  const TransactionOptionsDialog(
      {super.key,
      required this.ledgers,
      required this.profile,
      required this.reloadFn,
      this.vType,
      this.fAcc,
      this.oAcc,
      required this.currency});

  /// List of ledgers passed to select the fund and account
  final List<Ledger> ledgers;

  /// Selected profile
  final Profile profile;

  /// Function to reload the screen
  final Function reloadFn;

  /// VoucherType for the transaction
  final VoucherType? vType;

  /// Selected fund for the transaction
  final Account? fAcc;

  /// Selected account for transaction
  final Account? oAcc;

  /// Currency from profile
  final Currency currency;

  @override
  State<TransactionOptionsDialog> createState() =>
      _TransactionOptionsDialogState();
}

class _TransactionOptionsDialogState extends State<TransactionOptionsDialog> {
  final voucherTypes = VoucherType.values;
  int pageNo = 0;
  Account? selectedFund;
  Account? selectedAccount;
  VoucherType? voucherType;

  List<Ledger> funds = [];
  List<Ledger> otherAccounts = [];
  List<Ledger> fOtherAccounts = [];

  String accountFilterTerm = "";

  @override
  void initState() {
    voucherType = widget.vType;
    selectedFund = widget.fAcc;
    selectedAccount = widget.oAcc;

    funds = widget.ledgers
        .where((a) =>
            fundIDs.contains(a.accountType.dbID) ||
            cCardTypeID == a.accountType.dbID)
        .toList();
    if (voucherType != null) {
      pageNo = 1;
    }
    if (selectedFund != null) {
      sortOtherAccounts();
    }
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final appViewmodel = Provider.of<AppViewmodel>(context);
    List<String> titles = [
      AppLocalizations.of(context)!.transactionType,
      AppLocalizations.of(context)!.fundForTransaction,
      AppLocalizations.of(context)!.accountForTransaction
    ];
    return AlertDialog(
      titlePadding: const EdgeInsets.all(0),
      title: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24.0, 24.0, 24.0, 0.0),
            child: Text(AppLocalizations.of(context)!.select(titles[pageNo]),
                style: Theme.of(context).textTheme.titleLarge),
          ),
          const SizedBox(
            height: 24,
          ),
          Visibility(
            visible: pageNo == 2,
            child: SizedBox(
                width: smallWidth,
                child: SearchField(searchFn: (f) {
                  setState(() {
                    fOtherAccounts = otherAccounts
                        .where((a) => a
                            .toString()
                            .toLowerCase()
                            .contains(f.toLowerCase()))
                        .toList();
                  });
                })),
          ),
        ],
      ),
      content: SizedBox(
        width: smallWidth,
        child: buildList(appViewmodel.paymentColor, appViewmodel.receiptColor),
      ),
      contentPadding: const EdgeInsets.only(top: 2, bottom: 6),
      actions: [
        TextButton(
            onPressed: () {
              Navigator.pop(context);
              goToTransactionEditScreen();
            },
            child: Text(AppLocalizations.of(context)!.skip))
      ],
    );
  }

  ListView buildList(Color? paymentColor, Color? receiptColor) {
    switch (pageNo) {
      case 0:
        return ListView.builder(
          shrinkWrap: true,
          itemCount: voucherTypes.length,
          itemBuilder: (context, index) {
            final vType = voucherTypes[index];
            return ListTile(
              minTileHeight: 80,
              shape: Border(
                  bottom: BorderSide(
                      color: Theme.of(context).shadowColor, width: 0.10)),
              title: Padding(
                padding: const EdgeInsets.only(left: 20),
                child: Text(
                  vType.label,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: vType == VoucherType.payment
                          ? paymentColor
                          : receiptColor),
                ),
              ),
              onTap: () {
                setState(() {
                  voucherType = vType;
                  checkAndProceed();
                  if (selectedFund != null) {
                    sortOtherAccounts();
                  }
                });
              },
            );
          },
        );
      case 1:
        return ListView.builder(
          shrinkWrap: true,
          itemCount: funds.length,
          itemBuilder: (context, index) => ListTile(
            shape: Border(
                bottom: BorderSide(
                    color: Theme.of(context).shadowColor, width: 0.10)),
            title: Text(
              funds[index].account.name,
              style: Theme.of(context).textTheme.titleMedium,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(
              funds[index].accountType.name,
              style: const TextStyle(fontSize: 12),
              overflow: TextOverflow.ellipsis,
            ),
            trailing: Text(
              funds[index].balance.toCurrencyStringWSymbol(widget.currency),
              style: Theme.of(context).textTheme.bodyMedium,
              overflow: TextOverflow.ellipsis,
            ),
            onTap: () {
              setState(() {
                selectedFund = funds[index].account;
                sortOtherAccounts();
                checkAndProceed();
              });
            },
          ),
        );
      case 2:
        return ListView.builder(
          shrinkWrap: true,
          itemCount: fOtherAccounts.length,
          itemBuilder: (context, index) => Material(
            child: ListTile(
              minVerticalPadding: 2,
              minTileHeight: 10,
              shape: Border(
                  bottom: BorderSide(
                      color: Theme.of(context).shadowColor, width: 0.10)),
              title: Text(
                fOtherAccounts[index].account.name,
                style: Theme.of(context).textTheme.titleMedium,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Text(
                fOtherAccounts[index].accountType.name,
                style: const TextStyle(fontSize: 12),
                overflow: TextOverflow.ellipsis,
              ),
              trailing: Text(
                fOtherAccounts[index]
                    .balance
                    .toCurrencyStringWSymbol(widget.currency),
                style: Theme.of(context).textTheme.bodyMedium,
                overflow: TextOverflow.ellipsis,
              ),
              onTap: () {
                setState(() {
                  selectedAccount = fOtherAccounts[index].account;
                  Navigator.pop(context);
                  goToTransactionEditScreen();
                });
              },
            ),
          ),
        );
      default:
        return ListView();
    }
  }

  checkAndProceed() {
    if (voucherType != null &&
        selectedFund != null &&
        selectedAccount != null) {
      Navigator.pop(context);
      goToTransactionEditScreen();
    } else if (voucherType != null && selectedFund != null) {
      pageNo = 2;
    } else {
      setState(() {
        pageNo++;
      });
    }
  }

  sortOtherAccounts() {
    otherAccounts = widget.ledgers.where((a) {
      return (selectedFund != null && a.account.dbID != selectedFund!.dbID);
    }).toList();

    otherAccounts.sort((a, b) {
      if (voucherType == VoucherType.payment) {
        if (a.accountType.dbID == expenseTypeID) {
          return -1;
        }
      }

      if (voucherType == VoucherType.receipt) {
        if (a.accountType.dbID == incomeTypeID) {
          return -1;
        }
      }

      return 1;
    });
    fOtherAccounts = List.from(otherAccounts);
  }

  goToTransactionEditScreen() {
    Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => TransactionEntryScreen(
            profile: widget.profile,
            selectedAccount: selectedAccount,
            selectedFund: selectedFund,
            voucherType: voucherType,
          ),
        )).then((_) async {
      await widget.reloadFn();
    });
  }
}
