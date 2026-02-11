import 'dart:ffi';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pursenal/app/extensions/color.dart';
import 'package:pursenal/app/global/date_formats.dart';
import 'package:pursenal/app/global/values.dart';
import 'package:pursenal/app/global/values.dart' as values;
import 'package:pursenal/core/abstracts/database_repository.dart';
import 'package:pursenal/core/enums/app_date_format.dart';
import 'package:pursenal/core/models/domain/profile.dart';
import 'package:pursenal/core/models/domain/user.dart';
import 'package:pursenal/core/models/domain/user_device.dart';
import 'package:pursenal/core/repositories/drift/drift_repositories.dart';
import 'package:pursenal/utils/app_paths.dart';
import 'package:pursenal/utils/image_resizer.dart';
import 'package:pursenal/utils/services/notification_service.dart';
import 'package:pursenal/core/enums/loading_status.dart';
import 'package:pursenal/core/abstracts/profiles_repository.dart';
import 'package:pursenal/utils/app_logger.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:path/path.dart' as p;

class AppViewmodel extends ChangeNotifier {
  final ProfilesRepository _profilesRepository;
  final DatabaseRepository _databaseRepository;
  final UserDriftRepository _userDriftRepository;

  final DeviceInfoPlugin deviceInfoPlugin = DeviceInfoPlugin();

  AppViewmodel(this._profilesRepository, this._databaseRepository,
      this._userDriftRepository);

  static const uuid = Uuid();

  Profile? _selectedProfile;

  Profile? get selectedProfile => _selectedProfile;

  List<Profile> _profiles = [];

  List<Profile> get profiles => _profiles;

  bool isPhone = (Platform.isAndroid || Platform.isIOS);

  LoadingStatus loadingStatus = LoadingStatus.idle;
  String errorText = "";

  Color _paymentColor = Colors.red;
  Color get paymentColor => _paymentColor;

  Color _receiptColor = Colors.green;

  Color get receiptColor => _receiptColor;

  bool reminderStatus = false;
  String reminderTime = "";
  String paymentReminderTime = "";
  TimeOfDay paymentReminderTimeStamp = const TimeOfDay(hour: 8, minute: 0);

  DateFormat dateFormat = DateFormat(AppDateFormat.date1.pattern);

  String _deviceID = "";
  String get deviceID => _deviceID;

  set receiptColor(Color value) {
    try {
      _receiptColor = value;
      setReceiptColor(value.toHex());
    } catch (e) {
      AppLogger.instance.error(' ${e.toString()}');
      errorText = 'Error: Failed to set color';
    }
    notifyListeners();
  }

  set paymentColor(Color value) {
    try {
      _paymentColor = value;
      setPaymentColor(value.toHex());
    } catch (e) {
      AppLogger.instance.error(' ${e.toString()}');
      errorText = 'Error: Failed to set color';
    }
    notifyListeners();
  }

  Future<void> init() async {
    loadingStatus = LoadingStatus.loading;
    try {
      notifyListeners();
      _profiles = await _profilesRepository.getAll();
      _selectedProfile = await _profilesRepository.getSelectedProfile();

      loadingStatus = LoadingStatus.completed;

      _prefs = await SharedPreferences.getInstance();
      _isSystemDefaultTheme = _prefs?.getBool('isSystemDefaultTheme') ?? false;
      _paymentColor = (await getPaymentColor())?.hexToColor() ?? Colors.red;
      _receiptColor = (await getReceiptColor())?.hexToColor() ?? Colors.green;
      reminderStatus = await getReminderStatus();
      reminderTime = await getReminderTime();
      paymentReminderTime = await getPaymentReminderTime();
      if (paymentReminderTime.isEmpty) {
        await setPaymentReminderTime(paymentReminderTimeStamp);
      }

      dateFormat =
          DateFormat(await getAppDateFormat() ?? AppDateFormat.date1.pattern);
      await _resetTransactionsFilterStartDate();
      notifyListeners();
    } catch (e, stackTrace) {
      AppLogger.instance.error(' ${e.toString()}', [stackTrace]);
      errorText = 'Error: Failed to initialise App.\n $e';
      loadingStatus = LoadingStatus.error;
      notifyListeners();
    }
  }

