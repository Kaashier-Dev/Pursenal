import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:pursenal/app/global/dimensions.dart';
import 'package:pursenal/core/enums/currency.dart';
import 'package:pursenal/core/enums/loading_status.dart';
import 'package:pursenal/core/models/domain/profile.dart';
import 'package:pursenal/core/repositories/drift/profiles_drift_repository.dart';
import 'package:pursenal/screens/accounts_import_screen.dart';
import 'package:pursenal/viewmodels/profile_entry_viewmodel.dart';
import 'package:pursenal/widgets/shared/loading_body.dart';
import 'package:pursenal/l10n/app_localizations.dart';

class ProfileEntryScreen extends StatelessWidget {
  const ProfileEntryScreen({
    super.key,
    this.profile,
  });
  final Profile? profile;

  @override
  Widget build(BuildContext context) {
    final profilesDriftRepository =
        Provider.of<ProfilesDriftRepository>(context, listen: false);
    return ChangeNotifierProvider(
      create: (context) =>
          ProfileEntryViewmodel(profilesDriftRepository, profile: profile)
            ..init(),
      builder: (context, child) => Scaffold(
        appBar: AppBar(title: Text(AppLocalizations.of(context)!.profileForm)),
        body: Consumer<ProfileEntryViewmodel>(
          builder: (context, viewmodel, child) {
            return LoadingBody(
              loadingStatus: viewmodel.loadingStatus,
              resetErrorTextFn: () {
                viewmodel.resetErrorText();
              },
              errorText: viewmodel.errorText,
              widget: ProfileForm(
                viewmodel: viewmodel,
                isNew: profile == null,
              ),
            );
          },
        ),
      ),
    );
  }
}

class ProfileForm extends StatelessWidget {
  const ProfileForm({super.key, required this.viewmodel, this.isNew = true});

  final ProfileEntryViewmodel viewmodel;
  final bool isNew;

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
                    const SizedBox(
                      height: 4,
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: 4, horizontal: 8),
                      child: TextFormField(
                        initialValue: viewmodel.profileName,
                        decoration: InputDecoration(
                          labelText: AppLocalizations.of(context)!.profileName,
                          hintText: "Personal, Business etc.",
                          errorText: viewmodel.nameError != ""
                              ? viewmodel.nameError
                              : null,
                        ),
                        onChanged: (value) {
                          viewmodel.profileName = value;
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: 4, horizontal: 8),
                      child: TextFormField(
                        initialValue: viewmodel.nickName,
                        decoration: InputDecoration(
                          labelText: AppLocalizations.of(context)!.nickName,
                          errorText: viewmodel.nickNameError != ""
                              ? viewmodel.nickNameError
                              : null,
                        ),
                        onChanged: (value) {
                          viewmodel.nickName = value;
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: 4, horizontal: 8),
                      child: DropdownMenu<Currency>(
                          width: smallWidth,
                          hintText: AppLocalizations.of(context)!.currency,
                          label: Text(AppLocalizations.of(context)!.currency),
                          errorText: viewmodel.currencyError != ""
                              ? viewmodel.currencyError
                              : null,
                          onSelected: ((c) {
                            viewmodel.currency = c;
                          }),
                          initialSelection: viewmodel.currency,
                          dropdownMenuEntries: [
                            ...Currency.values.map((c) => DropdownMenuEntry(
                                value: c,
                                label: Currency.values[c.index].name,
                                trailingIcon: Text(
                                  Currency.values[c.index].symbol,
                                )))
                          ]),
                    ),
                    const SizedBox(height: 16),
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
                        decoration: InputDecoration(
                          hintText: "Business ID, Tax ID etc",
                          labelText: AppLocalizations.of(context)!.profileId,
                        ),
                        onChanged: (value) {
                          viewmodel.tin = value;
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
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
                        if (viewmodel.profile != null) {
                          isNew
                              ? await Navigator.pushAndRemoveUntil(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => AccountsImportScreen(
                                        profile: viewmodel.profile!),
                                  ),
                                  (r) => false)
                              : Navigator.pop(context);
                        } else {
                          Navigator.pop(context);
                        }
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
