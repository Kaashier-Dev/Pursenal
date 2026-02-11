import 'package:flutter/foundation.dart';
import 'package:pursenal/app/extensions/datetime.dart';
import 'package:pursenal/core/abstracts/file_paths_repository.dart';
import 'package:pursenal/core/enums/db_table_type.dart';
import 'package:pursenal/core/enums/loading_status.dart';
import 'package:pursenal/core/enums/project_status.dart';
import 'package:pursenal/core/models/domain/budget.dart';
import 'package:pursenal/core/models/domain/profile.dart';
import 'package:pursenal/core/models/domain/project.dart';
import 'package:pursenal/core/abstracts/projects_repository.dart';
import 'package:pursenal/core/repositories/repository_registry.dart';
import 'package:pursenal/utils/app_logger.dart';

class ProjectEntryViewmodel extends ChangeNotifier {
  final ProjectsRepository _projectsRepository;
  final FilePathsRepository _filePathsRepository;

  ProjectEntryViewmodel(
    RepositoryRegistry repositoryRegistry, {
    required Profile profile,
    Project? project,
  })  : _project = project,
        _profile = profile,
        _projectsRepository = repositoryRegistry.get<ProjectsRepository>(),
        _filePathsRepository = repositoryRegistry.get<FilePathsRepository>();
  LoadingStatus loadingStatus = LoadingStatus.idle;
  final Profile _profile;
  Project? _project;

  Project? get project => _project;

  final List<Project> _projects = [];
  String _projectName = "";
  String? _description;
  DateTime? _startDate;
  DateTime? _endDate;
  ProjectStatus _projectStatus = ProjectStatus.pending;
  Budget? _budget;
  String get projectName => _projectName;
  List<String> mediaPaths = [];
  final DateTime _now = DateTime.now();

  set projectName(String value) {
    _projectName = value;
    notifyListeners();
  }

  String? get description => _description;

  set description(String? value) {
    _description = value;
    notifyListeners();
  }

  DateTime? get startDate => _startDate;

  set startDate(DateTime? value) {
    _startDate = value;

    if (value != null &&
        value.isAfterOrEqualTo(_now) &&
        _projectStatus == ProjectStatus.pending) {
      _projectStatus = ProjectStatus.started;
    }
    notifyListeners();
  }

  DateTime? get endDate => _endDate;

  set endDate(DateTime? value) {
    _endDate = value;
    if (value != null &&
        value.isBeforeOrEqualTo(_now) &&
        _projectStatus == ProjectStatus.pending) {
      _projectStatus = ProjectStatus.completed;
    }
    notifyListeners();
  }

  ProjectStatus get projectStatus => _projectStatus;

  set projectStatus(ProjectStatus value) {
    _projectStatus = value;
    notifyListeners();
  }

  Budget? get getBudget => _budget;

  set setBudget(Budget? budget) {
    _budget = budget;
    notifyListeners();
  }

  Future<void> getProjects() async {
    // _projects = await _projectsRepository.getAll();
    notifyListeners();
  }

  set project(Project? project) {
    if (_project != null) {
      loadingStatus = LoadingStatus.loading;

      _projectName = _project!.name;
      _description = _project!.description;
      _startDate = _project!.startDate;
      _endDate = _project!.endDate;
      _projectStatus = _project!.status;
      mediaPaths = _project!.photoPaths.map((p) => p).toList();

      loadingStatus = LoadingStatus.completed;
      notifyListeners();
    }
  }

  // Error text variables
  String nameError = "";
  String descriptionError = "";

  String errorText = "";

  void init() async {
    try {
      loadingStatus = LoadingStatus.loading;
      notifyListeners();
      project = _project;
      getProjects();
      loadingStatus = LoadingStatus.completed;

      notifyListeners();
    } catch (e) {
      AppLogger.instance.error(' ${e.toString()}');
      errorText = 'Error: Failed to initialise project form';
      loadingStatus = LoadingStatus.error;
      notifyListeners();
    }
  }

  void addImage(String path) async {
    if (!mediaPaths.contains(path)) {
      mediaPaths.add(path);
      notifyListeners();
    }
  }

  void removeImage(String path) async {
    if (mediaPaths.contains(path)) {
      mediaPaths.remove(path);
      notifyListeners();
    }
  }

  bool _validate() {
    bool isValid = true;
    nameError = "";

    notifyListeners();

    if (projectName.isEmpty) {
      nameError = "Name cannot be empty";
      isValid = false;
    }
    if (_project == null &&
        _projects.where((p) => p.name == _projectName).isNotEmpty) {
      nameError = "Project name already exist";
      isValid = false;
    }
    notifyListeners();
    return isValid;
  }

  Future<bool> save() async {
    if (_validate()) {
      loadingStatus = LoadingStatus.submitting;
      notifyListeners();
      if (_project == null) {
        int newPro = await _projectsRepository.insertProject(
            name: _projectName,
            budget: _budget,
            profile: _profile,
            description: _description,
            startDate: _startDate,
            endDate: _endDate,
            projectStatus: _projectStatus);
        for (var p in mediaPaths) {
          await _filePathsRepository.insertFilePath(
              path: p, parentTableID: newPro, tableType: DBTableType.project);
        }
        _project = await _projectsRepository.getById(newPro);
      } else {
        await _filePathsRepository.deleteFilePathByParentID(_project!.dbID);
        await _projectsRepository.updateProject(
            profile: _profile,
            id: _project!.dbID,
            name: _projectName,
            budget: _budget,
            description: _description,
            startDate: _startDate,
            endDate: _endDate,
            projectStatus: _projectStatus);
        for (var p in mediaPaths) {
          await _filePathsRepository.insertFilePath(
              path: p,
              parentTableID: _project!.dbID,
              tableType: DBTableType.project);
        }
      }

      loadingStatus = LoadingStatus.submitted;
      notifyListeners();
      return true;
    }

    notifyListeners();
    return false;
  }

  void resetErrorText() {
    errorText = "";
    notifyListeners();
  }
}
