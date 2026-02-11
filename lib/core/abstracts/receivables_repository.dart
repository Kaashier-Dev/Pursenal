import 'package:pursenal/core/models/domain/account.dart';
import 'package:pursenal/core/models/domain/receivable.dart';

abstract class ReceivablesRepository {
  Future<int> insertReceivable({
    required Account account,
    DateTime? paidDate,
    int? paidAmount,
  });
  Future<bool> updateReceivable({
    required Account account,
    required int id,
    DateTime? paidDate,
    int? paidAmount,
  });
  Future<int> delete(int id);
  Future<Receivable> getById(int id);
  Future<Receivable> getByAccount(int id);
}
