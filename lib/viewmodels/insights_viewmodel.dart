import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:pursenal/app/extensions/currency.dart';
import 'package:pursenal/app/extensions/datetime.dart';
import 'package:pursenal/app/global/values.dart';
import 'package:pursenal/core/enums/budget_interval.dart';
import 'package:pursenal/core/enums/date_filter_type.dart';
import 'package:pursenal/core/enums/loading_status.dart';
import 'package:pursenal/core/models/domain/account.dart';
import 'package:pursenal/core/models/domain/budget.dart';
import 'package:pursenal/core/models/domain/daily_total_transaction.dart';
import 'package:pursenal/core/models/domain/ledger.dart';
import 'package:pursenal/core/models/domain/profile.dart';
import 'package:pursenal/core/models/domain/transaction.dart';
import 'package:pursenal/core/abstracts/accounts_repository.dart';
import 'package:pursenal/core/abstracts/balances_repository.dart';
import 'package:pursenal/core/abstracts/budgets_repository.dart';
import 'package:pursenal/core/abstracts/profiles_repository.dart';
import 'package:pursenal/core/abstracts/transactions_repository.dart';
import 'package:pursenal/core/repositories/repository_registry.dart';
import 'package:pursenal/utils/app_logger.dart';

class InsightsViewmodel extends ChangeNotifier {
  final ProfilesRepository _profilesRepository;
  final AccountsRepository _accountsRepository;
  final TransactionsRepository _transactionsRepository;
  final BalancesRepository _balancesRepository;
  final BudgetsRepository _budgetsRepository;

  InsightsViewmodel(
      RepositoryRegistry repositoryRegistry, this._profilesRepository,
      {required Profile profile})
      : _selectedProfile = profile,
        _accountsRepository = repositoryRegistry.get<AccountsRepository>(),
        _transactionsRepository =
            repositoryRegistry.get<TransactionsRepository>(),
        _balancesRepository = repositoryRegistry.get<BalancesRepository>(),
        _budgetsRepository = repositoryRegistry.get<BudgetsRepository>();

  List<Profile> _profiles = [];

  List<Profile> get profiles => _profiles;

  Profile _selectedProfile;

  Profile get selectedProfile => _selectedProfile;

  DateTime startDate = DateTime(DateTime.now().year, DateTime.now().month);

  DateTime endDate = DateTime.now().copyWith(hour: 23, minute: 59, second: 59);

  LoadingStatus loadingStatus = LoadingStatus.idle;
  LoadingStatus calculationStatus = LoadingStatus.idle;

  List<Ledger> allLedgers = [];

  String errorText = "";

  List<int> balances = [];

  final int recentCount = 4;

  List<Transaction> _transactions = [];
  List<Transaction> get transactions => _transactions;

  List<Account> _expenses = [];
  List<Account> _incomes = [];
  List<Account> _funds = [];
  List<Account> get funds => _funds;

  Set<int> selectedFundsForBalanceChart = {};

  Map<Account, int> expenseTotals = {};
  int expenseTotal = 0;

  DateFilterType _dateFilterType = DateFilterType.monthly;
  DateFilterType get dateFilterType => _dateFilterType;
  Map<Account, int> incomeTotals = {};

  int _closingBalance = 0;
  int get closingBalance => _closingBalance;

  List<DateTime> _rangeDates = [];
  List<DateTime> get rangeDates => _rangeDates;

  List<DailyTotalTransaction> _dailyTotalTransactions = [];

  List<DailyTotalTransaction> get dailyTotalTransactions =>
      _dailyTotalTransactions;

  Map<int, List<int>> weeklyAvgExpenses = {};

  Map<Account, List<int>> fundBalances = {};

  List<Budget> budgets = [];
  Budget? _selectedBudget;
  Budget? get selectedBudget => _selectedBudget;

  int _expCardPage = 0;
  final PageController _expCardpageController = PageController();

  int get expCardPage => _expCardPage;
  PageController get expCardpageController => _expCardpageController;

  int _dailyCardPage = 0;
  final PageController _dailyCardpageController = PageController();

  int get dailyCardPage => _dailyCardPage;
  PageController get dailyCardpageController => _dailyCardpageController;

  Future<void> init() async {
    try {
      _closingBalance = 0;
      loadingStatus = LoadingStatus.loading;
      notifyListeners();
      dateFilterType = DateFilterType.monthly;
      _profiles = await _profilesRepository.getAll();
      loadingStatus = LoadingStatus.completed;
      notifyListeners();
      await getData();
      await _calculate();
      await _getBudgets();
      if (budgets.isNotEmpty) {
        _selectedBudget = budgets.first;
      }
    } catch (e, stackTrace) {
      AppLogger.instance.error(' ${e.toString()}', [stackTrace]);
      errorText = 'Error: Failed to initialise insights';
      loadingStatus = LoadingStatus.error;
      notifyListeners();
    }
  }

