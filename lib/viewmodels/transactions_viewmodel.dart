import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:pursenal/app/extensions/datetime.dart';
import 'package:pursenal/core/models/domain/account.dart';
import 'package:pursenal/core/models/domain/profile.dart';
import 'package:pursenal/core/models/domain/transaction.dart';
import 'package:pursenal/core/repositories/repository_registry.dart';
import 'package:pursenal/utils/exporter.dart';
import 'package:pursenal/core/enums/loading_status.dart';
import 'package:pursenal/core/enums/voucher_type.dart';
import 'package:pursenal/core/models/domain/ledger.dart';
import 'package:pursenal/core/abstracts/accounts_repository.dart';
import 'package:pursenal/core/abstracts/transactions_repository.dart';
import 'package:pursenal/utils/app_logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TransactionsViewmodel extends ChangeNotifier with Exporter {
  final TransactionsRepository _transactionsRepository;
  final AccountsRepository _accountsRepository;

  TransactionsViewmodel(
    RepositoryRegistry repositoryRegistry, {
    required Profile profile,
  })  : _profile = profile,
        _transactionsRepository =
            repositoryRegistry.get<TransactionsRepository>(),
        _accountsRepository = repositoryRegistry.get<AccountsRepository>();

  LoadingStatus loadingStatus = LoadingStatus.idle;
  LoadingStatus searchLoadingStatus = LoadingStatus.idle;

  final Profile _profile;
  Profile get profile => _profile;

  String errorText = "";

  List<Account> allAccounts = [];

  List<Ledger> allLedgers = [];

  List<Transaction> _transactions = [];
  List<Transaction> _fTransactions = [];

  DateTime _startDate = DateTime.now().subtract(const Duration(days: 7));
  DateTime _endDate = DateTime.now();
  DateTime get startDate => _startDate;
  DateTime get endDate => _endDate;
  List<Transaction> get transactions => _transactions;
  List<Transaction> get fTransactions => _fTransactions;

  Set<VoucherType> voucherTypes = {};
  final Set<VoucherType> _voucherTypeFilters = {};

  final Set<Account> _fundCriterias = {};
  Set<Account> get fundCriterias => _fundCriterias;

  Set<int> fundFilters = {};
  Set<Account> otherAccounts = {};
  Set<int> _otherAccountFilters = {};
  get otherAccountFilters => _otherAccountFilters;

  set otherAccountFilters(value) => _otherAccountFilters = value;

  Set<VoucherType> get voucherTypeFilters => _voucherTypeFilters;

  String feedbackText = "";

  String _searchTerm = "";
  String get searchTerm => _searchTerm;

  Set<DateTime> fDates = {};

  SharedPreferences? _prefs;

  init() async {
    try {
      loadingStatus = LoadingStatus.loading;
      notifyListeners();
      _prefs = await SharedPreferences.getInstance();

      _startDate = await _getFilterStartDate() ??
          DateTime.now().subtract(const Duration(days: 30));

      scrollController.addListener(updateHeaderVisibility);

      await getTransactionsWithAccounts();
      _filterTransactions();
      notifyListeners();
      _populateVoucherTypes();
      _populateAccounts();
      loadingStatus = LoadingStatus.completed;

      // getAllAccounts();
      _getAllLedgers();
    } catch (e) {
      AppLogger.instance.error(' ${e.toString()}');
      errorText = 'Error: Failed to initialise transactions';
      loadingStatus = LoadingStatus.error;
      notifyListeners();
    }
  }

  set startDate(DateTime value) {
    _startDate = value;
    notifyListeners();
  }

  set endDate(DateTime value) {
    _endDate = value;
    notifyListeners();
  }

  set searchTerm(String term) {
    _searchTerm = term.toLowerCase();
    _filterTransactions();
  }

  addToFilter({
    VoucherType? voucherType,
    DateTime? sDate,
    DateTime? eDate,
    Account? fAcc,
    Account? oAcc,
  }) async {
    bool transactionsFetchNeeded = false;

    if (voucherType != null) {
      if (_voucherTypeFilters.contains(voucherType)) {
        _voucherTypeFilters.remove(voucherType);
      } else {
        _voucherTypeFilters.add(voucherType);
      }
    }
    if (sDate != null) {
      if (sDate.isBeforeOrEqualTo(_startDate)) {
        transactionsFetchNeeded = true;
      }
      _startDate = sDate;
    }
    if (eDate != null) {
      eDate = eDate.copyWith(hour: 23, minute: 59, second: 59);
      if (eDate.isAfter(_endDate)) {
        transactionsFetchNeeded = true;
      }
      _endDate = eDate;
    }

    if (fAcc != null) {
      if (fundFilters.contains(fAcc.dbID)) {
        fundFilters.remove(fAcc.dbID);
      } else {
        fundFilters.add(fAcc.dbID);
      }
    }
    if (oAcc != null) {
      if (_otherAccountFilters.contains(oAcc.dbID)) {
        _otherAccountFilters.remove(oAcc.dbID);
      } else {
        _otherAccountFilters.add(oAcc.dbID);
      }
    }

    if (transactionsFetchNeeded) {
      await getTransactionsWithAccounts();
      _populateVoucherTypes();
    }

    notifyListeners();
    _filterTransactions();
    await _setFilterStartDate();
  }

  _filterTransactions() {
    searchLoadingStatus = LoadingStatus.loading;
    notifyListeners();

    try {
      _fTransactions = List.from(_transactions);

      _fTransactions = fTransactions
          .where((f) => !voucherTypeFilters.contains(f.voucherType))
          .where((f) =>
              (!fundFilters.contains(f.crAccount.dbID) &&
                  !fundFilters.contains(f.drAccount.dbID)) &&
              (!_otherAccountFilters.contains(f.crAccount.dbID) &&
                  !_otherAccountFilters.contains(f.drAccount.dbID)))
          .where((d) => d.voucherDate.isBetween(_startDate, _endDate))
          .where((a) => a.toString().contains(_searchTerm))
          .toList();

      fDates = _fTransactions.map((t) {
        return t.voucherDate.copyWith(
            hour: 0, minute: 0, second: 0, microsecond: 0, millisecond: 0);
      }).toSet();
      searchLoadingStatus = LoadingStatus.completed;
    } catch (e) {
      AppLogger.instance
          .error("Failed to filter Transactions. ${e.toString()}");
      searchLoadingStatus = LoadingStatus.error;
    }

    notifyListeners();
  }

  _getAllLedgers() async {
    allLedgers = await _accountsRepository.getLedgers(profileId: profile.dbID);
    notifyListeners();
  }

  _populateVoucherTypes() {
    // _voucherTypeFilters = {};
    voucherTypes = _transactions.map((t) => t.voucherType).toSet();
    notifyListeners();
  }

  _populateAccounts() {
    // fundFilters = {};
    // _otherAccountFilters = {};

    for (var t in _transactions) {
      if (t.drAccount.accountType <= 3) {
        _fundCriterias.add(t.drAccount);
      } else {
        otherAccounts.add(t.drAccount);
      }
      if (t.crAccount.accountType <= 3) {
        _fundCriterias.add(t.crAccount);
      } else {
        otherAccounts.add(t.crAccount);
      }
    }
    notifyListeners();
  }

  Future<void> getTransactionsWithAccounts() async {
    // Explicitly reload the database before fetching

    _transactions.clear(); // Force clear old data
    _transactions = await _transactionsRepository.getTransactions(
        startDate: _startDate, endDate: _endDate, profileId: _profile.dbID);

    if (_transactions.isEmpty) {
      _transactions = await _transactionsRepository.getNTransactions(
          n: 30, profileId: _profile.dbID);

      if (_transactions.isNotEmpty) {
        _startDate = _transactions.first.voucherDate;
        _endDate = _transactions.last.voucherDate;
      }
    }

    AppLogger.instance.info("Transactions loaded ${_transactions.length} nos");
    notifyListeners();
  }

  void resetErrorText() {
    errorText = "";
    feedbackText = "";
    notifyListeners();
  }

  Future<void> exportPDF() async {
    try {
      feedbackText = await Exporter.genTransactionsPDF(
        transactions: _fTransactions.reversed.toList(),
        currency: _profile.currency,
        startDate: _startDate,
        endDate: _endDate,
      );
    } catch (e) {
      AppLogger.instance.error(' ${e.toString()}');
      errorText = 'Error: Failed to export PDF';
    }
    notifyListeners();
  }

  Future<void> exportXLSX() async {
    try {
      feedbackText = await Exporter.genTransactionsXLSX(
        transactions: _fTransactions.reversed.toList(),
        currency: _profile.currency,
        startDate: _startDate,
        endDate: _endDate,
      );
    } catch (e) {
      AppLogger.instance.error(' ${e.toString()}');
      errorText = 'Error: Failed to export spreadsheet';
    }
    notifyListeners();
  }

  final ScrollController scrollController = ScrollController();

  double? headerHeight;
  bool isHidden = false;

  void updateHeaderVisibility() {
    if (scrollController.position.userScrollDirection ==
        ScrollDirection.reverse) {
      if (!isHidden && _fTransactions.length > 20) {
        isHidden = true;
        headerHeight = 0;
        notifyListeners();
      }
    } else if (scrollController.position.userScrollDirection ==
        ScrollDirection.forward) {
      if (isHidden) {
        isHidden = false;
        headerHeight = null;
        notifyListeners();
      }
    }
  }

  Future<void> _setFilterStartDate() async {
    try {
      _prefs?.setInt(
          'filterStartDate',
          _startDate
              .copyWith(hour: 0, minute: 0, second: 0)
              .millisecondsSinceEpoch);
    } catch (e) {
      AppLogger.instance
          .error("Error setting Last updated timestamp ${e.toString()}");
    }
  }

  Future<DateTime?> _getFilterStartDate() async {
    try {
      int? timeStamp = _prefs?.getInt(
        'filterStartDate',
      );

      if (timeStamp != null) {
        return DateTime.fromMillisecondsSinceEpoch(timeStamp);
      }
    } catch (e) {
      AppLogger.instance
          .error("Error setting Last updated timestamp ${e.toString()}");
    }
    return null;
  }

  @override
  void dispose() {
    scrollController.dispose();
    super.dispose();
  }
}
