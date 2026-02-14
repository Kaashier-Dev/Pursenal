import 'package:flutter/material.dart';
import 'package:pursenal/app/global/dimensions.dart';
import 'package:pursenal/app/extensions/currency.dart';
import 'package:pursenal/core/enums/currency.dart';
import 'package:pursenal/core/models/domain/ledger.dart';
import 'package:pursenal/widgets/shared/search_field.dart';

class AccountsSearchDialog extends StatefulWidget {
  /// Search dialog for searching and selecting accounts for the transaction entry screen
  const AccountsSearchDialog(
      {super.key, required this.ledgers, required this.currency});

  /// List of ledgers to search
  final List<Ledger> ledgers;

  /// The currency from the profile
  final Currency currency;

  @override
  AccountsSearchDialogState createState() => AccountsSearchDialogState();
}

class AccountsSearchDialogState extends State<AccountsSearchDialog> {
  final TextEditingController _searchController = TextEditingController();
  List<Ledger> fLedgers = [];

  @override
  void initState() {
    fLedgers = List.from(widget.ledgers);
    super.initState();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      insetPadding: const EdgeInsets.all(20),
      child: SizedBox(
        width: smallWidth,
        child: Padding(
          padding: const EdgeInsets.all(2),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SearchField(
                autoFocus: true,
                searchFn: (query) {
                  filterList(query);
                },
              ),
              const SizedBox(height: 8),
              fLedgers.isNotEmpty
                  ? Flexible(
                      child: SizedBox(
                        height: fLedgers.length > 5 ? 350 : null,
                        child: ListView(
                          padding: const EdgeInsets.only(bottom: 8),
                          shrinkWrap: true,
                          children: fLedgers
                              .map((a) => Material(
                                    color: Colors.transparent,
                                    child: ListTile(
                                      minTileHeight: 10,
                                      subtitle: Text(
                                        a.accountType.name,
                                        style: Theme.of(context)
                                            .textTheme
                                            .labelSmall,
                                      ),
                                      title: Text(a.account.name,
                                          textAlign: TextAlign.start,
                                          overflow: TextOverflow.ellipsis,
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleSmall),
                                      trailing: Text(
                                        a.balance
                                            .toCurrencyString(widget.currency),
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleSmall
                                            ?.copyWith(
                                                fontWeight: FontWeight.bold),
                                      ),
                                      onTap: () {
                                        Navigator.of(context).pop(a.account);
                                      },
                                    ),
                                  ))
                              .toList(),
                        ),
                      ),
                    )
                  : Center(
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          "No Items",
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                    ),
              const SizedBox(
                height: 8,
              )
            ],
          ),
        ),
      ),
    );
  }

  filterList(String query) {
    setState(() {
      fLedgers = widget.ledgers
          .where(
            (l) => l.toString().toLowerCase().contains(query.toLowerCase()),
          )
          .toList();
    });
  }
}
