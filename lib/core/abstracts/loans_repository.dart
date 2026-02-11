import 'package:pursenal/core/models/domain/account.dart';
import 'package:pursenal/core/models/domain/loan.dart';

abstract class LoansRepository {
  Future<int> insertLoan(
      {required Account account,
      required String? institution,
      required String? accountNo,
      required String? agreementNo,
      required double? interestRate,
      required DateTime? startDate,
      required DateTime? endDate});
  Future<bool> updateLoan(
      {required int id,
      required Account account,
      required String? institution,
      required String? accountNo,
      required String? agreementNo,
      required double? interestRate,
      required DateTime? startDate,
      required DateTime? endDate});
  Future<int> delete(int id);
  Future<Loan> getById(int id);
  Future<Loan> getByAccount(int id);
}
