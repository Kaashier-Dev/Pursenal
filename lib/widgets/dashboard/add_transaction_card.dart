import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:pursenal/app/global/dimensions.dart';
import 'package:pursenal/core/models/domain/profile.dart';
import 'package:pursenal/viewmodels/app_viewmodel.dart';
import 'package:pursenal/viewmodels/dashboard_viewmodel.dart';
import 'package:pursenal/widgets/dashboard/add_transaction_button_group.dart';
import 'package:pursenal/widgets/shared/the_divider.dart';
import 'package:pursenal/l10n/app_localizations.dart';

class AddTransactionCard extends StatelessWidget {
  const AddTransactionCard({
    super.key,
    required this.appViewmodel,
    required this.profile,
    required this.viewmodel,
  });

  final AppViewmodel appViewmodel;
  final Profile profile;
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
                      AppLocalizations.of(context)!.add,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const Expanded(child: TheDivider()),
                  ],
                ),
              ),
              const SizedBox(
                height: 10,
              ),
              AddTransactionButtonGroup(
                  appViewmodel: appViewmodel,
                  profile: profile,
                  viewmodel: viewmodel)
            ],
          ),
        ),
      )
          .animate(delay: 50.ms)
          .scale(begin: const Offset(1.02, 1.02), duration: 100.ms)
          .fade(curve: Curves.easeInOut, duration: 100.ms),
    );
  }
}
