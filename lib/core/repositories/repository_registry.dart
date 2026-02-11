import 'package:flutter/foundation.dart';
import 'package:pursenal/core/abstracts/abstract_repositories.dart';
import 'package:pursenal/core/abstracts/paired_device_repository.dart';
import 'package:pursenal/core/abstracts/profiles_repository.dart';
import 'package:pursenal/core/db/app_drift_database.dart';
import 'package:pursenal/core/repositories/drift/drift_repositories.dart';
import 'package:pursenal/core/repositories/drift/paired_device_drift_repository.dart';
import 'package:pursenal/core/repositories/proto/profiles_proto_repository.dart';
import 'package:pursenal/core/repositories/proto/proto_repositories.dart';
import 'package:pursenal/providers/profile_provider.dart';
import 'package:pursenal/utils/proto_http_client.dart';

class RepositoryRegistry {
  final AppDriftDatabase _database;
  final ProfileProvider _profileProvider;
  final ProtoHttpClient _http;
  final String serverAddress;

  // Cache for repository instances
  final Map<Type, dynamic> _driftCache = {};
  final Map<Type, dynamic> _httpCache = {};

  ProtoHttpClient get http => _http;

  RepositoryRegistry({
    required AppDriftDatabase database,
    required ProfileProvider profileProvider,
    required this.serverAddress,
  })  : _database = database,
        _profileProvider = profileProvider,
        _http = ProtoHttpClient(baseUrl: serverAddress) {
    print("building RepositoryRegistry with server address: $serverAddress");
  }

  /// Get repository based on current profile
  T get<T>() {
    return _profileProvider.isOnline ? _getHttp<T>() : _getDrift<T>();
  }

  /// Always get Drift version (for offline-specific operations)
  T getDrift<T>() {
    return _getDrift<T>();
  }

  /// Always get HTTP version (for online-specific operations)
  T getHttp<T>() {
    return _getHttp<T>();
  }

  T _getDrift<T>() {
    if (_driftCache.containsKey(T)) {
      return _driftCache[T] as T;
    }

    final repo = _createDriftRepo<T>();
    _driftCache[T] = repo;
    return repo;
  }

  T _getHttp<T>() {
    if (_httpCache.containsKey(T)) {
      return _httpCache[T] as T;
    }

    final repo = _createHttpRepo<T>();
    _httpCache[T] = repo;
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
      case PairedDeviceRepository:
        return PairedDeviceDriftRepository(_database);
      default:
        throw UnimplementedError('No Drift repository registered for $T');
    }
  }

  dynamic _createHttpRepo<T>() {
    // Register all your HTTP repositories here
    switch (T) {
      case AccountTypesRepository:
        return AccountTypesProtoRepository(http: _http);
      case AccountsRepository:
        return AccountsProtoRepository(http: _http);
      case BalancesRepository:
        return BalancesProtoRepository(http: _http);
      case FilePathsRepository:
        return FilePathsProtoRepository(http: _http);
      case BanksRepository:
        return BanksProtoRepository(http: _http);
      case BudgetsRepository:
        return BudgetsProtoRepository(http: _http);
      case CreditCardsRepository:
        return CCardsProtoRepository(http: _http);
      case LoansRepository:
        return LoansProtoRepository(http: _http);
      case PaymentRemindersRepository:
        return PaymentRemindersProtoRepository(http: _http);
      case PeopleRepository:
        return PeopleProtoRepository(http: _http);
      case ProjectsRepository:
        return ProjectsProtoRepository(http: _http);
      case ReceivablesRepository:
        return ReceivablesProtoRepository(http: _http);
      case TransactionsRepository:
        return TransactionsProtoRepository(http: _http);
      case WalletsRepository:
        return WalletsProtoRepository(http: _http);
      case ProfilesRepository:
        return ProfilesProtoRepository(http: _http);

      default:
        throw UnimplementedError('No HTTP repository registered for $T');
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
