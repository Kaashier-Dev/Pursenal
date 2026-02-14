import 'package:drift/drift.dart';
import 'package:pursenal/app/extensions/drift_models.dart';
import 'package:pursenal/core/abstracts/user_repository.dart';
import 'package:pursenal/core/db/app_drift_database.dart';
import 'package:pursenal/core/models/domain/user.dart';
import 'package:pursenal/utils/app_logger.dart';

class UserDriftRepository implements UserRepository {
  UserDriftRepository(this.db);
  final AppDriftDatabase db;

  @override
  Future<User> getById(int id) async {
    try {
      return User(
          dbID: 0, name: "name", deviceID: "deviceID", photoPath: "photoPath");
    } catch (e) {
      AppLogger.instance.error("Failed to get user. ${e.toString()}");
      rethrow;
    }
  }

  @override
  Future<int> insertUser(
      {required String name,
      required String deviceID,
      required String filePath}) async {
    try {
      final driftUser = DriftUsersCompanion(
        name: Value(name),
        deviceID: Value(deviceID),
        photoPath: Value(filePath),
      );
      return db.insertUser(driftUser);
    } catch (e) {
      AppLogger.instance.error("Failed to insert user. ${e.toString()}");
      rethrow;
    }
  }

  @override
  Future<bool> updateUser(
      {required int dbID,
      required String name,
      required String deviceID,
      required String filePath}) {
    try {
      final driftUser = DriftUsersCompanion(
        id: Value(dbID),
        name: Value(name),
        deviceID: Value(deviceID),
        photoPath: Value(filePath),
      );
      return db.updateUser(driftUser);
    } catch (e) {
      AppLogger.instance.error("Failed to update user. ${e.toString()}");
      rethrow;
    }
  }
}
