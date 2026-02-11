import 'package:flutter/material.dart';
import 'package:pursenal/core/enums/loading_status.dart';
import 'package:pursenal/core/models/domain/profile.dart';
import 'package:pursenal/core/models/domain/project.dart';
import 'package:pursenal/core/models/domain/transaction.dart';
import 'package:pursenal/core/abstracts/balances_repository.dart';
import 'package:pursenal/core/abstracts/projects_repository.dart';
import 'package:pursenal/core/abstracts/transactions_repository.dart';
import 'package:pursenal/core/repositories/repository_registry.dart';
import 'package:pursenal/utils/app_logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TransactionViewmodel extends ChangeNotifier {
  final TransactionsRepository _transactionsRepository;
  final BalancesRepository _balancesRepository;
  final ProjectsRepository _projectsRepository;

  TransactionViewmodel(
    RepositoryRegistry repositoryRegistry, {
    required Profile profile,
    required Transaction transaction,
  })  : _profile = profile,
        _transaction = transaction,
        _transactionsRepository =
            repositoryRegistry.get<TransactionsRepository>(),
        _balancesRepository = repositoryRegistry.get<BalancesRepository>(),
        _projectsRepository = repositoryRegistry.get<ProjectsRepository>();
  Transaction _transaction;
  Transaction get transaction => _transaction;

  final Profile _profile;
  get profile => _profile;

  LoadingStatus loadingStatus = LoadingStatus.idle;
  String errorText = "";

  SharedPreferences? _prefs;
  Project? project;

  init() async {
    try {
      loadingStatus = LoadingStatus.loading;
      _prefs = await SharedPreferences.getInstance();
      notifyListeners();
      try {
        await _getProject();
        loadingStatus = LoadingStatus.completed;
      } catch (e) {
        loadingStatus = LoadingStatus.error;
        errorText = "Cannot load Transaction";
      }
      notifyListeners();
    } catch (e) {
      AppLogger.instance.error(' ${e.toString()}');
      errorText = 'Error: Failed to initialise Transaction';
      loadingStatus = LoadingStatus.error;
      notifyListeners();
    }
  }

  deleteTransaction() async {
    try {
      await _transactionsRepository.delete(_transaction.dbID);
      await _balancesRepository.updateBalanceByAccount(
          account: _transaction.crAccount);
      await _balancesRepository.updateBalanceByAccount(
          account: _transaction.drAccount);
      notifyListeners();
      await setLastUpdatedTimeStamp();
      return true;
    } catch (e) {
      loadingStatus = LoadingStatus.error;
      errorText = "Couldn't delete transaction";
      return false;
    }
  }

  void resetErrorText() {
    errorText = "";
    notifyListeners();
  }

  _getProject() async {
    try {
      if (transaction.project != null) {
        project = await _projectsRepository.getById(transaction.project!.dbID);
      }
    } catch (e) {
      AppLogger.instance.error(' ${e.toString()}');
      errorText = 'Error: Cannot load project details ';
    }
    notifyListeners();
  }

  Future<void> setLastUpdatedTimeStamp() async {
    try {
      final timeStamp = DateTime.now();
      _prefs?.setInt('lastUpdated', timeStamp.millisecondsSinceEpoch);
    } catch (e) {
      AppLogger.instance
          .error("Error setting Last updated timestamp ${e.toString()}");
    }
  }

  void refetchTransaction() async {
    try {
      loadingStatus = LoadingStatus.loading;
      notifyListeners();
      _transaction = await _transactionsRepository.getTransactionById(
          transactionID: transaction.dbID);
      _getProject();
      loadingStatus = LoadingStatus.completed;
    } catch (e) {
      errorText = "Failed to fetch transaction";
      loadingStatus = LoadingStatus.error;
    }
    notifyListeners();
  }
}