  set selectedBudget(Budget? value) {
    _selectedBudget = value;
    notifyListeners();

    if (_selectedBudget != null) {
      switch (_selectedBudget?.interval) {
        case BudgetInterval.weekly:
          if (_dateFilterType != DateFilterType.weekly) {
            dateFilterType = DateFilterType.weekly;
          }
          break;
        case BudgetInterval.monthly:
          if (_dateFilterType != DateFilterType.monthly) {
            dateFilterType = DateFilterType.monthly;
          }
          break;
        case BudgetInterval.annual:
          if (_dateFilterType != DateFilterType.annual) {
            dateFilterType = DateFilterType.annual;
          }
          break;
        default:
          dateFilterType = DateFilterType.monthly;
          break;
      }
    }
    notifyListeners();
  }

  trySetBudget() {
    switch (_dateFilterType) {
      case DateFilterType.weekly:
        final bs = budgets.where((b) => b.interval == BudgetInterval.weekly);
        if (bs.isNotEmpty) {
          _selectedBudget = bs.first;
        }
        break;
      case DateFilterType.monthly:
        final bs = budgets.where((b) => b.interval == BudgetInterval.monthly);
        if (bs.isNotEmpty) {
          _selectedBudget = bs.first;
        }
        break;

      case DateFilterType.annual:
        final bs = budgets.where((b) => b.interval == BudgetInterval.annual);
        if (bs.isNotEmpty) {
          _selectedBudget = bs.first;
        }
        break;
      default:
    }
    notifyListeners();
  }

  set selectedProfile(Profile value) {
    _selectedProfile = value;
    notifyListeners();
  }

  set dateFilterType(DateFilterType value) {
    _dateFilterType = value;

    if (value != DateFilterType.custom) {
      DateTime sDate = DateTime.now();
      DateTime eDate = sDate;

      if (_dateFilterType == DateFilterType.daily) {
        sDate = DateTime.now();
        eDate = sDate;
      } else if (_dateFilterType == DateFilterType.weekly) {
        eDate = DateTime.now();
        sDate = eDate.subtract(Duration(days: eDate.weekday - 1));
        trySetBudget();
      } else if (_dateFilterType == DateFilterType.monthly) {
        eDate = DateTime.now();
        sDate = eDate.copyWith(day: 1);
        trySetBudget();
      } else if (_dateFilterType == DateFilterType.annual) {
        eDate = DateTime.now();
        sDate = eDate.copyWith(year: eDate.year - 1);
        trySetBudget();
      }

      addToFilter(eDate: eDate, sDate: sDate);
      notifyListeners();
    }
  }

  getData() async {
    await _getAccounts();
    await _getTransactions();
  }

  _calculate() async {
    if (calculationStatus == LoadingStatus.loading) {
      return;
    }
    calculationStatus = LoadingStatus.loading;
    notifyListeners();
    _setLegends();
    await _setBalances();
    _calculateTotalExpenses();
    _populateWeekDayExpenses();
    calculationStatus = LoadingStatus.completed;
    notifyListeners();
  }

  _getAccounts() async {
    allLedgers =
        await _accountsRepository.getLedgers(profileId: _selectedProfile.dbID);

    _funds = await _accountsRepository.getAccountsByCategory(
        profileId: _selectedProfile.dbID, accTypeIDs: fundIDs);

    for (var f in _funds) {
      if (f.accountType > 1) {
        selectedFundsForBalanceChart.add(f.dbID);
      }
    }

    _expenses = await _accountsRepository.getAccountsByAccType(
        _selectedProfile.dbID, expenseTypeID);
    _incomes = await _accountsRepository.getAccountsByAccType(
        _selectedProfile.dbID, incomeTypeID);

    expenseTotals = {for (var k in _expenses) k: 0};
    incomeTotals = {for (var k in _incomes) k: 0};

    notifyListeners();
  }

  _getTransactions() async {
    _transactions = []; // Reset transactions
    _transactions = await _transactionsRepository.getTransactions(
        startDate: startDate,
        endDate: endDate,
        profileId: _selectedProfile.dbID);
    notifyListeners();
  }

  _getBudgets() async {
    budgets = await _budgetsRepository.getAll(_selectedProfile.dbID);

    notifyListeners();
  }

