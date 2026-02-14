import 'package:flutter/foundation.dart';
import 'package:pursenal/core/abstracts/abstract_repositories.dart';
import 'package:pursenal/core/abstracts/profiles_repository.dart';
import 'package:pursenal/core/db/app_drift_database.dart';
import 'package:pursenal/core/repositories/drift/drift_repositories.dart';
import 'package:pursenal/providers/profile_provider.dart';

class RepositoryRegistry {
  final AppDriftDatabase _database;
  final ProfileProvider _profileProvider;

  // Cache for repository instances
  final Map<Type, dynamic> _driftCache = {};
  final Map<Type, dynamic> _httpCache = {};

  RepositoryRegistry({
    required AppDriftDatabase database,
    required ProfileProvider profileProvider,
  })  : _database = database,
        _profileProvider = profileProvider {}

  /// Get repository based on current profile
  T get<T>() {
    return _getDrift<T>();
  }

  /// Always get Drift version (for offline-specific operations)
  T getDrift<T>() {
    return _getDrift<T>();
  }

  T _getDrift<T>() {
    if (_driftCache.containsKey(T)) {
      return _driftCache[T] as T;
    }

    final repo = _createDriftRepo<T>();
    _driftCache[T] = repo;
    return repo;
  }

  dynamic _createDriftRepo<T>() {
    // Register all your Drift repositories here
    switch (T) {
      case AccountTypesRepository:
        return AccountTypesDriftRepository(_database);
      case AccountsRepository:
        return AccountsDriftRepository(_database);
      case BalancesRepository:
        return BalancesDriftRepository(_database);
      case FilePathsRepository:
        return FilePathsDriftRepository(_database);
      case BanksRepository:
        return BanksDriftRepository(_database);
      case BudgetsRepository:
        return BudgetsDriftRepository(_database);
      case CreditCardsRepository:
        return CCardsDriftRepository(_database);
      case LoansRepository:
        return LoansDriftRepository(_database);
      case PaymentRemindersRepository:
        return PaymentRemindersDriftRepository(_database);
      case PeopleRepository:
        return PeopleDriftRepository(_database);
      case ProjectsRepository:
        return ProjectsDriftRepository(_database);
      case ReceivablesRepository:
        return ReceivablesDriftRepository(_database);
      case TransactionsRepository:
        return TransactionsDriftRepository(_database);
      case WalletsRepository:
        return WalletsDriftRepository(_database);

      default:
        throw UnimplementedError('No Drift repository registered for $T');
    }
  }

  void clearCache() {
    _disposeCache(_driftCache);
    _disposeCache(_httpCache);
    _driftCache.clear();
    _httpCache.clear();
  }

  void _disposeCache(Map<Type, dynamic> cache) {
    // for (final repo in cache.values) {
    //   if (repo is Disposable) {
    //     try {
    //       repo.dispose();
    //     } catch (e) {
    //       debugPrint('Error disposing repository: $e');
    //     }
    //   }
    // }
  }

  void dispose() {
    clearCache();
  }
}
