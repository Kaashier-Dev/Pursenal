import 'package:drift/drift.dart';
import 'package:pursenal/app/extensions/drift_models.dart';
import 'package:pursenal/core/abstracts/receivables_repository.dart';
import 'package:pursenal/core/db/app_drift_database.dart';
import 'package:pursenal/core/models/domain/account.dart';
import 'package:pursenal/core/models/domain/receivable.dart';
import 'package:pursenal/utils/app_logger.dart';

class ReceivablesDriftRepository implements ReceivablesRepository {
  ReceivablesDriftRepository(this.db);
  final AppDriftDatabase db;

  @override
  Future<int> insertReceivable({
    required Account account,
    DateTime? paidDate,
    int? paidAmount,
  }) async {
    try {
      final receivable = DriftReceivablesCompanion(
        accountId: Value(account.dbID),
        paidDate: Value(paidDate),
        totalAmount: Value(paidAmount),
      );
      return await db.insertReceivable(receivable);
    } catch (e) {
      AppLogger.instance.error("Failed to insert receivable. ${e.toString()}");
      rethrow;
    }
  }

  @override
  Future<bool> updateReceivable({
    required Account account,
    required int id,
    DateTime? paidDate,
    int? paidAmount,
  }) async {
    try {
      final receivable = DriftReceivablesCompanion(
        accountId: Value(account.dbID),
        id: Value(id),
        paidDate: Value(paidDate),
        totalAmount: Value(paidAmount),
      );
      return await db.updateReceivable(receivable);
    } catch (e) {
      AppLogger.instance.error("Failed to update receivable. ${e.toString()}");
      rethrow;
    }
  }

  @override
  Future<int> delete(int id) async {
    try {
      return await db.deleteReceivable(id);
    } catch (e) {
      AppLogger.instance.error("Failed to delete receivable. ${e.toString()}");
      rethrow;
    }
  }

  @override
  Future<Receivable> getById(int id) async {
    try {
      final account = (await db.getAccountbyId(id)).toDomain();
      return (await db.getReceivableById(id)).toDomain(account);
    } catch (e) {
      AppLogger.instance.error("Failed to get receivable. ${e.toString()}");
      rethrow;
    }
  }

  @override
  Future<Receivable> getByAccount(int id) async {
    try {
      final account = (await db.getAccountbyId(id)).toDomain();
      return (await db.getReceivableByAccount(id)).toDomain(account);
    } catch (e) {
      AppLogger.instance.error("Failed to get Bank. ${e.toString()}");
      rethrow;
    }
  }
}
