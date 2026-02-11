import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:pursenal/app/extensions/currency.dart';
import 'package:pursenal/app/global/dimensions.dart';
import 'package:pursenal/core/enums/loading_status.dart';
import 'package:pursenal/core/enums/voucher_type.dart';
import 'package:pursenal/core/models/domain/payment_reminder.dart';
import 'package:pursenal/core/models/domain/profile.dart';
import 'package:pursenal/core/repositories/drift/payment_reminders_drift_repository.dart';
import 'package:pursenal/core/repositories/repository_registry.dart';
import 'package:pursenal/screens/payment_reminder_entry_screen.dart';
import 'package:pursenal/screens/transaction_entry_screen.dart';
import 'package:pursenal/viewmodels/app_viewmodel.dart';
import 'package:pursenal/viewmodels/payment_reminders_viewmodel.dart';
import 'package:pursenal/widgets/shared/empty_list.dart';
import 'package:pursenal/widgets/shared/image_carousel.dart';
import 'package:pursenal/widgets/shared/loading_body.dart';
import 'package:pursenal/widgets/shared/search_field.dart';
import 'package:pursenal/l10n/app_localizations.dart';
import 'package:pursenal/widgets/shared/the_divider.dart';

class PaymentRemindersScreen extends StatelessWidget {
  const PaymentRemindersScreen({super.key, required this.profile});
  final Profile profile;

