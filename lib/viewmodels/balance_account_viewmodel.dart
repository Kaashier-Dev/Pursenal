import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:pursenal/app/extensions/datetime.dart';
import 'package:pursenal/app/global/values.dart';
import 'package:pursenal/core/abstracts/banks_repository.dart';
import 'package:pursenal/core/abstracts/credit_cards_repository.dart';
import 'package:pursenal/core/abstracts/loans_repository.dart';
import 'package:pursenal/core/abstracts/people_repository.dart';
import 'package:pursenal/core/abstracts/receivables_repository.dart';
import 'package:pursenal/core/models/domain/account.dart';
import 'package:pursenal/core/models/domain/bank.dart';
import 'package:pursenal/core/models/domain/credit_card.dart';
import 'package:pursenal/core/models/domain/loan.dart';
import 'package:pursenal/core/models/domain/people.dart';
import 'package:pursenal/core/models/domain/profile.dart';
import 'package:pursenal/core/models/domain/receivable.dart';
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

class BalanceAccountViewmodel extends ChangeNotifier with Exporter {
  final TransactionsRepository _transactionsRepository;
  final BalancesRepository _balancesRepository;

  final AccountsRepository _accountsRepository;

  final BanksRepository _banksRepository;
  final CreditCardsRepository _cardsRepository;
  final LoansRepository _loansRepository;
  final PeopleRepository _peopleRepository;
  final ReceivablesRepository _receivablesRepository;

  BalanceAccountViewmodel(
    RepositoryRegistry _repositoryRegistry, {
    required Profile profile,
    required Account account,
  })  : _profile = profile,
        _account = account,
        _transactionsRepository =
            _repositoryRegistry.get<TransactionsRepository>(),
        _balancesRepository = _repositoryRegistry.get<BalancesRepository>(),
        _accountsRepository = _repositoryRegistry.get<AccountsRepository>(),
        _banksRepository = _repositoryRegistry.get<BanksRepository>(),
        _cardsRepository = _repositoryRegistry.get<CreditCardsRepository>(),
        _loansRepository = _repositoryRegistry.get<LoansRepository>(),
        _peopleRepository = _repositoryRegistry.get<PeopleRepository>(),
        _receivablesRepository =
            _repositoryRegistry.get<ReceivablesRepository>();
  Account _account;
  Account get account => _account;

  Bank? bank;
  CreditCard? card;
  Loan? loan;
  People? people;
  Receivable? receivable;

  int openBal = 0;
  int closeBal = 0;
  List<Ledger> allLedgers = [];

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

  Set<Account> funds = {};

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
      await _getAccount();
      await _getBalanceAccount();
      await _getTransactions();
      if (_transactions.isEmpty) {
        _startDate = _startDate.subtract(const Duration(days: 50));
        await _getTransactions();
      }
      if (_transactions.isEmpty) {
        _startDate = _startDate.subtract(const Duration(days: 100));
        await _getTransactions();
      }
      if (_transactions.isEmpty) {
        _startDate = _account.openDate;
        await _getTransactions();
      }
      filterTransactions();
      _populateVoucherTypes();
      _populateAccounts();
      loadingStatus = LoadingStatus.completed;
      notifyListeners();
      _getOpeningBalance();
      _getClosingBalance();
      _getAllLedgers();
    } catch (e) {
      AppLogger.instance.error(' ${e.toString()}');
      errorText = 'Error: Failed to initialise Fund.';
      loadingStatus = LoadingStatus.error;
      notifyListeners();
    }
  }

  Future<void> _getAccount() async {
    try {
      _account = await _accountsRepository.getById(_account.dbID);
      AppLogger.instance.info("Fund loaded from database");
    } catch (e) {
      AppLogger.instance.error("Error loading Fund ${e.toString()}");
    }
    notifyListeners();
  }

  Future<void> _getBalanceAccount() async {
    try {
      switch (account.accountType) {
        case bankTypeID:
          bank = await _banksRepository.getByAccount(_account.dbID);
          break;
        case cCardTypeID:
          card = await _cardsRepository.getByAccount(_account.dbID);
          break;
        case loanTypeID:
          loan = await _loansRepository.getByAccount(_account.dbID);
          break;
        case peopleTypeID:
          people = await _peopleRepository.getByAccount(_account.dbID);
          break;
        case advanceTypeID:
          receivable = await _receivablesRepository.getByAccount(_account.dbID);
          break;
        default:
          break;
      }

      AppLogger.instance.info("Balance account loaded from database");
    } catch (e) {
      AppLogger.instance.error("Error loading account ${e.toString()}");
    }
    notifyListeners();
  }

  refetchAccount() async {
    try {
      _account = await _accountsRepository.getById(_account.dbID);
    } catch (e) {
      AppLogger.instance.error(' ${e.toString()}');
      errorText = 'Error: ';
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
    filterTransactions();
  }

  _getOpeningBalance() async {
    openBal = await _balancesRepository.getClosingBalance(
        account: _account,
        closingDate: _startDate.subtract(const Duration(days: 1)));
    notifyListeners();
  }

  _getClosingBalance() async {
    closeBal = await _balancesRepository.getClosingBalance(
        account: _account, closingDate: _endDate);
    notifyListeners();
  }

  _getAllLedgers() async {
    allLedgers = await _accountsRepository.getLedgers(profileId: profile.dbID);
    notifyListeners();
  }

  addToFilter({
    VoucherType? voucherType,
    DateTime? sDate,
    DateTime? eDate,
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
      _getOpeningBalance();
    }
    if (eDate != null) {
      eDate = eDate.copyWith(hour: 23, minute: 59, second: 59);
      if (eDate.isAfter(_endDate)) {
        transactionsFetchNeeded = true;
      }
      _endDate = eDate;
      _getClosingBalance();
    }

    if (oAcc != null) {
      if (_otherAccountFilters.contains(oAcc.dbID)) {
        _otherAccountFilters.remove(oAcc.dbID);
      } else {
        _otherAccountFilters.add(oAcc.dbID);
      }
    }

    if (transactionsFetchNeeded) {
      await _getTransactions();
      _populateVoucherTypes();
      _populateAccounts();
    }

    notifyListeners();
    filterTransactions();
  }

  filterTransactions() {
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

  _populateVoucherTypes() {
    // _voucherTypeFilters = {};
    voucherTypes = _transactions.map((t) => t.voucherType).toSet();
    notifyListeners();
  }

  _populateAccounts() {
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
  }

  Future<void> _getTransactions() async {
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
    feedbackText = "";
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
