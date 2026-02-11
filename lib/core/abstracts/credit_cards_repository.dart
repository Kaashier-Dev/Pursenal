import 'package:pursenal/core/models/domain/account.dart';
import 'package:pursenal/core/models/domain/credit_card.dart';

abstract class CreditCardsRepository {
  Future<int> insertCCard({
    required Account account,
    required String? institution,
    required String? cardNetwork,
    required String? cardNo,
    required int? statementDate,
  });
  Future<bool> updateCCard({
    required int id,
    required Account account,
    required String? institution,
    required String? cardNetwork,
    required String? cardNo,
    required int? statementDate,
  });
  Future<int> delete(int id);
  Future<CreditCard> getById(int id);
  Future<CreditCard> getByAccount(int id);
}
