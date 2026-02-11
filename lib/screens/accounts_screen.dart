import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:pursenal/app/global/dimensions.dart';
import 'package:pursenal/app/global/values.dart';
import 'package:pursenal/app/extensions/currency.dart';
import 'package:pursenal/core/enums/loading_status.dart';
import 'package:pursenal/core/models/domain/profile.dart';
import 'package:pursenal/core/repositories/drift/account_types_drift_repository.dart';
import 'package:pursenal/core/repositories/drift/accounts_drift_repository.dart';
import 'package:pursenal/core/repositories/repository_registry.dart';
import 'package:pursenal/screens/account_entry_screen.dart';
import 'package:pursenal/screens/account_screen.dart';
import 'package:pursenal/viewmodels/accounts_viewmodel.dart';
import 'package:pursenal/widgets/shared/acc_type_icon.dart';
import 'package:pursenal/widgets/shared/loading_body.dart';
import 'package:pursenal/widgets/shared/search_field.dart';
import 'package:pursenal/l10n/app_localizations.dart';

class AccountsScreen extends StatelessWidget {
  const AccountsScreen({
    super.key,
    required this.profile,
    this.accType,
  });
  final Profile profile;
  final int? accType;

  @override
  Widget build(BuildContext context) {
    final repositoryRegistry =
        Provider.of<RepositoryRegistry>(context, listen: false);
    return ChangeNotifierProvider<AccountsViewmodel>(
      create: (context) => AccountsViewmodel(
        repositoryRegistry,
        profile: profile,
      )..init(),
      builder: (context, child) => Consumer<AccountsViewmodel>(
        builder: (context, viewmodel, child) => Scaffold(
          appBar: AppBar(
            title: Text(AppLocalizations.of(context)!.accounts),
          ),
          body: LoadingBody(
            loadingStatus: viewmodel.loadingStatus,
            errorText: viewmodel.errorText,
            resetErrorTextFn: () {
              viewmodel.resetErrorText();
            },
            widget: LayoutBuilder(
              builder: (context, constraints) {
                bool isWide = constraints.maxWidth > 800;

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: AccountsList(
                        viewmodel: viewmodel,
                        isWide: isWide,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) {
                  return SimpleDialog(
                    title: Text(AppLocalizations.of(context)!
                        .select(AppLocalizations.of(context)!.accountType)),
                    children: [
                      ...viewmodel.accTypes.map((a) => ListTile(
                            title: Text(a.name,
                                style:
                                    Theme.of(context).textTheme.headlineSmall),
                            onTap: () {
                              Navigator.pop(context);
                              Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => AccountEntryScreen(
                                      profile: profile,
                                      accountType: a,
                                    ),
                                  )).then(
                                (_) => viewmodel.init(),
                              );
                            },
                          )),
                      const SizedBox(
                        height: 12,
                      )
                    ],
                  );
                },
              );
            },
            heroTag: "addAccount",
            child: const Icon(Icons.add),
          ),
        ),
      ),
    );
  }
}

class AccountsList extends StatelessWidget {
  const AccountsList({
    super.key,
    required this.viewmodel,
    required this.isWide,
  });

  final AccountsViewmodel viewmodel;
  final bool isWide;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: smallWidth),
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text(
                  AppLocalizations.of(context)!.myXAccounts(
                      viewmodel.accType != null ? viewmodel.accType!.name : ""),
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Row(
                children: [
                  Expanded(
                      child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
                    child: SizedBox(
                      height: 50,
                      child: ElevatedButton(
                        onPressed: () {
                          viewmodel.accTypeID = 4;
                        },
                        style: ButtonStyle(
                          backgroundColor: WidgetStatePropertyAll(
                              viewmodel.accTypeID == 4
                                  ? Theme.of(context).primaryColor
                                  : Theme.of(context).disabledColor),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(AppLocalizations.of(context)!.incomes),
                            const SizedBox(
                              width: 10,
                            ),
                            Icon(
                              getAccTypeIcon(incomeTypeID),
                              color: Colors.white,
                            )
                          ],
                        ),
                      ),
                    ),
                  )),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 2, vertical: 2),
                      child: SizedBox(
                        height: 50,
                        child: ElevatedButton(
                            style: ButtonStyle(
                              backgroundColor: WidgetStatePropertyAll(
                                  viewmodel.accTypeID == 5
                                      ? Theme.of(context).primaryColor
                                      : Theme.of(context).disabledColor),
                            ),
                            onPressed: () {
                              viewmodel.accTypeID = 5;
                            },
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(AppLocalizations.of(context)!.expenses),
                                const SizedBox(
                                  width: 10,
                                ),
                                Icon(
                                  getAccTypeIcon(expenseTypeID),
                                  color: Colors.white,
                                )
                              ],
                            )),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SearchField(searchFn: (term) {
              viewmodel.searchTerm = term;
            }),
            Expanded(child: Builder(builder: (_) {
              if (viewmodel.searchLoadingStatus == LoadingStatus.completed) {
                return ListView.builder(
                  itemCount: viewmodel.fLedgers.length,
                  padding: const EdgeInsets.only(bottom: 50),
                  itemBuilder: (context, index) {
                    final a = viewmodel.fLedgers[index];

                    return ListTile(
                      onTap: () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => AccountScreen(
                                profile: viewmodel.profile,
                                account: a.account,
                              ),
                            )).then((_) {
                          viewmodel.init();
                        });
                      },
                      shape: Border(
                          bottom: BorderSide(
                              color: Theme.of(context).shadowColor,
                              width: 0.10)),
                      title: Text(a.account.name,
                          style: Theme.of(context).textTheme.titleMedium),
                      trailing: Text(
                          a.balance
                              .toCurrencyString(viewmodel.profile.currency),
                          style: Theme.of(context).textTheme.titleMedium),
                    );
                  },
                )
                    .animate(delay: 100.ms)
                    .scale(begin: const Offset(1.02, 1.02), duration: 100.ms)
                    .fade(curve: Curves.easeInOut, duration: 100.ms);
              } else {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              }
            }))
          ],
        ),
      ),
    );
  }
}
