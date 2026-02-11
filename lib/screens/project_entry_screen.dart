import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:pursenal/app/global/dimensions.dart';
import 'package:pursenal/core/enums/app_date_format.dart';
import 'package:pursenal/core/enums/loading_status.dart';
import 'package:pursenal/core/enums/project_status.dart';
import 'package:pursenal/core/models/domain/profile.dart';
import 'package:pursenal/core/models/domain/project.dart';
import 'package:pursenal/core/repositories/drift/file_paths_drift_repository.dart';
import 'package:pursenal/core/repositories/drift/projects_drift_repository.dart';
import 'package:pursenal/core/repositories/repository_registry.dart';
import 'package:pursenal/viewmodels/app_viewmodel.dart';
import 'package:pursenal/viewmodels/project_entry_viewmodel.dart';
import 'package:pursenal/widgets/shared/images_selector.dart';
import 'package:pursenal/widgets/shared/loading_body.dart';
import 'package:pursenal/l10n/app_localizations.dart';
import 'package:pursenal/widgets/shared/the_date_picker.dart';

class ProjectEntryScreen extends StatelessWidget {
  const ProjectEntryScreen({
    super.key,
    this.project,
    required this.profile,
  });
  final Project? project;
  final Profile profile;

  @override
  Widget build(BuildContext context) {
    final repositoryRegistry =
        Provider.of<RepositoryRegistry>(context, listen: false);

    return ChangeNotifierProvider(
      create: (context) => ProjectEntryViewmodel(repositoryRegistry,
          project: project, profile: profile)
        ..init(),
      builder: (context, child) => Scaffold(
        appBar: AppBar(title: Text(AppLocalizations.of(context)!.projectForm)),
        body: Consumer<ProjectEntryViewmodel>(
          builder: (context, viewmodel, child) {
            return LoadingBody(
              loadingStatus: viewmodel.loadingStatus,
              resetErrorTextFn: () {
                viewmodel.resetErrorText();
              },
              errorText: viewmodel.errorText,
              widget: ProjectForm(
                viewmodel: viewmodel,
                isNew: project == null,
              ),
            );
          },
        ),
      ),
    );
  }
}

class ProjectForm extends StatelessWidget {
  const ProjectForm({super.key, required this.viewmodel, this.isNew = true});

  final ProjectEntryViewmodel viewmodel;
  final bool isNew;

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
                        initialValue: viewmodel.projectName,
                        decoration: InputDecoration(
                          labelText: AppLocalizations.of(context)!.projectName,
                          errorText: viewmodel.nameError != ""
                              ? viewmodel.nameError
                              : null,
                        ),
                        onChanged: (value) {
                          viewmodel.projectName = value;
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
                      child: TextFormField(
                        initialValue: viewmodel.description,
                        decoration: InputDecoration(
                          labelText: AppLocalizations.of(context)!.details,
                          errorText: viewmodel.descriptionError != ""
                              ? viewmodel.descriptionError
                              : null,
                        ),
                        onChanged: (value) {
                          viewmodel.description = value;
                        },
                      ),
                    )
                        .animate(delay: 50.ms)
                        .scale(
                            begin: const Offset(1.02, 1.02), duration: 100.ms)
                        .fade(curve: Curves.easeInOut, duration: 100.ms),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: 4, horizontal: 8),
                      child: TheDatePicker(
                        initialDate: viewmodel.startDate,
                        onChanged: (d) {
                          viewmodel.startDate = d;
                        },
                        label: AppLocalizations.of(context)!.startDate,
                        firstDate: viewmodel.startDate,
                        lastDate: viewmodel.endDate,
                        datePattern: appViewmodel.dateFormat.pattern ??
                            AppDateFormat.date1.pattern,
                      ),
                    )
                        .animate(delay: 100.ms)
                        .scale(
                            begin: const Offset(1.02, 1.02), duration: 100.ms)
                        .fade(curve: Curves.easeInOut, duration: 100.ms),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: 4, horizontal: 8),
                      child: TheDatePicker(
                        initialDate: viewmodel.endDate,
                        onChanged: (d) {
                          viewmodel.endDate = d;
                        },
                        label: AppLocalizations.of(context)!.endDate,
                        firstDate: viewmodel.startDate,
                        datePattern: appViewmodel.dateFormat.pattern ??
                            AppDateFormat.date1.pattern,
                      ),
                    )
                        .animate(delay: 150.ms)
                        .scale(
                            begin: const Offset(1.02, 1.02), duration: 100.ms)
                        .fade(curve: Curves.easeInOut, duration: 100.ms),
                    Visibility(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            vertical: 4, horizontal: 8),
                        child: DropdownMenu<ProjectStatus>(
                            label: Text(
                                AppLocalizations.of(context)!.projectStatus),
                            width: smallWidth,
                            initialSelection: viewmodel.projectStatus,
                            onSelected: (value) {
                              if (value != null) {
                                viewmodel.projectStatus = value;
                              }
                            },
                            dropdownMenuEntries: [
                              ...ProjectStatus.values.map((p) =>
                                  DropdownMenuEntry(value: p, label: p.label)),
                            ]),
                      ),
                    )
                        .animate(delay: 200.ms)
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
                        paths: viewmodel.mediaPaths,
                      ),
                    )
                        .animate(delay: 250.ms)
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
