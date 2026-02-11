import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:pursenal/app/global/dimensions.dart';
import 'package:pursenal/app/global/values.dart';
import 'package:pursenal/app/extensions/currency.dart';
import 'package:pursenal/core/enums/app_date_format.dart';
import 'package:pursenal/core/enums/loading_status.dart';
import 'package:pursenal/core/models/domain/account.dart';
import 'package:pursenal/core/models/domain/account_type.dart';
import 'package:pursenal/core/models/domain/profile.dart';
import 'package:pursenal/core/repositories/drift/account_types_drift_repository.dart';
import 'package:pursenal/core/repositories/drift/accounts_drift_repository.dart';
import 'package:pursenal/core/repositories/drift/balances_drift_repository.dart';
import 'package:pursenal/core/repositories/drift/banks_drift_repository.dart';
import 'package:pursenal/core/repositories/drift/ccards_drift_repository.dart';
import 'package:pursenal/core/repositories/drift/loans_drift_repository.dart';
import 'package:pursenal/core/repositories/drift/people_drift_repository.dart';
import 'package:pursenal/core/repositories/drift/receivables_drift_repository.dart';
import 'package:pursenal/core/repositories/drift/wallets_drift_repository.dart';
import 'package:pursenal/core/repositories/repository_registry.dart';
import 'package:pursenal/viewmodels/account_entry_viewmodel.dart';
import 'package:pursenal/viewmodels/app_viewmodel.dart';
import 'package:pursenal/widgets/shared/calculated_field.dart';
import 'package:pursenal/widgets/shared/loading_body.dart';
import 'package:pursenal/widgets/shared/the_date_picker.dart';
import 'package:pursenal/l10n/app_localizations.dart';

class AccountEntryScreen extends StatelessWidget {
  const AccountEntryScreen(
      {super.key, this.account, required this.profile, this.accountType});
  final Account? account;
  final Profile profile;
  final AccountType? accountType;

  @override
  Widget build(BuildContext context) {
    final repositoryRegistry =
        Provider.of<RepositoryRegistry>(context, listen: false);
    return ChangeNotifierProvider(
      create: (context) => AccountEntryViewModel(
        repositoryRegistry,
        profile: profile,
        account: account,
        accountType: accountType,
      )..init(),
      builder: (context, child) =>
          Consumer<AccountEntryViewModel>(builder: (context, viewmodel, child) {
        return Scaffold(
          appBar: AppBar(
            title: Text(AppLocalizations.of(context)!.accountForm),
            actions: [
              Visibility(
                visible: account != null,
                child: Padding(
                  padding: const EdgeInsets.all(2.0),
                  child: IconButton(
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            content: Text(AppLocalizations.of(context)!
                                .deleteAccountWarning),
                            actions: [
                              TextButton(
                                  onPressed: () async {
                                    final hasDeleted =
                                        await viewmodel.deleteAccount();
                                    if (hasDeleted && context.mounted) {
                                      Navigator.pop(context);
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
                                .deleteThisAccountQn),
                          ),
                        );
                      },
                      icon: const Icon(
                        Icons.delete,
                        color: Colors.red,
                      )),
                ),
              ),
              const SizedBox(
                width: 8,
              )
            ],
          ),
          body: LoadingBody(
              loadingStatus: viewmodel.loadingStatus,
              errorText: viewmodel.errorText,
              widget: AccountForm(
                account: account,
                viewmodel: viewmodel,
                autoFocusNameField: accountType != null,
                isAccountTypeDisabled: accountType != null,
              ),
              resetErrorTextFn: () {
                viewmodel.resetErrorText();
              }),
        );
      }),
    );
  }
}

class AccountForm extends StatelessWidget {
  const AccountForm({
    super.key,
    required this.account,
    required this.viewmodel,
    this.autoFocusNameField = false,
    this.isAccountTypeDisabled = false,
  });

  final Account? account;
  final AccountEntryViewModel viewmodel;
  final bool autoFocusNameField;
  final bool isAccountTypeDisabled;

