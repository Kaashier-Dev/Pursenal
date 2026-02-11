import 'dart:io';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:pursenal/app/global/dimensions.dart';
import 'package:pursenal/core/enums/project_status.dart';
import 'package:pursenal/core/models/domain/profile.dart';
import 'package:pursenal/core/models/domain/project.dart';
import 'package:pursenal/core/repositories/drift/projects_drift_repository.dart';
import 'package:pursenal/core/repositories/drift/transactions_drift_repository.dart';
import 'package:pursenal/core/repositories/repository_registry.dart';
import 'package:pursenal/screens/project_entry_screen.dart';
import 'package:pursenal/utils/app_paths.dart';
import 'package:pursenal/viewmodels/app_viewmodel.dart';
import 'package:pursenal/viewmodels/project_viewmodel.dart';
import 'package:pursenal/widgets/shared/export_button.dart';
import 'package:pursenal/widgets/shared/loading_body.dart';
import 'package:pursenal/l10n/app_localizations.dart';
import 'package:pursenal/widgets/shared/the_divider.dart';
import 'package:pursenal/widgets/shared/transactions_list.dart';
import 'package:pursenal/widgets/shared/transactions_list_wide.dart';
import 'package:path/path.dart' as p;

class ProjectScreen extends StatelessWidget {
  const ProjectScreen({
    super.key,
    required this.profile,
    required this.projectID,
  });
  final Profile profile;
  final int projectID;

