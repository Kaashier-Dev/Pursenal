import 'dart:io';
import 'package:collection/collection.dart';
import 'package:drift/drift.dart';
import 'package:drift/isolate.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pursenal/app/global/values.dart';
import 'package:pursenal/core/enums/budget_interval.dart';
import 'package:pursenal/core/enums/currency.dart';
import 'package:pursenal/core/enums/db_table_type.dart';
import 'package:pursenal/core/enums/payment_status.dart';
import 'package:pursenal/core/enums/primary_type.dart';
import 'package:pursenal/core/enums/project_status.dart';
import 'package:pursenal/core/enums/voucher_type.dart';
import 'package:pursenal/core/models/drift/models.dart';
import 'package:pursenal/utils/app_logger.dart';
import 'package:pursenal/utils/db_key_gen.dart';
import 'package:pursenal/utils/db_utils.dart';
import 'package:tuple/tuple.dart';
import 'package:uuid/uuid.dart';
import 'package:path/path.dart' as p;
import 'package:sqlite3/sqlite3.dart';

part 'app_drift_database.g.dart';

@DriftDatabase(tables: [
  DriftAccTypes,
  DriftAccounts,
  DriftTransactions,
  DriftUsers,
  DriftBanks,
  DriftWallets,
  DriftLoans,
  DriftCCards,
  DriftBalances,
  DriftProfiles,
  DriftBudgets,
  DriftBudgetAccounts,
  DriftBudgetFunds,
  DriftProjects,
  DriftReceivables,
  DriftPeople,
  DriftPaymentReminders,
  DriftFilePaths,
])
class AppDriftDatabase extends _$AppDriftDatabase {
  // we tell the database where to store the data with this constructor
  AppDriftDatabase(DatabaseConnection super.connection, this.dbName);

