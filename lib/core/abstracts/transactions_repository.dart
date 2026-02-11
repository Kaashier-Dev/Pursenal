import 'package:pursenal/core/enums/voucher_type.dart';
import 'package:pursenal/core/models/domain/account.dart';
import 'package:pursenal/core/models/domain/profile.dart';
import 'package:pursenal/core/models/domain/project.dart';
import 'package:pursenal/core/models/domain/transaction.dart';

abstract class TransactionsRepository {
  Future<int> insertTransaction(
      {required DateTime vchDate,
      required String narr,
      required String refNo,
      required Account dr,
      required Account cr,
      required int amount,
      required VoucherType vchType,
      required Profile profile,
      Project? project});

  Future<bool> updateTransaction(
      {required int id,
      required DateTime vchDate,
      required String narr,
      required String refNo,
      required Account dr,
      required Account cr,
      required int amount,
      required VoucherType vchType,
      required Profile profile,
      Project? project});

  Future<int> delete(int id);

  Future<List<Transaction>> getTransactions(
      {required DateTime startDate,
      required DateTime endDate,
      required int profileId});

  Future<List<Transaction>> getTransactionsbyAccount(
      {required DateTime startDate,
      required DateTime endDate,
      required int profileId,
      required int accountId,
      reversed = true});

  Future<int?> getLastTransactionID();

  Future<List<Transaction>> getNTransactions(
      {required int n, required int profileId});

  Future<Transaction> getTransactionById({required int transactionID});

  Future<List<Transaction>> getTransactionsbyProject({
    required int profileID,
    required int projectID,
  });
}
