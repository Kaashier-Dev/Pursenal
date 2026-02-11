import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:pursenal/app/global/date_formats.dart';
import 'package:pursenal/app/global/values.dart';
import 'package:pursenal/app/extensions/currency.dart';
import 'package:pursenal/app/extensions/datetime.dart';
import 'package:pursenal/core/enums/voucher_type.dart';
import 'package:pursenal/l10n/app_localizations.dart';
import 'package:pursenal/core/models/domain/account.dart';
import 'package:pursenal/core/models/domain/profile.dart';
import 'package:pursenal/core/models/domain/transaction.dart';
import 'package:pursenal/screens/transaction_screen.dart';
import 'package:pursenal/viewmodels/app_viewmodel.dart';
import 'package:pursenal/widgets/shared/transaction_tile2.dart';

class TransactionsList extends StatelessWidget {
  /// Transactions list for mobile screen
  const TransactionsList(
      {super.key,
      required this.scrollController,
      required this.fDates,
      required this.fTransactions,
      required this.profile,
      required this.initFn,
      this.account});

  /// Scroll controller for the screen
  final ScrollController? scrollController;

  /// Filtered dates for transactions
  final Set<DateTime> fDates;

  /// Filtered transactions
  final List<Transaction> fTransactions;

  /// App Profile
  final Profile profile;

  /// Viewmodel init function
  final Function initFn;

  /// Whether a specific account is selected for transactions
  final Account? account;

  @override
  Widget build(BuildContext context) {
    final appViewmodel = Provider.of<AppViewmodel>(context);
    final bool hasAccount = account != null;
    final bool isColorful = !hasAccount ||
        (hasAccount && fundingAccountIDs.contains(account!.accountType));
    return ListView.builder(
      cacheExtent: 20,
      controller: scrollController,
      padding: const EdgeInsets.only(bottom: 100),
      itemCount: fDates.length,
      itemBuilder: (context, index) {
        final vchDate = fDates.elementAt(index);
        final todayTransactions =
            fTransactions.where((tr) => tr.voucherDate.isSameDayAs(vchDate));

        int totalPayments = 0;
        int totalReceipts = 0;

        for (var t in todayTransactions.where((a) =>
            !(fundingAccountIDs.contains(a.crAccount.accountType) &&
                fundingAccountIDs.contains(a.drAccount.accountType)))) {
          if (t.voucherType == VoucherType.payment) {
            totalPayments += t.amount;
          } else if (t.voucherType == VoucherType.receipt) {
            totalReceipts += t.amount;
          }
        }

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(2.0),
                child: Card(
                  color: Theme.of(context).primaryColor.withAlpha(24),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4)),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(2.0),
                          child: Text(
                            style: const TextStyle(
                                fontSize: 28, fontWeight: FontWeight.w700),
                            vchDate.day.toString(),
                          ),
                        ),
                        const SizedBox(
                          width: 2,
                        ),
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              style: const TextStyle(fontSize: 12),
                              monthString.format(vchDate),
                            ),
                            Text(
                              yearString.format(vchDate),
                              style: const TextStyle(fontSize: 10),
                            ),
                          ],
                        ),
                        const Spacer(),
                        Column(
                          children: [
                            Text(
                              AppLocalizations.of(context)!.receipts,
                              style: const TextStyle(fontSize: 10),
                            ),
                            Text(
                              "+ ${totalReceipts.toCurrencyString(profile.currency)}",
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyLarge
                                  ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: appViewmodel.receiptColor),
                              overflow: TextOverflow.fade,
                            ),
                          ],
                        ),
                        const SizedBox(
                          width: 14,
                        ),
                        Column(
                          children: [
                            Text(
                              AppLocalizations.of(context)!.payments,
                              style: const TextStyle(fontSize: 10),
                            ),
                            Text(
                              "- ${totalPayments.toCurrencyString(profile.currency)}",
                              overflow: TextOverflow.fade,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyLarge
                                  ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: appViewmodel.paymentColor),
                            ),
                          ],
                        ),
                        const SizedBox(
                          width: 8,
                        )
                      ],
                    ),
                  ),
                ),
              ),
              ...todayTransactions.map((t) {
                final int amount = t.amount;

                final bool isTransfer =
                    fundingAccountIDs.contains(t.drAccount.accountType) &&
                        fundingAccountIDs.contains(t.crAccount.accountType) &&
                        !hasAccount;

                final Account acc = hasAccount
                    ? [t.crAccount, t.drAccount]
                        .firstWhere((a) => a.dbID != account!.dbID)
                    : (t.voucherType == VoucherType.payment
                        ? t.drAccount
                        : t.crAccount);

                final bool isNegative = !isTransfer &&
                    ((t.voucherType == VoucherType.payment &&
                            (!hasAccount ||
                                account!.dbID == t.crAccount.dbID)) ||
                        (t.voucherType == VoucherType.receipt &&
                            t.crAccount.dbID != acc.dbID &&
                            fundingAccountIDs
                                .contains(t.crAccount.accountType)));

                final String accountName = acc.name;
                final String? fundName = hasAccount
                    ? null
                    : (t.voucherType == VoucherType.receipt
                        ? t.drAccount.name
                        : t.crAccount.name);
                return TransactionTile2(
                  isColorful: isColorful,
                  currency: profile.currency,
                  vchDate: t.voucherDate,
                  isNegative: isNegative,
                  accountName: accountName,
                  isTransfer: isTransfer,
                  amount: amount,
                  onClick: () {
                    Navigator.of(context)
                        .push(MaterialPageRoute(
                      builder: (context) => TransactionScreen(
                        transaction: t,
                        profile: profile,
                      ),
                    ))
                        .then((_) {
                      initFn();
                    });
                  },
                  vchType: t.voucherType,
                  transactionID: t.dbID,
                  narr: t.narration,
                  fundName: fundName,
                );
              })
            ],
          ),
        ).animate().fade(duration: 250.ms);
      },
    );
  }
}
