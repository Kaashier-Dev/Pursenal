import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:pursenal/app/extensions/datetime.dart';
import 'package:pursenal/app/global/values.dart';
import 'package:pursenal/core/enums/budget_interval.dart';
import 'package:pursenal/core/enums/loading_status.dart';
import 'package:pursenal/core/models/domain/account.dart';
import 'package:pursenal/core/models/domain/budget.dart';
import 'package:pursenal/core/models/domain/daily_total_transaction.dart';
import 'package:pursenal/core/models/domain/profile.dart';
import 'package:pursenal/core/models/domain/transaction.dart';
import 'package:pursenal/core/abstracts/accounts_repository.dart';
import 'package:pursenal/core/abstracts/budgets_repository.dart';
import 'package:pursenal/core/abstracts/transactions_repository.dart';
import 'package:pursenal/core/repositories/repository_registry.dart';
import 'package:pursenal/utils/app_logger.dart';

class BudgetViewmodel extends ChangeNotifier {
  final AccountsRepository _accountsRepository;
  final BudgetsRepository _budgetsRepository;
  final TransactionsRepository _transactionsRepository;

  BudgetViewmodel(
    RepositoryRegistry repositoryRegistry, {
    required Profile profile,
    required Budget budget,
  })  : _profile = profile,
        _budget = budget,
        _accountsRepository = repositoryRegistry.get<AccountsRepository>(),
        _budgetsRepository = repositoryRegistry.get<BudgetsRepository>(),
        _transactionsRepository =
            repositoryRegistry.get<TransactionsRepository>();
  LoadingStatus loadingStatus = LoadingStatus.idle;

  Budget _budget;
  // ignore: unnecessary_getters_setters
  Budget get budget => _budget;

  List<DailyTotalTransaction> _dailyTotalTransactions = [];

  List<DailyTotalTransaction> get dailyTotalTransactions =>
      _dailyTotalTransactions;

  Map<Account, int> expenseTotals = {};
  Map<Account, int> incomeTotals = {};

  List<Account> _expenses = [];
  List<Account> _incomes = [];
  final List<Account> _funds = [];
  List<Account> get funds => _funds;

  set budget(Budget value) => _budget = value;

  final Profile _profile;

  String errorText = "";

  List<Transaction> _transactions = [];

  List<Account> expenses = [];
  List<Account> incomes = [];

  List<DateTime> rangeDates = [];

  Map<int, int> selectedIncomes = {};
  Map<int, int> selectedExpenses = {};
  Set<int> selectedFunds = {};

  int bExpenseTotal = 0;
  int bIncomeTotal = 0;
  int bDifference = 0;

  int aExpenseTotal = 0;
  int aIncomeTotal = 0;
  int aDifference = 0;

  int expectedAvgExp = 0;
  int expectedAvgInc = 0;
  int expectedAvgDif = 0;

  bool isWarningAlerted = false;

  final DateTime today = DateTime.now();

  void init() async {
    loadingStatus = LoadingStatus.loading;
    try {
      await getAccounts();
      await _calculateDifference();
      await _getTransactions();
      await _calculateTotalTransactions();
      loadingStatus = LoadingStatus.completed;
      notifyListeners();
    } catch (e, stackTrace) {
      AppLogger.instance.error(' ${e.toString()}', [stackTrace]);
      errorText = 'Error: Failed to initialise Budget form';
      loadingStatus = LoadingStatus.error;
      notifyListeners();
    }
  }

  refetchBudget() async {
    try {
      loadingStatus = LoadingStatus.loading;
      budget = await _budgetsRepository.getById(_budget.dbID);
      notifyListeners();
      init();
    } catch (e) {
      AppLogger.instance.error(' ${e.toString()}');
      loadingStatus = LoadingStatus.error;
      errorText = 'Error: Failed to Load budget plan';
    }
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

    _expenses =
        await _accountsRepository.getAccountsByAccType(_profile.dbID, 5);
    _incomes = await _accountsRepository.getAccountsByAccType(_profile.dbID, 4);

    notifyListeners();
  }

