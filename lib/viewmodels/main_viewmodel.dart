import 'package:flutter/material.dart';
import 'package:pursenal/core/abstracts/user_repository.dart';
import 'package:pursenal/core/enums/loading_status.dart';
import 'package:pursenal/core/models/domain/profile.dart';
import 'package:pursenal/core/abstracts/accounts_repository.dart';
import 'package:pursenal/core/abstracts/profiles_repository.dart';
import 'package:pursenal/core/models/domain/user.dart';
import 'package:pursenal/core/repositories/drift/drift_repositories.dart';
import 'package:pursenal/core/repositories/repository_registry.dart';
import 'package:pursenal/utils/app_logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MainViewmodel extends ChangeNotifier {
  final ProfilesRepository _profilesRepository;
  final AccountsRepository _accountsRepository;
  final UserRepository _userRepository;

  MainViewmodel(
    RepositoryRegistry repositoryRegistry,
    this._userRepository,
    this._profilesRepository, {
    required selectedProfile,
  })  : _selectedProfile = selectedProfile,
        _accountsRepository = repositoryRegistry.get<AccountsRepository>();

  List<Profile> _profiles = [];

  List<Profile> get profiles => _profiles;

  Profile _selectedProfile;

  Profile get selectedProfile => _selectedProfile;

  LoadingStatus loadingStatus = LoadingStatus.idle;
  String errorText = "";

  int _currentIndex = 0;
  final PageController _pageController = PageController();

  int get currentIndex => _currentIndex;
  PageController get pageController => _pageController;

  int cashCountinProfile = 0;
  int bankCountinProfile = 0;

  User? user;

  void setIndex(int index) {
    if (index != _currentIndex) {
      _currentIndex = index;
      _pageController.jumpToPage(
        index,
      );
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  set selectedProfile(Profile value) {
    _selectedProfile = value;
    _profilesRepository.setSelectedProfile(value.dbID);
    notifyListeners();
  }

  SharedPreferences? _prefs;

  Future<void> init() async {
    try {
      loadingStatus = LoadingStatus.loading;

      _prefs = await SharedPreferences.getInstance();
      notifyListeners();
      _profiles = await _profilesRepository.getAll();
      getUser();
      try {
        _selectedProfile =
            _profiles.firstWhere((p) => p.dbID == _selectedProfile.dbID);
      } catch (e) {
        AppLogger.instance.error("Failed to set profile");
        errorText = "Failed to set profile";
      }

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_pageController.hasClients) {
          _pageController.jumpToPage(0);
        }
      });
      loadingStatus = LoadingStatus.completed;

      notifyListeners();
      _getAccCounts();
    } catch (e) {
      AppLogger.instance.error(' ${e.toString()}');
      errorText = 'Error: Failed to initialise main page.';
      loadingStatus = LoadingStatus.error;
      notifyListeners();
    }
  }

  _getAccCounts() async {
    cashCountinProfile = (await _accountsRepository.getAccountsByAccType(
            _selectedProfile.dbID, 0))
        .length;
    bankCountinProfile = (await _accountsRepository.getAccountsByAccType(
            _selectedProfile.dbID, 1))
        .length;
    notifyListeners();
  }

  void resetErrorText() {
    errorText = "";
    notifyListeners();
  }

  void getUser() async {
    try {
      user = await _userRepository.getById(1);
      notifyListeners();
    } catch (e) {
      AppLogger.instance.error(' ${e.toString()}');
      errorText = 'Error: Failed to fetch user.';
      notifyListeners();
    }
  }

  Future<void> setLastUpdatedTimeStamp() async {
    try {
      final timeStamp = DateTime.now();
      _prefs?.setInt('lastUpdated', timeStamp.millisecondsSinceEpoch);
    } catch (e) {
      AppLogger.instance
          .error("Error setting Last updated timestamp ${e.toString()}");
    }
  }
}
