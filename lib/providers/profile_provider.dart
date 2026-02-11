// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:flutter/material.dart';

import 'package:pursenal/core/models/domain/profile.dart';
import 'package:pursenal/utils/app_logger.dart';

class ProfileProvider extends ChangeNotifier {
  Profile? _currentProfile;

  Profile? get currentProfile => _currentProfile;

  bool get isOnline => _currentProfile?.isLocal == false;

  void setProfile(Profile? profile) {
    AppLogger.instance.info('Profile $profile');
    if (profile == null) {
      return;
    }
    if (_currentProfile?.dbID != profile.dbID) {
      _currentProfile = profile;

      AppLogger.instance
          .info('Profile switched to: ${profile.name} (${profile.name})');
      notifyListeners();
    }
  }
}