  addToFilter(
      {DateTime? sDate,
      DateTime? eDate,
      int? a,
      bool shouldGetData = true}) async {
    if (sDate != null) {
      if (sDate.isBeforeOrEqualTo(startDate)) {}
      startDate = sDate;
    }
    if (eDate != null) {
      eDate = eDate.copyWith(hour: 23, minute: 59, second: 59);
      if (eDate.isAfter(endDate)) {}
      endDate = eDate;
    }

    if (a != null) {
      if (selectedFundsForBalanceChart.contains(a)) {
        selectedFundsForBalanceChart.remove(a);
      } else {
        selectedFundsForBalanceChart.add(a);
      }
      notifyListeners();
      await _calculate();
      return;
    }

    notifyListeners();

    if (shouldGetData) {
      await getData();
    }
    await _calculate();
    notifyListeners();
    setExpCardPage(0);
    setDailyCardPage(0);
  }

  _calculateTotalExpenses() {
    // Reset totals
    expenseTotals = {for (var k in _expenses) k: 0};
    incomeTotals = {for (var k in _incomes) k: 0};

    for (var t in _transactions) {
      final dtt = _dailyTotalTransactions
          .firstWhereOrNull((x) => x.dateTime.isSameDayAs(t.voucherDate));
      if (!t.voucherDate.isBetween(startDate, endDate)) {
        continue;
      }

      switch (t.crAccount.accountType) {
        case 4:
          incomeTotals.update(t.crAccount, (amount) {
            return amount + t.amount;
          });
          dtt?.addReceipt(t.amount);

          break;

        case 5:
          expenseTotals.update(t.crAccount, (amount) {
            return amount - t.amount;
          });
          dtt?.addReceipt(t.amount);
          break;
      }
      switch (t.drAccount.accountType) {
        case 5:
          expenseTotals.update(t.drAccount, (amount) {
            return amount - t.amount;
          });
          dtt?.addPayment(t.amount);

          break;

        case 4:
          incomeTotals.update(t.drAccount, (amount) {
            return amount + t.amount;
          });
          dtt?.addPayment(t.amount);

          break;
      }
    }
    expenseTotals.removeWhere((a, i) {
      return i == 0;
    });

    expenseTotals = Map.fromEntries(expenseTotals.entries.toList()
      ..sort((a, b) => a.value.compareTo(b.value)));

    incomeTotals = {for (var k in _incomes) k: 0};
    expenseTotal = expenseTotals.values.sum;

    notifyListeners();
  }

  _populateWeekDayExpenses() {
    weeklyAvgExpenses = {for (var e in List.generate(7, (i) => i + 1)) e: []};
    if (dailyTotalTransactions.length > 7) {
      for (var k in dailyTotalTransactions) {
        int weekDay = k.dateTime.weekday;
        weeklyAvgExpenses[weekDay]?.add(k.paymentsTotal.toCurrency().toInt());
      }
    }
    notifyListeners();
  }

  populateBudgetUsage() {
    if (_selectedBudget != null) {}
  }

  _setBalances() async {
    fundBalances = {};
    for (var f in _funds) {
      if (!selectedFundsForBalanceChart.contains(f.dbID)) {
        fundBalances.addAll({f: []});
      }
    }

    for (var d in _rangeDates) {
      for (var f in _funds) {
        fundBalances[f]?.add(await _balancesRepository.getClosingBalance(
            account: f, closingDate: d));
      }
    }

    notifyListeners();
  }

  _setLegends() {
    DateTime sDate = startDate;
    _rangeDates = List.generate(endDate.difference(sDate).inDays + 1,
        (index) => sDate.add(Duration(days: index)));

    _dailyTotalTransactions = List.from(
      _rangeDates.map((d) => DailyTotalTransaction(dateTime: d)),
    );

    notifyListeners();
  }

  void resetErrorText() {
    errorText = "";
    notifyListeners();
  }

  String getExpensePercentage(int value) {
    return (value != 0 && expenseTotal != 0)
        ? "${expenseTotals.entries.length == 1 ? 100 : (value / expenseTotal * 100).toStringAsPrecision(2)} %"
        : "";
  }

  void setExpCardPage(int index) {
    if (_expCardPage != index) {
      _expCardPage = index;
      _expCardpageController.animateToPage(index,
          duration: Durations.medium1, curve: Curves.bounceIn);
      notifyListeners();
    }
  }

  void setDailyCardPage(int index) {
    if (index != _dailyCardPage) {
      _dailyCardPage = index;
      _dailyCardpageController.jumpToPage(
        index,
      );
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _expCardpageController.dispose();
    _dailyCardpageController.dispose();
    super.dispose();
  }
}
