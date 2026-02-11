import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:pursenal/app/global/dimensions.dart';
import 'package:pursenal/core/models/domain/user.dart';
import 'package:pursenal/core/repositories/drift/user_drift_repository.dart';
import 'package:pursenal/utils/app_logger.dart';
import 'package:pursenal/utils/app_paths.dart';
import 'package:pursenal/utils/image_resizer.dart';
import 'package:pursenal/viewmodels/app_viewmodel.dart';
import 'package:pursenal/viewmodels/user_viewmodel.dart';
import 'package:pursenal/widgets/shared/loading_body.dart';
import 'package:pursenal/l10n/app_localizations.dart';
import 'package:path/path.dart' as p;

class UserEditScreen extends StatelessWidget {
  const UserEditScreen({
    super.key,
    required this.user,
  });
  final User user;

  @override
  Widget build(BuildContext context) {
    final userRepository =
        Provider.of<UserDriftRepository>(context, listen: false);

    final appViewmodel = Provider.of<AppViewmodel>(context);
    return ChangeNotifierProvider<UserViewmodel>(
      create: (context) => UserViewmodel(user, userRepository)..init(),
      child: Consumer<UserViewmodel>(
        builder: (context, viewmodel, child) {
          final String securePath = AppPaths.imagesDir;
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

          Future<void> pickImage(ImageSource imgSource) async {
            final ImagePicker picker = ImagePicker();
            XFile? file = await picker.pickImage(source: imgSource);
            if (file != null) {
              file = (await compressAndResizeXFile([file],
                      maxWidth: 512, quality: 70))
                  .first;

              String fileName = file.name;
              try {
                fileName = AppPaths.uniqueFileName(fileName);
              } catch (e) {
                AppLogger.instance
                    .error("Cannot rename image $fileName", e.toString());
              }
              // Move the selected image to a secure directory
              deleteImage(p.join(securePath, p.basename(viewmodel.photoPath)));
              await File(file.path).copy(p.join(securePath, fileName));
              viewmodel.photoPath = fileName;
            }
          }

          return Scaffold(
            appBar: AppBar(
              title: Text(
                viewmodel.project?.name ?? "",
                overflow: TextOverflow.ellipsis,
              ),
            ),
            body: LoadingBody(
                loadingStatus: viewmodel.loadingStatus,
                errorText: viewmodel.errorText,
                widget: Center(
                  child: SizedBox(
                    width: smallWidth,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          Hero(
                            tag: "user_photo",
                            child: InkWell(
                              radius: 60,
                              customBorder: const CircleBorder(),
                              onTap: () {
                                if (appViewmodel.isPhone) {
                                  showDialog(
                                    context: context,
                                    builder: (context) => ImageOrGalleryDialog(
                                      openGallery: () {
                                        pickImage(ImageSource.gallery);
                                      },
                                      openCamera: () {
                                        pickImage(ImageSource.camera);
                                      },
                                    ),
                                  ).then((_) {
                                    PaintingBinding.instance.imageCache.clear();
                                    PaintingBinding.instance.imageCache
                                        .clearLiveImages();
                                    viewmodel.init();
                                  });
                                } else {
                                  pickImage(ImageSource.gallery).then((_) {
                                    PaintingBinding.instance.imageCache.clear();
                                    PaintingBinding.instance.imageCache
                                        .clearLiveImages();
                                    viewmodel.init();
                                  });
                                }
                              },
                              child: CircleAvatar(
                                radius: 60,
                                backgroundImage: viewmodel
                                            .photoPath.isNotEmpty &&
                                        File(p.join(
                                                securePath,
                                                p.basename(
                                                    viewmodel.photoPath)))
                                            .existsSync()
                                    ? Image.file(
                                        File(p.join(securePath,
                                            p.basename(viewmodel.photoPath))),
                                        key: ValueKey(p.join(securePath,
                                            p.basename(viewmodel.photoPath))),
                                      ).image
                                    : null,
                                child: p
                                            .join(securePath,
                                                p.basename(viewmodel.photoPath))
                                            .isEmpty ||
                                        !File(p.join(
                                                securePath,
                                                p.basename(
                                                    viewmodel.photoPath)))
                                            .existsSync()
                                    ? const Center(
                                        child: Icon(
                                          Icons.person,
                                          size: 42,
                                        ),
                                      )
                                    : null,
                              ),
                            ),
                          ),
                          const SizedBox(height: 46),
                          TextFormField(
                            initialValue: viewmodel.name,
                            decoration: InputDecoration(
                              labelText:
                                  AppLocalizations.of(context)?.nickName ??
                                      "Name",
                              border: const OutlineInputBorder(),
                            ),
                            onChanged: (value) {
                              viewmodel.name = value;
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                resetErrorTextFn: () {
                  viewmodel.resetErrorText();
                }),
          );
        },
      ),
    );
  }
}

class ImageOrGalleryDialog extends StatelessWidget {
  const ImageOrGalleryDialog({
    super.key,
    required this.openCamera,
    required this.openGallery,
  });

  final Function openGallery;
  final Function openCamera;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        height: 100,
        width: smallWidth,
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            IconButton(
                onPressed: () {
                  openCamera();
                  Navigator.of(context).pop();
                },
                icon: const Icon(
                  Icons.camera_alt,
                  size: 32,
                )),
            IconButton(
                onPressed: () {
                  openGallery();
                  Navigator.of(context).pop();
                },
                icon: const Icon(
                  Icons.photo_rounded,
                  size: 32,
                )),
          ],
        ),
      ),
    );
  }
}