  _getTransactions() async {
    DateTime startDate = DateTime(
      today.year,
      today.month,
    );
    DateTime endDate = DateTime.now();

    switch (_budget.interval) {
      case BudgetInterval.weekly:
        startDate = endDate.subtract(Duration(days: endDate.weekday - 1));
        break;
      case BudgetInterval.monthly:
        startDate = DateTime(
          today.year,
          today.month,
        );
        break;
      case BudgetInterval.annual:
        startDate = DateTime(today.year);
        break;
    }
    _transactions = []; // Reset transactions
    _transactions = await _transactionsRepository.getTransactions(
        startDate: startDate, endDate: endDate, profileId: _profile.dbID);
    _transactions = _transactions
        .where((t) =>
            budget.funds.any((f) =>
                f.dbID == t.crAccount.dbID || f.dbID == t.drAccount.dbID) &&
            (budget.expenses.keys.any((f) =>
                    f.dbID == t.crAccount.dbID || f.dbID == t.drAccount.dbID) ||
                budget.incomes.keys.any((f) =>
                    f.dbID == t.crAccount.dbID || f.dbID == t.drAccount.dbID)))
        .toList()
        .reversed
        .toList();

    DateTime sDate = startDate;
    rangeDates = List.generate(endDate.difference(sDate).inDays + 1,
        (index) => sDate.add(Duration(days: index)));

    _dailyTotalTransactions = List.from(
      rangeDates.map((d) => DailyTotalTransaction(dateTime: d)),
    );

    notifyListeners();
  }

  int getExpenseAmt(int account) {
    return selectedExpenses[account] ?? 0;
  }

  int getIncomeAmt(int account) {
    return selectedIncomes[account] ?? 0;
  }

  _calculateDifference() {
    bIncomeTotal = _budget.incomes.values.sum;
    bExpenseTotal = _budget.expenses.values.sum;
    bDifference = bIncomeTotal - bExpenseTotal.abs();
    notifyListeners();
  }

  _calculateTotalTransactions() {
    // Reset totals
    aExpenseTotal = 0;
    aIncomeTotal = 0;
    aDifference = 0;
    expenseTotals = {for (var k in _expenses) k: 0};
    incomeTotals = {for (var k in _incomes) k: 0};

    int cumExpenseTotal = 0;
    int cumIncomeTotal = 0;

    for (var dt in rangeDates) {
      final dtt = _dailyTotalTransactions
          .firstWhereOrNull((x) => x.dateTime.isSameDayAs(dt));
      List<Transaction> doubleEntries =
          _transactions.where((t) => t.voucherDate.isSameDayAs(dt)).toList();
      for (var t in doubleEntries) {
        switch (t.crAccount.accountType) {
          case 4:
            incomeTotals.update(t.crAccount, (amount) {
              return amount + t.amount;
            });
            cumIncomeTotal += t.amount;
            break;

          case 5:
            expenseTotals.update(t.crAccount, (amount) {
              return amount - t.amount;
            });
            cumExpenseTotal -= t.amount;
            break;
        }
        switch (t.drAccount.accountType) {
          case 5:
            expenseTotals.update(t.drAccount, (amount) {
              return amount - t.amount;
            });
            cumExpenseTotal += t.amount;
            break;

          case 4:
            incomeTotals.update(t.drAccount, (amount) {
              return amount + t.amount;
            });
            cumIncomeTotal -= t.amount;
            break;
        }
      }
      dtt?.addPayment(cumExpenseTotal);
      dtt?.addReceipt(cumIncomeTotal);
    }

    expenseTotals.removeWhere((a, i) {
      return i == 0;
    });

    expenseTotals = Map.fromEntries(expenseTotals.entries.toList()
      ..sort((a, b) => a.value.compareTo(b.value)));

    incomeTotals.removeWhere((a, i) {
      return i == 0;
    });

    incomeTotals = Map.fromEntries(incomeTotals.entries.toList()
      ..sort((a, b) => a.value.compareTo(b.value)));

    aExpenseTotal = expenseTotals.values.sum;
    aIncomeTotal = incomeTotals.values.sum;
    aDifference = aIncomeTotal.abs() - aExpenseTotal.abs();

    try {
      if (dailyTotalTransactions.isNotEmpty) {
        int noOfDays = dailyTotalTransactions.length;
        int totalDays = budget.interval == BudgetInterval.monthly
            ? 30
            : budget.interval == BudgetInterval.weekly
                ? 7
                : budget.interval == BudgetInterval.annual
                    ? 365
                    : 30;

        expectedAvgExp = ((bExpenseTotal / totalDays) * noOfDays).round();
        expectedAvgInc = ((bIncomeTotal / totalDays) * noOfDays).round();
        expectedAvgDif = ((bDifference / totalDays) * noOfDays).round();
      }
    } catch (e) {
      AppLogger.instance.error(' ${e.toString()}');
    }

    notifyListeners();
  }

  void resetErrorText() {
    errorText = "";
    notifyListeners();
  }

  Future<bool> deleteBudget() async {
    try {
      await _budgetsRepository.delete(_budget.dbID);
      return true;
    } catch (e) {
      AppLogger.instance.error(' ${e.toString()}');
      errorText = 'Error: Failed to delete budget ';
      return false;
    }
  }
}
