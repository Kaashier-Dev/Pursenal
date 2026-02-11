import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:pursenal/core/enums/loading_status.dart';
import 'package:pursenal/core/enums/project_status.dart';
import 'package:pursenal/core/models/domain/profile.dart';
import 'package:pursenal/core/models/domain/project.dart';
import 'package:pursenal/core/models/domain/transaction.dart';
import 'package:pursenal/core/abstracts/projects_repository.dart';
import 'package:pursenal/core/abstracts/transactions_repository.dart';
import 'package:pursenal/core/repositories/repository_registry.dart';
import 'package:pursenal/utils/app_logger.dart';
import 'package:pursenal/utils/exporter.dart';

class ProjectViewmodel extends ChangeNotifier {
  final ProjectsRepository _projectsRepository;
  final TransactionsRepository _transactionsRepository;

  final int projectID;

  Project? _project;

  // ignore: unnecessary_getters_setters
  Project? get project => _project;

  set project(Project? value) => _project = value;

  final Profile _profile;
  Profile get profile => _profile;

  LoadingStatus loadingStatus = LoadingStatus.idle;
  String errorText = "";

  List<Transaction> transactions = [];
  Set<DateTime> fDates = {};

  double? headerHeight;
  bool isHidden = false;
  final ScrollController scrollController = ScrollController();
  bool _deleteTransactionsWithProject = false;

  String feedbackText = "";

  ProjectViewmodel(
    RepositoryRegistry repositoryRegistry, {
    required this.projectID,
    required Profile profile,
  })  : _profile = profile,
        _projectsRepository = repositoryRegistry.get<ProjectsRepository>(),
        _transactionsRepository =
            repositoryRegistry.get<TransactionsRepository>();

  init() async {
    try {
      loadingStatus = LoadingStatus.loading;
      scrollController.addListener(updateHeaderVisibility);
      notifyListeners();
      try {
        await refetchProject();
        await _getTransactions();
        loadingStatus = LoadingStatus.completed;
      } catch (e) {
        loadingStatus = LoadingStatus.error;
        errorText = "Cannot load Project";
      }
      notifyListeners();
    } catch (e) {
      AppLogger.instance.error(' ${e.toString()}');
      errorText = 'Error: Failed to initialise Project';
      loadingStatus = LoadingStatus.error;
      notifyListeners();
    }
  }

  Future<void> _getTransactions() async {
    try {
      if (project != null) {
        transactions = await _transactionsRepository.getTransactionsbyProject(
            profileID: _profile.dbID, projectID: project!.dbID);
        fDates = transactions.map((t) {
          return t.voucherDate.copyWith(
              hour: 0, minute: 0, second: 0, microsecond: 0, millisecond: 0);
        }).toSet();
      }
    } catch (e) {
      AppLogger.instance.error('Failed to get transactions ${e.toString()}');
      errorText = 'Error: Failed to get transactions';
    }
    notifyListeners();
  }

  bool get deleteTransactionsWithProject => _deleteTransactionsWithProject;

  set deleteTransactionsWithProject(bool value) {
    _deleteTransactionsWithProject = value;
    notifyListeners();
  }

  deleteProject({deleteTransactions = false}) async {
    try {
      if (_project != null) {
        await _projectsRepository.deleteProject(_project!.dbID,
            deleteTransactions: _deleteTransactionsWithProject);
        return true;
      }
      return false;
    } catch (e) {
      loadingStatus = LoadingStatus.error;
      errorText = "Couldn't delete project";
      return false;
    }
  }

  Future<bool> changeProjectStatus(ProjectStatus status) async {
    try {
      if (_project != null) {
        final p = _project!;
        _projectsRepository.updateProjectStatus(
            id: p.dbID,
            name: p.name,
            profile: _profile,
            description: p.description,
            endDate: p.endDate,
            startDate: p.startDate,
            projectStatus: status);
        return true;
      }
      return false;
    } catch (e) {
      AppLogger.instance.error(' ${e.toString()}');
      errorText = 'Error: ';
      return false;
    }
  }

  void resetErrorText() {
    errorText = "";
    feedbackText = "";
    notifyListeners();
  }

  Future<void> refetchProject() async {
    try {
      _project = await _projectsRepository.getProjectByID(projectID);
      if (_project != null && _project?.budget != null) {}
    } catch (e) {
      errorText = "Failed to fetch project";
      loadingStatus = LoadingStatus.error;
    }
    notifyListeners();
  }

  void updateHeaderVisibility() {
    if (scrollController.position.userScrollDirection ==
        ScrollDirection.reverse) {
      if (!isHidden && transactions.length > 8) {
        isHidden = true;
        headerHeight = 0;
        notifyListeners();
      }
    } else if (scrollController.position.userScrollDirection ==
        ScrollDirection.forward) {
      if (isHidden) {
        isHidden = false;
        headerHeight = null;
        notifyListeners();
      }
    }
  }

  Future<void> exportPDF() async {
    try {
      if (transactions.isNotEmpty) {
        DateTime sDate = transactions.last.voucherDate;
        DateTime eDate = transactions.first.voucherDate;
        feedbackText = await Exporter.genTransactionsPDF(
          title: "${project?.name} transactions",
          transactions: transactions.reversed.toList(),
          currency: _profile.currency,
          startDate: sDate,
          endDate: eDate,
        );
      } else {
        errorText = 'Error: No transactions to export';
      }
    } catch (e) {
      AppLogger.instance.error(' ${e.toString()}');
      errorText = 'Error: Failed to export PDF';
    }
    notifyListeners();
  }

  Future<void> exportXLSX() async {
    try {
      if (transactions.isNotEmpty) {
        DateTime sDate = transactions.last.voucherDate;
        DateTime eDate = transactions.first.voucherDate;
        feedbackText = await Exporter.genTransactionsXLSX(
          title: "${project?.name} transactions",
          transactions: transactions.reversed.toList(),
          currency: _profile.currency,
          startDate: sDate,
          endDate: eDate,
        );
      } else {
        errorText = 'Error: No transactions to export';
      }
    } catch (e) {
      AppLogger.instance.error(' ${e.toString()}');
      errorText = 'Error: Failed to export PDF';
    }
    notifyListeners();
  }

  @override
  void dispose() {
    scrollController.dispose();
    super.dispose();
  }
}
