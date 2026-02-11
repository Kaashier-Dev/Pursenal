import 'package:pursenal/core/models/domain/account.dart';
import 'package:pursenal/core/models/domain/people.dart';

abstract class PeopleRepository {
  Future<int> insertPeople({
    required Account account,
    String? address,
    String? email,
    String? tin,
    String? phone,
    String? zip,
  });
  Future<bool> updatePeople({
    required Account account,
    required int id,
    String? address,
    String? email,
    String? tin,
    String? phone,
    String? zip,
  });
  Future<int> delete(int id);
  Future<People> getById(int id);
  Future<People> getByAccount(int id);
}
