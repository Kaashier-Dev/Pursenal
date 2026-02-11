import 'package:flutter/material.dart';
import 'package:pursenal/core/enums/voucher_type.dart';
import 'package:pursenal/core/models/domain/profile.dart';
import 'package:pursenal/viewmodels/app_viewmodel.dart';
import 'package:pursenal/viewmodels/dashboard_viewmodel.dart';
import 'package:pursenal/widgets/shared/transaction_options_dialog.dart';
import 'package:pursenal/l10n/app_localizations.dart';

class AddTransactionButtonGroup extends StatelessWidget {
  const AddTransactionButtonGroup({
    super.key,
    required this.appViewmodel,
    required this.profile,
    required this.viewmodel,
    this.isWide = false,
  });
  final AppViewmodel appViewmodel;
  final Profile profile;
  final DashboardViewmodel viewmodel;
  final bool isWide;
  @override
  Widget build(BuildContext context) {
    final double buttonRadius = isWide ? 32 : 12;
    return Center(
      child: SizedBox(
        height: 120,
        child: Stack(
          children: [
            Align(
              alignment: Alignment.topCenter,
              child: InkWell(
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(buttonRadius),
                ),
                onTap: () async {
                  await showDialog(
                    context: context,
                    builder: (context) => TransactionOptionsDialog(
                      currency: profile.currency,
                      ledgers: viewmodel.allLedgers,
                      profile: profile,
                      vType: VoucherType.receipt,
                      reloadFn: () async {
                        await viewmodel.init();
                      },
                    ),
                  );
                },
                child: Container(
                  height: 60,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: appViewmodel.receiptColor,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(buttonRadius),
                    ),
                  ),
                  child: Center(
                    child: Text(
                      AppLocalizations.of(context)!.receipt,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontSize: 24,
                          color: Colors.white,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ),
            ),

            Align(
              alignment: Alignment.bottomCenter,
              child: InkWell(
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(buttonRadius),
                ),
                onTap: () async {
                  await showDialog(
                    context: context,
                    builder: (context) => TransactionOptionsDialog(
                      currency: profile.currency,
                      ledgers: viewmodel.allLedgers,
                      profile: profile,
                      vType: VoucherType.payment,
                      reloadFn: () async {
                        await viewmodel.init();
                      },
                    ),
                  );
                },
                child: Container(
                  height: 60,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: appViewmodel.paymentColor,
                    borderRadius: BorderRadius.vertical(
                      bottom: Radius.circular(buttonRadius),
                    ),
                  ),
                  child: Center(
                    child: Text(
                      AppLocalizations.of(context)!.payment,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontSize: 24,
                          color: Colors.white,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ),
            ),

            // White Hole (Center Text Area)
            Align(
              alignment: Alignment.centerLeft,
              child: Container(
                  width: 60,
                  height: 60,
                  margin: const EdgeInsets.only(left: 20),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(30),
                    color: Theme.of(context).primaryColor.withAlpha(100),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.add,
                      size: 50,
                      color: Colors.white,
                    ),
                  )),
            ),
          ],
        ),
      ),
    );
  }
}
