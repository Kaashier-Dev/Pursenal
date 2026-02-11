import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:pursenal/app/global/dimensions.dart';
import 'package:pursenal/app/extensions/currency.dart';
import 'package:pursenal/core/models/domain/account_type.dart';
import 'package:pursenal/core/models/domain/ledger.dart';
import 'package:pursenal/core/models/domain/profile.dart';
import 'package:pursenal/core/repositories/drift/account_types_drift_repository.dart';
import 'package:pursenal/core/repositories/drift/accounts_drift_repository.dart';
import 'package:pursenal/core/repositories/drift/banks_drift_repository.dart';
import 'package:pursenal/core/repositories/drift/ccards_drift_repository.dart';
import 'package:pursenal/core/repositories/drift/loans_drift_repository.dart';
import 'package:pursenal/core/repositories/drift/wallets_drift_repository.dart';
import 'package:pursenal/core/repositories/repository_registry.dart';
import 'package:pursenal/screens/account_entry_screen.dart';
import 'package:pursenal/screens/balance_account_screen.dart';
import 'package:pursenal/viewmodels/balances_viewmodel.dart';
import 'package:pursenal/widgets/shared/acc_type_dialog.dart';
import 'package:pursenal/widgets/shared/acc_type_icon.dart';
import 'package:pursenal/widgets/shared/loading_body.dart';
import 'package:pursenal/widgets/shared/the_divider.dart';
import 'package:pursenal/l10n/app_localizations.dart';

class BalancesScreen extends StatelessWidget {
  const BalancesScreen({
    super.key,
    required this.profile,
  });
  final Profile profile;

  @override
  Widget build(BuildContext context) {
    final repositoryRegistry =
        Provider.of<RepositoryRegistry>(context, listen: false);

    return ChangeNotifierProvider<BalancesViewmodel>(
      create: (context) =>
          BalancesViewmodel(repositoryRegistry, profile: profile)..init(),
      builder: (context, child) => Consumer<BalancesViewmodel>(
        builder: (context, viewmodel, child) => Scaffold(
          body: LoadingBody(
            isFirstScreen: true,
            resetErrorTextFn: () => viewmodel.resetErrorText(),
            loadingStatus: viewmodel.loadingStatus,
            errorText: viewmodel.errorText,
            widget: LayoutBuilder(
              builder: (context, constraints) {
                bool isWide = constraints.maxWidth > smallWidth;
                final isVeryWide = constraints.maxWidth > mediumWidth;

                return SingleChildScrollView(
                  padding: const EdgeInsets.only(bottom: 50, left: 4, right: 4),
                  child: Column(
                    crossAxisAlignment: isVeryWide
                        ? CrossAxisAlignment.start
                        : CrossAxisAlignment.center,
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          child: Text(
                            AppLocalizations.of(context)!.myFunds,
                            style: Theme.of(context).textTheme.headlineMedium,
                          ),
                        ),
                      ),
                      Wrap(
                        alignment: WrapAlignment.center,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        runAlignment: WrapAlignment.center,
                        children: [
                          ...viewmodel.fundAccountTypes.map((a) => FundsCard(
                                accountType: a,
                                profile: profile,
                                viewmodel: viewmodel,
                                width: isWide ? 400 : null,
                                balanceAccounts: viewmodel.funds
                                    .where((ac) =>
                                        ac.account.accountType == a.dbID)
                                    .toList(),
                              )),
                        ],
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12.0),
                        child: TheDivider(
                          indent: 0,
                        ),
                      ),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          child: Text(
                            AppLocalizations.of(context)!.myCredits,
                            style: Theme.of(context).textTheme.headlineMedium,
                          ),
                        ),
                      ),
                      Wrap(
                        alignment: WrapAlignment.center,
                        runAlignment: WrapAlignment.center,
                        children: [
                          ...viewmodel.creditAccountTypes.map((a) => FundsCard(
                                accountType: a,
                                profile: profile,
                                viewmodel: viewmodel,
                                width: isWide ? 400 : null,
                                balanceAccounts: viewmodel.credits
                                    .where((ac) =>
                                        ac.account.accountType == a.dbID)
                                    .toList(),
                              )),
                        ],
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12.0),
                        child: TheDivider(
                          indent: 0,
                        ),
                      ),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          child: Text(
                            AppLocalizations.of(context)!.otherAccounts,
                            style: Theme.of(context).textTheme.headlineMedium,
                          ),
                        ),
                      ),
                      Wrap(
                        alignment: WrapAlignment.center,
                        runAlignment: WrapAlignment.center,
                        children: [
                          ...viewmodel.otherAccountAccountTypes
                              .map((a) => FundsCard(
                                    accountType: a,
                                    profile: profile,
                                    viewmodel: viewmodel,
                                    width: isWide ? 400 : null,
                                    balanceAccounts: viewmodel.otherAccounts
                                        .where((ac) =>
                                            ac.account.accountType == a.dbID)
                                        .toList(),
                                  )),
                        ],
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12.0),
                        child: TheDivider(
                          indent: 0,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () async {
              showDialog(
                context: context,
                builder: (context) => AccountTypeDialog(
                  profile: profile,
                  accountTypes: viewmodel.balanceAccountTypes,
                  initFn: () {
                    viewmodel.init();
                  },
                ),
              );
            },
            heroTag: "addFund",
            child: const Icon(Icons.add),
          ),
        ),
      ),
    );
  }
}

