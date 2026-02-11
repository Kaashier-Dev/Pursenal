import 'package:flutter/foundation.dart';
import 'package:pursenal/core/enums/loading_status.dart';
import 'package:pursenal/core/models/domain/account_type.dart';
import 'package:pursenal/core/models/domain/ledger.dart';
import 'package:pursenal/core/models/domain/profile.dart';
import 'package:pursenal/core/abstracts/account_types_repository.dart';
import 'package:pursenal/core/abstracts/accounts_repository.dart';
import 'package:pursenal/core/repositories/repository_registry.dart';
import 'package:pursenal/utils/app_logger.dart';

class AccountsViewmodel extends ChangeNotifier {
  final AccountsRepository _accountsRepository;
  final AccountTypesRepository _accountTypesRepository;

  AccountsViewmodel(RepositoryRegistry repositoryRegistry,
      {required Profile profile, int accTypeID = 4})
      : _profile = profile,
        _accTypeID = accTypeID,
        _accountTypesRepository =
            repositoryRegistry.get<AccountTypesRepository>(),
        _accountsRepository = repositoryRegistry.get<AccountsRepository>();

  int _accTypeID;

  get accTypeID => _accTypeID;

  bool isPayment = false;

  final Profile _profile;
  Profile get profile => _profile;

  List<Ledger> _ledgers = [];
  List<Ledger> _fLedgers = [];

  AccountType? _accType;
  get accType => _accType;

  List<AccountType> accTypes = [];

  set accType(value) => _accType = value;

  LoadingStatus loadingStatus = LoadingStatus.idle;
  LoadingStatus searchLoadingStatus = LoadingStatus.idle;

  String _searchTerm = "";

  String get searchTerm => _searchTerm;
  List<Ledger> get fLedgers => _fLedgers;

  Future<void> init() async {
    loadingStatus = LoadingStatus.loading;
    try {
      await setAccType(_accTypeID);
      loadingStatus = LoadingStatus.completed;
    } catch (e) {
      AppLogger.instance.error(' ${e.toString()}');
      loadingStatus = LoadingStatus.error;
      errorText = 'Error: Failed to initialise accounts';
    }
    notifyListeners();
  }

  set searchTerm(String value) {
    _searchTerm = value.toLowerCase();
    _filterAccounts();
  }

  String errorText = "";

  set accTypeID(final value) {
    _accTypeID = value;
    setAccType(_accTypeID);
    notifyListeners();
  }

  Future<void> getAccounts() async {
    try {
      accTypes = [];
      _ledgers = await _accountsRepository.getLedgersByAccType(
          profileId: _profile.dbID, accTypeID: _accTypeID);
      for (int a in [4, 5]) {
        accTypes.add(await _accountTypesRepository.getById(a));
      }

      AppLogger.instance.info("Ledgers loaded from database");
    } catch (e) {
      AppLogger.instance.error("Error loading ledgers ${e.toString()}");
    }
    notifyListeners();
  }

  _filterAccounts() {
    searchLoadingStatus = LoadingStatus.loading;
    notifyListeners();
    try {
      _fLedgers = List.from(_ledgers);
      _fLedgers =
          _fLedgers.where((a) => a.toString().contains(_searchTerm)).toList();

      searchLoadingStatus = LoadingStatus.completed;
    } catch (e) {
      searchLoadingStatus = LoadingStatus.error;
      AppLogger.instance.error("Failed to filter Accounts. ${e.toString()}");
    }

    notifyListeners();
  }

  setAccType(int id) async {
    _accType = await _accountTypesRepository.getById(id);
    notifyListeners();
    await getAccounts();
    _filterAccounts();
  }

  void resetErrorText() {
    errorText = "";
    notifyListeners();
  }
}
