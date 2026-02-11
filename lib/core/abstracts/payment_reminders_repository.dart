import 'package:pursenal/core/enums/budget_interval.dart';
import 'package:pursenal/core/enums/payment_status.dart';
import 'package:pursenal/core/models/domain/account.dart';
import 'package:pursenal/core/models/domain/payment_reminder.dart';
import 'package:pursenal/core/models/domain/profile.dart';

abstract class PaymentRemindersRepository {
  Future<int> insertPaymentReminder({
    Account? account,
    required Profile profile,
    PaymentStatus status = PaymentStatus.pending,
    required int amount,
    BudgetInterval? interval,
    required String details,
    DateTime? paymentDate,
    Account? fund,
    int day = 1,
  });

  Future<bool> updatePaymentReminder({
    required int id,
    Account? account,
    required Profile profile,
    PaymentStatus status = PaymentStatus.pending,
    required int amount,
    BudgetInterval? interval,
    required String details,
    DateTime? paymentDate,
    Account? fund,
    int day = 1,
  });

  Future<bool> updatePaymentReminderStatus({
    required int id,
    Account? account,
    required Profile profile,
    PaymentStatus status = PaymentStatus.pending,
    required int amount,
    BudgetInterval? interval,
    required String details,
    DateTime? paymentDate,
    Account? fund,
    int day = 1,
  });

  Future<int> delete(int id);
  Future<int> deletePaymentReminder(
    int id,
  );
  Future<PaymentReminder> getById(int id);
  Future<List<PaymentReminder>> getAllPaymentReminders(int profile);
  Future<PaymentReminder?> getPaymentReminderByID(int id);
}