  @override
  Widget build(BuildContext context) {
    final appViewmodel = Provider.of<AppViewmodel>(context);
    return Center(
      child: SizedBox(
        width: smallWidth,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    account == null
                        ? Padding(
                            padding: const EdgeInsets.symmetric(
                                vertical: 4, horizontal: 8),
                            child: DropdownMenu<AccountType?>(
                              initialSelection: viewmodel.accountType,
                              errorText: viewmodel.accountTypeError.isNotEmpty
                                  ? viewmodel.accountTypeError
                                  : null,
                              textStyle: Theme.of(context).textTheme.titleLarge,
                              label: Text(
                                  AppLocalizations.of(context)!.accountType),
                              width: smallWidth,
                              enabled: !isAccountTypeDisabled,
                              dropdownMenuEntries: [
                                ...viewmodel.accountTypes.map(
                                  (a) => DropdownMenuEntry(
                                    style: ButtonStyle(
                                        textStyle: WidgetStatePropertyAll(
                                      Theme.of(context).textTheme.titleLarge,
                                    )),
                                    value: a,
                                    label: a.name,
                                  ),
                                ),
                              ],
                              onSelected: (value) {
                                viewmodel.accountType = value;
                              },
                            ),
                          )
                        : Padding(
                            padding: const EdgeInsets.symmetric(
                                vertical: 8, horizontal: 8),
                            child: SizedBox(
                              child: InputDecorator(
                                decoration: InputDecoration(
                                  labelText:
                                      AppLocalizations.of(context)!.accountType,
                                ),
                                child: Text(
                                  viewmodel.accountType?.name ??
                                      AppLocalizations.of(context)!.accountType,
                                  style: Theme.of(context).textTheme.titleLarge,
                                ),
                              ),
                            ),
                          ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: 4, horizontal: 8),
                      child: TextFormField(
                        maxLength: 32,
                        initialValue: viewmodel.accountName,
                        decoration: InputDecoration(
                          counterText: "",
                          labelText: AppLocalizations.of(context)!.accountName,
                          errorText: viewmodel.accountNameError.isNotEmpty
                              ? viewmodel.accountNameError
                              : null,
                        ),
                        autofocus: autoFocusNameField,
                        onChanged: (value) {
                          viewmodel.accountName = value;
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: 4, horizontal: 8),
                      child: TheDatePicker(
                        initialDate: viewmodel.openDate,
                        onChanged: (d) {
                          viewmodel.openDate = d;
                        },
                        label: AppLocalizations.of(context)!.openingDate,
                        needTime: false,
                        errorText: viewmodel.openDateError.isNotEmpty
                            ? viewmodel.openDateError
                            : null,
                        datePattern: appViewmodel.dateFormat.pattern ??
                            AppDateFormat.date1.pattern,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: 4, horizontal: 8),
                      child: CalculatedField(
                        currency: viewmodel.profile.currency,
                        onChanged: (value) {
                          viewmodel.openBal = value?.toIntCurrency() ?? 0;
                        },
                        textStyle: Theme.of(context).textTheme.titleLarge,
                        label: AppLocalizations.of(context)!.openingBalance,
                        amount: viewmodel.openBal.toCurrency(),
                        errorText: viewmodel.amountError.isNotEmpty
                            ? viewmodel.amountError
                            : null,
                        isDisabled: (viewmodel.accountType != null &&
                            incExpIDs.contains(viewmodel.accountType!.dbID)),
                        helperText: viewmodel.amountHelperText,
                      ),
                    ),
                    const SizedBox(
                      height: 16,
                    ),
                    if (viewmodel.accountType != null &&
                        viewmodel.accountType!.dbID == bankTypeID)
                      ...[
                        // Show Bank specific fields
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              vertical: 4, horizontal: 8),
                          child: TextFormField(
                            maxLength: 24,
                            initialValue: viewmodel.accountNo,
                            decoration: InputDecoration(
                                counterText: "",
                                labelText:
                                    AppLocalizations.of(context)!.accountNo),
                            onChanged: (value) {
                              viewmodel.accountNo = value;
                            },
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              vertical: 4, horizontal: 8),
                          child: TextFormField(
                            maxLength: 24,
                            initialValue: viewmodel.holderName,
                            decoration: InputDecoration(
                                counterText: "",
                                labelText:
                                    AppLocalizations.of(context)!.holderName),
                            onChanged: (value) {
                              viewmodel.holderName = value;
                            },
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              vertical: 4, horizontal: 8),
                          child: TextFormField(
                            maxLength: 32,
                            initialValue: viewmodel.institution,
                            decoration: InputDecoration(
                                counterText: "",
                                labelText:
                                    AppLocalizations.of(context)!.institution),
                            onChanged: (value) {
                              viewmodel.institution = value;
                            },
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              vertical: 4, horizontal: 8),
                          child: TextFormField(
                            maxLength: 24,
                            initialValue: viewmodel.branch,
                            decoration: InputDecoration(
                                counterText: "",
                                labelText:
                                    AppLocalizations.of(context)!.branch),
                            onChanged: (value) {
                              viewmodel.branch = value;
                            },
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              vertical: 4, horizontal: 8),
                          child: TextFormField(
                            maxLength: 24,
                            initialValue: viewmodel.branchCode,
                            decoration: InputDecoration(
                                counterText: "",
                                labelText:
                                    AppLocalizations.of(context)!.branchCode),
                            onChanged: (value) {
                              viewmodel.branchCode = value;
                            },
                          ),
                        ),
                      ]
                          .animate(delay: 100.ms)
                          .scale(
                              begin: const Offset(1.02, 1.02), duration: 100.ms)
                          .fade(curve: Curves.easeInOut, duration: 100.ms),
                    // Credit card
                    if (viewmodel.accountType != null &&
                        viewmodel.accountType!.dbID == cCardTypeID)
                      ...[
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              vertical: 4, horizontal: 8),
                          child: TextFormField(
                            maxLength: 24,
                            initialValue: viewmodel.institution,
                            decoration: InputDecoration(
                                counterText: "",
                                labelText:
                                    AppLocalizations.of(context)!.institution),
                            onChanged: (value) {
                              viewmodel.institution = value;
                            },
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              vertical: 4, horizontal: 8),
                          child: TextFormField(
                            maxLength: 24,
                            initialValue: viewmodel.cardNetwork,
                            decoration: InputDecoration(
                                counterText: "",
                                labelText:
                                    AppLocalizations.of(context)!.cardNetwork),
                            onChanged: (value) {
                              viewmodel.cardNetwork = value;
                            },
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              vertical: 4, horizontal: 8),
                          child: TextFormField(
                            maxLength: 24,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly
                            ],
                            initialValue: viewmodel.cardNo,
                            decoration: InputDecoration(
                                counterText: "",
                                labelText:
                                    AppLocalizations.of(context)!.cardNo),
                            onChanged: (value) {
                              viewmodel.cardNo = value;
                            },
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              vertical: 4, horizontal: 8),
                          child: TextFormField(
                            keyboardType: TextInputType.number,
                            initialValue: viewmodel.statementDate?.toString(),
                            inputFormatters: [
                              FilteringTextInputFormatter
                                  .digitsOnly, // Only allow digits
                              LengthLimitingTextInputFormatter(
                                  2), // Max 2 digits
                              _NumberRangeInputFormatter(
                                  1, 31), // Custom range formatter
                            ],
                            decoration: InputDecoration(
                              labelText:
                                  AppLocalizations.of(context)!.statementDate,
                            ),
                            onChanged: (value) {
                              viewmodel.statementDate = int.tryParse(value);
                            },
                          ),
                        ),
                      ]
                          .animate(delay: 100.ms)
                          .scale(
                              begin: const Offset(1.02, 1.02), duration: 100.ms)
                          .fade(curve: Curves.easeInOut, duration: 100.ms),
                    // Loan
                    if (viewmodel.accountType != null &&
                        viewmodel.accountType!.dbID == loanTypeID)
                      ...[
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              vertical: 4, horizontal: 8),
                          child: TextFormField(
                            maxLength: 24,
                            initialValue: viewmodel.institution,
                            decoration: InputDecoration(
                                counterText: "",
                                labelText:
                                    AppLocalizations.of(context)!.institution),
                            onChanged: (value) {
                              viewmodel.institution = value;
                            },
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              vertical: 4, horizontal: 8),
                          child: TextFormField(
                            maxLength: 24,
                            initialValue: viewmodel.accountNo,
                            decoration: InputDecoration(
                                counterText: "",
                                labelText:
                                    AppLocalizations.of(context)!.accountNo),
                            onChanged: (value) {
                              viewmodel.accountNo = value;
                            },
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              vertical: 4, horizontal: 8),
                          child: TextFormField(
                            maxLength: 24,
                            initialValue: viewmodel.agreementNo,
                            decoration: InputDecoration(
                                counterText: "",
                                labelText:
                                    AppLocalizations.of(context)!.agreementNo),
                            onChanged: (value) {
                              viewmodel.agreementNo = value;
                            },
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              vertical: 4, horizontal: 8),
                          child: TextFormField(
                            textAlign: TextAlign.end,
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(RegExp(
                                  r'^\d*\.?\d*$')), // Allow digits and a single dot
                              _DoubleRangeInputFormatter(
                                  0, 100), // Restrict range
                            ],
                            initialValue: viewmodel.interestRate?.toString(),
                            decoration: InputDecoration(
                                suffix: const Text("%"),
                                labelText:
                                    AppLocalizations.of(context)!.interestRate),
                            onChanged: (value) {
                              viewmodel.interestRate = double.tryParse(value);
                            },
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              vertical: 4, horizontal: 8),
                          child: TheDatePicker(
                            initialDate: viewmodel.startDate,
                            onChanged: (d) {
                              viewmodel.startDate = d;
                            },
                            label: AppLocalizations.of(context)!.startDate,
                            needTime: false,
                            datePattern: appViewmodel.dateFormat.pattern ??
                                AppDateFormat.date1.pattern,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              vertical: 4, horizontal: 8),
                          child: TheDatePicker(
                            initialDate: viewmodel.endDate,
                            onChanged: (d) {
                              viewmodel.endDate = d;
                            },
                            label: AppLocalizations.of(context)!.endDate,
                            needTime: false,
                            datePattern: appViewmodel.dateFormat.pattern ??
                                AppDateFormat.date1.pattern,
                          ),
                        ),
                      ]
                          .animate(delay: 100.ms)
                          .scale(
                              begin: const Offset(1.02, 1.02), duration: 100.ms)
                          .fade(curve: Curves.easeInOut, duration: 100.ms),

                    if (viewmodel.accountType != null &&
                        viewmodel.accountType!.dbID == advanceTypeID)
                      ...[
                        Padding(
                            padding: const EdgeInsets.symmetric(
                                vertical: 4, horizontal: 8),
                            child: CalculatedField(
                              onChanged: (d) {
                                if (d != null) {
                                  viewmodel.totalAmount = (d * 1000).toInt();
                                }
                              },
                              label: AppLocalizations.of(context)!
                                  .totalAdvancePaid,
                              currency: viewmodel.profile.currency,
                              amount: viewmodel.totalAmount?.toCurrency(),
                            )),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              vertical: 4, horizontal: 8),
                          child: TheDatePicker(
                            initialDate: viewmodel.paidDate,
                            onChanged: (d) {
                              viewmodel.paidDate = d;
                            },
                            label: AppLocalizations.of(context)!.paidDate,
                            needTime: false,
                            datePattern: appViewmodel.dateFormat.pattern ??
                                AppDateFormat.date1.pattern,
                          ),
                        ),
                      ]
                          .animate(delay: 100.ms)
                          .scale(
                              begin: const Offset(1.02, 1.02), duration: 100.ms)
                          .fade(curve: Curves.easeInOut, duration: 100.ms),

                    if (viewmodel.accountType != null &&
                        viewmodel.accountType!.dbID == peopleTypeID)
                      ...[
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              vertical: 4, horizontal: 8),
                          child: TextFormField(
                            initialValue: viewmodel.address,
                            decoration: InputDecoration(
                              labelText: AppLocalizations.of(context)!.address,
                              errorText: viewmodel.addressError != ""
                                  ? viewmodel.addressError
                                  : null,
                            ),
                            onChanged: (value) {
                              viewmodel.address = value;
                            },
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              vertical: 4, horizontal: 8),
                          child: TextFormField(
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly
                            ],
                            initialValue: viewmodel.zip,
                            decoration: InputDecoration(
                              labelText: AppLocalizations.of(context)!.zip,
                              errorText: viewmodel.zipError != ""
                                  ? viewmodel.zipError
                                  : null,
                            ),
                            onChanged: (value) {
                              viewmodel.zip = value;
                            },
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              vertical: 4, horizontal: 8),
                          child: TextFormField(
                            initialValue: viewmodel.email,
                            decoration: InputDecoration(
                              labelText: AppLocalizations.of(context)!.email,
                              errorText: viewmodel.emailError != ""
                                  ? viewmodel.emailError
                                  : null,
                            ),
                            onChanged: (value) {
                              viewmodel.email = value;
                            },
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              vertical: 4, horizontal: 8),
                          child: TextFormField(
                            initialValue: viewmodel.phone,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly
                            ],
                            decoration: InputDecoration(
                              labelText: AppLocalizations.of(context)!.phone,
                              errorText: viewmodel.phoneError != ""
                                  ? viewmodel.phoneError
                                  : null,
                            ),
                            onChanged: (value) {
                              viewmodel.phone = value;
                            },
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              vertical: 4, horizontal: 8),
                          child: TextFormField(
                            initialValue: viewmodel.tin,
                            decoration: const InputDecoration(
                              hintText: "Business ID, Tax ID etc",
                              labelText: "ID",
                            ),
                            onChanged: (value) {
                              viewmodel.tin = value;
                            },
                          ),
                        ),
                      ]
                          .animate(delay: 100.ms)
                          .scale(
                              begin: const Offset(1.02, 1.02), duration: 100.ms)
                          .fade(curve: Curves.easeInOut, duration: 100.ms),

                    const SizedBox(
                      height: 50,
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    if (viewmodel.loadingStatus != LoadingStatus.submitting) {
                      bool isSaved = await viewmodel.save();
                      if (isSaved && context.mounted) {
                        Navigator.pop(context);
                      }
                    }
                  },
                  child: viewmodel.loadingStatus == LoadingStatus.submitting
                      ? const Padding(
                          padding: EdgeInsets.all(8.0),
                          child: CircularProgressIndicator(
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          AppLocalizations.of(context)!.save,
                          style: const TextStyle(fontSize: 22),
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

/// Custom input formatter to restrict numbers to a given range
class _NumberRangeInputFormatter extends TextInputFormatter {
  final int min;
  final int max;

  _NumberRangeInputFormatter(this.min, this.max);

  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.text.isEmpty) return newValue;

    final int? value = int.tryParse(newValue.text);
    if (value == null || value < min || value > max) {
      return oldValue; // Reject invalid input
    }
    return newValue;
  }
}

/// Custom input formatter to restrict double values within range
class _DoubleRangeInputFormatter extends TextInputFormatter {
  final double min;
  final double max;

  _DoubleRangeInputFormatter(this.min, this.max);

  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.text.isEmpty || newValue.text == ".") return newValue;

    final double? value = double.tryParse(newValue.text);
    if (value == null || value < min || value > max) {
      return oldValue; // Reject invalid input
    }
    return newValue;
  }
}
