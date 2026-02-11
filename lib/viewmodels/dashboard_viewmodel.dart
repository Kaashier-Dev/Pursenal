import 'package:flutter/material.dart';
import 'package:pursenal/app/extensions/datetime.dart';
import 'package:pursenal/core/enums/loading_status.dart';
import 'package:pursenal/core/models/domain/account_type.dart';
import 'package:pursenal/core/models/domain/ledger.dart';
import 'package:pursenal/core/models/domain/profile.dart';
import 'package:pursenal/core/models/domain/transaction.dart';
import 'package:pursenal/core/abstracts/account_types_repository.dart';
import 'package:pursenal/core/abstracts/accounts_repository.dart';
import 'package:pursenal/core/abstracts/balances_repository.dart';
import 'package:pursenal/core/abstracts/profiles_repository.dart';
import 'package:pursenal/core/abstracts/transactions_repository.dart';
import 'package:pursenal/core/repositories/repository_registry.dart';
import 'package:pursenal/utils/app_logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DashboardViewmodel extends ChangeNotifier {
  final ProfilesRepository _profilesRepository;
  final AccountsRepository _accountsRepository;
  final TransactionsRepository _transactionsRepository;
  final BalancesRepository _balancesRepository;
  final AccountTypesRepository _accountTypesRepository;

  DashboardViewmodel(
      RepositoryRegistry repositoryRegistry, this._profilesRepository,
      {required Profile profile})
      : _selectedProfile = profile,
        _accountsRepository = repositoryRegistry.get<AccountsRepository>(),
        _transactionsRepository =
            repositoryRegistry.get<TransactionsRepository>(),
        _balancesRepository = repositoryRegistry.get<BalancesRepository>(),
        _accountTypesRepository =
            repositoryRegistry.get<AccountTypesRepository>();

  List<Profile> _profiles = [];

  List<Profile> get profiles => _profiles;

  Profile _selectedProfile;

  Profile get selectedProfile => _selectedProfile;

  String errorText = "";

  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  final DateTime _endDate =
      DateTime.now().copyWith(hour: 23, minute: 59, second: 59);

  LoadingStatus loadingStatus = LoadingStatus.idle;

  List<Ledger> allLedgers = [];

  List<int> balances = [];

  final int recentCount = 4;

  List<Transaction> recentTransactions = [];

  int _closingBalance = 0;
  int get closingBalance => _closingBalance;

  bool canAddTransaction = false;

  bool mustAddAccounts = true;

  List<AccountType> _accTypes = [];
  List<AccountType> fAccountTypes = [];

  SharedPreferences? _prefs;

  Future<void> init() async {
    try {
      _closingBalance = 0;
      loadingStatus = LoadingStatus.loading;
      if (hasListeners) notifyListeners();

      _prefs = await SharedPreferences.getInstance();
      _profiles = await _profilesRepository.getAll();
      await getAllLedgers();
      await getAccountTypes();
      filterAccountTypes();
      await setBalances(await checkBalanceNeedReload());
      await getTransactions();
      loadingStatus = LoadingStatus.completed;
      if (hasListeners) notifyListeners();
    } catch (e) {
      AppLogger.instance.error(' ${e.toString()}');
      errorText = 'Error: Failed to initialise dashboard';
      loadingStatus = LoadingStatus.error;
      if (hasListeners) notifyListeners();
    }
  }

  set selectedProfile(Profile value) {
    _selectedProfile = value;
    notifyListeners();
  }

  getAllLedgers() async {
    allLedgers =
        await _accountsRepository.getLedgers(profileId: _selectedProfile.dbID);
    notifyListeners();
  }

  getAccountTypes() async {
    _accTypes = await _accountTypesRepository.getAll();
    notifyListeners();
  }

  filterAccountTypes() {
    fAccountTypes = List.from(_accTypes);
    fAccountTypes.removeWhere(
        (a) => allLedgers.any((l) => l.accountType.dbID == a.dbID));

    if (fAccountTypes.length < 6) {
      canAddTransaction = true;
    }
    notifyListeners();
  }

  getTransactions() async {
    recentTransactions = await _transactionsRepository.getNTransactions(
        n: recentCount, profileId: _selectedProfile.dbID);

    notifyListeners();
  }

  setBalances(bool reloadNeeded) async {
    if (reloadNeeded) {
      do {
        final balance = await _balancesRepository.getFundClosingBalance(
            _startDate, _selectedProfile.dbID);
        balances.add(balance);
        _startDate = _startDate.add(const Duration(days: 1));
      } while (_startDate.isBeforeOrEqualTo(_endDate));
      _closingBalance = balances.last;
      setLastBalance(_closingBalance);
      AppLogger.instance.info('Balance recalculated: $_closingBalance');
    } else {
      getLastBalance();
    }

    if (hasListeners) notifyListeners();
  }

  void resetErrorText() {
    errorText = "";

    notifyListeners();
  }

  Future<void> setLastBalanceLoadedTimeStamp() async {
    try {
      final timeStamp = DateTime.now();
      _prefs?.setInt('lastBalanceLoaded', timeStamp.millisecondsSinceEpoch);
    } catch (e) {
      AppLogger.instance.error(
          "Error setting Last balance calculated timestamp ${e.toString()}");
    }
  }

  Future<void> setLastBalance(int amount) async {
    try {
      _prefs?.setInt('lastBalance', amount);
      setLastBalanceLoadedTimeStamp();
    } catch (e) {
      AppLogger.instance
          .error("Error setting last calculated balance ${e.toString()}");
    }
  }

  Future<void> getLastBalance() async {
    try {
      setLastBalanceLoadedTimeStamp();
      final balance = _prefs?.getInt('lastBalance');
      if (balance != null) {
        _closingBalance = balance;
      } else {
        setBalances(true);
      }
    } catch (e) {
      AppLogger.instance
          .error("Error setting last calculated balance ${e.toString()}");
    }
  }

  Future<bool> checkBalanceNeedReload() async {
    try {
      final lBLTimestamp = _prefs?.getInt('lastBalanceLoaded');
      final lUTimestamp = _prefs?.getInt('lastUpdated');

      if (lBLTimestamp != null && lUTimestamp != null) {
        DateTime lastBalanceLoaded =
            DateTime.fromMillisecondsSinceEpoch(lBLTimestamp);
        DateTime lastUpdated = DateTime.fromMillisecondsSinceEpoch(lUTimestamp);
        if (lastUpdated.isAfter(lastBalanceLoaded)) {
          return true;
        }
      }

      return false;
    } catch (e) {
      AppLogger.instance.error(
          "Error checking last balance reload timestamp ${e.toString()}");
      return true;
    }
  }
}