  final String dbName;
  @override
  int get schemaVersion => 6;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON');
    }, onCreate: (Migrator m) async {
      await m.createAll();
      await insertAccType(const DriftAccTypesCompanion(
          id: Value(walletTypeID),
          name: Value("Wallets"),
          primary: Value(PrimaryType.asset)));
      await insertAccType(const DriftAccTypesCompanion(
          id: Value(bankTypeID),
          name: Value("Banks"),
          primary: Value(PrimaryType.asset)));
      await insertAccType(const DriftAccTypesCompanion(
          id: Value(cCardTypeID),
          name: Value("Credit Cards"),
          primary: Value(PrimaryType.liability)));
      await insertAccType(const DriftAccTypesCompanion(
          id: Value(loanTypeID),
          name: Value("Loans"),
          primary: Value(PrimaryType.liability)));
      await insertAccType(const DriftAccTypesCompanion(
          id: Value(incomeTypeID),
          name: Value("Incomes"),
          primary: Value(PrimaryType.income)));
      await insertAccType(const DriftAccTypesCompanion(
          id: Value(expenseTypeID),
          name: Value("Expenses"),
          primary: Value(PrimaryType.expense)));
      await insertAccType(const DriftAccTypesCompanion(
          id: Value(advanceTypeID),
          name: Value("Receivables"),
          primary: Value(PrimaryType.asset)));
      await insertAccType(const DriftAccTypesCompanion(
          id: Value(peopleTypeID),
          name: Value("People"),
          primary: Value(PrimaryType.asset)));

      await insertUser(DriftUsersCompanion(
          name: const Value("User"),
          photoPath: const Value(""),
          deviceID: Value(const Uuid().v4())));
    }, onUpgrade: (Migrator m, int from, int to) async {
      if (from == 1) {
        await m.deleteTable('drift_subscriptions');
        await m.createTable(driftPaymentReminders);
        await m.createTable(driftFilePaths);
      }
      if (from < 3) {
        // 2. Migrate data from DriftProjectPhotos
        await customStatement('''
        INSERT INTO drift_file_paths (table_type, parent_table, path)
        SELECT ${DBTableType.project.index}, project, path FROM drift_project_photos
      ''');

        // 3. Migrate data from DriftTransactionPhotos
        await customStatement('''
            INSERT INTO drift_file_paths (table_type, parent_table, path)
            SELECT 0, "transaction", path FROM drift_transaction_photos;
      ''');

        // 4. Drop the old tables
        await m.deleteTable('drift_project_photos');
        await m.deleteTable('drift_transaction_photos');
      }

      if (from < 4) {
        if ((await select(driftUsers).get()).isEmpty) {
          await insertUser(DriftUsersCompanion(
              name: const Value("User"),
              photoPath: const Value(""),
              deviceID: Value(const Uuid().v4())));
        }
      }

      if (from < 6) {
        final rows = await select(driftFilePaths).get();
        for (final row in rows) {
          final filename = p.basename(row.path);
          await (update(driftFilePaths)..where((tbl) => tbl.id.equals(row.id)))
              .write(DriftFilePathsCompanion(path: Value(filename)));
        }
      }
    });
  }

  Future<void> deleteAll(int id) async {
    await (delete(driftTransactions)).go();
    await (delete(driftAccounts)).go();
    await (delete(driftAccTypes)).go();
  }

  Future<List<DriftAccType>> getAccTypes() async {
    return await select(driftAccTypes).get();
  }

  Future<DriftAccType> getAccTypeById(int id) async {
    return await (select(driftAccTypes)..where((tbl) => tbl.id.equals(id)))
        .getSingle();
  }

  Future<DriftAccType> getAccTypeByType(int type) async {
    return await (select(driftAccTypes)
          ..where((tbl) => tbl.primary.equals(type)))
        .getSingle();
  }

  // Future<bool> updateAccType(DriftAccTypesCompanion companion) async {
  //   return await update(driftAccTypes).replace(companion);
  // }

  Future<int> insertAccType(DriftAccTypesCompanion companion) async {
    return await into(driftAccTypes).insert(companion);
  }

  // Future<int> deleteAccType(int id) async {
  //   return await (delete(driftAccTypes)..where((tbl) => tbl.id.equals(id))).go();
  // }

  Future<DriftAccount> getAccountbyId(int id) async {
    return await (select(driftAccounts)..where((tbl) => tbl.id.equals(id)))
        .getSingle();
  }

  Future<void> insertAccounts(List<DriftAccountsCompanion> accountsList) async {
    await transaction(() async {
      final insertedIds = <int>[];

      for (final account in accountsList) {
        // Check if the account already exists for the profile
        final existingAccount = await (select(driftAccounts)
              ..where((a) => a.name.equals(account.name.value))
              ..where((a) => a.profile.equals(account.profile.value)))
            .getSingleOrNull();

        if (existingAccount == null) {
          // Insert if no duplicate exists
          final id = await into(driftAccounts).insert(account);
          insertedIds.add(id);
        }
      }

      // Insert driftBalances for newly added driftAccounts
      if (insertedIds.isNotEmpty) {
        final balancesList = insertedIds.map((accountId) {
          return DriftBalancesCompanion(
            account: Value(accountId),
            amount: const Value(0),
          );
        }).toList();

        await batch((batch) {
          batch.insertAll(driftBalances, balancesList);
        });
      }
    });
  }

  Future<List<DriftAccount>> getAccountsByProfile(int id) async {
    return await (select(driftAccounts)
          ..where((tbl) => tbl.profile.equals(id))
          ..orderBy([(tbl) => OrderingTerm(expression: tbl.name)]))
        .get();
  }

  Future<List<DriftAccount>> getAccountsByAccType(int id, int accType) async {
    return await (select(driftAccounts)
          ..where((tbl) => tbl.profile.equals(id) & tbl.accType.equals(accType))
          ..orderBy([(tbl) => OrderingTerm(expression: tbl.name)]))
        .get();
  }

  Future<List<DriftAccount>> getFundingAccounts(int profile) async {
    return await (select(driftAccounts)
          ..where((tbl) =>
              tbl.profile.equals(profile) & tbl.accType.isIn(fundingAccountIDs))
          ..orderBy([(tbl) => OrderingTerm(expression: tbl.name)]))
        .get();
  }

  Future<List<DriftAccount>> getAccountsByCategory(
      {required int profileID, required List<int> accTypeIDs}) async {
    return await (select(driftAccounts)
          ..where((tbl) =>
              tbl.profile.equals(profileID) & tbl.accType.isIn(accTypeIDs))
          ..orderBy([(tbl) => OrderingTerm(expression: tbl.name)]))
        .get();
  }

  Future<List<DriftAccount>> getFundAccounts(int profile) async {
    return await (select(driftAccounts)
          ..where(
              (tbl) => tbl.profile.equals(profile) & tbl.accType.isIn(fundIDs))
          ..orderBy([(tbl) => OrderingTerm(expression: tbl.name)]))
        .get();
  }

  Future<List<DriftAccount>> getCreditAccounts(int profile) async {
    return await (select(driftAccounts)
          ..where((tbl) =>
              tbl.profile.equals(profile) & tbl.accType.isIn(creditIDs))
          ..orderBy([(tbl) => OrderingTerm(expression: tbl.name)]))
        .get();
  }

  Future<bool> updateAccount(DriftAccountsCompanion companion) async {
    return await update(driftAccounts).replace(companion);
  }

  Future<int> insertAccount(DriftAccountsCompanion companion) async {
    return await into(driftAccounts).insert(companion);
  }

  Future<int> deleteAccount(int id) async {
    return await (delete(driftAccounts)..where((tbl) => tbl.id.equals(id)))
        .go();
  }

  // Future<DriftTransaction> getTransactionById(int id) async {
  //   return await (select(driftTransactions)..where((tbl) => tbl.id.equals(id)))
  //       .getSingle();
  // }

  Future<bool> updateTransaction(DriftTransactionsCompanion companion) async {
    return await update(driftTransactions).replace(companion);
  }

  Future<int> insertTransaction(DriftTransactionsCompanion companion) async {
    return await into(driftTransactions).insert(companion);
  }

  Future<int> deleteTransaction(int id) async {
    await deleteFilePathByParentID(id);
    return await (delete(driftTransactions)..where((tbl) => tbl.id.equals(id)))
        .go();
  }

  Future<int> deleteTransactionsByProject(int id) async {
    return await (delete(driftTransactions)
          ..where((tbl) => tbl.project.equals(id)))
        .go();
  }

  Future<List<DriftTransaction>> getTransactionsByProfile(int id) async {
    return await (select(driftTransactions)
          ..where((tbl) => tbl.profile.equals(id)))
        .get();
  }

  Future<List<DriftProfile>> getProfiles() async => select(driftProfiles).get();

  Future<int> insertProfile(DriftProfilesCompanion business) =>
      into(driftProfiles).insert(business);

  Future<bool> updateProfile(DriftProfilesCompanion business) =>
      update(driftProfiles).replace(business);

  Future<int> deleteProfile(int id) =>
      (delete(driftProfiles)..where((tbl) => tbl.id.equals(id))).go();

  Future<DriftProfile> getProfileById(int id) =>
      (select(driftProfiles)..where((tbl) => tbl.id.equals(id))).getSingle();

  Future<DriftProfile?> getSelectedProfile() async {
    final selectedProfile = await (select(driftProfiles)
          ..where((tbl) => tbl.isSelected.equals(true)))
        .getSingleOrNull();
    if (selectedProfile != null) {
      return selectedProfile;
    }
    final firstProfile =
        await (select(driftProfiles)..limit(1)).getSingleOrNull();
    return firstProfile;
  }

  Future<void> setSelectedProfile(int id) async {
    await (update(driftProfiles)..where((tbl) => tbl.isSelected.equals(true)))
        .write(const DriftProfilesCompanion(isSelected: Value(false)));
    await (update(driftProfiles)..where((tbl) => tbl.id.equals(id)))
        .write(const DriftProfilesCompanion(isSelected: Value(true)));
  }

  Future<int> insertBank(DriftBanksCompanion bank) =>
      into(driftBanks).insert(bank);
  Future<bool> updateBank(DriftBanksCompanion bank) =>
      update(driftBanks).replace(bank);
  Future<int> deleteBank(int id) =>
      (delete(driftBanks)..where((t) => t.id.equals(id))).go();
  Future<DriftBank> getBankById(int id) =>
      (select(driftBanks)..where((t) => t.id.equals(id))).getSingle();

  Future<DriftBank> getBankByAccount(int id) =>
      (select(driftBanks)..where((t) => t.account.equals(id))).getSingle();

  Future<int> insertCCard(DriftCCardsCompanion card) =>
      into(driftCCards).insert(card);
  Future<bool> updateCCard(DriftCCardsCompanion card) =>
      update(driftCCards).replace(card);
  Future<int> deleteCCard(int id) =>
      (delete(driftCCards)..where((t) => t.id.equals(id))).go();
  Future<DriftCCard> getCCardById(int id) =>
      (select(driftCCards)..where((t) => t.id.equals(id))).getSingle();
  Future<DriftCCard> getCCardByAccount(int id) =>
      (select(driftCCards)..where((t) => t.account.equals(id))).getSingle();

  Future<int> insertLoan(DriftLoansCompanion loan) =>
      into(driftLoans).insert(loan);
  Future<bool> updateLoan(DriftLoansCompanion loan) =>
      update(driftLoans).replace(loan);
  Future<int> deleteLoan(int id) =>
      (delete(driftLoans)..where((t) => t.id.equals(id))).go();
  Future<DriftLoan> getLoanById(int id) =>
      (select(driftLoans)..where((t) => t.id.equals(id))).getSingle();
  Future<DriftLoan> getLoanByAccount(int id) =>
      (select(driftLoans)..where((t) => t.account.equals(id))).getSingle();

  Future<int> insertWallet(DriftWalletsCompanion wallet) =>
      into(driftWallets).insert(wallet);
  Future<bool> updateWallet(DriftWalletsCompanion wallet) =>
      update(driftWallets).replace(wallet);
  Future<int> deleteWallet(int id) =>
      (delete(driftWallets)..where((t) => t.id.equals(id))).go();
  Future<DriftWallet> getWalletById(int id) =>
      (select(driftWallets)..where((t) => t.id.equals(id))).getSingle();
  Future<DriftWallet> getWalletByAccount(int id) =>
      (select(driftWallets)..where((t) => t.account.equals(id))).getSingle();

  Future<int> insertBalance(DriftBalancesCompanion balance) =>
      into(driftBalances).insert(balance);
  Future<bool> updateBalance(DriftBalancesCompanion balance) =>
      update(driftBalances).replace(balance);
  Future<int> deleteBalance(int id) =>
      (delete(driftBalances)..where((t) => t.id.equals(id))).go();
  Future<DriftBalance> getBalanceById(int id) =>
      (select(driftBalances)..where((t) => t.id.equals(id))).getSingle();
  Future<DriftBalance> getBalanceByAccount(int id) =>
      (select(driftBalances)..where((t) => t.account.equals(id))).getSingle();

  Future<
      List<
          Tuple5<DriftTransaction, DriftAccount, DriftAccount,
              List<DriftFilePath>, DriftProject?>>> getTransactions({
    required DateTime startDate,
    required DateTime endDate,
    required int profileId,
  }) async {
    // Aliases for 'dr' and 'cr' accounts
    final drAccounts = alias(driftAccounts, 'drAccounts');
    final crAccounts = alias(driftAccounts, 'crAccounts');

    // Join transactions with dr/cr accounts
    final query = select(driftTransactions).join([
      leftOuterJoin(drAccounts, drAccounts.id.equalsExp(driftTransactions.dr)),
      leftOuterJoin(crAccounts, crAccounts.id.equalsExp(driftTransactions.cr)),
    ])
      ..where(
        driftTransactions.vchDate.isBetweenValues(startDate, endDate) &
            driftTransactions.profile.equals(profileId),
      )
      ..orderBy([OrderingTerm.desc(driftTransactions.vchDate)]);

    final transactionResults = await query.get();

    // Extract transaction IDs to fetch related file paths
    final transactionIds = transactionResults
        .map((row) => row.readTable(driftTransactions).id)
        .toList();

    // Fetch file paths where tableType is transaction
    final filePathResults = await (select(driftFilePaths)
          ..where((fp) =>
              fp.tableType.equals(DBTableType.transaction.index) &
              fp.parentTable.isIn(transactionIds)))
        .get();

    // Map transaction ID to its related file paths
    final filePathMap = <int, List<DriftFilePath>>{};
    for (final fp in filePathResults) {
      filePathMap.putIfAbsent(fp.parentTable, () => []).add(fp);
    }

    final allProjects = await getProjectsByProfile(profileId);

    // Build final result list
    return transactionResults.map((row) {
      final transaction = row.readTable(driftTransactions);
      final drAccount = row.readTable(drAccounts);
      final crAccount = row.readTable(crAccounts);

      return Tuple5(
        transaction,
        drAccount,
        crAccount,
        filePathMap[transaction.id] ?? [],
        allProjects.firstWhereOrNull((p) => p.id == transaction.project),
      );
    }).toList();
  }

  Future<
      Tuple5<DriftTransaction, DriftAccount, DriftAccount, List<DriftFilePath>,
          DriftProject?>> getTransactionById(int transactionId) async {
    // Define aliases for driftAccounts table to handle 'dr' and 'cr'
    final drAccounts = alias(driftAccounts, 'drAccounts');
    final crAccounts = alias(driftAccounts, 'crAccounts');

    // Query to fetch the transaction and its related driftAccounts
    final query = select(driftTransactions).join([
      leftOuterJoin(drAccounts, drAccounts.id.equalsExp(driftTransactions.dr)),
      leftOuterJoin(crAccounts, crAccounts.id.equalsExp(driftTransactions.cr)),
    ])
      ..where(driftTransactions.id.equals(transactionId));

    // Get the transaction result
    final row = await query.getSingle();

    // Query to fetch all file paths related to the transaction ID using DriftFilePaths
    final filePathResults = await (select(driftFilePaths)
          ..where((fp) =>
              fp.tableType.equals(DBTableType.transaction.index) &
              fp.parentTable.equals(transactionId)))
        .get();

    // Read transaction and accounts from the joined result
    final transaction = row.readTable(driftTransactions);
    final drAccount = row.readTable(drAccounts);
    final crAccount = row.readTable(crAccounts);

    // Fetch associated project if available
    final project = transaction.project != null
        ? await (select(driftProjects)
              ..where((tbl) => tbl.id.equals(transaction.project!)))
            .getSingleOrNull()
        : null;

    return Tuple5(transaction, drAccount, crAccount, filePathResults, project);
  }

  Future<
      List<
          Tuple5<
              DriftTransaction,
              DriftAccount,
              DriftAccount,
              List<DriftFilePath>,
              DriftProject?>>> getNTransactions(int n, int profileId) async {
    // Define aliases for driftAccounts table to handle 'dr' and 'cr'
    final drAccounts = alias(driftAccounts, 'drAccounts');
    final crAccounts = alias(driftAccounts, 'crAccounts');

    // Query to fetch driftTransactions and their related driftAccounts
    final query = select(driftTransactions).join([
      leftOuterJoin(drAccounts, drAccounts.id.equalsExp(driftTransactions.dr)),
      leftOuterJoin(crAccounts, crAccounts.id.equalsExp(driftTransactions.cr)),
    ])
      ..where(driftTransactions.profile.equals(profileId))
      ..orderBy([OrderingTerm.desc(driftTransactions.vchDate)])
      ..limit(n);

    // Get transaction results
    final transactionResults = await query.get();

    // Extract transaction IDs to fetch related file paths
    final transactionIds = transactionResults
        .map((row) => row.readTable(driftTransactions).id)
        .toList();

    // Query to fetch all file paths from DriftFilePaths for those transactions
    final filePathResults = await (select(driftFilePaths)
          ..where((fp) =>
              fp.tableType.equals(DBTableType.transaction.index) &
              fp.parentTable.isIn(transactionIds)))
        .get();

    // Map transaction ID to its related file paths
    final filePathMap = <int, List<DriftFilePath>>{};
    for (final filePath in filePathResults) {
      filePathMap.putIfAbsent(filePath.parentTable, () => []).add(filePath);
    }

    final allProjects = await getProjectsByProfile(profileId);

    // Map the results to the Tuple5
    return transactionResults.map((row) {
      final transaction = row.readTable(driftTransactions);
      final drAccount = row.readTable(drAccounts);
      final crAccount = row.readTable(crAccounts);

      return Tuple5(
        transaction,
        drAccount,
        crAccount,
        filePathMap[transaction.id] ?? [],
        allProjects.firstWhereOrNull((p) => p.id == transaction.project),
      );
    }).toList();
  }

  Future<
      List<
          Tuple5<DriftTransaction, DriftAccount, DriftAccount,
              List<DriftFilePath>, DriftProject?>>> getTransactionsByAccount({
    required DateTime startDate,
    required DateTime endDate,
    required int profileId,
    required int accountId,
    bool reversed = true,
  }) async {
    // Define aliases for driftAccounts table to handle 'dr' and 'cr'
    final drAccounts = alias(driftAccounts, 'drAccounts');
    final crAccounts = alias(driftAccounts, 'crAccounts');

    // Query to fetch driftTransactions and their related driftAccounts
    final query = select(driftTransactions).join([
      leftOuterJoin(drAccounts, drAccounts.id.equalsExp(driftTransactions.dr)),
      leftOuterJoin(crAccounts, crAccounts.id.equalsExp(driftTransactions.cr)),
    ])
      ..where(
        driftTransactions.vchDate.isBetweenValues(startDate, endDate) &
            driftTransactions.profile.equals(profileId) &
            (driftTransactions.dr.equals(accountId) |
                driftTransactions.cr.equals(accountId)),
      )
      ..orderBy([
        reversed
            ? OrderingTerm.desc(driftTransactions.vchDate)
            : OrderingTerm.asc(driftTransactions.vchDate),
      ]);

    // Get transaction results
    final transactionResults = await query.get();

    // Extract transaction IDs to fetch related file paths
    final transactionIds = transactionResults
        .map((row) => row.readTable(driftTransactions).id)
        .toList();

    // Query to fetch all file paths related to the transaction IDs
    final filePathResults = await (select(driftFilePaths)
          ..where((fp) =>
              fp.tableType.equals(DBTableType.transaction.index) &
              fp.parentTable.isIn(transactionIds)))
        .get();

    // Map transaction ID to its related file paths
    final filePathMap = <int, List<DriftFilePath>>{};
    for (final filePath in filePathResults) {
      filePathMap.putIfAbsent(filePath.parentTable, () => []).add(filePath);
    }

    final allProjects = await getProjectsByProfile(profileId);

    // Map the results to the Tuple5
    return transactionResults.map((row) {
      final transaction = row.readTable(driftTransactions);
      final drAccount = row.readTable(drAccounts);
      final crAccount = row.readTable(crAccounts);

      return Tuple5(
        transaction,
        drAccount,
        crAccount,
        filePathMap[transaction.id] ?? [],
        allProjects.firstWhereOrNull((p) => p.id == transaction.project),
      );
    }).toList();
  }

  Future<List<Tuple3<DriftAccount, DriftAccType, DriftBalance>>> getLedgers(
      {required int profileId}) async {
    final query = select(driftAccounts).join([
      innerJoin(
          driftAccTypes, driftAccTypes.id.equalsExp(driftAccounts.accType)),
      leftOuterJoin(
          driftBalances, driftBalances.account.equalsExp(driftAccounts.id)),
    ])
      ..where(driftAccounts.profile.equals(profileId));

    final results = await query.get();

    return results.map((row) {
      final account = row.readTable(driftAccounts);
      final accType = row.readTable(driftAccTypes);
      final balance = row.readTable(driftBalances);

      return Tuple3(
        account,
        accType,
        balance,
      );
    }).toList();
  }

  Future<List<Tuple3<DriftAccount, DriftAccType, DriftBalance>>>
      getLedgersByAccType(
          {required int profileId, required int accTypeID}) async {
    final query = select(driftAccounts).join([
      innerJoin(
          driftAccTypes, driftAccTypes.id.equalsExp(driftAccounts.accType)),
      leftOuterJoin(
          driftBalances, driftBalances.account.equalsExp(driftAccounts.id)),
    ])
      ..where(driftAccounts.profile.equals(profileId) &
          driftAccounts.accType.equals(accTypeID));

    final results = await query.get();

    return results.map((row) {
      final account = row.readTable(driftAccounts);
      final accType = row.readTable(driftAccTypes);
      final balance = row.readTable(driftBalances);

      return Tuple3(
        account,
        accType,
        balance,
      );
    }).toList();
  }

  Future<List<Tuple3<DriftAccount, DriftAccType, DriftBalance>>>
      getLedgersByCategory(
          {required int profileId, required List<int> accTypeIDs}) async {
    final query = select(driftAccounts).join([
      innerJoin(
          driftAccTypes, driftAccTypes.id.equalsExp(driftAccounts.accType)),
      leftOuterJoin(
          driftBalances, driftBalances.account.equalsExp(driftAccounts.id)),
    ])
      ..where(driftAccounts.profile.equals(profileId) &
          driftAccounts.accType.isIn(accTypeIDs));

    final results = await query.get();

    return results.map((row) {
      final account = row.readTable(driftAccounts);
      final accType = row.readTable(driftAccTypes);
      final balance = row.readTable(driftBalances);

      return Tuple3(
        account,
        accType,
        balance,
      );
    }).toList();
  }

  // Future<List<Ledger>> getCredits({required int profileId}) async {
  //   final query = select(driftAccounts).join([
  //     innerJoin(
  //         driftAccTypes, driftAccTypes.id.equalsExp(driftAccounts.accType)),
  //     leftOuterJoin(
  //         driftBalances, driftBalances.account.equalsExp(driftAccounts.id)),
  //   ])
  //     ..where(driftAccounts.profile.equals(profileId) &
  //         driftAccounts.accType.isIn(creditIDs));

  //   final results = await query.get();

  //   return results.map((row) {
  //     final account = row.readTable(driftAccounts);
  //     final accType = row.readTable(driftAccTypes);
  //     final balance = row.readTable(driftBalances);

  //     return Ledger(
  //       account: account,
  //       accType: accType,
  //       balance: balance,
  //     );
  //   }).toList();
  // }

  // Future<List<Ledger>> getFundingLedgers({required int profileId}) async {
  //   final query = select(driftAccounts).join([
  //     innerJoin(
  //         driftAccTypes, driftAccTypes.id.equalsExp(driftAccounts.accType)),
  //     leftOuterJoin(
  //         driftBalances, driftBalances.account.equalsExp(driftAccounts.id)),
  //   ])
  //     ..where(driftAccounts.profile.equals(profileId) &
  //         driftAccounts.accType.isIn(fundingAccountIDs));

  //   final results = await query.get();

  //   return results.map((row) {
  //     final account = row.readTable(driftAccounts);
  //     final accType = row.readTable(driftAccTypes);
  //     final balance = row.readTable(driftBalances);

  //     return Ledger(
  //       account: account,
  //       accType: accType,
  //       balance: balance,
  //     );
  //   }).toList();
  // }

  Future<List<DriftAccType>> getFundAccTypes() async {
    return await (select(driftAccTypes)..where((a) => a.id.isIn(fundIDs)))
        .get();
  }

  Future<List<DriftAccType>> getCreditAccTypes() async {
    return await (select(driftAccTypes)..where((a) => a.id.isIn(creditIDs)))
        .get();
  }

  Future<List<DriftAccType>> getFundingAccTypes() async {
    return await (select(driftAccTypes)
          ..where((a) => a.id.isIn(fundingAccountIDs)))
        .get();
  }

  Future<List<DriftAccType>> getAccTypesByCategory(List<int> accTypeIDs) async {
    return await (select(driftAccTypes)..where((a) => a.id.isIn(accTypeIDs)))
        .get();
  }

  Future<List<DriftAccType>> getBalanceAccTypes() async {
    return await (select(driftAccTypes)..where((a) => a.id.isNotIn(incExpIDs)))
        .get();
  }

  Future<int?> getLastTransactionID() async {
    // Query to get the maximum value of the id column
    final query = select(driftTransactions)
      ..orderBy([(t) => OrderingTerm.desc(t.id)])
      ..limit(1);

    final result = await query.getSingleOrNull();
    return result?.id;
  }

  Future<Map<E, DriftAccount>>
      getTableWithAccounts<E extends DataClass, T extends Table>(
    TableInfo<T, E> table,
    Column<int> accountColumn,
  ) async {
    final query = select(table).join([
      innerJoin(driftAccounts, driftAccounts.id.equalsExp(accountColumn)),
    ]);

    final results = await query.get();

    final map = <E, DriftAccount>{};
    for (final row in results) {
      final tableEntry = row.readTable(table);
      final accountEntry = row.readTable(driftAccounts);
      map[tableEntry] = accountEntry;
    }
    return map;
  }

  Future<Map<DriftBank, DriftAccount>> getBanksWithAccounts() {
    return getTableWithAccounts(driftBanks, driftBanks.account);
  }

  Future<Map<DriftWallet, DriftAccount>> getWalletsWithAccounts() {
    return getTableWithAccounts(driftWallets, driftWallets.account);
  }

  Future<Map<DriftLoan, DriftAccount>> getLoansWithAccounts() {
    return getTableWithAccounts(driftLoans, driftLoans.account);
  }

  Future<Map<DriftCCard, DriftAccount>> getCCardsWithAccounts() {
    return getTableWithAccounts(driftCCards, driftCCards.account);
  }

  Future<int> calculateBalance(int accountId) async {
    // Fetch the opening balance from the account table
    final account = await (select(driftAccounts)
          ..where((a) => a.id.equals(accountId)))
        .getSingleOrNull();

    if (account == null) {
      throw Exception("DriftAccount not found");
    }

    final query = customSelect(
      'SELECT '
      'SUM(CASE WHEN dr = ? THEN amount ELSE 0 END) AS totalDebit, '
      'SUM(CASE WHEN cr = ? THEN amount ELSE 0 END) AS totalCredit '
      'FROM drift_transactions',
      variables: [
        Variable.withInt(accountId),
        Variable.withInt(accountId),
      ],
      readsFrom: {driftTransactions},
    );

    final row = await query.getSingle();
    final totalDebit = row.data['totalDebit'] as int? ?? 0;
    final totalCredit = row.data['totalCredit'] as int? ?? 0;

    final openingBalance = account.openBal;
    int closingBalance;

    // Determine account type
    final accountType = account.accType;
    // Adjust closing balance calculation based on account type
    if (DBUtils.isAssetOrExpense(accountType)) {
      // Asset and Expense driftAccounts: Debit increases, Credit decreases
      closingBalance = openingBalance + totalDebit - totalCredit;
    } else if (DBUtils.isLiabilityOrIncome(accountType)) {
      // Liability and Income driftAccounts: Credit increases, Debit decreases
      closingBalance = openingBalance + totalCredit - totalDebit;
    } else {
      throw Exception("Unknown account type");
    }
    return closingBalance;
  }

  Future<int> getFundClosingBalance(DateTime closingDate, int profileID) async {
    // Fetch driftAccounts where accType < 4
    final acc = await (select(driftAccounts)
          ..where((a) => a.accType.isIn(fundIDs) & a.profile.equals(profileID)))
        .get();

    // If no driftAccounts match, return 0
    if (acc.isEmpty) {
      return 0;
    }

    int totalBalance = 0;

    for (var account in acc) {
      // For each account, calculate the closing balance using the previous method
      final closingBalance = await getClosingBalance(account.id, closingDate);
      totalBalance += closingBalance;
    }

    return totalBalance;
  }

  Future<int> getClosingBalance(int accountId, DateTime closingDate) async {
    // Fetch account details
    final account = await (select(driftAccounts)
          ..where((a) => a.id.equals(accountId)))
        .getSingleOrNull();

    if (account == null) {
      throw Exception("DriftAccount not found");
    }

    // If the account was opened after the closing date, just return the opening balance.
    if (account.openDate.isAfter(closingDate)) {
      return account.openBal;
    }

    // Adjust closing date to cover the entire day
    final closingDateLimit =
        closingDate.copyWith(hour: 23, minute: 59, second: 59);

    // Use a single SQL query to sum both debit and credit driftTransactions
    final query = customSelect(
      'SELECT '
      'SUM(CASE WHEN dr = ? THEN amount ELSE 0 END) AS totalDebit, '
      'SUM(CASE WHEN cr = ? THEN amount ELSE 0 END) AS totalCredit '
      'FROM drift_transactions '
      'WHERE vch_date <= ?',
      variables: [
        Variable.withInt(accountId),
        Variable.withInt(accountId),
        Variable.withDateTime(closingDateLimit),
      ],
      readsFrom: {driftTransactions},
    );

    final row = await query.getSingle();
    final totalDebit = row.data['totalDebit'] as int? ?? 0;
    final totalCredit = row.data['totalCredit'] as int? ?? 0;

    final openingBalance = account.openBal;
    int closingBalance;

    // Determine account type
    final accountType = account.accType;
    // Adjust closing balance calculation based on account type
    if (DBUtils.isAssetOrExpense(accountType)) {
      // Asset and Expense driftAccounts: Debit increases, Credit decreases
      closingBalance = openingBalance + totalDebit - totalCredit;
    } else if (DBUtils.isLiabilityOrIncome(accountType)) {
      // Liability and Income driftAccounts: Credit increases, Debit decreases
      closingBalance = openingBalance + totalCredit - totalDebit;
    } else {
      throw Exception("Unknown account type");
    }
    return closingBalance;
  }

  Future<List<DriftTransaction>> getLastNTransactions(int n) async {
    return await (select(driftTransactions)
          ..orderBy(
              [(t) => OrderingTerm.desc(t.vchDate)]) // Order by latest date
          ..limit(n)) // Get last 8 entries
        .get();
  }

  Future<List<DriftBudget>> getBudgets() async {
    return await select(driftBudgets).get();
  }

  Future<DriftBudget> getBudgetbyId(int id) async {
    return await (select(driftBudgets)..where((tbl) => tbl.id.equals(id)))
        .getSingle();
  }

  Future<List<DriftBudget>> getBudgetsByProfile(int id) async {
    return await (select(driftBudgets)
          ..where((tbl) => tbl.profile.equals(id))
          ..orderBy([(tbl) => OrderingTerm(expression: tbl.name)]))
        .get();
  }

  Future<bool> updateBudget(DriftBudgetsCompanion companion) async {
    return await update(driftBudgets).replace(companion);
  }

  Future<int> insertBudget(DriftBudgetsCompanion companion) async {
    return await into(driftBudgets).insert(companion);
  }

  Future<int> deleteBudget(int id) async {
    return await (delete(driftBudgets)..where((tbl) => tbl.id.equals(id))).go();
  }

  Future<List<DriftBudgetFund>> getBudgetFunds() async {
    return await select(driftBudgetFunds).get();
  }

  Future<DriftBudgetFund> getBudgetFundbyId(int id) async {
    return await (select(driftBudgetFunds)..where((tbl) => tbl.id.equals(id)))
        .getSingle();
  }

  Future<List<DriftAccount>> getBudgetFundAccountsByBudget(int id) async {
    final funds = await (select(driftBudgetFunds)
          ..where((tbl) => tbl.budget.equals(id))
          ..orderBy([(tbl) => OrderingTerm(expression: tbl.budget)]))
        .get();

    return await (select(driftAccounts)
          ..where((a) => a.id.isIn(funds.map((f) => f.account))))
        .get();
  }

  Future<bool> updateBudgetFund(DriftBudgetFundsCompanion companion) async {
    return await update(driftBudgetFunds).replace(companion);
  }

  Future<int> insertBudgetFund(DriftBudgetFundsCompanion companion) async {
    return await into(driftBudgetFunds).insert(companion);
  }

  Future<int> deleteBudgetFund(int id) async {
    return await (delete(driftBudgetFunds)..where((tbl) => tbl.id.equals(id)))
        .go();
  }

  Future<int> deleteBudgetFundByBudget(int id) async {
    return await (delete(driftBudgetFunds)
          ..where((tbl) => tbl.budget.equals(id)))
        .go();
  }

  Future<List<DriftBudgetAccount>> getBudgetAccounts() async {
    return await select(driftBudgetAccounts).get();
  }

  Future<DriftBudgetAccount> getBudgetAccountbyId(int id) async {
    return await (select(driftBudgetAccounts)
          ..where((tbl) => tbl.id.equals(id)))
        .getSingle();
  }

  Future<List<DriftBudgetAccount>> getBudgetAccountsByBudget(int id) async {
    return await (select(driftBudgetAccounts)
          ..where((tbl) => tbl.budget.equals(id))
          ..orderBy([(tbl) => OrderingTerm(expression: tbl.budget)]))
        .get();
  }

  Future<bool> updateBudgetAccount(
      DriftBudgetAccountsCompanion companion) async {
    return await update(driftBudgetAccounts).replace(companion);
  }

  Future<int> insertBudgetAccount(
      DriftBudgetAccountsCompanion companion) async {
    return await into(driftBudgetAccounts).insert(companion);
  }

  Future<int> deleteBudgetAccount(int id) async {
    return await (delete(driftBudgetAccounts)
          ..where((tbl) => tbl.id.equals(id)))
        .go();
  }

  Future<int> deleteBudgetAccountByBudget(int id) async {
    return await (delete(driftBudgetAccounts)
          ..where((tbl) => tbl.budget.equals(id)))
        .go();
  }

  Future<Map<DriftAccount, int>> getAccountBalances(
      DateTime startDate, DateTime endDate) async {
    // Fetch all driftTransactions within the date range
    final trx = await (select(driftTransactions)
          ..where((t) => t.vchDate.isBiggerOrEqualValue(startDate))
          ..where((t) => t.vchDate.isSmallerOrEqualValue(endDate)))
        .get();

    // Map to store account driftBalances
    final Map<int, int> accountBalances = {};

    for (var txn in trx) {
      // Add to dr account balance
      accountBalances[txn.dr] = (accountBalances[txn.dr] ?? 0) + txn.amount;
      // Subtract from cr account balance
      accountBalances[txn.cr] = (accountBalances[txn.cr] ?? 0) - txn.amount;
    }

    // Fetch account details for all involved driftAccounts
    final accx = await (select(driftAccounts)
          ..where((a) => a.id.isIn(accountBalances.keys.toList())))
        .get();

    // Convert to Map<DriftAccount, int>
    return {for (var acc in accx) acc: accountBalances[acc.id] ?? 0};
  }

  Future<
      List<
          Tuple4<DriftBudget, List<DriftAccount>, Map<DriftAccount, int>,
              Map<DriftAccount, int>>>> getAllBudgets(int profileID) async {
    final budgetList = await (select(driftBudgets)
          ..where((b) => b.profile.equals(profileID)))
        .get(); // Get all driftBudgets
    List<
        Tuple4<DriftBudget, List<DriftAccount>, Map<DriftAccount, int>,
            Map<DriftAccount, int>>> plans = [];

    for (var budget in budgetList) {
      final funds = await (select(driftAccounts)
            ..where((a) => a.id.isInQuery(selectOnly(driftBudgetFunds)
              ..addColumns([driftBudgetFunds.account])
              ..where(driftBudgetFunds.budget.equals(budget.id)))))
          .get();

      final budgetAccountsList = await (select(driftBudgetAccounts)
            ..where((ba) => ba.budget.equals(budget.id)))
          .get();

      Map<DriftAccount, int> incomes = {};
      Map<DriftAccount, int> expenses = {};

      for (var ba in budgetAccountsList) {
        final account = await (select(driftAccounts)
              ..where((a) => a.id.equals(ba.account)))
            .getSingleOrNull();
        if (account != null) {
          if (ba.amount > 0) {
            incomes[account] = ba.amount;
          } else {
            expenses[account] = ba.amount;
          }
        }
      }

      plans.add(Tuple4(
        budget,
        funds,
        incomes,
        expenses,
      ));
    }

    return plans;
  }

  Future<
      Tuple4<DriftBudget, List<DriftAccount>, Map<DriftAccount, int>,
          Map<DriftAccount, int>>> getBudgetByID(int id) async {
    final budget =
        await (select(driftBudgets)..where((b) => b.id.equals(id))).getSingle();

    final funds = await (select(driftAccounts)
          ..where((a) => a.id.isInQuery(selectOnly(driftBudgetFunds)
            ..addColumns([driftBudgetFunds.account])
            ..where(driftBudgetFunds.budget.equals(budget.id)))))
        .get();

    final budgetAccountsList = await (select(driftBudgetAccounts)
          ..where((ba) => ba.budget.equals(budget.id)))
        .get();

    Map<DriftAccount, int> incomes = {};
    Map<DriftAccount, int> expenses = {};

    for (var ba in budgetAccountsList) {
      final account = await (select(driftAccounts)
            ..where((a) => a.id.equals(ba.account)))
          .getSingleOrNull();
      if (account != null) {
        if (ba.amount > 0) {
          incomes[account] = ba.amount;
        } else {
          expenses[account] = ba.amount;
        }
      }
    }

    return Tuple4(
      budget,
      funds,
      incomes,
      expenses,
    );
  }

  Future<int> insertProject(DriftProjectsCompanion project) =>
      into(driftProjects).insert(project);
  Future<bool> updateProject(DriftProjectsCompanion project) =>
      update(driftProjects).replace(project);
  Future<int> deleteProject(int id, {bool deleteTransactions = false}) async {
    await deleteFilePathByParentID(id);
    return (delete(driftProjects)..where((t) => t.id.equals(id))).go();
  }

  Future<DriftProject> getProjectById(int id) =>
      (select(driftProjects)..where((t) => t.id.equals(id))).getSingle();
  Future<List<DriftProject>> getProjectsByProfile(int id) =>
      (select(driftProjects)..where((t) => t.profile.equals(id))).get();

  Future<Tuple2<DriftProject, List<String>>?> getProjectByID(
      int projectId) async {
    // Fetch the project
    final project = await (select(driftProjects)
          ..where((tbl) => tbl.id.equals(projectId)))
        .getSingleOrNull();

    if (project == null) {
      return null; // DriftProject not found
    }

    // Fetch all related photos
    final photos = await (select(driftFilePaths)
          ..where((tbl) =>
              tbl.parentTable.equals(projectId) &
              tbl.tableType.equals(DBTableType.project.index)))
        .get();

    // Fetch the associated budget (if exists)

    // Construct and return the Project
    return Tuple2(
      project,
      photos.map((p) => p.path).toList(),
    );
  }

  Future<
      List<
          Tuple5<DriftTransaction, DriftAccount, DriftAccount,
              List<DriftFilePath>, DriftProject?>>> getTransactionsByProject({
    required int profileID,
    required int projectID,
    bool reversed = true,
  }) async {
    // Define aliases for driftAccounts table to handle 'dr' and 'cr'
    final drAccounts = alias(driftAccounts, 'drAccounts');
    final crAccounts = alias(driftAccounts, 'crAccounts');

    // Query to fetch driftTransactions and their related driftAccounts
    final query = select(driftTransactions).join([
      leftOuterJoin(drAccounts, drAccounts.id.equalsExp(driftTransactions.dr)),
      leftOuterJoin(crAccounts, crAccounts.id.equalsExp(driftTransactions.cr)),
    ])
      ..where(
        driftTransactions.profile.equals(profileID) &
            driftTransactions.project.equals(projectID),
      )
      ..orderBy([
        reversed
            ? OrderingTerm.desc(driftTransactions.vchDate)
            : OrderingTerm.asc(driftTransactions.vchDate),
      ]);

    // Get transaction results
    final transactionResults = await query.get();

    // Extract transaction IDs
    final transactionIds = transactionResults
        .map((row) => row.readTable(driftTransactions).id)
        .toList();

    // Query to fetch related file paths
    final filePathResults = await (select(driftFilePaths)
          ..where((fp) =>
              fp.tableType.equals(DBTableType.transaction.index) &
              fp.parentTable.isIn(transactionIds)))
        .get();

    // Map transaction ID to its related file paths
    final filePathMap = <int, List<DriftFilePath>>{};
    for (final filePath in filePathResults) {
      filePathMap.putIfAbsent(filePath.parentTable, () => []).add(filePath);
    }

    final allProjects = await getProjectsByProfile(profileID);

    // Map the results to the Tuple5 model
    return transactionResults.map((row) {
      final transaction = row.readTable(driftTransactions);
      final drAccount = row.readTable(drAccounts);
      final crAccount = row.readTable(crAccounts);

      return Tuple5(
        transaction,
        drAccount,
        crAccount,
        filePathMap[transaction.id] ?? [],
        allProjects.firstWhereOrNull((p) => p.id == transaction.project),
      );
    }).toList();
  }

  Future<int> insertReceivable(DriftReceivablesCompanion receivable) =>
      into(driftReceivables).insert(receivable);
  Future<bool> updateReceivable(DriftReceivablesCompanion receivable) =>
      update(driftReceivables).replace(receivable);
  Future<int> deleteReceivable(int id) =>
      (delete(driftReceivables)..where((t) => t.id.equals(id))).go();
  Future<DriftReceivable> getReceivableById(int id) =>
      (select(driftReceivables)..where((t) => t.id.equals(id))).getSingle();
  Future<DriftReceivable> getReceivableByAccount(int id) =>
      (select(driftReceivables)..where((t) => t.accountId.equals(id)))
          .getSingle();

  Future<int> insertPeople(DriftPeopleCompanion people) =>
      into(driftPeople).insert(people);
  Future<bool> updatePeople(DriftPeopleCompanion people) =>
      update(driftPeople).replace(people);
  Future<int> deletePeople(int id) =>
      (delete(driftPeople)..where((t) => t.id.equals(id))).go();
  Future<DriftPeopleData> getPeopleById(int id) =>
      (select(driftPeople)..where((t) => t.id.equals(id))).getSingle();
  Future<DriftPeopleData> getPeopleByAccount(int id) =>
      (select(driftPeople)..where((t) => t.accountId.equals(id))).getSingle();

  Future<int> insertPaymentReminder(
          DriftPaymentRemindersCompanion paymentReminder) =>
      into(driftPaymentReminders).insert(paymentReminder);
  Future<bool> updatePaymentReminder(
          DriftPaymentRemindersCompanion paymentReminder) =>
      update(driftPaymentReminders).replace(paymentReminder);
  Future<int> deletePaymentReminder(int id) async {
    await deleteFilePathByParentID(id);
    return (delete(driftPaymentReminders)..where((t) => t.id.equals(id))).go();
  }

  Future<DriftPaymentReminder> getPaymentReminderById(int id) =>
      (select(driftPaymentReminders)..where((t) => t.id.equals(id)))
          .getSingle();

  Future<
      List<
          Tuple4<DriftPaymentReminder, DriftAccount?, DriftAccount?,
              List<DriftFilePath>>>> getReminders(int profileID) async {
    final reminderAlias = alias(driftPaymentReminders, 'reminder');
    final accountAlias = alias(driftAccounts, 'account');
    final fundAlias = alias(driftAccounts, 'fund');

    // 1. Fetch all reminders with their related accounts (nullable joins)
    final rows = await (select(reminderAlias)
          ..where((r) => r.profile.equals(profileID))
          ..orderBy([
            (r) =>
                OrderingTerm(expression: r.paymentDate, mode: OrderingMode.desc)
          ]))
        .join([
      leftOuterJoin(
          accountAlias, accountAlias.id.equalsExp(reminderAlias.account)),
      leftOuterJoin(fundAlias, fundAlias.id.equalsExp(reminderAlias.fund)),
    ]).get();

    final List<
        Tuple4<DriftPaymentReminder, DriftAccount?, DriftAccount?,
            List<DriftFilePath>>> result = [];

    for (final row in rows) {
      final reminder = row.readTable(reminderAlias);
      final account = row.readTableOrNull(accountAlias);
      final fund = row.readTableOrNull(fundAlias);

      // 2. Fetch the list of file paths for this reminder
      final filePaths = await (select(driftFilePaths)
            ..where((fp) =>
                fp.tableType.equals(DBTableType.paymentReminder.index) &
                fp.parentTable.equals(reminder.id)))
          .get();

      result.add(Tuple4(reminder, account, fund, filePaths));
    }

    return result;
  }

  Future<
      Tuple4<DriftPaymentReminder, DriftAccount?, DriftAccount?,
          List<DriftFilePath>>> getReminder(int id) async {
    final reminderAlias = alias(driftPaymentReminders, 'reminder');
    final accountAlias = alias(driftAccounts, 'account');
    final fundAlias = alias(driftAccounts, 'fund');

    // 1. Fetch all reminders with their related accounts (nullable joins)
    final row = await (select(reminderAlias)
          ..where((r) => r.id.equals(id))
          ..orderBy([
            (r) =>
                OrderingTerm(expression: r.paymentDate, mode: OrderingMode.desc)
          ]))
        .join([
      leftOuterJoin(
          accountAlias, accountAlias.id.equalsExp(reminderAlias.account)),
      leftOuterJoin(fundAlias, fundAlias.id.equalsExp(reminderAlias.fund)),
    ]).getSingle();

    final List<
        Tuple4<DriftPaymentReminder, DriftAccount?, DriftAccount?,
            List<DriftFilePath>>> result = [];

    final reminder = row.readTable(reminderAlias);
    final account = row.readTableOrNull(accountAlias);
    final fund = row.readTableOrNull(fundAlias);

    // 2. Fetch the list of file paths for this reminder
    final filePaths = await (select(driftFilePaths)
          ..where((fp) =>
              fp.tableType.equals(DBTableType.paymentReminder.index) &
              fp.parentTable.equals(reminder.id)))
        .get();

    result.add(Tuple4(reminder, account, fund, filePaths));

    return Tuple4(reminder, account, fund, filePaths);
  }

  Future<int> insertFilePath(DriftFilePathsCompanion filePath) =>
      into(driftFilePaths).insert(filePath);
  Future<bool> updateFilePath(DriftFilePathsCompanion filePath) =>
      update(driftFilePaths).replace(filePath);
  Future<int> deleteFilePath(int id) =>
      (delete(driftFilePaths)..where((t) => t.id.equals(id))).go();
  Future<DriftFilePath> getFilePathById(int id) =>
      (select(driftFilePaths)..where((t) => t.id.equals(id))).getSingle();

  Future<int> insertUser(DriftUsersCompanion user) =>
      into(driftUsers).insert(user);
  Future<bool> updateUser(DriftUsersCompanion user) =>
      update(driftUsers).replace(user);
  Future<DriftUser> getUserById(int id) =>
      (select(driftUsers)..where((t) => t.id.equals(id))).getSingle();

  Future<DriftUser> getUser() => (select(driftUsers)).getSingle();

  Future<int> deleteFilePathByParentID(int id) async {
    final fps = await (select(driftFilePaths)
          ..where((t) => t.parentTable.equals(id)))
        .get();
    // Delete files
    for (final filePath in fps) {
      try {
        final file = File(filePath.path);
        if (await file.exists()) {
          await file.delete();
        }
      } catch (e) {
        AppLogger.instance.error("Cannot delete media file");
      }
    }

    return (delete(driftFilePaths)..where((t) => t.parentTable.equals(id)))
        .go();
  }

  Future<int> deleteFilePathByPath(String path) async {
    try {
      final file = File(path);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      AppLogger.instance.error("Cannot delete media file");
    }

    return (delete(driftFilePaths)..where((t) => t.path.equals(path))).go();
  }

  Future<List<DriftFilePath>> getFilePathByParentId(int id) =>
      (select(driftFilePaths)..where((t) => t.parentTable.equals(id))).get();

  Future<void> exportDatabase(File destination) async {
    if (await destination.exists()) {
      await destination.delete();
    }

    await exclusively(() async {
      final path = destination.path.replaceAll("'", "''");

      await customStatement(
        "ATTACH DATABASE '$path' AS backup KEY '$backupKey';",
      );

      await customStatement(
        "SELECT sqlcipher_export('backup');",
      );

      await customStatement(
        "DETACH DATABASE backup;",
      );
    });
  }

  Future<void> importDatabase(File backupFile) async {
    try {
      await close();
      await File(await _getDatabasePath())
          .writeAsBytes(await backupFile.readAsBytes(), flush: true);
    } catch (e) {
      AppLogger.instance.error("Cannot import database. $e");
    }
  }
}

