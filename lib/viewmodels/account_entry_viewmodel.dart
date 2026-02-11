import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:pursenal/app/global/date_formats.dart';
import 'package:pursenal/app/global/values.dart';
import 'package:pursenal/core/abstracts/balances_repository.dart';
import 'package:pursenal/core/abstracts/credit_cards_repository.dart';
import 'package:pursenal/core/abstracts/wallets_repository.dart';
import 'package:pursenal/core/enums/loading_status.dart';
import 'package:pursenal/core/models/domain/account.dart';
import 'package:pursenal/core/models/domain/account_type.dart';
import 'package:pursenal/core/models/domain/bank.dart';
import 'package:pursenal/core/models/domain/credit_card.dart';
import 'package:pursenal/core/models/domain/loan.dart';
import 'package:pursenal/core/models/domain/people.dart';
import 'package:pursenal/core/models/domain/profile.dart';
import 'package:pursenal/core/models/domain/receivable.dart';
import 'package:pursenal/core/models/domain/wallet.dart';
import 'package:pursenal/core/abstracts/account_types_repository.dart';
import 'package:pursenal/core/abstracts/accounts_repository.dart';
import 'package:pursenal/core/abstracts/banks_repository.dart';
import 'package:pursenal/core/abstracts/loans_repository.dart';
import 'package:pursenal/core/abstracts/people_repository.dart';
import 'package:pursenal/core/abstracts/receivables_repository.dart';
import 'package:pursenal/core/repositories/repository_registry.dart';
import 'package:pursenal/utils/app_logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AccountEntryViewModel extends ChangeNotifier {
  final WalletsRepository _walletsRepository;
  final AccountsRepository _accountsRepository;
  final AccountTypesRepository _accountTypesRepository;
  final BalancesRepository _balancesRepository;
  final LoansRepository _loansRepository;
  final CreditCardsRepository _cCardsRepository;
  final BanksRepository _banksRepository;
  final PeopleRepository _peopleRepository;
  final ReceivablesRepository _receivablesRepository;

  AccountEntryViewModel(
    RepositoryRegistry repositoryRegistry, {
    required Profile profile,
    AccountType? accountType,
    Account? account,
  })  : _profile = profile,
        _walletsRepository = repositoryRegistry.get<WalletsRepository>(),
        _accountsRepository = repositoryRegistry.get<AccountsRepository>(),
        _accountTypesRepository =
            repositoryRegistry.get<AccountTypesRepository>(),
        _balancesRepository = repositoryRegistry.get<BalancesRepository>(),
        _loansRepository = repositoryRegistry.get<LoansRepository>(),
        _cCardsRepository = repositoryRegistry.get<CreditCardsRepository>(),
        _banksRepository = repositoryRegistry.get<BanksRepository>(),
        _peopleRepository = repositoryRegistry.get<PeopleRepository>(),
        _receivablesRepository =
            repositoryRegistry.get<ReceivablesRepository>(),
        _accountType = accountType,
        _account = account;

  int? _accountId;
  String _accountName = "";
  AccountType? _accountType;
  int _openBal = 0;
  DateTime _openDate = DateTime.now();
  bool _isEditable = true;
  final Profile _profile;

  Profile get profile => _profile;

  String? _holderName;
  String? _institution;
  String? _branch;
  String? _branchCode;

  String? _cardNetwork;
  String? _cardNo;
  int? _statementDate;
  String? _accountNo;
  String? _agreementNo;
  double? _interestRate;
  DateTime? _startDate;
  DateTime? _endDate;

  DateTime? _paidDate;
  int? _totalAmount;
  String? _address;
  String? _zip;
  String? _email;
  String? _phone;
  String? _tin;

  Account? _account;
  Loan? _loan;
  Wallet? _wallet;
  Bank? _bank;
  CreditCard? _card;
  People? _people;
  Receivable? _receivable;

  String _accountNameError = "";
  String _accountTypeError = "";
  String _amountError = "";
  String _openDateError = "";
  String _statementDateError = "";
  String _interestRateError = "";

  String get accountNameError => _accountNameError;
  String get accountTypeError => _accountTypeError;
  String get amountError => _amountError;
  String get openDateError => _openDateError;
  String get statementDateError => _statementDateError;
  String get interestRateError => _interestRateError;

  LoadingStatus loadingStatus = LoadingStatus.idle;
  String errorText = "";

  List<AccountType> _accountTypes = [];

  List<AccountType> get accountTypes => _accountTypes;

  List<Account> _accounts = [];

  SharedPreferences? _prefs;

  String? amountHelperText;

  String nameError = "";
  String nickNameError = "";
  String currencyError = "";
  String addressError = "";
  String zipError = "";
  String emailError = "";
  String phoneError = "";

  Future<void> init() async {
    loadingStatus = LoadingStatus.loading;
    _prefs = await SharedPreferences.getInstance();

    await _getAccount();
    if (_accountType != null &&
        [incomeTypeID, expenseTypeID].contains(_accountType?.dbID)) {
      _openDate = DateTime(_openDate.year);
    }

    if (_account != null) {
      _accountName = _account!.name;
      _openBal = _account!.openBalance;
      _openDate = _account!.openDate;
    }

    if (_wallet != null) {
    } else if (_bank != null) {
      _holderName = _bank!.holderName;
      _accountNo = _bank!.accountNo;
      _branch = _bank!.branch;
      _institution = _bank!.institution;
      _branchCode = _bank!.branchCode;
    } else if (_card != null) {
      _cardNetwork = _card!.cardNetwork;
      _cardNo = _card!.cardNo;
      _statementDate = _card!.statementDate;
      _institution = _card!.institution;
    } else if (_loan != null) {
      _institution = _loan!.institution;
      _accountNo = _loan!.accountNo;
      _agreementNo = _loan!.agreementNo;
      _interestRate = _loan!.interestRate;
      _startDate = _loan!.startDate;
      _endDate = _loan!.endDate;
    } else if (_people != null) {
      _address = _people?.address;
      _email = _people?.email;
      _phone = _people?.phone;
      _tin = _people?.tin;
      _zip = _people?.zip;
    } else if (_receivable != null) {
      _totalAmount = _receivable?.totalAmount;
      _paidDate = _receivable?.paidDate;
    }

    await _getAccountTypes();
    _accountType ??= _accountTypes
            .firstWhereOrNull((a) => a.dbID == _account?.accountType) ??
        _accountTypes.first;

    _setHelperText();

    loadingStatus = LoadingStatus.completed;
    notifyListeners();
    await _getAccounts();
  }

  Future<void> _getAccount() async {
    try {
      if (_account != null) {
        _account = await _accountsRepository.getById(_account!.dbID);

        switch (_account?.accountType) {
          case walletTypeID:
            _wallet = await _walletsRepository.getByAccount(_account!.dbID);
            break;
          case bankTypeID:
            _bank = await _banksRepository.getByAccount(_account!.dbID);
            break;
          case cCardTypeID:
            _card = await _cCardsRepository.getByAccount(_account!.dbID);
            break;
          case loanTypeID:
            _loan = await _loansRepository.getByAccount(_account!.dbID);
            break;
          case peopleTypeID:
            _people = await _peopleRepository.getByAccount(_account!.dbID);
            break;
          case advanceTypeID:
            _receivable =
                await _receivablesRepository.getByAccount(_account!.dbID);
            break;
          default:
            break;
        }
      }

      AppLogger.instance.info("Account loaded from database");
    } catch (e) {
      AppLogger.instance.error("Error loading account ${e.toString()}");
    }
    notifyListeners();
  }

  Future<void> _getAccounts() async {
    try {
      _accounts = await _accountsRepository.getAccountsByProfile(
          profileId: _profile.dbID);

      if (_account != null) {
        _accounts.removeWhere((a) {
          return a.dbID == _account!.dbID;
        });
      }

      AppLogger.instance.info("Accounts loaded from database");
    } catch (e) {
      AppLogger.instance.error("Error loading ledgers ${e.toString()}");
    }
    notifyListeners();
  }

  // Getters and Setters for Account-related fields
  int? get accountId => _accountId;
  set accountId(int? value) {
    _accountId = value;
    notifyListeners();
  }

  String get accountName => _accountName;
  set accountName(String value) {
    _accountName = value;
    notifyListeners();
  }

  AccountType? get accountType => _accountType;
  set accountType(AccountType? value) {
    _accountType = value;
    if (value != null && fundingAccountIDs.contains(value.dbID)) {
      openBal = 0;
    }
    _setHelperText();
    notifyListeners();
  }

  int get openBal => _openBal;
  set openBal(int value) {
    _openBal = value;
    if (_openBal == 0) {
      _setHelperText();
    }
    notifyListeners();
  }

  DateTime get openDate => _openDate;
  set openDate(DateTime value) {
    _openDate = value;
    _setHelperText();
    notifyListeners();
  }

  bool get isEditable => _isEditable;
  set isEditable(bool value) {
    _isEditable = value;
    notifyListeners();
  }

  // Getters and Setters for Bank-related fields

  String? get holderName => _holderName;
  set holderName(String? value) {
    _holderName = value;
    notifyListeners();
  }

  String? get institution => _institution;
  set institution(String? value) {
    _institution = value;
    notifyListeners();
  }

  String? get branch => _branch;
  set branch(String? value) {
    _branch = value;
    notifyListeners();
  }

  String? get branchCode => _branchCode;
  set branchCode(String? value) {
    _branchCode = value;
    notifyListeners();
  }

  // Getters and Setters for Card-related fields

  String? get cardNetwork => _cardNetwork;
  set cardNetwork(String? value) {
    _cardNetwork = value;
    notifyListeners();
  }

  String? get cardNo => _cardNo;
  set cardNo(String? value) {
    _cardNo = value;
    notifyListeners();
  }

  int? get statementDate => _statementDate;
  set statementDate(int? value) {
    _statementDate = value;
    notifyListeners();
  }

  // Getters and Setters for Loan-related fields

  String? get accountNo => _accountNo;
  set accountNo(String? value) {
    _accountNo = value;
    notifyListeners();
  }

  String? get agreementNo => _agreementNo;
  set agreementNo(String? value) {
    _agreementNo = value;
    notifyListeners();
  }

  double? get interestRate => _interestRate;
  set interestRate(double? value) {
    _interestRate = value;
    notifyListeners();
  }

  DateTime? get startDate => _startDate;
  set startDate(DateTime? value) {
    _startDate = value;
    notifyListeners();
  }

  DateTime? get endDate => _endDate;
  set endDate(DateTime? value) {
    _endDate = value;
    notifyListeners();
  }

  DateTime? get paidDate => _paidDate;
  set paidDate(DateTime? value) {
    _paidDate = value;
    notifyListeners();
  }

  int? get totalAmount => _totalAmount;
  set totalAmount(int? value) {
    _totalAmount = value;
    notifyListeners();
  }

  String? get address => _address;
  set address(String? value) {
    _address = value;
    notifyListeners();
  }

  String? get zip => _zip;
  set zip(String? value) {
    _zip = value;
    notifyListeners();
  }

  String? get email => _email;
  set email(String? value) {
    _email = value;
    notifyListeners();
  }

  String? get phone => _phone;
  set phone(String? value) {
    _phone = value;
    notifyListeners();
  }

  String? get tin => _tin;
  set tin(String? value) {
    _tin = value;
    notifyListeners();
  }

  // Setters for related objects

  // Loan setter

  set loan(Loan? value) {
    _loan = value;
    if (value != null) {
      _getAccountbyId(value.account.dbID);
      _accountNo = value.accountNo;
      _agreementNo = value.agreementNo;
      _interestRate = value.interestRate;
      _startDate = value.startDate;
      _endDate = value.endDate;
    }
    notifyListeners();
  }

  set wallet(Wallet? value) {
    _wallet = value;
    if (value != null) {
      _getAccountbyId(value.account.dbID);

      _accountId = value.account.dbID;
    }
    notifyListeners();
  }

  set bank(Bank? value) {
    _bank = value;
    if (value != null) {
      _getAccountbyId(value.account.dbID);

      _holderName = value.holderName;
      _institution = value.institution;
      _branch = value.branch;
      _branchCode = value.branchCode;
    }
    notifyListeners();
  }

  // Card setter
  set card(CreditCard? value) {
    _card = value;
    if (value != null) {
      _getAccountbyId(value.account.dbID);

      _cardNetwork = value.cardNetwork;
      _cardNo = value.cardNo;
      _statementDate = value.statementDate;
    }
    notifyListeners();
  }

  set people(People? value) {
    _people = value;
    if (value != null) {
      _address = _people?.address;
      _email = _people?.email;
      _phone = _people?.phone;
      _tin = _people?.tin;
      _zip = _people?.zip;
    }
    notifyListeners();
  }

  set receivable(Receivable? value) {
    _receivable = value;
    if (value != null) {
      _totalAmount = _receivable?.totalAmount;
      _paidDate = _receivable?.paidDate;
    }
    notifyListeners();
  }

  Future<void> _getAccountTypes() async {
    try {
      _accountTypes = await _accountTypesRepository.getAll();
    } catch (e) {
      AppLogger.instance.error(' ${e.toString()}');
    }
    notifyListeners();
  }

  Future<void> _getAccountbyId(int id) async {
    try {
      _account = await _accountsRepository.getById(id);
      if (_account != null) {
        _accountName = _account!.name;
        _accountId = _account!.dbID;
        _openBal = _account!.openBalance;
      }
    } catch (e) {
      AppLogger.instance.error(' ${e.toString()}');
    }
    notifyListeners();
  }

  // Validate Fields
  bool _validate() {
    bool isValid = true;

    // Clear all error texts
    _accountNameError = "";
    _accountTypeError = "";
    _amountError = "";
    _statementDateError = "";
    _interestRateError = "";
    _openDateError = "";
    notifyListeners();

    // Validation logic
    if (_accountName.trim().isEmpty) {
      _accountNameError = "Account name must be valid.";
      isValid = false;
    }

    if (_accounts.where((a) => a.name == _accountName).isNotEmpty) {
      _accountNameError = "Account name already exist.";
      isValid = false;
    }
    if (_accountType == null) {
      _accountTypeError = "Account type is required.";
      isValid = false;
    }
    if (_accountType != null &&
        _accountType!.dbID == cCardTypeID &&
        _statementDate != null &&
        (_statementDate! < 1 || _statementDate! > 31)) {
      _statementDateError = "Statement date must be between 1 and 31.";
      isValid = false;
    }
    if (_interestRate != null && (_interestRate! < 0 || _interestRate! > 100)) {
      _interestRateError = "Interest rate must be between 0 and 100.";
      isValid = false;
    }
    if (_openBal < 0) {
      _amountError = "Enter a valid amount.";
      isValid = false;
    }
    if (_openDate.isAfter(DateTime.now())) {
      _openDateError = "Date cannot be in the future.";
      isValid = false;
    }
    notifyListeners();

    return isValid;
  }

  Future<bool> deleteAccount() async {
    if (_account != null) {
      try {
        await _accountsRepository.delete(_account!.dbID);
        return true;
      } catch (e) {
        AppLogger.instance.error(' ${e.toString()}');
        errorText = 'Error: Failed to delete account ';
        return false;
      }
    }
    notifyListeners();
    return false;
  }

  Future<bool> save() async {
    try {
      if (_validate()) {
        loadingStatus = LoadingStatus.submitting;
        notifyListeners();
        int? accId = _account == null
            ? await _accountsRepository.insertAccount(
                name: _accountName,
                accType: _accountType!.dbID,
                openBal: _openBal,
                openDate: _openDate,
                profile: _profile.dbID,
              )
            : await _accountsRepository.updateAccount(
                    name: _accountName,
                    accType: _accountType!.dbID,
                    openBal: _openBal,
                    openDate: _openDate,
                    profile: _profile.dbID,
                    id: _account!.dbID)
                ? _account!.dbID
                : null;
        _account = await _accountsRepository.getById(accId!);
        if (accId != null) {
          if (_accountType!.dbID == walletTypeID) {
            if (_wallet == null) {
              _walletsRepository.insertWallet(account: _account!);
            } else {
              _walletsRepository.updateWallet(
                  id: _wallet!.dbID, account: _account!);
            }
          } else if (_accountType!.dbID == bankTypeID) {
            if (_bank == null) {
              _banksRepository.insertBank(
                  account: _account!,
                  branch: _branch,
                  accountNo: _accountNo,
                  branchCode: _branchCode,
                  holderName: _holderName,
                  institution: _institution);
            } else {
              _banksRepository.updateBank(
                  id: _bank!.dbID,
                  account: _account!,
                  accountNo: _accountNo,
                  branch: _branch,
                  branchCode: _branchCode,
                  holderName: _holderName,
                  institution: _institution);
            }
          } else if (_accountType!.dbID == cCardTypeID) {
            if (_card == null) {
              _cCardsRepository.insertCCard(
                  account: _account!,
                  cardNetwork: _cardNetwork,
                  cardNo: _cardNo,
                  institution: _institution,
                  statementDate: _statementDate);
            } else {
              _cCardsRepository.updateCCard(
                  id: _card!.dbID,
                  account: _account!,
                  cardNetwork: _cardNetwork,
                  cardNo: _cardNo,
                  institution: _institution,
                  statementDate: _statementDate);
            }
          } else if (_accountType!.dbID == loanTypeID) {
            if (_loan == null) {
              _loansRepository.insertLoan(
                account: _account!,
                institution: _institution,
                accountNo: _accountNo,
                agreementNo: _agreementNo,
                interestRate: _interestRate,
                startDate: _startDate,
                endDate: _endDate,
              );
            } else {
              _loansRepository.updateLoan(
                id: _loan!.dbID,
                account: _account!,
                institution: _institution,
                accountNo: _accountNo,
                agreementNo: _agreementNo,
                interestRate: _interestRate,
                startDate: _startDate,
                endDate: _endDate,
              );
            }
          } else if (_accountType!.dbID == peopleTypeID) {
            if (_people == null) {
              _peopleRepository.insertPeople(
                  account: _account!,
                  address: _address,
                  email: _email,
                  phone: _phone,
                  tin: _tin,
                  zip: _zip);
            } else {
              _peopleRepository.updatePeople(
                  id: _people!.dbID,
                  account: _account!,
                  address: _address,
                  email: _email,
                  phone: _phone,
                  tin: _tin,
                  zip: _zip);
            }
          } else if (_accountType!.dbID == advanceTypeID) {
            if (_receivable == null) {
              _receivablesRepository.insertReceivable(
                  account: _account!,
                  paidAmount: _totalAmount,
                  paidDate: _paidDate);
            } else {
              _receivablesRepository.updateReceivable(
                  id: _receivable!.dbID,
                  account: _account!,
                  paidAmount: _totalAmount,
                  paidDate: _paidDate);
            }
          }

          if (_account != null) {
            await _balancesRepository.updateBalanceByAccount(
              account: _account!,
            );
          } else {
            await _balancesRepository.insertBalance(
                account: _account!, amount: _openBal);
          }
        }
        loadingStatus = LoadingStatus.submitted;
        notifyListeners();
        _setLastUpdatedTimeStamp();
        AppLogger.instance.info("Account saved.");
        return true;
      }

      notifyListeners();
      return false;
    } catch (e) {
      AppLogger.instance.error('Failed to save account : ${e.toString()}');
      errorText = 'Error: Failed to save account';
      return false;
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

  _setHelperText() {
    if (_accountType != null && _openBal == 0) {
      switch (_accountType?.dbID) {
        case walletTypeID:
          amountHelperText =
              "* Enter your wallet balance (as on ${defaultDate2.format(openDate)})";
          break;
        case bankTypeID:
          amountHelperText =
              "* Enter the bank account balance (as on ${defaultDate2.format(openDate)})";
          break;
        case cCardTypeID:
          amountHelperText =
              "* Enter the used amount out of total credit card limit (as on ${defaultDate2.format(openDate)})";
          break;
        case loanTypeID:
          amountHelperText =
              "* Enter the loan balance (as on ${defaultDate2.format(openDate)})";
          break;
        case advanceTypeID:
          amountHelperText =
              "* Enter the amount receivable (as on ${defaultDate2.format(openDate)})";
          break;
        default:
          amountHelperText = null;
          break;
      }
    } else {
      amountHelperText = null;
    }
    notifyListeners();
  }
}
