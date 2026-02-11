import 'package:flutter/material.dart';
import 'package:pursenal/core/repositories/repository_registry.dart';
import 'package:pursenal/l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:pursenal/app/global/default_accounts.dart';
import 'package:pursenal/app/global/dimensions.dart';
import 'package:pursenal/app/extensions/currency.dart';
import 'package:pursenal/core/enums/loading_status.dart';
import 'package:pursenal/core/models/domain/profile.dart';
import 'package:pursenal/core/repositories/drift/accounts_drift_repository.dart';
import 'package:pursenal/core/repositories/drift/balances_drift_repository.dart';
import 'package:pursenal/core/repositories/drift/wallets_drift_repository.dart';
import 'package:pursenal/screens/main_screen.dart';
import 'package:pursenal/viewmodels/accounts_import_viewmodel.dart';
import 'package:pursenal/widgets/shared/calculated_field.dart';
import 'package:pursenal/widgets/shared/loading_body.dart';

class AccountsImportScreen extends StatelessWidget {
  const AccountsImportScreen({
    super.key,
    required this.profile,
  });

  final Profile profile;

  @override
  Widget build(BuildContext context) {
    final repositoryRegistry =
        Provider.of<RepositoryRegistry>(context, listen: false);

    return ChangeNotifierProvider<AccountsImportViewmodel>(
      create: (context) => AccountsImportViewmodel(
        repositoryRegistry,
        profile: profile,
      )..init(),
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
              onPressed: () {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                    builder: (context) => MainScreen(profile: profile),
                  ),
                  (route) => false,
                );
                Provider.of<AccountsImportViewmodel>(context)
                    .setLastUpdatedTimeStamp();
              },
              icon: const Icon(Icons.close)),
          title: Consumer<AccountsImportViewmodel>(
              builder: (context, viewmodel, child) =>
                  Text(AppLocalizations.of(context)!.importAccounts)),
        ),
        body: Consumer<AccountsImportViewmodel>(
          builder: (context, viewmodel, child) {
            return LoadingBody(
              errorText: viewmodel.errorText,
              loadingStatus: viewmodel.loadingStatus,
              widget: AccountsImportList(
                profile: profile,
                viewmodel: viewmodel,
              ),
              resetErrorTextFn: () {
                viewmodel.resetErrorText();
              },
            );
          },
        ),
      ),
    );
  }
}

class AccountsImportList extends StatelessWidget {
  const AccountsImportList(
      {super.key, required this.viewmodel, required this.profile});

  final AccountsImportViewmodel viewmodel;

  final Profile profile;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: smallWidth,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        AppLocalizations.of(context)!.selectAccountsToCreate,
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: 2, horizontal: 16),
                      child: Text(
                        AppLocalizations.of(context)!.cash,
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                    ),
                    ListTile(
                      contentPadding: const EdgeInsets.symmetric(vertical: 4),
                      title: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(defaultCash.entries.first.key),
                      ),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(
                            vertical: 2, horizontal: 16),
                        width: 200,
                        child: CalculatedField(
                            amount: viewmodel.cashOpenBalance.toCurrency(),
                            onChanged: (v) {
                              viewmodel.cashOpenBalance =
                                  v?.toIntCurrency() ?? 0;
                            },
                            label: AppLocalizations.of(context)!.openingBalance,
                            currency: profile.currency),
                      ),
                    ),
                    ExpansionTile(
                      title: Text(
                        AppLocalizations.of(context)!.expenses,
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      children: [
                        ...defaultExpense.entries.map((e) => CheckboxListTile(
                            title: Text(e.key),
                            value: viewmodel.selectedExpense.contains(e.key),
                            onChanged: (v) {
                              viewmodel.addToImport(e: e.key);
                            })),
                      ],
                    ),
                    ExpansionTile(
                      title: Text(
                        AppLocalizations.of(context)!.incomes,
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      children: [
                        ...defaultIncome.entries.map((i) => CheckboxListTile(
                            title: Text(i.key),
                            value: viewmodel.selectedIncome.contains(i.key),
                            onChanged: (v) {
                              viewmodel.addToImport(i: i.key);
                            })),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            Center(
              child: SizedBox(
                width: double.maxFinite,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: ElevatedButton(
                    onPressed: () async {
                      if (viewmodel.loadingStatus != LoadingStatus.submitting) {
                        bool isSaved = await viewmodel.save();
                        if (isSaved && context.mounted) {
                          viewmodel.setLastUpdatedTimeStamp();
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  MainScreen(profile: profile),
                            ),
                            (route) => false,
                          );
                        }
                      }
                    },
                    child: Text(AppLocalizations.of(context)!.save,
                        style: const TextStyle(fontSize: 22)),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
