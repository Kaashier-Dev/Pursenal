import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pursenal/app/global/date_formats.dart';
import 'package:pursenal/app/global/dimensions.dart';
import 'package:pursenal/app/global/values.dart';
import 'package:pursenal/app/extensions/currency.dart';
import 'package:pursenal/core/enums/voucher_type.dart';
import 'package:pursenal/core/models/domain/profile.dart';
import 'package:pursenal/core/models/domain/transaction.dart';
import 'package:pursenal/core/repositories/drift/balances_drift_repository.dart';
import 'package:pursenal/core/repositories/drift/projects_drift_repository.dart';
import 'package:pursenal/core/repositories/drift/transactions_drift_repository.dart';
import 'package:pursenal/core/repositories/repository_registry.dart';
import 'package:pursenal/screens/transaction_entry_screen.dart';
import 'package:pursenal/viewmodels/app_viewmodel.dart';
import 'package:pursenal/viewmodels/transaction_viewmodel.dart';
import 'package:pursenal/widgets/shared/image_carousel.dart';
import 'package:pursenal/widgets/shared/loading_body.dart';
import 'package:pursenal/l10n/app_localizations.dart';

class TransactionScreen extends StatelessWidget {
  const TransactionScreen({
    super.key,
    required this.profile,
    required this.transaction,
  });
  final Profile profile;
  final Transaction transaction;

  @override
  Widget build(BuildContext context) {
    final repositoryRegistry =
        Provider.of<RepositoryRegistry>(context, listen: false);

    final appViewmodel = Provider.of<AppViewmodel>(context);
    return ChangeNotifierProvider<TransactionViewmodel>(
      create: (context) => TransactionViewmodel(repositoryRegistry,
          profile: profile, transaction: transaction)
        ..init(),
      child: Consumer<TransactionViewmodel>(
        builder: (context, viewmodel, child) {
          final Transaction transaction = viewmodel.transaction;

          return LoadingBody(
              loadingStatus: viewmodel.loadingStatus,
              errorText: viewmodel.errorText,
              resetErrorTextFn: () {
                viewmodel.resetErrorText();
              },
              widget: Scaffold(
                appBar: AppBar(
                  title: Text(AppLocalizations.of(context)!
                      .transactionNo(transaction.dbID)),
                  actions: [
                    Padding(
                      padding: const EdgeInsets.all(2.0),
                      child: IconButton(
                          onPressed: () {
                            Navigator.of(context)
                                .push(MaterialPageRoute(
                              builder: (context) => TransactionEntryScreen(
                                transaction: viewmodel.transaction,
                                profile: profile,
                              ),
                            ))
                                .then((_) {
                              viewmodel.refetchTransaction();
                            });
                          },
                          icon: const Icon(Icons.edit)),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(2.0),
                      child: IconButton(
                          onPressed: () {
                            Navigator.of(context)
                                .push(MaterialPageRoute(
                              builder: (context) => TransactionEntryScreen(
                                dupeTransaction: transaction,
                                profile: profile,
                              ),
                            ))
                                .then((_) {
                              viewmodel.init();
                            });
                          },
                          icon: const Icon(Icons.copy)),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(2.0),
                      child: IconButton(
                          color: Colors.red,
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                actions: [
                                  TextButton(
                                      onPressed: () async {
                                        final hasDeleted =
                                            await viewmodel.deleteTransaction();
                                        if (hasDeleted && context.mounted) {
                                          Navigator.pop(context);
                                          Navigator.pop(context);
                                        }
                                      },
                                      child: Text(
                                        AppLocalizations.of(context)!.delete,
                                        style: const TextStyle(
                                            color: Colors.red,
                                            fontWeight: FontWeight.bold),
                                      )),
                                  TextButton(
                                      onPressed: () {
                                        Navigator.pop(context);
                                      },
                                      child: Text(
                                          AppLocalizations.of(context)!.cancel))
                                ],
                                title: Text(AppLocalizations.of(context)!
                                    .deleteThisTransactionQn),
                              ),
                            );
                          },
                          icon: const Icon(Icons.delete)),
                    ),
                    const SizedBox(
                      width: 8,
                    )
                  ],
                ),
                body: SizedBox(
                  height: double.infinity,
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          viewmodel.transaction.filePaths.isNotEmpty
                              ? ImageCarousel(
                                  filePaths: viewmodel.transaction.filePaths,
                                )
                              : const SizedBox(
                                  height: 100,
                                ),
                          Center(
                            child: SizedBox(
                              width: smallWidth,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    transaction.narration.isNotEmpty
                                        ? '"${transaction.narration}"'
                                        : "",
                                    style:
                                        Theme.of(context).textTheme.titleMedium,
                                  ),
                                  const SizedBox(
                                    height: 6,
                                  ),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          transaction.voucherType ==
                                                  VoucherType.payment
                                              ? viewmodel
                                                  .transaction.drAccount.name
                                              : viewmodel
                                                  .transaction.crAccount.name,
                                          overflow: TextOverflow.ellipsis,
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleLarge,
                                        ),
                                      ),
                                      if (viewmodel.project != null)
                                        Padding(
                                          padding: const EdgeInsets.all(8.0),
                                          child: Chip(
                                              shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(0)),
                                              avatar: const Icon(
                                                Icons.assignment,
                                                color: Colors.white,
                                              ),
                                              color: WidgetStatePropertyAll(
                                                  Theme.of(context)
                                                      .primaryColor),
                                              padding: const EdgeInsets.all(0),
                                              label: Text(
                                                viewmodel.project!.name,
                                                overflow: TextOverflow.ellipsis,
                                              )),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(
                                    height: 12,
                                  ),
                                  Text(
                                    transaction.amount.toCurrencyStringWSymbol(
                                        viewmodel.profile.currency),
                                    style:
                                        Theme.of(context).textTheme.titleLarge,
                                  ),
                                  Text(
                                    transaction.voucherType !=
                                            VoucherType.payment
                                        ? AppLocalizations.of(context)!
                                            .receivedIn(viewmodel
                                                .transaction.drAccount.name)
                                        : fundingAccountIDs.contains(viewmodel
                                                    .transaction
                                                    .crAccount
                                                    .accountType) &&
                                                fundingAccountIDs.contains(viewmodel
                                                    .transaction
                                                    .drAccount
                                                    .accountType)
                                            ? AppLocalizations.of(context)!
                                                .transferFrom(viewmodel
                                                    .transaction.crAccount.name)
                                            : AppLocalizations.of(context)!
                                                .paidFrom(viewmodel.transaction.crAccount.name),
                                    overflow: TextOverflow.ellipsis,
                                    style:
                                        Theme.of(context).textTheme.titleMedium,
                                  ),
                                  Visibility(
                                    visible: transaction.refNo.isNotEmpty,
                                    child: Text(
                                      "${AppLocalizations.of(context)!.referenceNo}${transaction.refNo}",
                                      overflow: TextOverflow.ellipsis,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleSmall,
                                    ),
                                  ),
                                  const SizedBox(
                                    height: 16,
                                  ),
                                  SizedBox(
                                    width: smallWidth,
                                    child: Align(
                                      alignment: Alignment.centerRight,
                                      child: Padding(
                                        padding: const EdgeInsets.all(2.0),
                                        child: Text(
                                          "${appViewmodel.dateFormat.format(
                                            transaction.voucherDate,
                                          )}, ${timeFormat.format(transaction.voucherDate)}",
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleSmall,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(
                                    height: 20,
                                  ),
                                ],
                              ),
                            ),
                          )
                        ],
                      ),
                    ),
                  ),
                ),
              ));
        },
      ),
    );
  }
}
