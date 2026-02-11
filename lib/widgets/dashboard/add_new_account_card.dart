import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:pursenal/app/global/dimensions.dart';
import 'package:pursenal/core/models/domain/account_type.dart';
import 'package:pursenal/core/models/domain/profile.dart';
import 'package:pursenal/screens/account_entry_screen.dart';
import 'package:pursenal/viewmodels/dashboard_viewmodel.dart';
import 'package:pursenal/widgets/shared/acc_type_icon.dart';
import 'package:pursenal/widgets/shared/the_divider.dart';
import 'package:pursenal/l10n/app_localizations.dart';

class AddNewAccountCard extends StatelessWidget {
  const AddNewAccountCard({
    super.key,
    required this.viewmodel,
  });
  final DashboardViewmodel viewmodel;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(
        maxWidth: cardWidth,
      ),
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
                      AppLocalizations.of(context)!.addAccount,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const Expanded(child: TheDivider()),
                  ],
                ),
              ),
              const SizedBox(
                height: 10,
              ),
              ...viewmodel.fAccountTypes.map((a) => _createAddNewAccountBtn(
                  context, viewmodel.selectedProfile, a.name, a)),
              const SizedBox(
                height: 12,
              ),
            ],
          ),
        ),
      )
          .animate(delay: 200.ms)
          .scale(begin: const Offset(1.02, 1.02), duration: 100.ms)
          .fade(curve: Curves.easeInOut, duration: 100.ms),
    );
  }

  Padding _createAddNewAccountBtn(BuildContext context, Profile profile,
      String label, AccountType accountType) {
    return Padding(
      padding: const EdgeInsets.all(2.0),
      child: SizedBox(
        width: double.maxFinite,
        height: 50,
        child: ElevatedButton(
          style: ButtonStyle(
            backgroundColor: WidgetStatePropertyAll(
                Theme.of(context).primaryColor.withAlpha(20)),
            elevation: const WidgetStatePropertyAll(0),
            shape: WidgetStatePropertyAll(
              RoundedRectangleBorder(
                borderRadius: const BorderRadius.all(Radius.circular(10)),
                side: BorderSide(
                  color: Theme.of(context).primaryColor,
                  width: 0.5,
                ),
              ),
            ),
          ),
          onPressed: () async {
            Navigator.of(context)
                .push(MaterialPageRoute(
              builder: (context) => AccountEntryScreen(
                profile: profile,
                accountType: accountType,
              ),
            ))
                .then((_) {
              viewmodel.init();
            });
          },
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: Theme.of(context)
                    .textTheme
                    .bodyLarge
                    ?.copyWith(fontWeight: FontWeight.bold, fontSize: 20),
              ),
              Icon(
                getAccTypeIcon(accountType.dbID),
                size: 24,
                color: Theme.of(context).textTheme.bodyLarge?.color,
              )
            ],
          ),
        ),
      ),
    );
  }
}
