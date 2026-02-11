import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:pursenal/app/extensions/datetime.dart';
import 'package:pursenal/core/models/domain/account.dart';
import 'package:pursenal/core/models/domain/bank.dart';
import 'package:pursenal/core/models/domain/credit_card.dart';
import 'package:pursenal/core/models/domain/loan.dart';
import 'package:pursenal/core/models/domain/profile.dart';
import 'package:pursenal/core/models/domain/transaction.dart';
import 'package:pursenal/core/repositories/repository_registry.dart';
import 'package:pursenal/utils/exporter.dart';
import 'package:pursenal/core/enums/loading_status.dart';
import 'package:pursenal/core/enums/voucher_type.dart';
import 'package:pursenal/core/models/domain/ledger.dart';
import 'package:pursenal/core/abstracts/accounts_repository.dart';
import 'package:pursenal/core/abstracts/balances_repository.dart';
import 'package:pursenal/core/abstracts/transactions_repository.dart';
import 'package:pursenal/utils/app_logger.dart';

class AccountViewmodel extends ChangeNotifier {
  final TransactionsRepository _transactionsRepository;
  final BalancesRepository _balancesRepository;

  final AccountsRepository _accountsRepository;

  AccountViewmodel(
    RepositoryRegistry repositoryRegistry, {
    required Profile profile,
    required Account account,
  })  : _profile = profile,
        _account = account,
        _transactionsRepository =
            repositoryRegistry.get<TransactionsRepository>(),
        _balancesRepository = repositoryRegistry.get<BalancesRepository>(),
        _accountsRepository = repositoryRegistry.get<AccountsRepository>();

  Account _account;
  Account get account => _account;

  int openBal = 0;
  int closeBal = 0;
  List<Ledger> allLedgers = [];

  Bank? _bank;
  get bank => _bank;

  set bank(value) => _bank = value;
  CreditCard? _cCard;
  get cCard => _cCard;

  set cCard(value) => _cCard = value;
  Loan? _loan;
  get loan => _loan;

  set loan(value) => _loan = value;

  LoadingStatus loadingStatus = LoadingStatus.idle;
  LoadingStatus searchLoadingStatus = LoadingStatus.idle;

  final Profile _profile;
  Profile get profile => _profile;

  String errorText = "";

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

  Set<Account> otherAccounts = {};
  Set<int> _otherAccountFilters = {};
  get otherAccountFilters => _otherAccountFilters;

  set otherAccountFilters(value) => _otherAccountFilters = value;

  Set<VoucherType> get voucherTypeFilters => _voucherTypeFilters;

  String _searchTerm = "";
  String get searchTerm => _searchTerm;

  String feedbackText = "";

  Set<DateTime> fDates = {};

  init() async {
    try {
      loadingStatus = LoadingStatus.loading;
      if (_account.openDate.isAfter(_startDate)) {
        _startDate = _account.openDate;
      }
      scrollController.addListener(updateHeaderVisibility);

      await getAccount();
      await getTransactions();
      _filterTransactions();
      _populateVoucherTypes();
      _populateAccounts();
      loadingStatus = LoadingStatus.completed;
      notifyListeners();
      getOpeningBalance();
      getClosingBalance();
      getAllLedgers();
    } catch (e) {
      AppLogger.instance.error(' ${e.toString()}');
      loadingStatus = LoadingStatus.error;
      errorText = 'Error: Cannot initialise';
    }
    notifyListeners();
  }

