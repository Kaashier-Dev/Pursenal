import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:pursenal/app/extensions/currency.dart';
import 'package:pursenal/app/global/dimensions.dart';
import 'package:pursenal/app/global/values.dart';
import 'package:pursenal/core/enums/app_date_format.dart';
import 'package:pursenal/core/enums/budget_interval.dart';
import 'package:pursenal/core/enums/loading_status.dart';
import 'package:pursenal/core/enums/payment_status.dart';
import 'package:pursenal/core/enums/week_days.dart';
import 'package:pursenal/core/models/domain/account.dart';
import 'package:pursenal/core/models/domain/payment_reminder.dart';
import 'package:pursenal/core/models/domain/profile.dart';
import 'package:pursenal/core/repositories/drift/account_types_drift_repository.dart';
import 'package:pursenal/core/repositories/drift/accounts_drift_repository.dart';
import 'package:pursenal/core/repositories/drift/file_paths_drift_repository.dart';
import 'package:pursenal/core/repositories/drift/payment_reminders_drift_repository.dart';
import 'package:pursenal/core/repositories/repository_registry.dart';
import 'package:pursenal/viewmodels/app_viewmodel.dart';
import 'package:pursenal/viewmodels/payment_reminder_entry_viewmodel.dart';
import 'package:pursenal/widgets/shared/acc_type_dialog.dart';
import 'package:pursenal/widgets/shared/accounts_search_dialog.dart';
import 'package:pursenal/widgets/shared/calculated_field.dart';
import 'package:pursenal/widgets/shared/images_selector.dart';
import 'package:pursenal/widgets/shared/loading_body.dart';
import 'package:pursenal/l10n/app_localizations.dart';
import 'package:pursenal/widgets/shared/the_date_picker.dart';

class PaymentReminderEntryScreen extends StatelessWidget {
  const PaymentReminderEntryScreen({
    super.key,
    this.paymentReminder,
    required this.profile,
  });
  final PaymentReminder? paymentReminder;
  final Profile profile;

  @override
  Widget build(BuildContext context) {
    final repositoryRegistry =
        Provider.of<RepositoryRegistry>(context, listen: false);
    return ChangeNotifierProvider(
      create: (context) => PaymentReminderEntryViewmodel(
        repositoryRegistry,
        reminder: paymentReminder,
        profile: profile,
      )..init(),
      builder: (context, child) => Scaffold(
        appBar: AppBar(title: Text(AppLocalizations.of(context)!.details)),
        body: Consumer<PaymentReminderEntryViewmodel>(
          builder: (context, viewmodel, child) {
            return LoadingBody(
              loadingStatus: viewmodel.loadingStatus,
              resetErrorTextFn: () {
                viewmodel.resetErrorText();
              },
              errorText: viewmodel.errorText,
              widget: PaymentReminderForm(
                viewmodel: viewmodel,
                isNew: paymentReminder == null,
                profile: profile,
              ),
            );
          },
        ),
      ),
    );
  }
}

class PaymentReminderForm extends StatelessWidget {
  const PaymentReminderForm(
      {super.key,
      required this.viewmodel,
      this.isNew = true,
      required this.profile});

