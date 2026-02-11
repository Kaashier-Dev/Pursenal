import 'dart:typed_data';

class UserDevice {
  final String deviceID;
  final String name;
  final String platform;
  final String osVersion;
  final Uint8List? photo;
  final String appVersion;

  UserDevice({
    required this.deviceID,
    required this.name,
    required this.platform,
    required this.osVersion,
    this.photo,
    required this.appVersion,
  });

  @override
  bool operator ==(covariant UserDevice other) {
    if (identical(this, other)) return true;

    return other.deviceID == deviceID;
  }

  @override
  int get hashCode {
    return deviceID.hashCode;
  }
}