Future<String> _getDatabasePath() async {
  final appDir = await getApplicationSupportDirectory();
  return p.join(appDir.path, 'db', 'app_drift_database.sqlite');
}

void checkSqliteLibrary() {
  // Open a temporary in-memory database to check the library features
  final tempDb = sqlite3.openInMemory();
  try {
    // sqlite3mc_version() is ONLY available if the hook worked

    final result = tempDb.select('SELECT sqlite3mc_version();');
    AppLogger.instance.info('SUCCESS: Using SQLite3MC ${result.first}');
  } catch (e) {
    AppLogger.instance.error(
        'Encryption library NOT loaded. Current SQLite version: ${sqlite3.version.libVersion}\n$e');
  } finally {
    tempDb.close();
  }
}

Future<bool> _migrateToEncryption(
    String oldPath, String newPath, String password) async {
  Database? plainDb;
  try {
    final newFile = File(newPath);
    if (await newFile.exists()) await newFile.delete();

    plainDb = sqlite3.open(oldPath);

    // 1. Attach the new database with the key
    plainDb.execute("ATTACH DATABASE '$newPath' AS encrypted KEY '$password';");
    plainDb.execute("PRAGMA encrypted.cipher = 'sqlcipher';");

    // 2. Step-by-Step Manual Copy
    // Get all tables from the original DB
    final tables = plainDb.select(
        "SELECT name, sql FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%';");

    for (final row in tables) {
      final tableName = row['name'] as String;
      final createSql = row['sql'] as String;

      // Recreate the table in the 'encrypted' schema
      // We replace 'CREATE TABLE "' with 'CREATE TABLE encrypted."'
      final encryptedCreateSql =
          createSql.replaceFirst('CREATE TABLE ', 'CREATE TABLE encrypted.');
      plainDb.execute(encryptedCreateSql);

      // Copy the data
      plainDb.execute(
          "INSERT INTO encrypted.$tableName SELECT * FROM main.$tableName;");
      AppLogger.instance.info("Migrated table: $tableName");
    }

    // 3. Transfer the schema version (Crucial for Drift)
    final versionRow = plainDb.select('PRAGMA user_version;').first;
    final version = versionRow.columnAt(0) as int;
    plainDb.execute("PRAGMA encrypted.user_version = $version;");

    // 4. Verify before finishing
    final check = plainDb.select(
        "SELECT name FROM encrypted.sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%';");
    AppLogger.instance
        .info("Final Table Count in Encrypted DB: ${check.length}");

    plainDb.execute("DETACH DATABASE encrypted;");
    return true;
  } catch (e) {
    AppLogger.instance.error('Manual Migration failed: $e');
    return false;
  } finally {
    plainDb?.close();
  }
}

