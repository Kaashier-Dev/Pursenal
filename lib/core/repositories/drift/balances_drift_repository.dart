import 'package:drift/drift.dart';
import 'package:pursenal/core/abstracts/balances_repository.dart';
import 'package:pursenal/core/db/app_drift_database.dart';
import 'package:pursenal/core/models/domain/account.dart';
import 'package:pursenal/utils/app_logger.dart';

class BalancesDriftRepository implements BalancesRepository {
  BalancesDriftRepository(this.db);
  final AppDriftDatabase db;

  @override
  Future<int> insertBalance(
      {required Account account, required int amount}) async {
    try {
      final balance = DriftBalancesCompanion(
          account: Value(account.dbID), amount: Value(amount));
      return await db.insertBalance(balance);
    } catch (e) {
      AppLogger.instance.error("Failed to insert balance. ${e.toString()}");
      rethrow;
    }
  }

  @override
  Future<bool> updateBalanceByAccount({required Account account}) async {
    try {
      final amount = await db.calculateBalance(account.dbID);
      final balance = await db.getBalanceByAccount(account.dbID);
      final newBal = DriftBalancesCompanion(
          account: Value(account.dbID),
          amount: Value(amount),
          id: Value(balance.id));
      return await db.updateBalance(newBal);
    } catch (e, stackTrace) {
      AppLogger.instance
          .error("Failed to insert balance. ${e.toString()}", [stackTrace]);
      rethrow;
    }
  }

  @override
  Future<int> getClosingBalance(
      {required Account account, required DateTime closingDate}) async {
    try {
      return await db.getClosingBalance(account.dbID, closingDate);
    } catch (e) {
      AppLogger.instance.error("Failed to get balance. ${e.toString()}");
      rethrow;
    }
  }

  @override
  Future<int> delete(int id) async {
    try {
      return await db.deleteBalance(id);
    } catch (e) {
      AppLogger.instance.error("Failed to delete balance. ${e.toString()}");
      rethrow;
    }
  }

  @override
  Future<int> getFundClosingBalance(DateTime closingDate, int profileID) async {
    try {
      return await db.getFundClosingBalance(closingDate, profileID);
    } catch (e, stackTrace) {
      AppLogger.instance.error(
          "Failed to get fund closing balance. ${e.toString()}", [stackTrace]);
      rethrow;
    }
  }
}
