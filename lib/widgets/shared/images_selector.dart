import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pursenal/utils/app_logger.dart';
import 'package:pursenal/l10n/app_localizations.dart';
import 'package:path/path.dart' as p;
import 'package:pursenal/utils/app_paths.dart';
import 'package:pursenal/utils/image_resizer.dart';

class ImagesSelector extends StatelessWidget {
  /// Field to select multiple images from the system
  const ImagesSelector({
    super.key,
    required this.paths,
    required this.addPathFn,
    required this.deletePathFn,
  });

  /// Paths for images already saved
  final List<String> paths;

  /// Callback function to add new a photo path
  final Function(String) addPathFn;

  /// Callback function to delete a photo path
  final Function(String) deletePathFn;

  @override
  Widget build(BuildContext context) {
    final String securePath = AppPaths.imagesDir;
    Future<void> pickImages() async {
      final ImagePicker picker = ImagePicker();
      List<XFile> pickedFiles = await picker.pickMultiImage();
      pickedFiles = await compressAndResizeXFile(
        pickedFiles,
        maxWidth: 1080,
      );
      if (pickedFiles.isNotEmpty) {
        for (XFile file in pickedFiles) {
          String fileName = file.name;
          try {
            fileName = AppPaths.uniqueFileName(fileName);
          } catch (e) {
            AppLogger.instance
                .error("Cannot rename image $fileName", e.toString());
          }
          await File(file.path).copy(p.join(securePath, fileName));
          // Delete the temp file because it is processed with image_resizer.dart
          await File(file.path).delete();
          addPathFn(fileName);
        }
      }
    }

    Future<void> deleteImage(String path) async {
      try {
        path = p.join(securePath, p.basename(path));
        final File file = File(path);
        if (await file.exists()) {
          await file.delete();
        }
      } catch (e) {
        AppLogger.instance.error('Error deleting image: $e');
      }
    }

    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: InputDecorator(
            decoration: InputDecoration(
                labelText: AppLocalizations.of(context)!.addPhotos,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                )),
            child: Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              runAlignment: WrapAlignment.center,
              children: [
                ...paths.map((i) {
                  final String path = p.join(securePath, p.basename(i));
                  return Padding(
                    padding: const EdgeInsets.all(2.0),
                    child: SizedBox(
                      width: 60,
                      height: 60,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(5),
                        child: Stack(
                          alignment: Alignment.topRight,
                          children: [
                            SizedBox(
                              width: 60,
                              height: 60,
                              child: Image.file(
                                File(path),
                                fit: BoxFit.cover,
                              ),
                            ),
                            Positioned(
                              top: -5,
                              right: -5,
                              child: IconButton(
                                onPressed: () {
                                  deletePathFn(i);
                                  deleteImage(i);
                                },
                                icon: const Icon(
                                  Icons.close,
                                  color: Colors.red,
                                  size: 20,
                                ),
                              ),
                            )
                          ],
                        ),
                      ),
                    ),
                  );
                }),
                Padding(
                  padding: const EdgeInsets.all(2.0),
                  child: SizedBox(
                    height: 60,
                    width: 60,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        elevation: 1,
                        padding: EdgeInsets.zero,
                      ),
                      onPressed: () {
                        pickImages();
                      },
                      child: const Icon(
                        Icons.add,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
