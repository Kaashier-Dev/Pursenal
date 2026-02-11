import 'package:flutter/material.dart';
import 'package:pursenal/l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:pursenal/app/global/dimensions.dart';
import 'package:pursenal/screens/transaction_entry_screen.dart';
import 'package:pursenal/viewmodels/app_viewmodel.dart';
import 'package:pursenal/widgets/shared/loading_body.dart';

class ProfileSelectionScreen extends StatelessWidget {
  const ProfileSelectionScreen({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const SizedBox.shrink(),
        leadingWidth: 0,
        title: Text(AppLocalizations.of(context)!.myProfiles),
      ),
      body: Consumer<AppViewmodel>(
        builder: (context, viewmodel, child) {
          return LoadingBody(
            errorText: viewmodel.errorText,
            loadingStatus: viewmodel.loadingStatus,
            widget: const ProfilesList(),
            resetErrorTextFn: () {
              viewmodel.resetErrorText();
            },
          );
        },
      ),
    );
  }
}

class ProfilesList extends StatelessWidget {
  const ProfilesList({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppViewmodel>(
      builder: (context, viewmodel, child) => Center(
        child: SizedBox(
          width: smallWidth,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  AppLocalizations.of(context)!.select("a Profile"),
                  style: Theme.of(context).textTheme.displaySmall,
                ),
              ),
              Expanded(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: viewmodel.profiles.length,
                  itemBuilder: (context, index) {
                    final profile = viewmodel.profiles[index];
                    return ListTile(
                        minTileHeight: 72,
                        title: Text(profile.name,
                            style: Theme.of(context).textTheme.titleMedium),
                        trailing: const Icon(Icons.keyboard_double_arrow_right),
                        onTap: () => Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    TransactionEntryScreen(profile: profile),
                              ),
                            ));
                  },
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
