import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:pursenal/app/global/values.dart';
import 'package:pursenal/core/enums/budget_interval.dart';
import 'package:pursenal/core/enums/loading_status.dart';
import 'package:pursenal/core/models/domain/account.dart';
import 'package:pursenal/core/models/domain/budget.dart';
import 'package:pursenal/core/models/domain/profile.dart';
import 'package:pursenal/core/abstracts/accounts_repository.dart';
import 'package:pursenal/core/abstracts/budgets_repository.dart';
import 'package:pursenal/core/repositories/repository_registry.dart';
import 'package:pursenal/utils/app_logger.dart';

class BudgetEntryViewmodel extends ChangeNotifier {
  final AccountsRepository _accountsRepository;
  final BudgetsRepository _budgetsRepository;

  BudgetEntryViewmodel(
    RepositoryRegistry repositoryRegistry, {
    required Profile profile,
    Budget? budget,
  })  : _profile = profile,
        _budget = budget,
        _accountsRepository = repositoryRegistry.get<AccountsRepository>(),
        _budgetsRepository = repositoryRegistry.get<BudgetsRepository>();

  LoadingStatus loadingStatus = LoadingStatus.idle;

  Budget? _budget;

  final Profile _profile;

  String errorText = "";

  List<Account> expenses = [];
  List<Account> incomes = [];
  List<Account> funds = [];

  Map<int, int> selectedIncomes = {};
  Map<int, int> selectedExpenses = {};
  Set<int> selectedFunds = {};

  int expenseTotal = 0;
  int incomesTotal = 0;

  Budget? get budget => _budget;
  String _name = "";
  DateTime _startDate = DateTime.now();
  BudgetInterval _interval = BudgetInterval.monthly;
  String _details = "";

  String get name => _name;
  DateTime get startDate => _startDate;
  String get details => _details;
  BudgetInterval get interval => _interval;

  String nameError = "";
  String detailsError = "";
  String intervalError = "";
  String startDateError = "";
  String selectedExpensesError = "";
  String selectedIncomesError = "";
  String selectedFundsError = "";

  int difference = 0;
  List<Budget> _budgets = [];

  bool isWarningAlerted = false;

  void init() async {
    loadingStatus = LoadingStatus.loading;
    try {
      await getAccounts();
      setDefaults();
      _calculateIncomes();
      _calculateExpenses();
      _calculateDifference();
      loadingStatus = LoadingStatus.completed;
      notifyListeners();
    } catch (e) {
      AppLogger.instance.error(' ${e.toString()}');
      errorText = 'Error: Failed to initialise Budget form';
      loadingStatus = LoadingStatus.error;
      notifyListeners();
    }
  }

  set details(String value) {
    _details = value;
    notifyListeners();
  }

  set interval(BudgetInterval value) {
    _interval = value;
    notifyListeners();
  }

  set startDate(DateTime value) {
    _startDate = value;
    notifyListeners();
  }

  set name(String value) {
    _name = value;
    notifyListeners();
  }

  void setDefaults() {
    if (_budget != null) {
      _budget = _budget;
      _name = budget!.name;
      _details = _budget!.details;
      _interval = budget!.interval;
      _startDate = budget!.startDate;
      selectedExpenses = _budget!.expenses.map((k, v) => MapEntry(k.dbID, -v));
      selectedFunds = _budget!.funds.map((f) => f.dbID).toSet();
      selectedIncomes = _budget!.incomes.map((k, v) => MapEntry(k.dbID, v));
    }
    notifyListeners();
  }

  getAccounts() async {
    expenses = await _accountsRepository.getAccountsByAccType(_profile.dbID, 5);
    incomes = await _accountsRepository.getAccountsByAccType(_profile.dbID, 4);

    int accType = 0;
    do {
      funds.addAll(await _accountsRepository.getAccountsByAccType(
          _profile.dbID, accType));
      accType++;
    } while (fundingAccountIDs.contains(accType));

    selectedFunds = funds.map((f) => f.dbID).toSet();

    notifyListeners();
  }

  int getExpenseAmt(int account) {
    return selectedExpenses[account] ?? 0;
  }

  int getIncomeAmt(int account) {
    return selectedIncomes[account] ?? 0;
  }

  addExpense(int account, int amount) {
    selectedExpenses[account] = amount;

    notifyListeners();
    _calculateExpenses();
  }

  addIncome(int account, int amount) {
    selectedIncomes[account] = amount;

    notifyListeners();
    _calculateIncomes();
  }

  _calculateExpenses() {
    expenseTotal = selectedExpenses.values.sum;
    notifyListeners();
    _calculateDifference();
  }

  _calculateIncomes() {
    incomesTotal = selectedIncomes.values.sum;
    notifyListeners();
    _calculateDifference();
  }

  _calculateDifference() {
    difference = incomesTotal - expenseTotal;
    notifyListeners();
  }

  toggleFund(int id) {
    if (selectedFunds.contains(id)) {
      selectedFunds.remove(id);
    } else {
      selectedFunds.add(id);
    }
    notifyListeners();
  }

  Future<void> getBudgets() async {
    try {
      _budgets = await _budgetsRepository.getAll(_profile.dbID);

      AppLogger.instance.info("Budgets loaded from database");
    } catch (e) {
      AppLogger.instance.error("Error loading budgets ${e.toString()}");
    }
    notifyListeners();
  }

  bool _validate() {
    bool isValid = true;

    nameError = "";
    detailsError = "";
    intervalError = "";
    startDateError = "";
    selectedExpensesError = "";
    selectedIncomesError = "";
    selectedFundsError = "";
    notifyListeners();

    if (_name.trim().isEmpty) {
      nameError = "Budget name must be valid.";
      isValid = false;
    }
    if (_budget == null && _budgets.where((b) => b.name == _name).isNotEmpty) {
      nameError = "Budget name already exist";
      isValid = false;
    }
    if (selectedExpenses.isEmpty) {
      selectedExpensesError = "No expenses selected";
      isValid = false;
    }
    if (selectedFunds.isEmpty) {
      errorText = "No funds selected";
      isValid = false;
    }
    if (selectedIncomes.isEmpty) {
      errorText = "No incomes selected";
      isValid = false;
    }
    if (incomesTotal < expenseTotal) {
      if (!isWarningAlerted) {
        errorText =
            "Warning: Expenses are more than incomes. Cash flow will be negative";
        isValid = false;
      }
      isWarningAlerted = true;
    }

    notifyListeners();
    return isValid;
  }

  Future<bool> save() async {
    if (_validate()) {
      loadingStatus = LoadingStatus.submitting;
      notifyListeners();

      final Map<int, int> acc =
          Map.from(selectedExpenses.map((k, v) => MapEntry(k, -v)));
      acc.addAll(selectedIncomes);

      final f = funds.where((a) => selectedFunds.contains(a.dbID)).toList();

      if (_budget == null) {
        await _budgetsRepository.insertBudget(
            name, details, f, acc, interval, _profile.dbID);
      } else {
        await _budgetsRepository.updateBudget(
            _budget!.dbID, name, details, f, acc, interval, _profile.dbID);
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

  Future<bool> deleteBudget() async {
    if (_budget != null && _budget != null) {
      try {
        await _budgetsRepository.delete(_budget!.dbID);
        return true;
      } catch (e) {
        AppLogger.instance.error(' ${e.toString()}');
        errorText = 'Error: Failed to delete budget ';
        return false;
      }
    }
    notifyListeners();
    return false;
  }
}
