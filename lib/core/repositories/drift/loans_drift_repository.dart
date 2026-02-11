import 'package:drift/drift.dart';
import 'package:pursenal/app/extensions/drift_models.dart';
import 'package:pursenal/core/abstracts/loans_repository.dart';
import 'package:pursenal/core/db/app_drift_database.dart';
import 'package:pursenal/core/models/domain/account.dart';
import 'package:pursenal/core/models/domain/loan.dart';
import 'package:pursenal/utils/app_logger.dart';

class LoansDriftRepository implements LoansRepository {
  LoansDriftRepository(this.db);
  final AppDriftDatabase db;

  @override
  Future<int> insertLoan(
      {required Account account,
      required String? institution,
      required String? accountNo,
      required String? agreementNo,
      required double? interestRate,
      required DateTime? startDate,
      required DateTime? endDate}) async {
    try {
      final loan = DriftLoansCompanion(
          account: Value(account.dbID),
          institution: Value(institution),
          accountNo: Value(accountNo),
          agreementNo: Value(agreementNo),
          interestRate: Value(interestRate),
          startDate: Value(startDate),
          endDate: Value(endDate));
      return await db.insertLoan(loan);
    } catch (e) {
      AppLogger.instance.error("Failed to insert loan. ${e.toString()}");
      rethrow;
    }
  }

  @override
  Future<bool> updateLoan(
      {required int id,
      required Account account,
      required String? institution,
      required String? accountNo,
      required String? agreementNo,
      required double? interestRate,
      required DateTime? startDate,
      required DateTime? endDate}) async {
    try {
      final loan = DriftLoansCompanion(
        id: Value(id),
        account: Value(account.dbID),
        institution: Value(institution),
        accountNo: Value(accountNo),
        agreementNo: Value(agreementNo),
        interestRate: Value(interestRate),
        startDate: Value(startDate),
        endDate: Value(endDate),
      );
      return await db.updateLoan(loan);
    } catch (e) {
      AppLogger.instance.error("Failed to insert loan. ${e.toString()}");
      rethrow;
    }
  }

  @override
  Future<int> delete(int id) async {
    try {
      return await db.deleteLoan(id);
    } catch (e) {
      AppLogger.instance.error("Failed to delete loan. ${e.toString()}");
      rethrow;
    }
  }

  @override
  Future<Loan> getById(int id) async {
    try {
      final account = (await db.getAccountbyId(id)).toDomain();
      return (await db.getLoanById(id)).toDomain(account);
    } catch (e) {
      AppLogger.instance.error("Failed to get loan. ${e.toString()}");
      rethrow;
    }
  }

  @override
  Future<Loan> getByAccount(int id) async {
    try {
      final account = (await db.getAccountbyId(id)).toDomain();
      return (await db.getLoanByAccount(id)).toDomain(account);
    } catch (e) {
      AppLogger.instance.error("Failed to get Bank. ${e.toString()}");
      rethrow;
    }
  }
}