  @override
  Widget build(BuildContext context) {
    final repositoryRegistry =
        Provider.of<RepositoryRegistry>(context, listen: false);

    return ChangeNotifierProvider<PaymentRemindersViewmodel>(
      create: (context) => PaymentRemindersViewmodel(
        repositoryRegistry,
        profile: profile,
      )..init(),
      builder: (context, child) => Consumer<PaymentRemindersViewmodel>(
        builder: (context, viewmodel, child) => Scaffold(
          appBar: AppBar(
            actions: const [SizedBox.shrink()],
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
                    Visibility(
                      visible: isWide,
                      child: SizedBox(
                        width: 300,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          child: SingleChildScrollView(
                            child: Column(
                              spacing: 5,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: createFilterMenu(
                                viewmodel,
                                context,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Visibility(
                      visible: isWide,
                      child: const VerticalDivider(
                        thickness: .10,
                        width: .10,
                      ),
                    ),
                    Expanded(
                      child: PaymentRemindersList(
                        viewmodel: viewmodel,
                        isWide: isWide,
                        profile: profile,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        PaymentReminderEntryScreen(profile: profile),
                  )).then((_) {
                viewmodel.init();
              });
            },
            heroTag: "addPaymentReminder",
            child: const Icon(Icons.add),
          ),
          endDrawer: Drawer(
            shape: const RoundedRectangleBorder(),
            child: SingleChildScrollView(
              child: Container(
                padding: const EdgeInsets.all(8),
                width: double.maxFinite,
                child: ListView(
                  shrinkWrap: true,
                  children: createFilterMenu(
                    viewmodel,
                    context,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class PaymentRemindersList extends StatelessWidget {
  const PaymentRemindersList({
    super.key,
    required this.viewmodel,
    required this.isWide,
    required this.profile,
  });

  final PaymentRemindersViewmodel viewmodel;
  final bool isWide;
  final Profile profile;

  @override
  Widget build(BuildContext context) {
    final appViewmodel = Provider.of<AppViewmodel>(context);

    final ebStyle = ElevatedButton.styleFrom(
      minimumSize: const Size(0, 50), // Reduce button's width/height
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.compact,
    );
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
                  AppLocalizations.of(context)!.myPaymentReminders,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: SearchField(
                      initText: viewmodel.searchTerm,
                      searchFn: (term) {
                        viewmodel.searchTerm = term;
                      }),
                ),
                Visibility(
                  visible: !isWide,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: IconButton(
                      onPressed: () {
                        Scaffold.of(context).openEndDrawer();
                      },
                      icon: const Icon(Icons.filter_list),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(
              height: 8,
            ),
            Visibility(
              visible: viewmodel.fPaymentReminders.isEmpty,
              child: Expanded(
                child: EmptyList(
                  items: AppLocalizations.of(context)!.reminders,
                  addFn: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => PaymentReminderEntryScreen(
                              profile: viewmodel.profile),
                        )).then((_) {
                      viewmodel.init();
                    });
                  },
                  isListFiltered: viewmodel.paymentReminders.isNotEmpty ||
                      (viewmodel.paymentReminders.isNotEmpty &&
                          viewmodel.fPaymentReminders.length ==
                              viewmodel.paymentReminders.length),
                ),
              ),
            ),
            Visibility(
              visible: viewmodel.fPaymentReminders.isNotEmpty,
              child: Expanded(child: Builder(builder: (_) {
                if (viewmodel.searchLoadingStatus == LoadingStatus.completed) {
                  return ListView.builder(
                    itemCount: viewmodel.fPaymentReminders.length,
                    padding: const EdgeInsets.only(bottom: 50),
                    itemBuilder: (context, index) {
                      final p = viewmodel.fPaymentReminders[index];

                      return Card(
                        child: InkWell(
                          borderRadius: BorderRadius.circular(14),
                          onTap: () {
                            showReminderDialog(
                                context, p, appViewmodel, ebStyle);
                          },
                          child: ListTile(
                              shape: const Border(
                                  bottom: BorderSide(
                                      color: Colors.transparent, width: 0.10)),
                              title: Text(p.details,
                                  style:
                                      Theme.of(context).textTheme.titleMedium),
                              trailing: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Text(
                                    p.amount.toCurrencyStringWSymbol(
                                        profile.currency),
                                    overflow: TextOverflow.ellipsis,
                                    style:
                                        Theme.of(context).textTheme.titleSmall,
                                  )),
                              subtitle: Text(
                                p.paymentStatus.label,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.labelSmall,
                              )),
                        ),
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
              })),
            )
          ],
        ),
      ),
    );
  }

  Future<dynamic> showReminderDialog(BuildContext context, PaymentReminder p,
      AppViewmodel appViewmodel, ButtonStyle ebStyle) {
    return showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          insetPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: smallWidth),
            child: IntrinsicHeight(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(
                    height: 16,
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                vertical: 6, horizontal: 12),
                            child: Text(
                              textAlign: TextAlign.start,
                              p.details,
                              style: Theme.of(context).textTheme.titleLarge,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      ),
                      Text(
                        p.amount.toCurrencyStringWSymbol(profile.currency),
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      const SizedBox(
                        width: 16,
                      )
                    ],
                  ),
                  Flexible(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(4),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            children: [
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  p.paymentDate != null
                                      ? appViewmodel.dateFormat
                                          .format(p.paymentDate!)
                                      : "",
                                  overflow: TextOverflow.ellipsis,
                                  style:
                                      Theme.of(context).textTheme.titleMedium,
                                ),
                              ),
                              const SizedBox(width: 12),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  p.paymentStatus.label,
                                  overflow: TextOverflow.ellipsis,
                                  style:
                                      Theme.of(context).textTheme.labelMedium,
                                ),
                              ),
                              Text(
                                p.interval?.label ??
                                    AppLocalizations.of(context)!.oneTime,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.labelMedium,
                              ),
                              const SizedBox(width: 12),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const SizedBox(width: 12),
                              Visibility(
                                visible: p.fund != null,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(4),
                                    color: Theme.of(context)
                                        .primaryColor
                                        .withAlpha(50),
                                  ),
                                  child: Text(
                                    p.fund?.name ?? "",
                                    overflow: TextOverflow.ellipsis,
                                    style:
                                        Theme.of(context).textTheme.labelMedium,
                                  ),
                                ),
                              ),
                              Visibility(
                                visible: p.account != null && p.fund != null,
                                child: const Icon(Icons.arrow_right_alt),
                              ),
                              Visibility(
                                visible: p.account != null,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(4),
                                    color: Theme.of(context)
                                        .primaryColor
                                        .withAlpha(50),
                                  ),
                                  child: Text(
                                    p.account?.name ?? "",
                                    overflow: TextOverflow.ellipsis,
                                    style:
                                        Theme.of(context).textTheme.labelMedium,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                            ],
                          ),
                          const SizedBox(height: 2),
                          if (p.filePaths.isNotEmpty)
                            ImageCarousel(
                              filePaths: p.filePaths,
                              maxHeight: 300,
                            ),
                          const SizedBox(height: 12),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            style: ebStyle,
                            onPressed: () {
                              Navigator.pop(context);
                              Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        TransactionEntryScreen(
                                      profile: profile,
                                      selectedAccount: p.account,
                                      selectedFund: p.fund,
                                      voucherType: VoucherType.payment,
                                      amount: p.amount,
                                    ),
                                  )).then((_) {
                                viewmodel.init();
                              });
                            },
                            child: Text(AppLocalizations.of(context)!.pay),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ebStyle.copyWith(
                              backgroundColor: WidgetStatePropertyAll(
                                  Theme.of(context).colorScheme.secondary),
                            ),
                            onPressed: () {
                              Navigator.pop(context);
                              Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) =>
                                          PaymentReminderEntryScreen(
                                            profile: profile,
                                            paymentReminder: p,
                                          ))).then((_) {
                                viewmodel.init();
                              });
                            },
                            icon: const Icon(Icons.edit),
                            label: Text(AppLocalizations.of(context)!.edit),
                          ),
                        ),
                        const SizedBox(width: 4),
                        ElevatedButton(
                          style: ebStyle.copyWith(
                            backgroundColor:
                                const WidgetStatePropertyAll(Colors.red),
                          ),
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                actions: [
                                  TextButton(
                                      onPressed: () async {
                                        final hasDeleted = await viewmodel
                                            .deleteReminder(p.dbID);

                                        if (hasDeleted && context.mounted) {
                                          viewmodel.init();
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
                                    .deleteThisReminderQn),
                              ),
                            );
                          },
                          child: const Icon(Icons.delete),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

List<Widget> createFilterMenu(
  PaymentRemindersViewmodel viewmodel,
  BuildContext context,
) {
  return [
    Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      child: Text(
        AppLocalizations.of(context)!.filters,
        style: Theme.of(context).textTheme.titleLarge,
      ),
    ),
    Visibility(
      visible: viewmodel.paymentReminders.isNotEmpty,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          children: [
            Text(
              AppLocalizations.of(context)!.status,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const Expanded(child: TheDivider()),
          ],
        ),
      ),
    ),
    Visibility(
      visible: viewmodel.paymentReminders.isNotEmpty,
      child: Wrap(
        spacing: 4,
        runSpacing: 4,
        children: [
          ...viewmodel.statusCriterias.toList().map((v) => FilterChip(
              selected: !viewmodel.statusFilters.contains(v),
              label: Text(v.label),
              onSelected: (s) {
                viewmodel.addToFilter(status: v);
              }))
        ],
      )
          .animate(delay: 50.ms)
          .scale(begin: const Offset(1.02, 1.02), duration: 100.ms)
          .fade(curve: Curves.easeInOut, duration: 100.ms),
    ),
    const SizedBox(
      height: 40,
    )
  ];
}
