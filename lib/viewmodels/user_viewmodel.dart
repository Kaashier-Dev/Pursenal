import 'package:flutter/material.dart';
import 'package:pursenal/core/abstracts/user_repository.dart';
import 'package:pursenal/core/enums/loading_status.dart';
import 'package:pursenal/core/models/domain/project.dart';
import 'package:pursenal/core/models/domain/user.dart';
import 'package:pursenal/utils/app_logger.dart';

class UserViewmodel extends ChangeNotifier {
  final UserRepository _userRepository;

  UserViewmodel(this._user, this._userRepository);

  User _user;
  User get user => _user;

  String _name = "";
  String get name => _name;

  String _photoPath = "";
  String get photoPath => _photoPath;

  LoadingStatus loadingStatus = LoadingStatus.idle;
  String errorText = "";

  Project? project;

  init() async {
    try {
      loadingStatus = LoadingStatus.loading;
      notifyListeners();
      try {
        await refetchUser();
        _name = _user.name;
        _photoPath = _user.photoPath;
        loadingStatus = LoadingStatus.completed;
      } catch (e) {
        loadingStatus = LoadingStatus.error;
        errorText = "Cannot load User";
      }
      notifyListeners();
    } catch (e) {
      AppLogger.instance.error(' ${e.toString()}');
      errorText = 'Error: Failed to initialise User';
      loadingStatus = LoadingStatus.error;
      notifyListeners();
    }
  }

  set name(String value) {
    _name = value;
    _userRepository.updateUser(
        dbID: _user.dbID,
        name: value,
        deviceID: _user.deviceID,
        filePath: _user.photoPath);
    notifyListeners();
  }

  set photoPath(String value) {
    _photoPath = value;
    notifyListeners();
    _userRepository.updateUser(
        dbID: _user.dbID,
        name: _user.name,
        deviceID: _user.deviceID,
        filePath: value);
  }

  void resetErrorText() {
    errorText = "";
    notifyListeners();
  }

  Future<void> refetchUser() async {
    try {
      loadingStatus = LoadingStatus.loading;
      _user = await _userRepository.getUser();
      notifyListeners();
      loadingStatus = LoadingStatus.completed;
    } catch (e) {
      errorText = "Failed to fetch user";
      loadingStatus = LoadingStatus.error;
    }
    notifyListeners();
  }
}