class FundsCard extends StatelessWidget {
  const FundsCard({
    super.key,
    required this.accountType,
    required this.profile,
    required this.viewmodel,
    required this.balanceAccounts,
    this.width,
  });

  final AccountType accountType;
  final Profile profile;
  final BalancesViewmodel viewmodel;
  final double? width;
  final List<Ledger> balanceAccounts;

  @override
  Widget build(BuildContext context) {
    int balance = viewmodel.getBalanceByAccountType(accountType.dbID);
    return Padding(
      padding: const EdgeInsets.all(0.0),
      child: SizedBox(
          width: width,
          child: Card(
            elevation: 1.4,
            shape: RoundedRectangleBorder(
              borderRadius: const BorderRadius.all(Radius.circular(8)),
              side:
                  BorderSide(color: Theme.of(context).primaryColor, width: 0.4),
            ),
            child: InkWell(
              borderRadius: const BorderRadius.all(Radius.circular(8)),
              onTap: () {
                if (balanceAccounts.isEmpty) {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AccountEntryScreen(
                          profile: profile,
                          accountType: accountType,
                        ),
                      )).then((_) {
                    viewmodel.init();
                  });
                }
              },
              child: ExpansionTile(
                enabled: balanceAccounts.isNotEmpty,
                initiallyExpanded: balanceAccounts.isNotEmpty,
                minTileHeight: 64,
                leading: Icon(
                  getAccTypeIcon(accountType.dbID),
                  color: Theme.of(context).textTheme.titleMedium?.color,
                ),
                backgroundColor: Theme.of(context).cardColor,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(8)),
                ),
                collapsedShape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                title: Text(
                  accountType.name,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                trailing: Text(
                  balance.toCurrencyStringWSymbol(profile.currency),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                children: [
                  const TheDivider(
                    indent: 0,
                  ),
                  ...balanceAccounts.map((f) {
                    return ListTile(
                      shape: Border(
                          bottom: BorderSide(
                              color: Theme.of(context).shadowColor,
                              width: 0.10)),
                      title: Text(
                        f.account.name,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      trailing: Text(
                        f.balance.toCurrencyString(profile.currency),
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      onTap: () async {
                        if (context.mounted) {
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => BalanceAccountScreen(
                                  profile: profile,
                                  account: f.account,
                                ),
                              )).then((_) {
                            viewmodel.init();
                          });
                        }
                      },
                    );
                  }),
                  const SizedBox(
                    height: 12,
                  )
                ],
              ),
            ),
          )
              .animate()
              .scale(begin: const Offset(1.02, 1.02), duration: 100.ms)
              .fade(curve: Curves.easeInOut, duration: 100.ms)),
    );
  }
}
