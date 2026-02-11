import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:pursenal/app/extensions/currency.dart';
import 'package:pursenal/app/global/values.dart';
import 'package:pursenal/core/abstracts/file_paths_repository.dart';
import 'package:pursenal/core/enums/db_table_type.dart';
import 'package:pursenal/core/enums/loading_status.dart';
import 'package:pursenal/core/enums/voucher_type.dart';
import 'package:pursenal/core/models/domain/account.dart';
import 'package:pursenal/core/models/domain/account_type.dart';
import 'package:pursenal/core/models/domain/ledger.dart';
import 'package:pursenal/core/models/domain/profile.dart';
import 'package:pursenal/core/models/domain/project.dart';
import 'package:pursenal/core/models/domain/transaction.dart';
import 'package:pursenal/core/abstracts/account_types_repository.dart';
import 'package:pursenal/core/abstracts/accounts_repository.dart';
import 'package:pursenal/core/abstracts/balances_repository.dart';
import 'package:pursenal/core/abstracts/projects_repository.dart';
import 'package:pursenal/core/abstracts/transactions_repository.dart';
import 'package:pursenal/core/repositories/repository_registry.dart';
import 'package:pursenal/utils/app_logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TransactionEntryViewmodel extends ChangeNotifier {
  final AccountsRepository _accountsRepository;
  final TransactionsRepository _transactionsRepository;
  final BalancesRepository _balancesRepository;
  final AccountTypesRepository _accountTypesRepository;
  final ProjectsRepository _projectsRepository;
  final FilePathsRepository _filePathsRepository;

  TransactionEntryViewmodel(
    RepositoryRegistry repositoryRegistry, {
    required Profile profile,
    Transaction? transaction,
    Transaction? dupeTransaction,
    Account? selectedAccount,
    Account? selectedFund,
    VoucherType? vchType,
    int amount = 0,
  })  : _profile = profile,
        _accountTypesRepository =
            repositoryRegistry.get<AccountTypesRepository>(),
        _accountsRepository = repositoryRegistry.get<AccountsRepository>(),
        _transactionsRepository =
            repositoryRegistry.get<TransactionsRepository>(),
        _balancesRepository = repositoryRegistry.get<BalancesRepository>(),
        _projectsRepository = repositoryRegistry.get<ProjectsRepository>(),
        _filePathsRepository = repositoryRegistry.get<FilePathsRepository>(),
        _transaction = transaction,
        _dupeTransaction = dupeTransaction,
        _selectedAccount = selectedAccount,
        _selectedFund = selectedFund,
        _amount = amount,
        _vchType = vchType ?? VoucherType.payment;

  LoadingStatus loadingStatus = LoadingStatus.idle;
  bool isNegativeBalanceAlerted = false;

  Transaction? _transaction;
  final Transaction? _dupeTransaction;

  bool _isPayment = true;
  int _vchNo = 1;
  DateTime _vchDate = DateTime.now();
  DateTime _startDate = DateTime(2000);

  String _narr = "";
  VoucherType _vchType = VoucherType.payment;
  int _amount = 0;
  String _refNo = "";
  List<String> _images = [];
  List<Ledger> _funds = [];
  List<Ledger> _ledgers = [];
  List<Ledger> _fLedgers = [];

  final Profile _profile;
  Account? _selectedFund;
  Account? _selectedAccount;
  Project? _selectedProject;

  // Error text variables
  String _vchNoError = "";
  String _vchDateError = "";
  final String _narrError = "";
  final String _vchTypeError = "";
  String _amountError = "";
  String _selectedFundError = "";
  String _selectedAccountError = "";

  String errorText = "";

