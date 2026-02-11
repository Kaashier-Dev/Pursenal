import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:pursenal/app/global/dimensions.dart';
import 'package:pursenal/app/global/values.dart';
import 'package:pursenal/core/enums/voucher_type.dart';
import 'package:pursenal/screens/transaction_screen.dart';
import 'package:pursenal/viewmodels/dashboard_viewmodel.dart';
import 'package:pursenal/viewmodels/main_viewmodel.dart';
import 'package:pursenal/widgets/shared/the_divider.dart';
import 'package:pursenal/l10n/app_localizations.dart';
import 'package:pursenal/widgets/shared/transaction_tile.dart';

class TransactionsCard extends StatelessWidget {
  const TransactionsCard({
    super.key,
    required this.viewmodel,
  });

  final DashboardViewmodel viewmodel;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(
          maxWidth: cardWidth, minWidth: 300, minHeight: 200),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Row(
                  children: [
                    const Expanded(child: TheDivider()),
                    Text(
                      AppLocalizations.of(context)!.recentTransactions,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const Expanded(child: TheDivider()),
                  ],
                ),
              ),
              const SizedBox(
                height: 10,
              ),
              ...viewmodel.recentTransactions.map((t) => TransactionTile(
                  isColorful: true,
                  isNegative: t.voucherType == VoucherType.payment,
                  vchDate: t.voucherDate,
                  accountName: t.voucherType == VoucherType.payment
                      ? t.drAccount.name
                      : t.crAccount.name,
                  amount: t.amount,
                  isTransfer:
                      (fundingAccountIDs.contains(t.drAccount.accountType) &&
                          fundingAccountIDs.contains(t.crAccount.accountType)),
                  onClick: () {
                    Navigator.of(context)
                        .push(MaterialPageRoute(
                      builder: (context) => TransactionScreen(
                        transaction: t,
                        profile: viewmodel.selectedProfile,
                      ),
                    ))
                        .then((_) {
                      viewmodel.init();
                    });
                  },
                  vchType: t.voucherType,
                  transactionID: t.dbID,
                  narr: t.narration,
                  currency: viewmodel.selectedProfile.currency)),
              viewmodel.recentTransactions.length >= viewmodel.recentCount
                  ? Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: TextButton(
                          onPressed: () {
                            Provider.of<MainViewmodel>(context, listen: false)
                                .setIndex(2);
                          },
                          child: Text(AppLocalizations.of(context)!.more)),
                    )
                  : const SizedBox(
                      height: 12,
                    )
            ],
          ),
        ),
      )
          .animate(delay: 150.ms)
          .scale(begin: const Offset(1.02, 1.02), duration: 100.ms)
          .fade(curve: Curves.easeInOut, duration: 100.ms),
    );
  }
}
