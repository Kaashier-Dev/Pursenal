// ignore_for_file: public_member_api_docs, sort_constructors_first
class User {
  final int dbID;
  final String name;
  final String deviceID;
  final String photoPath;

  User({
    required this.dbID,
    required this.name,
    required this.deviceID,
    required this.photoPath,
  });

  @override
  String toString() {
    return 'User(dbID: $dbID, name: $name, deviceID: $deviceID, photoPath: $photoPath)';
  }
}
