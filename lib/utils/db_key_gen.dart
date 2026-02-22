import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';
import 'dart:math';

Future<String> getOrGenerateKey() async {
  const storage = FlutterSecureStorage();
  var key = await storage.read(key: 'db_password');

  if (key == null) {
    // Generate a random 32-character string
    final values = List<int>.generate(32, (i) => Random.secure().nextInt(256));
    key = base64Url.encode(values);
    await storage.write(key: 'db_password', value: key);
  }
  return key;
}
