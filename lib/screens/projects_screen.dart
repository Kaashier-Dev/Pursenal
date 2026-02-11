import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:pursenal/app/global/dimensions.dart';
import 'package:pursenal/core/enums/loading_status.dart';
import 'package:pursenal/core/enums/project_status.dart';
import 'package:pursenal/core/models/domain/profile.dart';
import 'package:pursenal/core/repositories/drift/account_types_drift_repository.dart';
import 'package:pursenal/core/repositories/drift/projects_drift_repository.dart';
import 'package:pursenal/core/repositories/repository_registry.dart';
import 'package:pursenal/screens/project_entry_screen.dart';
import 'package:pursenal/screens/project_screen.dart';
import 'package:pursenal/viewmodels/projects_viewmodel.dart';
import 'package:pursenal/widgets/shared/empty_list.dart';
import 'package:pursenal/widgets/shared/loading_body.dart';
import 'package:pursenal/widgets/shared/search_field.dart';
import 'package:pursenal/l10n/app_localizations.dart';
import 'package:pursenal/widgets/shared/the_divider.dart';

class ProjectsScreen extends StatelessWidget {
  const ProjectsScreen({super.key, required this.profile});
  final Profile profile;

  @override
  Widget build(BuildContext context) {
    final repositoryRegistry =
        Provider.of<RepositoryRegistry>(context, listen: false);

    return ChangeNotifierProvider<ProjectsViewmodel>(
      create: (context) => ProjectsViewmodel(
        repositoryRegistry,
        profile: profile,
      )..init(),
      builder: (context, child) => Consumer<ProjectsViewmodel>(
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
                      child: ProjectsList(
                        viewmodel: viewmodel,
                        isWide: isWide,
                      ),
                    ),
                  ],
                );
              },
            ),
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
          floatingActionButton: FloatingActionButton(
            onPressed: () {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ProjectEntryScreen(profile: profile),
                  )).then((_) {
                viewmodel.init();
              });
            },
            heroTag: "addProject",
            child: const Icon(Icons.add),
          ),
        ),
      ),
    );
  }
}

class ProjectsList extends StatelessWidget {
  const ProjectsList({
    super.key,
    required this.viewmodel,
    required this.isWide,
  });

  final ProjectsViewmodel viewmodel;
  final bool isWide;

  @override
  Widget build(BuildContext context) {
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
                  AppLocalizations.of(context)!.myProjects,
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
              visible: viewmodel.fProjects.isEmpty,
              child: Expanded(
                child: EmptyList(
                  items: AppLocalizations.of(context)!.projects,
                  addFn: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              ProjectEntryScreen(profile: viewmodel.profile),
                        )).then((_) {
                      viewmodel.init();
                    });
                  },
                  isListFiltered: viewmodel.projects.isNotEmpty ||
                      (viewmodel.projects.isNotEmpty &&
                          viewmodel.fProjects.length ==
                              viewmodel.projects.length),
                ),
              ),
            ),
            Visibility(
              visible: viewmodel.fProjects.isNotEmpty,
              child: Expanded(child: Builder(builder: (_) {
                if (viewmodel.searchLoadingStatus == LoadingStatus.completed) {
                  return ListView.builder(
                    itemCount: viewmodel.fProjects.length,
                    padding: const EdgeInsets.only(bottom: 50),
                    itemBuilder: (context, index) {
                      final p = viewmodel.fProjects[index];

                      return Card(
                        child: Row(
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Checkbox(
                                value: p.status == ProjectStatus.completed,
                                onChanged: p.status == ProjectStatus.completed
                                    ? null
                                    : (s) {
                                        if (s != null) {
                                          viewmodel.changeProjectStatus(
                                              p, ProjectStatus.completed);

                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            SnackBar(
                                                content: Text(
                                                    "${p.name} status set to : Completed")),
                                          );
                                        }
                                      },
                              ),
                            ),
                            Expanded(
                              child: InkWell(
                                onTap: () {
                                  Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => ProjectScreen(
                                          profile: viewmodel.profile,
                                          projectID: p.dbID,
                                        ),
                                      )).then((_) {
                                    viewmodel.init();
                                  });
                                },
                                borderRadius: const BorderRadius.only(
                                    topRight: Radius.circular(14),
                                    bottomRight: Radius.circular(14)),
                                child: ListTile(
                                  shape: Border(
                                      bottom: BorderSide(
                                          color: Theme.of(context).shadowColor,
                                          width: 0.10)),
                                  title: Text(p.name,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium),
                                  trailing: Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Text(
                                        p.status.label,
                                        overflow: TextOverflow.ellipsis,
                                      )),
                                  subtitle: Text(
                                    p.description,
                                    maxLines: 4,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),
                            ),
                          ],
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
}

List<Widget> createFilterMenu(
  ProjectsViewmodel viewmodel,
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
      visible: viewmodel.projects.isNotEmpty,
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
      visible: viewmodel.projects.isNotEmpty,
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
