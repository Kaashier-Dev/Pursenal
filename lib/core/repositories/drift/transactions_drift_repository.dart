import 'package:drift/drift.dart';
import 'package:pursenal/app/extensions/drift_models.dart';
import 'package:pursenal/core/abstracts/transactions_repository.dart';
import 'package:pursenal/core/db/app_drift_database.dart';
import 'package:pursenal/core/enums/voucher_type.dart';
import 'package:pursenal/core/models/domain/account.dart';
import 'package:pursenal/core/models/domain/profile.dart';
import 'package:pursenal/core/models/domain/project.dart';
import 'package:pursenal/core/models/domain/transaction.dart';
import 'package:pursenal/utils/app_logger.dart';

class TransactionsDriftRepository implements TransactionsRepository {
  TransactionsDriftRepository(this.db);
  final AppDriftDatabase db;

  @override
  Future<int> insertTransaction(
      {required DateTime vchDate,
      required String narr,
      required String refNo,
      required Account dr,
      required Account cr,
      required int amount,
      required VoucherType vchType,
      required Profile profile,
      Project? project}) async {
    try {
      final transaction = DriftTransactionsCompanion(
          vchDate: Value(vchDate),
          narr: Value(narr),
          refNo: Value(refNo),
          dr: Value(dr.dbID),
          cr: Value(cr.dbID),
          project: Value(project?.dbID),
          amount: Value(amount),
          vchType: Value(vchType),
          profile: Value(profile.dbID));
      AppLogger.instance.info("Inserting transaction");
      return await db.insertTransaction(transaction);
    } catch (e) {
      AppLogger.instance.error("Failed to insert transaction. ${e.toString()}");
      rethrow;
    }
  }

  @override
  Future<bool> updateTransaction(
      {required int id,
      required DateTime vchDate,
      required String narr,
      required String refNo,
      required Account dr,
      required Account cr,
      required int amount,
      required VoucherType vchType,
      required Profile profile,
      Project? project}) async {
    try {
      final transaction = DriftTransactionsCompanion(
          id: Value(id),
          vchDate: Value(vchDate),
          narr: Value(narr),
          refNo: Value(refNo),
          dr: Value(dr.dbID),
          cr: Value(cr.dbID),
          amount: Value(amount),
          vchType: Value(vchType),
          profile: Value(profile.dbID),
          project: Value(project?.dbID),
          updateDate: Value(DateTime.now()));
      AppLogger.instance.info("Updating transaction id: $id");
      return await db.updateTransaction(transaction);
    } catch (e) {
      AppLogger.instance.error("Failed to update transaction. ${e.toString()}");
      rethrow;
    }
  }

  @override
  Future<int> delete(int id) async {
    try {
      AppLogger.instance.info("Deleting Transaction: $id");
      return await db.deleteTransaction(id);
    } catch (e) {
      AppLogger.instance.error("Failed to delete transaction. ${e.toString()}");
      rethrow;
    }
  }

  @override
  Future<Transaction> getTransactionById({required int transactionID}) async {
    try {
      final t = await db.getTransactionById(transactionID);

      return t.item1.toDomain(
          t.item2.toDomain(),
          t.item3.toDomain(),
          t.item5?.toDomain(photoPaths: []),
          t.item4.map((p) => p.path).toList());
    } catch (e) {
      AppLogger.instance.error("Failed to get transaction. ${e.toString()}");
      rethrow;
    }
  }

  @override
  Future<List<Transaction>> getTransactions(
      {required DateTime startDate,
      required DateTime endDate,
      required int profileId}) async {
    try {
      AppLogger.instance.info("Loading Transactions");
      final transactionsTuples = await db.getTransactions(
          startDate: startDate.copyWith(hour: 0, minute: 0, second: 0),
          endDate: endDate.copyWith(hour: 23, minute: 59, second: 59),
          profileId: profileId);

      return transactionsTuples
          .map((t) => t.item1.toDomain(
              t.item2.toDomain(),
              t.item3.toDomain(),
              t.item5?.toDomain(photoPaths: []),
              t.item4.map((p) => p.path).toList()))
          .toList();
    } catch (e) {
      AppLogger.instance
          .error("Failed to get transactions list. ${e.toString()}");
      rethrow;
    }
  }

  @override
  Future<List<Transaction>> getTransactionsbyAccount(
      {required DateTime startDate,
      required DateTime endDate,
      required int profileId,
      required int accountId,
      reversed = true}) async {
    try {
      AppLogger.instance.info("Loading Transactions for account : $accountId");

      final transactionsTuples = await db.getTransactionsByAccount(
        startDate: startDate.copyWith(hour: 0, minute: 0, second: 0),
        endDate: endDate.copyWith(hour: 23, minute: 59, second: 59),
        profileId: profileId,
        accountId: accountId,
        reversed: reversed,
      );
      return transactionsTuples
          .map((t) => t.item1.toDomain(
              t.item2.toDomain(),
              t.item3.toDomain(),
              t.item5?.toDomain(photoPaths: []),
              t.item4.map((p) => p.path).toList()))
          .toList();
    } catch (e) {
      AppLogger.instance
          .error("Failed to get transactions list. ${e.toString()}");
      rethrow;
    }
  }

  @override
  Future<int?> getLastTransactionID() async {
    try {
      return await db.getLastTransactionID();
    } catch (e) {
      AppLogger.instance.error("Failed to get transaction id. ${e.toString()}");
      rethrow;
    }
  }

  @override
  Future<List<Transaction>> getNTransactions(
      {required int n, required int profileId}) async {
    try {
      AppLogger.instance.info("Loading $n Transactions");

      final transactionsTuples = await db.getNTransactions(n, profileId);

      return transactionsTuples
          .map((t) => t.item1.toDomain(
              t.item2.toDomain(),
              t.item3.toDomain(),
              t.item5?.toDomain(photoPaths: []),
              t.item4.map((p) => p.path).toList()))
          .toList();
    } catch (e) {
      AppLogger.instance
          .error("Failed to get transactions list. ${e.toString()}");
      rethrow;
    }
  }

  @override
  Future<List<Transaction>> getTransactionsbyProject({
    required int profileID,
    required int projectID,
  }) async {
    try {
      AppLogger.instance.info("Loading Transactions for project : $projectID");

      final transactionsTuples = await db.getTransactionsByProject(
          profileID: profileID, projectID: projectID);

      return transactionsTuples
          .map((t) => t.item1.toDomain(
              t.item2.toDomain(),
              t.item3.toDomain(),
              t.item5?.toDomain(photoPaths: []),
              t.item4.map((p) => p.path).toList()))
          .toList();
    } catch (e) {
      AppLogger.instance
          .error("Failed to get transactions list. ${e.toString()}");
      rethrow;
    }
  }
}