  set selectedProfile(Profile? value) {
    _selectedProfile = value;

    if (value != null) {
      _profilesRepository.setSelectedProfile(value.dbID);
    }
    notifyListeners();
  }

  SharedPreferences? _prefs;

  bool _isSystemDefaultTheme = false;

  bool get isSystemDefaultTheme => _isSystemDefaultTheme;

  set isSystemDefaultTheme(bool value) {
    _isSystemDefaultTheme = value;
    setSytemDefaultThemeSP();
    notifyListeners();
  }

  void setSytemDefaultThemeSP() {
    _prefs?.setBool('isSystemDefaultTheme', _isSystemDefaultTheme);
    notifyListeners();
  }

  Future<void> setDeviceID() async {
    try {
      if (_deviceID.isNotEmpty) {
        return;
      }
      _deviceID = uuid.v4();

      await _prefs?.setString('pursenalAppDeviceID', _deviceID);
    } catch (e) {
      AppLogger.instance.error("Error setting device ID ${e.toString()}");
    }
  }

  Future<String?> getDeviceID() async {
    try {
      String? id = _prefs?.getString('pursenalAppDeviceID');
      if (id == null || id.isEmpty) {
        await setDeviceID();
        id = _prefs?.getString('pursenalAppDeviceID');
      }
      return id;
    } catch (e) {
      AppLogger.instance.error("Error selecting device ID ${e.toString()}");
      return null;
    }
  }

  Future<int?> getActiveProfileID() async {
    try {
      return _prefs?.getInt('activeProfileID');
    } catch (e) {
      AppLogger.instance.error("Error selecting profile ${e.toString()}");
      return null;
    }
  }

  Future<void> setActiveProfileID(int id) async {
    try {
      _prefs?.setInt('activeProfileID', id);
    } catch (e) {
      AppLogger.instance.error("Error setting profile ${e.toString()}");
    }
  }

  Future<String?> getPaymentColor() async {
    try {
      return _prefs?.getString('paymentColor');
    } catch (e) {
      AppLogger.instance.error("Error selecting primary color ${e.toString()}");
      return null;
    }
  }

  Future<void> setPaymentColor(String color) async {
    try {
      _prefs?.setString('paymentColor', color);
    } catch (e) {
      AppLogger.instance.error("Error setting primary color ${e.toString()}");
    }
  }

  Future<String?> getReceiptColor() async {
    try {
      return _prefs?.getString('receiptColor');
    } catch (e) {
      AppLogger.instance.error("Error selecting primary color ${e.toString()}");
      return null;
    }
  }

  Future<void> setReceiptColor(String color) async {
    try {
      _prefs?.setString('receiptColor', color);
    } catch (e) {
      AppLogger.instance.error("Error setting primary color ${e.toString()}");
    }
  }

  void resetErrorText() {
    errorText = "";
    notifyListeners();
  }

  Future<void> toggleReminder(bool status) async {
    try {
      await _prefs?.setBool('isReminderEnabled', status);
      reminderStatus = status;
      if (!status) {
        NotificationService.cancelReminder();
      }
    } catch (e) {
      AppLogger.instance.error(' ${e.toString()}');
      errorText = 'Error: Cannot set reminder status';
    }
    notifyListeners();
  }

  Future<bool> getReminderStatus() async {
    try {
      return _prefs?.getBool('isReminderEnabled') ?? false;
    } catch (e) {
      AppLogger.instance.error(' ${e.toString()}');
      errorText = 'Error: Cannot get reminder status';
      return false;
    }
  }

  Future<void> setRemindTime(TimeOfDay time) async {
    try {
      await _prefs?.setInt('reminderHour', time.hour);
      await _prefs?.setInt('reminderMinute', time.minute);
      final dt = DateTime(0, 0, 0, time.hour, time.minute);
      reminderTime = timeFormat.format(dt);
      if (reminderStatus) {
        NotificationService.scheduleDailyReminder(0, "Pursenal",
            "Click to add today's transactions", time, '/profiles');
      }
    } catch (e) {
      AppLogger.instance.error(' ${e.toString()}');
      errorText = 'Error: Cannot set reminder time';
    }
    notifyListeners();
  }