Future<DatabaseConnection> getIsolateDBConnection() async {
  try {
    final appDir = await getApplicationSupportDirectory();
    final plainDBPath = p.join(appDir.path, 'db', 'app_drift_database.sqlite');
    final encryptedDBPath = p.join(appDir.path, 'db', 'pursenal_db.sqlite');

    String password = await getOrGenerateKey();
    bool existsPlain = await File(plainDBPath).exists();
    bool existsEncrypted = await File(encryptedDBPath).exists();
    bool isMigrated = false;

    if (existsPlain) {
      if (!existsEncrypted) {
        checkSqliteLibrary();
        isMigrated =
            await _migrateToEncryption(plainDBPath, encryptedDBPath, password);

        if (isMigrated) await _deleteDB(plainDBPath);
      } else {
        isMigrated = true;
      }
    }

    // Determine final path and pass password as string
    final finalPath =
        (existsPlain & !isMigrated) ? plainDBPath : encryptedDBPath;
    final finalPass = (finalPath == encryptedDBPath) ? password : 'null';

    // IMPORTANT: Pass the arguments as a list to the spawn function
    final isolate = await DriftIsolate.spawn(
      () => _backgroundConnection([finalPath, finalPass]),
    );
    return await isolate.connect();
  } catch (e) {
    AppLogger.instance.error(' ${e.toString()}');
    rethrow;
  }
}

Future<void> _deleteDB(String path) async {
  try {
    await File(path).delete();
  } catch (e) {
    AppLogger.instance.error(' ${e.toString()}');
    rethrow;
  }
}

DatabaseConnection _backgroundConnection(List<String> args) {
  final path = args[0];
  final password = args[1]; // This will be 'null' as a string if no password

  return DatabaseConnection(
    NativeDatabase.createInBackground(
      File(path),
      setup: password == 'null'
          ? null
          : (rawDb) {
              rawDb.execute("PRAGMA key = '$password';");
            },
    ),
  );
}
