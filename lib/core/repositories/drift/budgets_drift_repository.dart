import 'package:drift/drift.dart';
import 'package:pursenal/app/extensions/drift_models.dart';
import 'package:pursenal/core/abstracts/budgets_repository.dart';
import 'package:pursenal/core/db/app_drift_database.dart';
import 'package:pursenal/core/enums/budget_interval.dart';
import 'package:pursenal/core/models/domain/account.dart';
import 'package:pursenal/core/models/domain/budget.dart';
import 'package:pursenal/utils/app_logger.dart';

class BudgetsDriftRepository implements BudgetsRepository {
  BudgetsDriftRepository(this.db);
  final AppDriftDatabase db;

  @override
  Future<int> delete(int id) async {
    try {
      return await db.deleteBudget(id);
    } catch (e) {
      AppLogger.instance.error("Failed to delete Budget. ${e.toString()}");
      rethrow;
    }
  }

  @override
  Future<Budget> getById(int id) async {
    try {
      final budgetTuple = await db.getBudgetByID(id);

      return budgetTuple.item1.toDomain(
          funds: budgetTuple.item2.map((f) => f.toDomain()).toList(),
          incomes: budgetTuple.item3.map((k, v) => MapEntry(k.toDomain(), v)),
          expenses: budgetTuple.item4.map((k, v) => MapEntry(k.toDomain(), v)));
    } catch (e) {
      AppLogger.instance.error("Failed to get Budget. ${e.toString()}");
      rethrow;
    }
  }

  @override
  Future<List<Budget>> getAll(int profile) async {
    try {
      return (await db.getAllBudgets(profile))
          .map((b) => b.item1.toDomain(
              funds: b.item2.map((f) => f.toDomain()).toList(),
              incomes: b.item3.map((k, v) => MapEntry(k.toDomain(), v)),
              expenses: b.item4.map((k, v) => MapEntry(k.toDomain(), v))))
          .toList();
    } catch (e) {
      AppLogger.instance.error("Failed to get Budget list. ${e.toString()}");
      rethrow;
    }
  }

  @override
  Future<int> insertBudget(String name, String details, List<Account> funds,
      Map<int, int> accounts, BudgetInterval interval, int profile) async {
    try {
      DriftBudgetsCompanion b = DriftBudgetsCompanion.insert(
          name: name, interval: interval, details: details, profile: profile);

      final bId = await db.insertBudget(b);

      for (var i in funds) {
        await db.insertBudgetFund(
            DriftBudgetFundsCompanion.insert(account: i.dbID, budget: bId));
      }

      accounts.forEach((k, v) async {
        if (v != 0) {
          await db.insertBudgetAccount(DriftBudgetAccountsCompanion.insert(
              account: k, budget: bId, amount: Value(v)));
        }
      });

      return bId;
    } catch (e) {
      AppLogger.instance.error("Failed to insert Budget. ${e.toString()}");
      rethrow;
    }
  }

  @override
  Future<bool> updateBudget(
      int id,
      String name,
      String details,
      List<Account> funds,
      Map<int, int> accounts,
      BudgetInterval interval,
      int profile) async {
    try {
      DriftBudgetsCompanion b = DriftBudgetsCompanion.insert(
          id: Value(id),
          name: name,
          interval: interval,
          details: details,
          profile: profile);

      await db.updateBudget(b);

      await db.deleteBudgetAccountByBudget(id);
      await db.deleteBudgetFundByBudget(id);

      for (var i in funds) {
        await db.insertBudgetFund(
            DriftBudgetFundsCompanion.insert(account: i.dbID, budget: id));
      }

      accounts.forEach((k, v) async {
        if (v != 0) {
          await db.insertBudgetAccount(DriftBudgetAccountsCompanion.insert(
              account: k, budget: id, amount: Value(v)));
        }
      });

      return true;
    } catch (e) {
      AppLogger.instance.error("Failed to update Budget. ${e.toString()}");
      rethrow;
    }
  }
}