// Getters for error text
  String get vchNoError => _vchNoError;
  String get vchDateError => _vchDateError;
  String get narrError => _narrError;
  String get vchTypeError => _vchTypeError;
  String get amountError => _amountError;
  String get selectedFundError => _selectedFundError;
  String get selectedAccountError => _selectedAccountError;

  Transaction? get transaction => _transaction;
  bool get isPayment => _isPayment;
  DateTime get vchDate => _vchDate;
  String get narr => _narr;
  int get vchNo => _vchNo;
  int get amount => _amount;
  String get refNo => _refNo;
  VoucherType get vchType => _vchType;
  List<String> get images => _images;
  List<Ledger> get funds => _funds;
  List<Ledger> get fAccounts => _fLedgers;
  Account? get selectedFund => _selectedFund;
  Account? get selectedAccount => _selectedAccount;
  DateTime get startDate => _startDate;
  Project? get selectedProject => _selectedProject;

  List<AccountType> accountTypes = [];

  SharedPreferences? _prefs;

  List<Project> projects = [];

  Future<void> init() async {
    loadingStatus = LoadingStatus.loading;
    await getAccounts();
    await _getAllProjects();
    _prefs = await SharedPreferences.getInstance();

    isPayment = _vchType == VoucherType.payment;

    if (_transaction != null) {
      _transaction = _transaction;
      AppLogger.instance.info("Editing transaction : ${_transaction!.dbID}");
      try {
        _setDefaults(_transaction!);
        _images = [..._transaction!.filePaths];
      } catch (e, stackTrace) {
        errorText = "Error: Failed to initialise Transaction form";
        loadingStatus = LoadingStatus.error;
        AppLogger.instance.error(' ${e.toString()}', [stackTrace]);
        return;
      }
    } else {
      try {
        if (_dupeTransaction != null) {
          _setDefaults(_dupeTransaction);
        } else if (_selectedFund == null && _funds.length == 1) {
          _selectedFund = _funds.first.account;
        }
      } catch (e) {
        errorText = "Error: Failed to initialise Transaction form";
        AppLogger.instance.error(' ${e.toString()}');
        loadingStatus = LoadingStatus.error;
        notifyListeners();
      }

      vchNo = (await _transactionsRepository.getLastTransactionID() ?? 0) + 1;
    }

    loadingStatus = LoadingStatus.completed;
    notifyListeners();
    _sortOtherAccounts();
    _setDatePickerStartDate();
  }

  set selectedFund(Account? value) {
    _selectedFund = value;
    notifyListeners();
    _filterAccounts();
    _sortOtherAccounts();
    _setDatePickerStartDate();
  }

  set selectedAccount(Account? value) {
    _selectedAccount = value;
    if (value == _selectedFund) {
      _selectedFund = null;
    }
    notifyListeners();
    _setDatePickerStartDate();
  }

  set imagePath(List<String> value) {
    _images = value;
    notifyListeners();
  }

  set transaction(Transaction? value) {
    _transaction = value;
    notifyListeners();
  }

  set isPayment(bool value) {
    _isPayment = value;
    vchType = value ? VoucherType.payment : VoucherType.receipt;
    notifyListeners();
  }

  set vchNo(int value) {
    _vchNo = value;
    notifyListeners();
  }

  set vchDate(DateTime value) {
    _vchDate = value;
    notifyListeners();
  }

  set narr(String value) {
    _narr = value;
    notifyListeners();
  }

  set vchType(VoucherType value) {
    _vchType = value;
    _sortOtherAccounts();

    notifyListeners();
  }

  set amount(int value) {
    _amount = value;
    notifyListeners();
  }

  set refNo(String value) {
    _refNo = value;
    notifyListeners();
  }

  _setDatePickerStartDate() {
    if (_selectedFund != null) {
      _startDate = _selectedFund!.openDate;
    }

    if (_vchDate.isBefore(_startDate)) {
      _vchDate = DateTime.now();
    }
    notifyListeners();
  }

  set selectedProject(Project? value) {
    _selectedProject = value;
    notifyListeners();
  }

  Future<void> getAccounts() async {
    _ledgers = await _accountsRepository.getLedgers(profileId: _profile.dbID);
    _funds = await _accountsRepository.getLedgersByCategory(
        profileId: _profile.dbID, accTypeIDs: fundingAccountIDs);

    accountTypes = await _accountTypesRepository.getAll();

    // _ledgers.where((a) => a.accType.dbID <= 3).toList();
    notifyListeners();
    _filterAccounts();
  }

  void _setDefaults(Transaction tr) {
    try {
      if (tr.voucherType == VoucherType.payment) {
        _isPayment = true;
        _selectedFund = _funds
            .firstWhere((a) => a.account.dbID == tr.crAccount.dbID)
            .account;
        _selectedAccount = _ledgers
            .firstWhere((a) => a.account.dbID == tr.drAccount.dbID)
            .account;
      } else {
        _isPayment = false;
        _selectedAccount = _ledgers
            .firstWhere((a) => a.account.dbID == tr.crAccount.dbID)
            .account;
        _selectedFund = _funds
            .firstWhere((a) => a.account.dbID == tr.drAccount.dbID)
            .account;
      }
      _amount = tr.amount;
      _vchNo = tr.dbID;
      _vchDate = tr.voucherDate;
      _vchType = tr.voucherType;
      _narr = tr.narration;
      _refNo = tr.refNo;
      if (tr.project != null) {
        _selectedProject = projects.firstWhereOrNull((p) => p == tr.project);
      }

      notifyListeners();
    } catch (e, stackTrace) {
      AppLogger.instance.error(' ${e.toString()}', [stackTrace]);
      errorText = 'Error: Failed to set transaction ';
    }
  }

  void _filterAccounts() {
    _fLedgers = List.from(_ledgers);

    if (_selectedFund != null) {
      _fLedgers.removeWhere((l) => l.account.dbID == _selectedFund?.dbID);
    }
    notifyListeners();
  }

  void addImage(String path) async {
    if (!_images.contains(path)) {
      _images.add(path);
      notifyListeners();
    }
  }

  void removeImage(String path) async {
    if (_images.contains(path)) {
      _images.remove(path);
      notifyListeners();
    }
  }

  Future<void> _getAllProjects() async {
    try {
      projects = await _projectsRepository.getAllProjects(_profile.dbID);
    } catch (e) {
      AppLogger.instance.error(' ${e.toString()}');
      errorText = 'Error: ';
    }
  }

  bool _validate() {
    bool isValid = true;
    _vchNoError = '';
    _vchDateError = '';
    _amountError = '';
    _selectedFundError = '';
    _selectedAccountError = '';
    notifyListeners();

    int fundBalance = _funds
            .firstWhereOrNull((f) => f.account.dbID == _selectedFund?.dbID)
            ?.balance ??
        0;

    if (_vchNo <= 0) {
      _vchNoError = 'Voucher number must be greater than 0';
      isValid = false;
    }
    if (_vchDate.isAfter(DateTime.now())) {
      _vchDateError = 'Voucher date cannot be in the future';
      isValid = false;
    }

    if (_amount <= 0) {
      _amountError = 'Amount must be greater than 0';
      isValid = false;
    }

    if (isPayment && !isNegativeBalanceAlerted) {
      int difference = fundBalance - amount;
      if (_transaction != null) {
        if (_transaction!.voucherType == VoucherType.receipt) {
          difference -= (_transaction!.amount);
        } else if (_transaction!.voucherType == VoucherType.payment) {
          difference += (_transaction!.amount);
        }
      }

      if (difference < 0) {
        errorText =
            "Warning: The account balance after payment will be ${difference.toCurrencyStringWSymbol(_profile.currency)}";
        isValid = false;
        isNegativeBalanceAlerted = true;
      }
    }

    if (_selectedFund == null) {
      _selectedFundError = 'Fund must be selected';
      isValid = false;
    }

    if (_selectedAccount == null) {
      _selectedAccountError = 'Account must be selected';
      isValid = false;
    }
    notifyListeners();
    return isValid;
  }

  Future<bool> save() async {
    try {
      if (_validate() && _selectedFund != null && _selectedAccount != null) {
        loadingStatus = LoadingStatus.submitting;
        notifyListeners();

        if (_transaction != null && _transaction != null) {
          AppLogger.instance
              .info("Updating Transaction with ID:${_transaction!.dbID}");
          await _transactionsRepository.updateTransaction(
              id: _transaction!.dbID,
              vchDate: _vchDate,
              narr: _narr,
              refNo: _refNo,
              dr: isPayment ? _selectedAccount! : _selectedFund!,
              cr: isPayment ? _selectedFund! : _selectedAccount!,
              amount: _amount,
              vchType: _vchType,
              project: _selectedProject,
              profile: _profile);

          await _filePathsRepository
              .deleteFilePathByParentID(transaction!.dbID);

          for (var p in _images) {
            await _filePathsRepository.insertFilePath(
                path: p,
                parentTableID: _transaction!.dbID,
                tableType: DBTableType.transaction);
          }
        } else {
          final trId = await _transactionsRepository.insertTransaction(
              vchDate: _vchDate,
              narr: _narr,
              refNo: _refNo,
              dr: isPayment ? _selectedAccount! : _selectedFund!,
              cr: isPayment ? _selectedFund! : _selectedAccount!,
              amount: _amount,
              vchType: _vchType,
              project: _selectedProject,
              profile: _profile);
          for (String p in _images) {
            await _filePathsRepository.insertFilePath(
                path: p,
                parentTableID: trId,
                tableType: DBTableType.transaction);
          }
        }

        await _updateBalances();
        loadingStatus = LoadingStatus.submitted;
        notifyListeners();
        _setLastUpdatedTimeStamp();
        AppLogger.instance.info("Transaction saved.");
        return true;
      }

      notifyListeners();
      return false;
    } catch (e) {
      AppLogger.instance
          .error('Failed to save the transaction : ${e.toString()}');
      errorText = 'Error: Failed to save the transaction';
      loadingStatus = LoadingStatus.error;
      notifyListeners();
      return false;
    }
  }

  _updateBalances() async {
    try {
      if (_selectedAccount != null && _selectedFund != null) {
        await _balancesRepository.updateBalanceByAccount(
          account: _selectedFund!,
        );

        await _balancesRepository.updateBalanceByAccount(
          account: _selectedAccount!,
        );
      }
    } catch (e) {
      AppLogger.instance.error(
          'Failed to update balance after enterring transaction ${e.toString()}');
      errorText = 'Error: Failed to update balance.';
      loadingStatus = LoadingStatus.error;
    }
  }

  void resetErrorText() {
    errorText = "";
    notifyListeners();
  }

  Future<void> _setLastUpdatedTimeStamp() async {
    try {
      final timeStamp = DateTime.now();
      _prefs?.setInt('lastUpdated', timeStamp.millisecondsSinceEpoch);
    } catch (e) {
      AppLogger.instance
          .error("Error setting Last updated timestamp ${e.toString()}");
    }
  }

  _sortOtherAccounts() {
    _fLedgers.sort((a, b) {
      if (_vchType == VoucherType.payment) {
        if (a.accountType.dbID == 5) {
          return -1;
        }
      }

      if (_vchType == VoucherType.receipt) {
        if (a.accountType.dbID == 4) {
          return -1;
        }
      }

      return 1;
    });
    notifyListeners();
  }
}
