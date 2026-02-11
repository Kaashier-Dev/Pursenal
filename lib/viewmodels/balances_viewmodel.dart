import 'package:flutter/foundation.dart';
import 'package:pursenal/app/global/values.dart';
import 'package:pursenal/core/abstracts/banks_repository.dart';
import 'package:pursenal/core/abstracts/credit_cards_repository.dart';
import 'package:pursenal/core/abstracts/loans_repository.dart';
import 'package:pursenal/core/abstracts/wallets_repository.dart';
import 'package:pursenal/core/enums/loading_status.dart';
import 'package:pursenal/core/models/domain/account_type.dart';
import 'package:pursenal/core/models/domain/bank.dart';
import 'package:pursenal/core/models/domain/credit_card.dart';
import 'package:pursenal/core/models/domain/ledger.dart';
import 'package:pursenal/core/models/domain/loan.dart';
import 'package:pursenal/core/models/domain/profile.dart';
import 'package:pursenal/core/models/domain/wallet.dart';
import 'package:pursenal/core/abstracts/account_types_repository.dart';
import 'package:pursenal/core/abstracts/accounts_repository.dart';
import 'package:pursenal/core/repositories/repository_registry.dart';
import 'package:pursenal/utils/app_logger.dart';

class BalancesViewmodel extends ChangeNotifier {
  final AccountsRepository _accountsRepository;
  final AccountTypesRepository _accountTypesRepository;
  final WalletsRepository _walletsRepository;
  final BanksRepository _banksRepository;
  final CreditCardsRepository _cardsRepository;
  final LoansRepository _loansRepository;
  BalancesViewmodel(RepositoryRegistry repositoryRegistry,
      {required Profile profile})
      : _profile = profile,
        _accountsRepository = repositoryRegistry.get<AccountsRepository>(),
        _accountTypesRepository =
            repositoryRegistry.get<AccountTypesRepository>(),
        _walletsRepository = repositoryRegistry.get<WalletsRepository>(),
        _banksRepository = repositoryRegistry.get<BanksRepository>(),
        _cardsRepository = repositoryRegistry.get<CreditCardsRepository>(),
        _loansRepository = repositoryRegistry.get<LoansRepository>();

  Future<void> init() async {
    try {
      loadingStatus = LoadingStatus.loading;
      notifyListeners();
      await getFunds();
      await getAccountTypes();
      loadingStatus = LoadingStatus.completed;
      notifyListeners();
    } catch (e) {
      AppLogger.instance.error(' ${e.toString()}');
      errorText = 'Error: Failed to initialise funds';
      loadingStatus = LoadingStatus.error;
      notifyListeners();
    }
  }

  final Profile _profile;

  List<AccountType> _fundingAccountTypes = [];
  List<AccountType> get fundingAccountTypes => _fundingAccountTypes;

  List<AccountType> _balanceAccountTypes = [];
  List<AccountType> get balanceAccountTypes => _balanceAccountTypes;

  List<Ledger> _funds = [];
  List<Ledger> get funds => _funds;

  List<AccountType> _fundAccountTypes = [];
  List<AccountType> get fundAccountTypes => _fundAccountTypes;

  List<Ledger> _credits = [];
  List<Ledger> get credits => _credits;

  List<AccountType> _creditAccountTypes = [];
  List<AccountType> get creditAccountTypes => _creditAccountTypes;

  List<Ledger> _otherAccounts = [];
  List<Ledger> get otherAccounts => _otherAccounts;

  List<AccountType> _otherAccountAccountTypes = [];
  List<AccountType> get otherAccountAccountTypes => _otherAccountAccountTypes;

  LoadingStatus loadingStatus = LoadingStatus.idle;
  LoadingStatus searchLoadingStatus = LoadingStatus.idle;

  String errorText = "";

  Future<void> getFunds() async {
    try {
      _funds = await _accountsRepository.getLedgersByCategory(
          profileId: _profile.dbID, accTypeIDs: fundIDs);
      _credits = await _accountsRepository.getLedgersByCategory(
          profileId: _profile.dbID, accTypeIDs: creditIDs);
      _otherAccounts = [
        ...await _accountsRepository.getLedgersByAccType(
            profileId: _profile.dbID, accTypeID: advanceTypeID),
        ...await _accountsRepository.getLedgersByAccType(
            profileId: _profile.dbID, accTypeID: peopleTypeID),
      ];
      AppLogger.instance.info("Funds loaded from database");
    } catch (e) {
      loadingStatus = LoadingStatus.error;
      errorText = "Error loading funds";
    }
    notifyListeners();
  }

  Future<void> getAccountTypes() async {
    try {
      _fundAccountTypes =
          await _accountTypesRepository.getAccTypesByCategory(fundIDs);
      _fundingAccountTypes = await _accountTypesRepository
          .getAccTypesByCategory(fundingAccountIDs);
      _creditAccountTypes =
          await _accountTypesRepository.getAccTypesByCategory(creditIDs);
      _otherAccountAccountTypes = [
        await _accountTypesRepository.getById(advanceTypeID),
        await _accountTypesRepository.getById(peopleTypeID),
      ];
      _balanceAccountTypes = await _accountTypesRepository
          .getAccTypesByCategory(balanceAccountIDs);
    } catch (e) {
      loadingStatus = LoadingStatus.error;
      errorText = "Error loading Account types";
    }
    notifyListeners();
  }

  Future<Wallet> getWalletByAccount(int id) async {
    try {
      return await _walletsRepository.getByAccount(id);
    } catch (e) {
      AppLogger.instance.error("Failed to get Wallet. ${e.toString()}");
      loadingStatus = LoadingStatus.error;
      errorText = "Error loading wallets";
      rethrow;
    }
  }

  Future<Bank> getBankByAccount(int id) async {
    try {
      return await _banksRepository.getByAccount(id);
    } catch (e) {
      AppLogger.instance.error("Failed to get Bank. ${e.toString()}");
      loadingStatus = LoadingStatus.error;
      errorText = "Error loading banks";
      rethrow;
    }
  }

  Future<Loan> getLoanByAccount(int id) async {
    try {
      return await _loansRepository.getByAccount(id);
    } catch (e) {
      AppLogger.instance.error("Failed to get Loan. ${e.toString()}");
      loadingStatus = LoadingStatus.error;
      errorText = "Error loading loans";
      rethrow;
    }
  }

  Future<CreditCard> getCCardByAccount(int id) async {
    try {
      return await _cardsRepository.getByAccount(id);
    } catch (e) {
      AppLogger.instance.error("Failed to get Credit Card. ${e.toString()}");
      loadingStatus = LoadingStatus.error;
      errorText = "Error loading cards";
      rethrow;
    }
  }

  void resetErrorText() {
    errorText = "";
    notifyListeners();
  }

  int getBalanceByAccountType(int id) {
    int balance = 0;
    if (fundIDs.contains(id)) {
      balance = funds
          .where((a) => a.accountType.dbID == id)
          .fold<int>(0, (sum, item) => sum + item.balance);
    } else if (creditIDs.contains(id)) {
      balance = credits
          .where((a) => a.accountType.dbID == id)
          .fold<int>(0, (sum, item) => sum + item.balance);
    } else if ([advanceTypeID, peopleTypeID].contains(id)) {
      balance = otherAccounts
          .where((a) => a.accountType.dbID == id)
          .fold<int>(0, (sum, item) => sum + item.balance);
    }
    return balance;
  }
}
