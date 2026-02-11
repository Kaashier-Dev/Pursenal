import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pursenal/app/extensions/currency.dart';
import 'package:pursenal/core/enums/currency.dart';
import 'package:pursenal/core/enums/voucher_type.dart';
import 'package:pursenal/l10n/app_localizations.dart';
import 'package:pursenal/viewmodels/app_viewmodel.dart';

class TransactionTile2 extends StatelessWidget {
  /// A list tile for a single transaction : mobile
  const TransactionTile2(
      {super.key,
      required this.vchDate,
      required this.accountName,
      required this.amount,
      required this.onClick,
      required this.vchType,
      required this.transactionID,
      this.fundName,
      required this.narr,
      this.isTransfer = false,
      required this.currency,
      this.isColorful = false,
      this.isNegative = false});

  /// Transaction voucher date
  final DateTime vchDate;

  /// Transaction account
  final String accountName;

  /// Transaction amount
  final int amount;

  /// On click callback function
  final Function onClick;

  /// Transaction voucher type
  final VoucherType vchType;

  /// Transaction id
  final int transactionID;

  /// Fund used for transaction
  final String? fundName;

  /// Transaction details text
  final String narr;

  /// Whether fund is a transfer to another fund
  final bool isTransfer;

  /// Whether the tile should show the amount with a negative sign
  final bool isNegative;

  /// Currency from profile
  final Currency currency;

  /// Whether to show different color for elements
  final bool isColorful;

  @override
  Widget build(BuildContext context) {
    final appViewmodel = Provider.of<AppViewmodel>(context);
    return Material(
      color: Colors.transparent,
      child: ListTile(
        minVerticalPadding: 2,
        visualDensity: const VisualDensity(horizontal: 0.5, vertical: 0.5),
        title: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "#$transactionID",
                  style: Theme.of(context)
                      .textTheme
                      .labelSmall
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                Expanded(
                  child: Text(
                    fundName != null
                        ? isTransfer
                            ? AppLocalizations.of(context)!
                                .transferFrom(fundName!)
                            : vchType == VoucherType.payment
                                ? AppLocalizations.of(context)!
                                    .paidFrom(fundName!)
                                : AppLocalizations.of(context)!
                                    .receivedIn(fundName!)
                        : "",
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.end,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ],
            ),
            Row(
              children: [
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        accountName,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context)
                            .textTheme
                            .bodyLarge
                            ?.copyWith(fontWeight: FontWeight.bold),
                        maxLines: 2,
                      ),
                      Padding(
                        padding: const EdgeInsets.only(left: 10),
                        child: Text(narr,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleSmall),
                      )
                    ],
                  ),
                ),
                Text(
                  "${isTransfer ? "" : isNegative ? "-" : "+"} ${amount.toCurrencyString(currency)}",
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: (isTransfer) || !isColorful
                          ? null
                          : isNegative
                              ? appViewmodel.paymentColor
                              : appViewmodel.receiptColor),
                  maxLines: 2,
                  overflow: TextOverflow.fade,
                ),
              ],
            ),
          ],
        ),
        onTap: () {
          onClick();
        },
      ),
    );
  }
}
