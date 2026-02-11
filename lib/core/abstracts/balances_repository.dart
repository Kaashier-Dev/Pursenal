import 'package:pursenal/core/models/domain/account.dart';

abstract class BalancesRepository {
  Future<int> insertBalance({required Account account, required int amount});
  Future<bool> updateBalanceByAccount({required Account account});
  Future<int> getClosingBalance(
      {required Account account, required DateTime closingDate});
  Future<int> delete(int id);
  Future<int> getFundClosingBalance(DateTime closingDate, int profileID);
}
