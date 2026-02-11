import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:pursenal/core/enums/loading_status.dart';
import 'package:pursenal/core/models/domain/budget.dart';
import 'package:pursenal/core/models/domain/profile.dart';
import 'package:pursenal/core/abstracts/budgets_repository.dart';
import 'package:pursenal/core/repositories/repository_registry.dart';
import 'package:pursenal/utils/app_logger.dart';

class BudgetsViewmodel extends ChangeNotifier {
  final BudgetsRepository _budgetsRepository;

  BudgetsViewmodel(RepositoryRegistry repositoryRegistry,
      {required Profile profile, int accTypeID = 4})
      : _profile = profile,
        _budgetsRepository = repositoryRegistry.get<BudgetsRepository>();

  final Profile _profile;
  Profile get profile => _profile;

  List<Budget> _budgets = [];
  get budgets => _budgets;

  List<Budget> _fBudgets = [];

  LoadingStatus loadingStatus = LoadingStatus.idle;
  LoadingStatus searchLoadingStatus = LoadingStatus.idle;

  String _searchTerm = "";

  String get searchTerm => _searchTerm;
  List<Budget> get fBudgets => _fBudgets;

  Future<void> init() async {
    try {
      loadingStatus = LoadingStatus.loading;
      scrollController.addListener(updateHeaderVisibility);
      await _getBudgets();
      _filterBudgets();
      loadingStatus = LoadingStatus.completed;
    } catch (e) {
      AppLogger.instance.error(' ${e.toString()}');
      errorText = 'Error: Failed to initialise Budgets';
      loadingStatus = LoadingStatus.error;
      notifyListeners();
    }
  }

  set searchTerm(String value) {
    _searchTerm = value.toLowerCase();
    _filterBudgets();
  }

  String errorText = "";

  Future<void> _getBudgets() async {
    try {
      _budgets = await _budgetsRepository.getAll(profile.dbID);

      AppLogger.instance.info("Budgets loaded from database");
    } catch (e) {
      AppLogger.instance.error("Error loading budgets ${e.toString()}");
    }
    notifyListeners();
  }

  _filterBudgets() {
    searchLoadingStatus = LoadingStatus.loading;
    notifyListeners();
    try {
      _fBudgets = List.from(_budgets);
      _fBudgets =
          _fBudgets.where((a) => a.toString().contains(_searchTerm)).toList();

      searchLoadingStatus = LoadingStatus.completed;
    } catch (e) {
      searchLoadingStatus = LoadingStatus.error;
      AppLogger.instance.error("Failed to filter Budgets. ${e.toString()}");
    }

    notifyListeners();
  }

  void resetErrorText() {
    errorText = "";
    notifyListeners();
  }

  final ScrollController scrollController = ScrollController();

  double? headerHeight;
  bool isHidden = false;

  void updateHeaderVisibility() {
    if (scrollController.position.userScrollDirection ==
        ScrollDirection.reverse) {
      if (!isHidden && _fBudgets.length > 3) {
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

  @override
  void dispose() {
    scrollController.dispose();
    super.dispose();
  }
}
