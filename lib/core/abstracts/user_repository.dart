import 'package:pursenal/core/models/domain/user.dart';

abstract class UserRepository {
  Future<int> insertUser(
      {required String name,
      required String deviceID,
      required String filePath});
  Future<bool> updateUser(
      {required int dbID,
      required String name,
      required String deviceID,
      required String filePath});
  Future<User> getUser();
}
