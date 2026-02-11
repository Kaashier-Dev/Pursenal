import 'package:pursenal/core/models/domain/account.dart';
import 'package:pursenal/core/models/domain/bank.dart';

abstract class BanksRepository {
  Future<int> insertBank({
    required Account account,
    required String? branch,
    required String? branchCode,
    required String? holderName,
    required String? accountNo,
    required String? institution,
  });

  Future<bool> updateBank({
    required int id,
    required Account account,
    required String? branch,
    required String? branchCode,
    required String? accountNo,
    required String? holderName,
    required String? institution,
  });

  Future<int> delete(int id);
  Future<Bank> getById(int id);
  Future<Bank> getByAccount(int id);
}
