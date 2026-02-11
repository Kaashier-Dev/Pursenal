import 'package:flutter/material.dart';
import 'package:pursenal/app/extensions/currency.dart';
import 'package:pursenal/app/global/values.dart';
import 'package:pursenal/core/abstracts/account_types_repository.dart';
import 'package:pursenal/core/abstracts/accounts_repository.dart';
import 'package:pursenal/core/abstracts/file_paths_repository.dart';
import 'package:pursenal/core/abstracts/payment_reminders_repository.dart';
import 'package:pursenal/core/enums/budget_interval.dart';
import 'package:pursenal/core/enums/db_table_type.dart';
import 'package:pursenal/core/enums/loading_status.dart';
import 'package:pursenal/core/enums/payment_status.dart';
import 'package:pursenal/core/models/domain/account.dart';
import 'package:pursenal/core/models/domain/account_type.dart';
import 'package:pursenal/core/models/domain/ledger.dart';
import 'package:pursenal/core/models/domain/payment_reminder.dart';
import 'package:pursenal/core/models/domain/profile.dart';
import 'package:pursenal/core/repositories/repository_registry.dart';
import 'package:pursenal/utils/app_logger.dart';
import 'package:pursenal/utils/services/notification_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PaymentReminderEntryViewmodel extends ChangeNotifier {
  final PaymentRemindersRepository _paymentRemindersRepository;
  final AccountsRepository _accountsRepository;
  final AccountTypesRepository _accountTypesRepository;
  final FilePathsRepository _filePathsRepository;

  PaymentReminderEntryViewmodel(
    RepositoryRegistry repositoryRegistry, {
    required Profile profile,
    PaymentReminder? reminder,
  })  : _profile = profile,
        _reminder = reminder,
        _paymentRemindersRepository =
            repositoryRegistry.get<PaymentRemindersRepository>(),
        _accountsRepository = repositoryRegistry.get<AccountsRepository>(),
        _filePathsRepository = repositoryRegistry.get<FilePathsRepository>(),
        _accountTypesRepository =
            repositoryRegistry.get<AccountTypesRepository>();
  final Profile _profile;
  PaymentReminder? _reminder;

  Account? _selectedFund;
  Account? _selectedAccount;

  LoadingStatus loadingStatus = LoadingStatus.idle;

  Account? _account;
  Account? _fund;
  BudgetInterval? _interval;
  int _amount = 0;
  int? _day = 1;
  DateTime? _paymentDate;
  PaymentStatus _paymentStatus = PaymentStatus.pending;
  List<String> _filePaths = [];
  String _details = "";

  List<Ledger> _ledgers = [];
  List<Ledger> _funds = [];

  bool _doesRepeat = false;

  String errorText = '';
  String amountError = '';
  String detailsError = '';
  String selectedFundError = "";
  String selectedAccountError = "";
  String paymentDateError = "";
  String intervalError = "";
  String weekDayError = "";
  String monthDayError = "";

  // Getters
  Account? get account => _account;
  Account? get fund => _fund;
  BudgetInterval? get interval => _interval;
  int? get day => _day;
  int get amount => _amount;
  DateTime? get paymentDate => _paymentDate;
  PaymentStatus get paymentStatus => _paymentStatus;
  List<String> get filePaths => List.unmodifiable(_filePaths);
  String get details => _details;
  bool get doesRepeat => _doesRepeat;
  Account? get selectedFund => _selectedFund;
  Account? get selectedAccount => _selectedAccount;
  List<Ledger> get funds => _funds;

  List<Ledger> get fAccounts => _ledgers;

  List<AccountType> accountTypes = [];

  SharedPreferences? _prefs;

  TimeOfDay prTime = const TimeOfDay(hour: 8, minute: 0);

  // Setters with notifyListeners
  set account(Account? value) {
    _account = value;
    notifyListeners();
  }

  set fund(Account? value) {
    _fund = value;
    notifyListeners();
  }

  set interval(BudgetInterval? value) {
    _interval = value;
    notifyListeners();
  }

  set day(int? value) {
    _day = value;
    notifyListeners();
  }

  set amount(int value) {
    _amount = value;
    notifyListeners();
  }

  set paymentDate(DateTime? value) {
    _paymentDate = value;
    notifyListeners();
  }

  set paymentStatus(PaymentStatus value) {
    _paymentStatus = value;
    notifyListeners();
  }

  set details(String value) {
    _details = value;
    notifyListeners();
  }

  set doesRepeat(bool value) {
    _doesRepeat = value;
    _day = null;
    _interval = BudgetInterval.monthly;
    _paymentDate = null;
    notifyListeners();
  }

  set selectedFund(Account? value) {
    _selectedFund = value;
    notifyListeners();
  }

  set selectedAccount(Account? value) {
    _selectedAccount = value;
    if (value == _selectedFund) {
      _selectedFund = null;
    }
    notifyListeners();
  }

  void addImage(String path) {
    if (!_filePaths.contains(path)) {
      _filePaths.add(path);
      notifyListeners();
    }
  }

  void removeImage(String path) {
    _filePaths.remove(path);
    notifyListeners();
  }

  void resetErrorText() {
    errorText = "";
    notifyListeners();
  }

  void init() async {
    loadingStatus = LoadingStatus.loading;
    notifyListeners();
    try {
      await getAccounts();

      _prefs = await SharedPreferences.getInstance();

      if (_reminder != null) {
        _account = _reminder!.account;
        _fund = _reminder!.fund;
        _interval = _reminder!.interval;
        _amount = _reminder!.amount;
        _day = _reminder!.day;
        _paymentDate = _reminder!.paymentDate;
        _paymentStatus = _reminder!.paymentStatus;
        _filePaths = List.from(_reminder!.filePaths);
        _details = _reminder!.details;
        if (_reminder?.paymentDate == null) {
          _doesRepeat = true;
          _interval = _reminder?.interval;
        }
      }

      prTime = await getPaymentReminderTime();
      loadingStatus = LoadingStatus.completed;
    } catch (e) {
      AppLogger.instance.error(' ${e.toString()}');
      loadingStatus = LoadingStatus.error;
      errorText = 'Error: failed to initialise payment reminder entry $e';
    }
    notifyListeners();
  }

  Future<void> getAccounts() async {
    try {
      _ledgers = await _accountsRepository.getLedgers(profileId: _profile.dbID);
      _funds = await _accountsRepository.getLedgersByCategory(
          profileId: _profile.dbID, accTypeIDs: fundingAccountIDs);

      accountTypes = await _accountTypesRepository.getAll();

      // _ledgers.where((a) => a.accType.dbID <= 3).toList();
    } catch (e) {
      AppLogger.instance.error(' ${e.toString()}');
      errorText = 'Error: Failed to load accounts';
    }
    notifyListeners();
  }

  bool _validate() {
    bool isValid = true;
    amountError = '';
    detailsError = '';
    selectedFundError = "";
    selectedAccountError = "";
    paymentDateError = "";
    intervalError = "";
    weekDayError = "";
    monthDayError = "";

    try {
      if (_amount <= 0) {
        amountError = "Amount must be greater than 0";
        isValid = false;
      }

      if (_details.length > 200) {
        detailsError = "Details too long";
        isValid = false;
      }

      if (_details.isEmpty) {
        detailsError = "Enter details";
        isValid = false;
      }

      if (_doesRepeat) {
        if (_interval == BudgetInterval.monthly) {
          if ((_day == null || _day! > 31)) {
            monthDayError = "Enter a valid day";
            isValid = false;
          }
        } else if (_interval == BudgetInterval.weekly) {
          if (_day == null || _day! > 7) {
            weekDayError = "Select a valid day";
            isValid = false;
          }
        } else {
          intervalError = "Select a valid interval";
          isValid = false;
        }
      } else {
        if (_paymentDate == null) {
          paymentDateError = "Enter a valid date";
          isValid = false;
        }
      }

      notifyListeners();
      return isValid;
    } catch (e) {
      AppLogger.instance.error(' ${e.toString()}');
      errorText = 'Error: failed to validate input ';
      notifyListeners();
      return false;
    }
  }

  Future<bool> save() async {
    if (!_validate()) return false;

    loadingStatus = LoadingStatus.submitting;
    notifyListeners();

    try {
      final isNew = _reminder == null;
      final reminderId = isNew
          ? await _paymentRemindersRepository.insertPaymentReminder(
              profile: _profile,
              account: _account,
              fund: _fund,
              interval: _interval,
              day: _day ?? 0,
              amount: _amount,
              paymentDate: _paymentDate,
              status: _paymentStatus,
              details: _details,
            )
          : _reminder!.dbID;

      if (!isNew) {
        await _filePathsRepository.deleteFilePathByParentID(reminderId);
        await _paymentRemindersRepository.updatePaymentReminder(
          id: reminderId,
          profile: _profile,
          account: _account,
          fund: _fund,
          interval: _interval,
          day: _day ?? 0,
          amount: _amount,
          paymentDate: _paymentDate,
          status: _paymentStatus,
          details: _details,
        );
        await NotificationService.cancelReminder(id: reminderId);
      }

      for (var p in filePaths) {
        await _filePathsRepository.insertFilePath(
          path: p,
          parentTableID: reminderId,
          tableType: DBTableType.paymentReminder,
        );
      }

      await NotificationService.schedulePaymentReminder(
        id: reminderId,
        title:
            "Today's payment reminder : ${amount.toCurrencyStringWSymbol(_profile.currency)}",
        body: "Towards $details",
        isWeekly: _interval == BudgetInterval.weekly,
        startDateTime: DateTime.now()
            .copyWith(hour: prTime.hour, minute: prTime.minute, second: 0),
        monthDay: _interval == BudgetInterval.monthly ? day : null,
        weekday: _interval == BudgetInterval.weekly ? day : null,
        paymentDate: !_doesRepeat ? _paymentDate : null,
      );

      if (isNew) {
        _reminder = await _paymentRemindersRepository
            .getPaymentReminderByID(reminderId);
      }

      loadingStatus = LoadingStatus.submitted;
      notifyListeners();
      return true;
    } catch (e) {
      errorText = 'Failed to save reminder: ${e.toString()}';
      loadingStatus = LoadingStatus.error;
      notifyListeners();
      return false;
    }
  }

  Future<TimeOfDay> getPaymentReminderTime() async {
    try {
      final hr = _prefs?.getInt('paymentReminderHour') ?? 08;
      final mi = _prefs?.getInt('paymentReminderMinute') ?? 00;
      final time = TimeOfDay(hour: hr, minute: mi);
      return time;
    } catch (e) {
      AppLogger.instance.error(' ${e.toString()}');
      errorText = 'Error: Cannot get payment reminder time';
      return const TimeOfDay(hour: 08, minute: 00);
    }
  }
}
