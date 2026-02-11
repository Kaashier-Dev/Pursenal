import 'dart:typed_data';
import 'dart:io';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:pursenal/utils/app_logger.dart';

Uint8List resizeTo64(Uint8List bytes) {
  final original = img.decodeImage(bytes);
  if (original == null) {
    throw Exception('Invalid image data');
  }

  final resized = img.copyResize(
    original,
    width: 64,
    height: 64,
    interpolation: img.Interpolation.average,
  );

  return Uint8List.fromList(
    img.encodeJpg(resized, quality: 80),
  );
}

Future<List<XFile>> compressAndResizeXFile(
  List<XFile> images, {
  int maxWidth = 1024,
  int quality = 36,
}) async {
  List<XFile> compressedFiles = [];
  for (var image in images) {
    final bytes = await image.readAsBytes();
    img.Image? decoded;

    try {
      decoded = img.decodeImage(bytes);
    } catch (e) {
      AppLogger.instance.error('Error decoding image ${image.name}: $e');
      compressedFiles.add(image);
      continue;
    }

    if (decoded == null) {
      AppLogger.instance.error('Unable to decode image ${image.name}');
      compressedFiles.add(image);
      continue;
    }

    final resized = img.copyResize(
      decoded,
      width: decoded.width > maxWidth ? maxWidth : decoded.width,
    );

    final encoded = img.encodeJpg(resized, quality: quality);

    final dir = Directory.systemTemp;
    final outPath = p.join(
      dir.path,
      '${p.basenameWithoutExtension(image.name)}_compressed.jpg',
    );

    final outFile = File(outPath);
    await outFile.writeAsBytes(encoded, flush: true);
    compressedFiles.add(XFile(outFile.path, name: p.basename(outPath)));
  }

  return compressedFiles;
}