  final PaymentReminderEntryViewmodel viewmodel;
  final bool isNew;
  final Profile profile;

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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(
                      height: 4,
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: 4, horizontal: 8),
                      child: TextFormField(
                        initialValue: viewmodel.details,
                        decoration: InputDecoration(
                          labelText: AppLocalizations.of(context)!.details,
                          errorText: viewmodel.detailsError != ""
                              ? viewmodel.detailsError
                              : null,
                        ),
                        onChanged: (value) {
                          viewmodel.details = value;
                        },
                      ),
                    )
                        .animate()
                        .scale(
                            begin: const Offset(1.02, 1.02), duration: 100.ms)
                        .fade(curve: Curves.easeInOut, duration: 100.ms),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: 4, horizontal: 8),
                      child: SwitchListTile(
                          title: const Text("Repeat?"),
                          value: viewmodel.doesRepeat,
                          onChanged: (v) {
                            viewmodel.doesRepeat = v;
                          }),
                    )
                        .animate(delay: 20.ms)
                        .scale(
                            begin: const Offset(1.02, 1.02), duration: 100.ms)
                        .fade(curve: Curves.easeInOut, duration: 100.ms),
                    Visibility(
                      visible: viewmodel.doesRepeat,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            vertical: 4, horizontal: 8),
                        child: DropdownMenu<BudgetInterval>(
                          hintText: "Select interval",
                          label: const Text("Reminder interval"),
                          errorText: viewmodel.intervalError.isNotEmpty
                              ? viewmodel.intervalError
                              : null,
                          enableSearch: false,
                          initialSelection: viewmodel.interval,
                          width: smallWidth,
                          dropdownMenuEntries: [
                            DropdownMenuEntry<BudgetInterval>(
                                value: BudgetInterval.monthly,
                                label: BudgetInterval.monthly.label),
                            DropdownMenuEntry<BudgetInterval>(
                                value: BudgetInterval.weekly,
                                label: BudgetInterval.weekly.label),
                          ],
                          onSelected: (i) {
                            if (i != null) {
                              viewmodel.interval = i;
                            }
                          },
                        ),
                      )
                          .animate(delay: 40.ms)
                          .scale(
                              begin: const Offset(1.02, 1.02), duration: 100.ms)
                          .fade(curve: Curves.easeInOut, duration: 100.ms),
                    ),
                    Visibility(
                      visible: !viewmodel.doesRepeat,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            vertical: 4, horizontal: 8),
                        child: TheDatePicker(
                          initialDate: viewmodel.paymentDate,
                          onChanged: (d) {
                            viewmodel.paymentDate = d;
                          },
                          firstDate: DateTime.now(),
                          label: AppLocalizations.of(context)!.paymentDate,
                          datePattern: appViewmodel.dateFormat.pattern ??
                              AppDateFormat.date1.pattern,
                          errorText: viewmodel.paymentDateError.isNotEmpty
                              ? viewmodel.paymentDateError
                              : null,
                        ),
                      )
                          .animate(delay: 40.ms)
                          .scale(
                              begin: const Offset(1.02, 1.02), duration: 100.ms)
                          .fade(curve: Curves.easeInOut, duration: 100.ms),
                    ),
                    Visibility(
                      visible: viewmodel.interval == BudgetInterval.weekly &&
                          viewmodel.doesRepeat == true,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            vertical: 4, horizontal: 8),
                        child: DropdownMenu<WeekDays>(
                          initialSelection:
                              viewmodel.interval == BudgetInterval.weekly
                                  ? WeekDays.values[viewmodel.day ?? 1]
                                  : null,
                          label: const Text("Day of the week"),
                          errorText: viewmodel.weekDayError.isNotEmpty
                              ? viewmodel.weekDayError
                              : null,
                          enableSearch: false,
                          width: smallWidth,
                          dropdownMenuEntries: [
                            ...WeekDays.values.map(
                              (d) => DropdownMenuEntry<WeekDays>(
                                  value: d, label: d.label),
                            ),
                          ],
                          onSelected: (d) {
                            viewmodel.day = d?.weekday;
                          },
                        ),
                      )
                          .animate(delay: 40.ms)
                          .scale(
                              begin: const Offset(1.02, 1.02), duration: 100.ms)
                          .fade(curve: Curves.easeInOut, duration: 100.ms),
                    ),
                    Visibility(
                      visible: viewmodel.interval == BudgetInterval.monthly &&
                          viewmodel.doesRepeat == true,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            vertical: 4, horizontal: 8),
                        child: TextFormField(
                          keyboardType: TextInputType.number,
                          initialValue: viewmodel.day?.toString(),
                          inputFormatters: [
                            FilteringTextInputFormatter
                                .digitsOnly, // Only allow digits
                            LengthLimitingTextInputFormatter(2), // Max 2 digits
                            _NumberRangeInputFormatter(
                                1, 31), // Custom range formatter
                          ],
                          textAlign: TextAlign.end,
                          decoration: InputDecoration(
                            labelText: "Day of the month",
                            errorText: viewmodel.monthDayError.isNotEmpty
                                ? viewmodel.monthDayError
                                : null,
                          ),
                          onChanged: (value) {
                            viewmodel.day = int.tryParse(value);
                          },
                        ),
                      )
                          .animate(delay: 40.ms)
                          .scale(
                              begin: const Offset(1.02, 1.02), duration: 100.ms)
                          .fade(curve: Curves.easeInOut, duration: 100.ms),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: 4, horizontal: 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                showDialog(
                                  context: context,
                                  builder: (context) => AccountsSearchDialog(
                                      ledgers: viewmodel.fAccounts,
                                      currency: profile.currency),
                                ).then((f) {
                                  if (f != null && f.runtimeType == Account) {
                                    viewmodel.account = f;
                                  }
                                });
                              },
                              child: MouseRegion(
                                cursor: SystemMouseCursors.click,
                                child: InputDecorator(
                                  decoration: InputDecoration(
                                    errorText: viewmodel
                                            .selectedAccountError.isNotEmpty
                                        ? viewmodel.selectedAccountError
                                        : null,
                                    label: Text(
                                        AppLocalizations.of(context)!.account),
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        viewmodel.account?.name ??
                                            AppLocalizations.of(context)!
                                                .select(AppLocalizations.of(
                                                        context)!
                                                    .account),
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleLarge
                                            ?.copyWith(fontSize: 24),
                                      ),
                                      const Icon(Icons.arrow_drop_down)
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 4.0),
                            child: GestureDetector(
                              onTap: () {
                                showDialog(
                                  context: context,
                                  builder: (context) => AccountTypeDialog(
                                      profile: profile,
                                      initFn: () {
                                        viewmodel.getAccounts();
                                      },
                                      accountTypes: viewmodel.accountTypes),
                                );
                              },
                              child: MouseRegion(
                                cursor: SystemMouseCursors.click,
                                child: Container(
                                  width: 56,
                                  height: 56,
                                  decoration: BoxDecoration(
                                      color: Theme.of(context).primaryColor,
                                      borderRadius: BorderRadius.circular(8)),
                                  child: const Center(
                                    child: Icon(
                                      Icons.add,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                        .animate(delay: 60.ms)
                        .scale(
                            begin: const Offset(1.02, 1.02), duration: 100.ms)
                        .fade(curve: Curves.easeInOut, duration: 100.ms),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: 4, horizontal: 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: () {
                                showDialog(
                                  context: context,
                                  builder: (context) => AccountsSearchDialog(
                                      ledgers: viewmodel.funds,
                                      currency: profile.currency),
                                ).then((f) {
                                  if (f != null && f.runtimeType == Account) {
                                    viewmodel.fund = f;
                                  }
                                });
                              },
                              child: InputDecorator(
                                decoration: InputDecoration(
                                  errorText:
                                      viewmodel.selectedFundError.isNotEmpty
                                          ? viewmodel.selectedFundError
                                          : null,
                                  label:
                                      Text(AppLocalizations.of(context)!.fund),
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      viewmodel.fund?.name ??
                                          AppLocalizations.of(context)!.select(
                                              AppLocalizations.of(context)!
                                                  .fund),
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium,
                                    ),
                                    const Icon(Icons.arrow_drop_down)
                                  ],
                                ),
                              ),
                            ),
                          ),
                          Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 4.0),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: () {
                                showDialog(
                                  context: context,
                                  builder: (context) => AccountTypeDialog(
                                      profile: profile,
                                      initFn: () {
                                        viewmodel.getAccounts();
                                      },
                                      accountTypes:
                                          viewmodel.accountTypes.where((a) {
                                        return fundingAccountIDs
                                            .contains(a.dbID);
                                      }).toList()),
                                );
                              },
                              child: Container(
                                width: 52,
                                height: 52,
                                decoration: BoxDecoration(
                                    color: Theme.of(context).primaryColor,
                                    borderRadius: BorderRadius.circular(8)),
                                child: const Center(
                                  child: Icon(
                                    Icons.add,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                        .animate(delay: 80.ms)
                        .scale(
                            begin: const Offset(1.02, 1.02), duration: 100.ms)
                        .fade(curve: Curves.easeInOut, duration: 100.ms),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: 4, horizontal: 8),
                      child: CalculatedField(
                        currency: profile.currency,
                        textStyle: Theme.of(context).textTheme.titleLarge,
                        onChanged: (value) {
                          viewmodel.amount = value?.toIntCurrency() ?? 0;
                        },
                        amount: viewmodel.amount.toCurrency(),
                        label: AppLocalizations.of(context)!.amount,
                        errorText: viewmodel.amountError.isNotEmpty
                            ? viewmodel.amountError
                            : null,
                      ),
                    )
                        .animate(delay: 100.ms)
                        .scale(
                            begin: const Offset(1.02, 1.02), duration: 100.ms)
                        .fade(curve: Curves.easeInOut, duration: 100.ms),
                    Visibility(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            vertical: 4, horizontal: 8),
                        child: DropdownMenu<PaymentStatus>(
                            label: Text(
                                AppLocalizations.of(context)!.projectStatus),
                            width: smallWidth,
                            initialSelection: viewmodel.paymentStatus,
                            onSelected: (value) {
                              if (value != null) {
                                viewmodel.paymentStatus = value;
                              }
                            },
                            dropdownMenuEntries: [
                              ...PaymentStatus.values.map((p) =>
                                  DropdownMenuEntry(value: p, label: p.label)),
                            ]),
                      ),
                    )
                        .animate(delay: 120.ms)
                        .scale(
                            begin: const Offset(1.02, 1.02), duration: 100.ms)
                        .fade(curve: Curves.easeInOut, duration: 100.ms),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: 4, horizontal: 8),
                      child: ImagesSelector(
                        addPathFn: (path) {
                          viewmodel.addImage(path);
                        },
                        deletePathFn: (path) {
                          viewmodel.removeImage(path);
                        },
                        paths: viewmodel.filePaths,
                      ),
                    )
                        .animate(delay: 140.ms)
                        .scale(
                            begin: const Offset(1.02, 1.02), duration: 100.ms)
                        .fade(curve: Curves.easeInOut, duration: 100.ms),
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
                      final isSaved = await viewmodel.save();
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
                      : Text(AppLocalizations.of(context)!.save,
                          style: const TextStyle(fontSize: 22)),
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
