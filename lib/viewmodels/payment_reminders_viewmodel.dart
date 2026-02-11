import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:pursenal/core/abstracts/payment_reminders_repository.dart';
import 'package:pursenal/core/enums/loading_status.dart';
import 'package:pursenal/core/enums/payment_status.dart';
import 'package:pursenal/core/models/domain/payment_reminder.dart';
import 'package:pursenal/core/models/domain/profile.dart';
import 'package:pursenal/core/repositories/repository_registry.dart';
import 'package:pursenal/utils/app_logger.dart';
import 'package:pursenal/utils/services/notification_service.dart';

class PaymentRemindersViewmodel extends ChangeNotifier {
  final PaymentRemindersRepository _paymentRemindersRepository;

  PaymentRemindersViewmodel(
    RepositoryRegistry repositoryRegistry, {
    required Profile profile,
  })  : _profile = profile,
        _paymentRemindersRepository =
            repositoryRegistry.get<PaymentRemindersRepository>();

  bool isPayment = false;

  final Profile _profile;
  Profile get profile => _profile;

  List<PaymentReminder> _paymentReminders = [];
  List<PaymentReminder> get paymentReminders => _paymentReminders;

  List<PaymentReminder> _fPaymentReminders = [];

  LoadingStatus loadingStatus = LoadingStatus.idle;
  LoadingStatus searchLoadingStatus = LoadingStatus.idle;

  String _searchTerm = "";

  String get searchTerm => _searchTerm;
  List<PaymentReminder> get fPaymentReminders => _fPaymentReminders;

  Set<PaymentStatus> statusCriterias = {};
  Set<PaymentStatus> statusFilters = {};

  Future<void> init() async {
    loadingStatus = LoadingStatus.loading;
    try {
      await getPaymentReminders();
      _filterPaymentReminders();
      loadingStatus = LoadingStatus.completed;

      List<PendingNotificationRequest> pending =
          await NotificationService.getPendingNotifications();

      for (var p in pending) {
        AppLogger.instance.info(
            '🔔 ID: ${p.id}, Title: ${p.title}, Body: ${p.body}, Payload: ${p.payload}');
      }
    } catch (e) {
      AppLogger.instance.error(' ${e.toString()}');
      loadingStatus = LoadingStatus.error;
      errorText = 'Error: Failed to initialise paymentReminders';
    }
    notifyListeners();
  }

  set searchTerm(String value) {
    _searchTerm = value.toLowerCase();
    _filterPaymentReminders();
  }

  String errorText = "";

  Future<void> getPaymentReminders() async {
    try {
      _paymentReminders = await _paymentRemindersRepository
          .getAllPaymentReminders(profile.dbID);
      _paymentReminders.sort(
        (a, b) => a.paymentStatus.index.compareTo(b.paymentStatus.index),
      );
      statusCriterias = _paymentReminders.map((a) => a.paymentStatus).toSet();
      AppLogger.instance.info("PaymentReminders loaded from database");
    } catch (e) {
      AppLogger.instance
          .error("Error loading paymentReminders ${e.toString()}");
    }
    notifyListeners();
  }

  _filterPaymentReminders() {
    searchLoadingStatus = LoadingStatus.loading;
    notifyListeners();
    try {
      _fPaymentReminders = List.from(_paymentReminders);
      _fPaymentReminders = _fPaymentReminders
          .where((a) => a.toString().contains(_searchTerm))
          .where((aa) => !statusFilters.contains(aa.paymentStatus))
          .toList();

      searchLoadingStatus = LoadingStatus.completed;
    } catch (e) {
      searchLoadingStatus = LoadingStatus.error;
      AppLogger.instance
          .error("Failed to filter PaymentReminders. ${e.toString()}");
    }

    notifyListeners();
  }

  addToFilter({PaymentStatus? status}) async {
    if (status != null) {
      if (statusFilters.contains(status)) {
        statusFilters.remove(status);
      } else {
        statusFilters.add(status);
      }
    }

    notifyListeners();
    _filterPaymentReminders();
  }

  Future<bool> deleteReminder(int id) async {
    try {
      await _paymentRemindersRepository.deletePaymentReminder(id);
      notifyListeners();
      return true;
    } catch (e) {
      AppLogger.instance.error(' ${e.toString()}');
      errorText = 'Error: ';
      notifyListeners();
      return false;
    }
  }

  void resetErrorText() {
    errorText = "";
    notifyListeners();
  }
}