  Future<String> getReminderTime() async {
    try {
      final hr = _prefs?.getInt('reminderHour') ?? 00;
      final mi = _prefs?.getInt('reminderMinute') ?? 00;
      final dt = DateTime(0, 0, 0, hr, mi);
      return timeFormat.format(dt);
    } catch (e) {
      AppLogger.instance.error(' ${e.toString()}');
      errorText = 'Error: Cannot get reminder time';
      return "";
    }
  }

  Future<void> setPaymentReminderTime(TimeOfDay time) async {
    try {
      await _prefs?.setInt('paymentReminderHour', time.hour);
      await _prefs?.setInt('paymentReminderMinute', time.minute);
      final dt = DateTime(0, 0, 0, time.hour, time.minute);
      paymentReminderTime = timeFormat.format(dt);
      paymentReminderTimeStamp = time;
    } catch (e) {
      AppLogger.instance.error(' ${e.toString()}');
      errorText = 'Error: Cannot set reminder time';
    }
    notifyListeners();
  }

  Future<String> getPaymentReminderTime() async {
    try {
      final hr = _prefs?.getInt('paymentReminderHour') ?? 00;
      final mi = _prefs?.getInt('paymentReminderMinute') ?? 00;
      final dt = DateTime(0, 0, 0, hr, mi);
      paymentReminderTimeStamp = TimeOfDay(hour: hr, minute: mi);
      return timeFormat.format(dt);
    } catch (e) {
      AppLogger.instance.error(' ${e.toString()}');
      errorText = 'Error: Cannot get payment reminder time';
      return "";
    }
  }

  Future<String?> getAppDateFormat() async {
    try {
      return _prefs?.getString('appDateFormat');
    } catch (e) {
      AppLogger.instance.error("Error selecting date format ${e.toString()}");
      return null;
    }
  }

  Future<void> setAppDateFormat(String format) async {
    try {
      _prefs?.setString('appDateFormat', format);
      dateFormat = DateFormat(format);

      notifyListeners();
    } catch (e) {
      AppLogger.instance.error("Error setting date format ${e.toString()}");
    }
  }

  Future<void> _resetTransactionsFilterStartDate() async {
    try {
      await _prefs?.remove(
        'filterStartDate',
      );
    } catch (e) {
      AppLogger.instance
          .error("Error setting Last updated timestamp ${e.toString()}");
    }
  }

  Future<String> exportDatabase(File destination) async {
    try {
      await _databaseRepository.exportDatabase(destination);
      return "Database exported successfully to ${destination.path}";
    } catch (e) {
      AppLogger.instance.error("Error exporting database ${e.toString()}");
      return "Error exporting database";
    }
  }

  Future<String> importDatabase(File backupFile) async {
    try {
      await _databaseRepository.restoreDatabase(backupFile);
      return "Database imported successfully";
    } catch (e) {
      AppLogger.instance.error("Error importing database ${e.toString()}");
      return "Error imrporting database";
    }
  }

  Future<UserDevice> getUserDeviceInfo() async {
    try {
      final deviceID = await getDeviceID();
      if (deviceID == null) {
        throw Exception("Device ID is null");
      }
      final deviceInfo = await deviceInfoPlugin.deviceInfo;
      final user = await _userDriftRepository.getById(0);
      final userPhoto = user.photoPath;
      const appVersion = values.appVersion;
      if (deviceInfo.data.isNotEmpty) {
        Uint8List? photoBytes;
        if (userPhoto != null && userPhoto.isNotEmpty) {
          photoBytes =
              await File(p.join(AppPaths.imagesDir, userPhoto)).readAsBytes();
          photoBytes = resizeTo64(photoBytes);
        }
        return UserDevice(
          deviceID: deviceID,
          appVersion: appVersion,
          name: user.name,
          osVersion: deviceInfo.data['version.release'] ?? 'Unknown',
          photo: photoBytes,
          platform: deviceInfo.data['name'] ?? 'Unknown',
        );
      } else {
        throw Exception("Device info is empty");
      }
    } catch (e) {
      AppLogger.instance.error(' ${e.toString()}');
      rethrow;
    }
  }
}