  @override
  Widget build(BuildContext context) {
    final appViewmodel = Provider.of<AppViewmodel>(context);

    final repositoryRegistry =
        Provider.of<RepositoryRegistry>(context, listen: false);

    return ChangeNotifierProvider<ProjectViewmodel>(
      create: (context) => ProjectViewmodel(repositoryRegistry,
          profile: profile, projectID: projectID)
        ..init(),
      child: Consumer<ProjectViewmodel>(
        builder: (context, viewmodel, child) {
          return Scaffold(
            appBar: AppBar(
              title: Text(
                viewmodel.project?.name ?? "",
                overflow: TextOverflow.ellipsis,
              ),
              actions: [
                IconButton(
                    onPressed: () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ProjectEntryScreen(
                                profile: profile, project: viewmodel.project),
                          )).then((v) {
                        viewmodel.refetchProject();
                      });
                    },
                    icon: const Icon(Icons.edit)),
                Padding(
                  padding: const EdgeInsets.all(2.0),
                  child: IconButton(
                      color: Colors.red,
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (context) {
                            return StatefulBuilder(
                              builder: (context, setState) {
                                return AlertDialog(
                                  title: Text(AppLocalizations.of(context)!
                                      .deleteThisProjectQn),
                                  content: CheckboxListTile(
                                    shape: const Border(
                                      bottom: BorderSide(
                                          color: Colors.transparent, width: 0),
                                    ),
                                    value:
                                        viewmodel.deleteTransactionsWithProject,
                                    title: const Text(
                                        "Delete related transactions also?"),
                                    onChanged: (v) {
                                      if (v != null) {
                                        setState(() {
                                          viewmodel
                                              .deleteTransactionsWithProject = v;
                                        });
                                      }
                                    },
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () async {
                                        final hasDeleted =
                                            await viewmodel.deleteProject();
                                        if (hasDeleted && context.mounted) {
                                          Navigator.pop(context);
                                          Navigator.pop(context);
                                        }
                                      },
                                      child: Text(
                                        AppLocalizations.of(context)!.delete,
                                        style: const TextStyle(
                                          color: Colors.red,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    TextButton(
                                      onPressed: () {
                                        viewmodel
                                                .deleteTransactionsWithProject =
                                            false;
                                        Navigator.pop(context);
                                      },
                                      child: Text(
                                          AppLocalizations.of(context)!.cancel),
                                    )
                                  ],
                                );
                              },
                            );
                          },
                        );
                      },
                      icon: const Icon(Icons.delete)),
                ),
                const SizedBox(
                  width: 12,
                )
              ],
            ),
            body: LoadingBody(
                feedbackText: viewmodel.feedbackText,
                loadingStatus: viewmodel.loadingStatus,
                errorText: viewmodel.errorText,
                widget: LayoutBuilder(
                  builder: (context, constraints) {
                    bool isWide = constraints.maxWidth > 800;
                    if (viewmodel.project != null) {
                      final String securePath = AppPaths.imagesDir;
                      Project project = viewmodel.project!;
                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            height: viewmodel.headerHeight,
                            curve: Curves.easeInOut,
                            child: Center(
                              child: SizedBox(
                                width: smallWidth,
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        children: [
                                          Padding(
                                            padding: const EdgeInsets.symmetric(
                                                vertical: 2, horizontal: 16),
                                            child: Align(
                                              alignment: Alignment.centerLeft,
                                              child: Text(
                                                viewmodel.project!.description,
                                                overflow: TextOverflow.ellipsis,
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .bodyMedium,
                                              ),
                                            ),
                                          )
                                              .animate(delay: 50.ms)
                                              .scale(
                                                  begin:
                                                      const Offset(1.02, 1.02),
                                                  duration: 100.ms)
                                              .fade(
                                                  curve: Curves.easeInOut,
                                                  duration: 100.ms),
                                          Visibility(
                                            visible: project.startDate != null,
                                            child: Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      vertical: 2,
                                                      horizontal: 16),
                                              child: Align(
                                                alignment: Alignment.centerLeft,
                                                child: Text(
                                                  "${AppLocalizations.of(context)!.startDate} : ${appViewmodel.dateFormat.format(project.startDate ?? DateTime.now())}",
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .labelMedium,
                                                ),
                                              ),
                                            ),
                                          )
                                              .animate(delay: 100.ms)
                                              .scale(
                                                  begin:
                                                      const Offset(1.02, 1.02),
                                                  duration: 100.ms)
                                              .fade(
                                                  curve: Curves.easeInOut,
                                                  duration: 100.ms),
                                          Visibility(
                                            visible: project.endDate != null,
                                            child: Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      vertical: 2,
                                                      horizontal: 16),
                                              child: Align(
                                                alignment: Alignment.centerLeft,
                                                child: Text(
                                                  "${AppLocalizations.of(context)!.endDate} : ${appViewmodel.dateFormat.format(project.endDate ?? DateTime.now())}",
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .labelMedium,
                                                ),
                                              ),
                                            ),
                                          )
                                              .animate(delay: 150.ms)
                                              .scale(
                                                  begin:
                                                      const Offset(1.02, 1.02),
                                                  duration: 100.ms)
                                              .fade(
                                                  curve: Curves.easeInOut,
                                                  duration: 100.ms),
                                          Visibility(
                                                  visible: project
                                                      .photoPaths.isNotEmpty,
                                                  child: SingleChildScrollView(
                                                    scrollDirection:
                                                        Axis.horizontal,
                                                    child: Align(
                                                      alignment:
                                                          Alignment.centerLeft,
                                                      child: Padding(
                                                        padding:
                                                            const EdgeInsets
                                                                .symmetric(
                                                                vertical: 4,
                                                                horizontal: 16),
                                                        child: Row(
                                                          spacing: 8,
                                                          children: project
                                                              .photoPaths
                                                              .mapIndexed((index,
                                                                  filePath) {
                                                            final String path =
                                                                p.join(
                                                                    securePath,
                                                                    p.basename(
                                                                        filePath));
                                                            return ClipRRect(
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                          5),
                                                              child:
                                                                  GestureDetector(
                                                                onTap: () {
                                                                  if (!File(
                                                                          path)
                                                                      .existsSync()) {
                                                                    return;
                                                                  }
                                                                  showDialog(
                                                                    context:
                                                                        context,
                                                                    builder:
                                                                        (context) =>
                                                                            Stack(
                                                                      children: [
                                                                        Dialog(
                                                                          backgroundColor:
                                                                              Colors.transparent,
                                                                          shape:
                                                                              Border.all(),
                                                                          child:
                                                                              SizedBox(
                                                                            child:
                                                                                Image.file(
                                                                              errorBuilder: (context, error, stackTrace) => const Center(
                                                                                child: Padding(
                                                                                  padding: EdgeInsets.all(8.0),
                                                                                  child: Text("Media error"),
                                                                                ),
                                                                              ),
                                                                              File(path),
                                                                              fit: BoxFit.fitWidth,
                                                                            ),
                                                                          ),
                                                                        ),
                                                                        Positioned(
                                                                          top:
                                                                              -5,
                                                                          right:
                                                                              -5,
                                                                          child:
                                                                              Padding(
                                                                            padding:
                                                                                const EdgeInsets.all(24.0),
                                                                            child:
                                                                                IconButton(
                                                                              onPressed: () {
                                                                                Navigator.pop(context);
                                                                              },
                                                                              icon: const Icon(
                                                                                Icons.close,
                                                                                color: Colors.red,
                                                                                size: 30,
                                                                              ),
                                                                            ),
                                                                          ),
                                                                        ),
                                                                      ],
                                                                    ),
                                                                  );
                                                                },
                                                                child:
                                                                    ConstrainedBox(
                                                                  constraints: const BoxConstraints(
                                                                      maxWidth:
                                                                          50,
                                                                      maxHeight:
                                                                          50),
                                                                  child: Image
                                                                      .file(
                                                                    File(path),
                                                                    width: 50,
                                                                    fit: BoxFit
                                                                        .cover,
                                                                    errorBuilder: (context,
                                                                            error,
                                                                            stackTrace) =>
                                                                        Card(
                                                                      shape:
                                                                          RoundedRectangleBorder(
                                                                        borderRadius:
                                                                            BorderRadius.circular(5),
                                                                      ),
                                                                      child:
                                                                          const Center(
                                                                        child:
                                                                            Padding(
                                                                          padding:
                                                                              EdgeInsets.all(8.0),
                                                                          child:
                                                                              Icon(Icons.broken_image),
                                                                        ),
                                                                      ),
                                                                    ),
                                                                  ),
                                                                ).animate(delay: (index * 50).ms).fade(
                                                                        duration:
                                                                            250.ms),
                                                              ),
                                                            );
                                                          }).toList(),
                                                        ),
                                                      ),
                                                    ),
                                                  ))
                                              .animate(delay: 200.ms)
                                              .scale(
                                                  begin:
                                                      const Offset(1.02, 1.02),
                                                  duration: 100.ms)
                                              .fade(
                                                  curve: Curves.easeInOut,
                                                  duration: 100.ms),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const TheDivider(
                            indent: 0,
                          ),
                          Visibility(
                            visible: viewmodel.transactions.isNotEmpty,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  vertical: 2, horizontal: 16),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    AppLocalizations.of(context)!.transactions,
                                    overflow: TextOverflow.ellipsis,
                                    style:
                                        Theme.of(context).textTheme.titleLarge,
                                  ),
                                  ExportButton(
                                    pdfExportFn: () async {
                                      await viewmodel.exportPDF();
                                    },
                                    xlsxExportFn: () async {
                                      await viewmodel.exportXLSX();
                                    },
                                  )
                                ],
                              ),
                            ),
                          ),
                          Visibility(
                            visible: viewmodel.transactions.isNotEmpty,
                            child: Expanded(
                              child: TransactionsSection(
                                  viewmodel: viewmodel,
                                  isWide: isWide,
                                  constraints: constraints),
                            ),
                          ),
                          Visibility(
                              visible: viewmodel.transactions.isEmpty,
                              child: const SizedBox(
                                height: 200,
                                child: Center(
                                  child: Text("No transactions"),
                                ),
                              ))
                        ],
                      );
                    }

                    return const Center(
                      child: Text("Project not found"),
                    );
                  },
                ),
                resetErrorTextFn: () {
                  viewmodel.resetErrorText();
                }),
            floatingActionButton: FloatingActionButton.extended(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => SimpleDialog(
                    title: Text(AppLocalizations.of(context)!
                        .select(AppLocalizations.of(context)!.projectStatus)),
                    children: [
                      ...ProjectStatus.values.map((p) => ListTile(
                            title: Text(p.label),
                            onTap: () async {
                              final bool ss =
                                  await viewmodel.changeProjectStatus(p);
                              if (ss) {
                                viewmodel.refetchProject();
                              }
                              if (context.mounted) {
                                Navigator.pop(context);
                              }
                            },
                          )),
                      const SizedBox(
                        height: 12,
                      )
                    ],
                  ),
                );
              },
              icon: const Icon(Icons.edit),
              label: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    viewmodel.project?.status.label ?? "",
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    "${AppLocalizations.of(context)!.edit} ${AppLocalizations.of(context)!.status}",
                    style: Theme.of(context)
                        .textTheme
                        .labelSmall
                        ?.copyWith(fontSize: 8, color: Colors.white),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class TransactionsSection extends StatelessWidget {
  const TransactionsSection(
      {super.key,
      required this.viewmodel,
      required this.isWide,
      required this.constraints});

  final ProjectViewmodel viewmodel;
  final bool isWide;
  final BoxConstraints constraints;

  @override
  Widget build(BuildContext context) {
    final appViewmodel = Provider.of<AppViewmodel>(context);
    if (!appViewmodel.isPhone) {
      return TransactionsListWide(
          scrollController: viewmodel.scrollController,
          fTransactions: viewmodel.transactions,
          profile: viewmodel.profile,
          initFn: () {
            viewmodel.init();
          });
    }
    return TransactionsList(
        scrollController: viewmodel.scrollController,
        fDates: viewmodel.fDates,
        fTransactions: viewmodel.transactions,
        profile: viewmodel.profile,
        initFn: () {
          viewmodel.init();
        });
  }
}