  Future<void> getAccount() async {
    try {
      _account = await _accountsRepository.getById(_account.dbID);
      AppLogger.instance.info("Account loaded from database");
    } catch (e) {
      AppLogger.instance.error("Error loading Account ${e.toString()}");
    }
    notifyListeners();
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

  getOpeningBalance() async {
    openBal = await _balancesRepository.getClosingBalance(
        account: _account,
        closingDate: _startDate.subtract(const Duration(days: 1)));
    notifyListeners();
  }

  getClosingBalance() async {
    try {
      closeBal = await _balancesRepository.getClosingBalance(
          account: _account, closingDate: _endDate);
      notifyListeners();
    } catch (e) {
      AppLogger.instance.error(' ${e.toString()}');
      errorText = 'Error: Cannot calculate closing balance';
    }
  }

  getAllLedgers() async {
    try {
      allLedgers =
          await _accountsRepository.getLedgers(profileId: profile.dbID);
      notifyListeners();
    } catch (e) {
      AppLogger.instance.error(' ${e.toString()}');
      errorText = 'Error: Cannot load ledgers list';
    }
  }

  addToFilter({
    VoucherType? voucherType,
    DateTime? sDate,
    DateTime? eDate,
    Account? fAcc,
    Account? oAcc,
  }) async {
    try {
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
        getOpeningBalance();
      }
      if (eDate != null) {
        eDate = eDate.copyWith(hour: 23, minute: 59, second: 59);
        if (eDate.isAfter(_endDate)) {
          transactionsFetchNeeded = true;
        }
        _endDate = eDate;
        getClosingBalance();
      }

      if (oAcc != null) {
        if (_otherAccountFilters.contains(oAcc.dbID)) {
          _otherAccountFilters.remove(oAcc.dbID);
        } else {
          _otherAccountFilters.add(oAcc.dbID);
        }
      }

      if (transactionsFetchNeeded) {
        await getTransactions();
        _populateVoucherTypes();
        _populateAccounts();
      }

      notifyListeners();
      _filterTransactions();
    } catch (e) {
      AppLogger.instance.error(' ${e.toString()}');
      errorText = 'Error: Failed to filter';
    }
  }

  _filterTransactions() {
    searchLoadingStatus = LoadingStatus.loading;
    notifyListeners();

    try {
      _fTransactions = List.from(_transactions);

      _fTransactions = fTransactions
          .where((f) => !voucherTypeFilters.contains(f.voucherType))
          .where((f) =>
              (f.crAccount.dbID == _account.dbID &&
                  !_otherAccountFilters.contains(f.drAccount.dbID)) ||
              (f.drAccount.dbID == _account.dbID &&
                  !_otherAccountFilters.contains(f.crAccount.dbID)))
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

  refetchAccount() async {
    try {
      _account = await _accountsRepository.getById(_account.dbID);
      notifyListeners();
    } catch (e) {
      AppLogger.instance.error(' ${e.toString()}');
    }
  }

  _populateVoucherTypes() {
    // _voucherTypeFilters = {};
    voucherTypes = _transactions.map((t) => t.voucherType).toSet();
    notifyListeners();
  }

  _populateAccounts() {
    try {
      _otherAccountFilters.clear();
      otherAccounts.clear();

      for (var t in _transactions) {
        if (t.drAccount.dbID != _account.dbID) {
          otherAccounts.add(t.drAccount);
        }
        if (t.crAccount.dbID != _account.dbID) {
          otherAccounts.add(t.crAccount);
        }
      }
      notifyListeners();
    } catch (e) {
      AppLogger.instance.error(' ${e.toString()}');
      errorText = 'Error: Cannot get accounts list';
    }
  }

  Future<void> getTransactions() async {
    _transactions = await _transactionsRepository.getTransactionsbyAccount(
      startDate: _startDate,
      endDate: _endDate,
      profileId: _profile.dbID,
      accountId: _account.dbID,
      reversed: false,
    );
    AppLogger.instance.info("Transactions loaded ${_transactions.length} nos");
    notifyListeners();
  }

  void resetErrorText() {
    errorText = "";
    notifyListeners();
  }

  Future<void> exportPDF() async {
    try {
      feedbackText = await Exporter.genLTransactionsPDF(
          transactions: _fTransactions,
          currency: _profile.currency,
          startDate: _startDate,
          openingBalance: openBal,
          openDate: _startDate,
          endDate: _endDate,
          closingBalance: closeBal,
          account: _account);
    } catch (e) {
      AppLogger.instance.error(' ${e.toString()}');
      errorText = 'Error: Failed to export PDF';
    }
    notifyListeners();
  }

  Future<void> exportXLSX() async {
    try {
      feedbackText = await Exporter.genLTransactionsXLSX(
          transactions: _fTransactions,
          currency: _profile.currency,
          startDate: _startDate,
          openingBalance: openBal,
          openDate: _startDate,
          endDate: _endDate,
          closingBalance: closeBal,
          account: _account);
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

  @override
  void dispose() {
    scrollController.dispose();
    super.dispose();
  }
}
