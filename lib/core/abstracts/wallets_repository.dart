import 'package:pursenal/core/models/domain/account.dart';
import 'package:pursenal/core/models/domain/wallet.dart';

abstract class WalletsRepository {
  Future<int> insertWallet({required Account account});
  Future<bool> updateWallet({required Account account, required int id});
  Future<int> delete(int id);
  Future<Wallet> getById(int id);
  Future<Wallet> getByAccount(int id);
}
