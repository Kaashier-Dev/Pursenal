import 'package:drift/drift.dart';
import 'package:pursenal/core/db/app_drift_database.dart';
import 'package:pursenal/core/models/domain/account.dart';
import 'package:pursenal/core/models/domain/account_type.dart';
import 'package:pursenal/core/models/domain/bank.dart';
import 'package:pursenal/core/models/domain/budget.dart';
import 'package:pursenal/core/models/domain/credit_card.dart';
import 'package:pursenal/core/models/domain/loan.dart';
import 'package:pursenal/core/models/domain/payment_reminder.dart';
import 'package:pursenal/core/models/domain/people.dart';
import 'package:pursenal/core/models/domain/profile.dart';
import 'package:pursenal/core/models/domain/project.dart';
import 'package:pursenal/core/models/domain/receivable.dart';
import 'package:pursenal/core/models/domain/transaction.dart';
import 'package:pursenal/core/models/domain/user.dart';
import 'package:pursenal/core/models/domain/wallet.dart';

extension AccountMapper on DriftAccount {
  Account toDomain() {
    return Account(
      dbID: id,
      name: name,
      openBalance: openBal,
      openDate: openDate,
      isEditable: isEditable,
      addedDate: addedDate,
      updateDate: updateDate,
      accountType: accType,
    );
  }
}

extension AccountEntityMapper on Account {
  DriftAccountsCompanion toDrift(int profileId) {
    return DriftAccountsCompanion(
      id: Value(dbID),
      name: Value(name),
      openBal: Value(openBalance),
      openDate: Value(openDate),
      accType: Value(accountType),
      isEditable: Value(isEditable),
      addedDate: Value(addedDate),
      updateDate: Value(updateDate),
      profile: Value(profileId),
    );
  }
}

extension AccountTypeMapper on DriftAccType {
  AccountType toDomain() {
    return AccountType(
      dbID: id,
      name: name,
      primary: primary,
      addedDate: addedDate,
      updateDate: updateDate,
      isEditable: isEditable,
    );
  }
}

extension AccountTypeEntityMapper on AccountType {
  DriftAccTypesCompanion toDrift() {
    return DriftAccTypesCompanion(
      id: Value(dbID),
      name: Value(name),
      primary: Value(primary),
      addedDate: Value(addedDate),
      updateDate: Value(updateDate),
      isEditable: Value(isEditable),
    );
  }
}

extension BudgetMapper on DriftBudget {
  Budget toDomain({
    required List<Account> funds,
    required Map<Account, int> incomes,
    required Map<Account, int> expenses,
  }) {
    return Budget(
      dbID: id,
      name: name,
      interval: interval,
      details: details,
      startDay: startDay,
      startDate: startDate,
      funds: funds,
      incomes: incomes,
      expenses: expenses,
      addedDate: addedDate,
      updateDate: updateDate,
    );
  }
}

extension BudgetEntityMapper on Budget {
  DriftBudgetsCompanion toDrift() {
    return DriftBudgetsCompanion(
      id: Value(dbID),
      name: Value(name),
      interval: Value(interval),
      details: Value(details),
      startDay: Value(startDay),
      startDate: Value(startDate),
      addedDate: Value(addedDate),
      updateDate: Value(updateDate),
    );
  }
}

extension ProjectMapper on DriftProject {
  Project toDomain({
    required List<String> photoPaths,
    Budget? budget,
  }) {
    return Project(
      dbID: id,
      name: name,
      description: description ?? '',
      startDate: startDate,
      endDate: endDate,
      status: status,
      budget: budget,
      photoPaths: photoPaths,
      addedDate: addedDate,
      updateDate: updateDate,
    );
  }
}

extension ProjectEntityMapper on Project {
  DriftProjectsCompanion toDrift() {
    return DriftProjectsCompanion(
      id: Value(dbID),
      name: Value(name),
      description: Value(description),
      startDate: Value(startDate),
      endDate: Value(endDate),
      status: Value(status),
      budget: Value(budget?.dbID),
      addedDate: Value(addedDate),
      updateDate: Value(updateDate),
    );
  }
}

extension TransactionMapper on DriftTransaction {
  Transaction toDomain(
      Account dr, Account cr, Project? project, List<String> filePaths) {
    return Transaction(
      dbID: id,
      voucherDate: vchDate,
      narration: narr,
      refNo: refNo,
      voucherType: vchType,
      drAccount: dr,
      crAccount: cr,
      amount: amount,
      project: project,
      addedDate: addedDate,
      updateDate: updateDate,
      filePaths: filePaths,
    );
  }
}

extension LoanMapper on DriftLoan {
  Loan toDomain(Account account) {
    return Loan(
      dbID: id,
      account: account,
      institution: institution,
      interestRate: interestRate,
      startDate: startDate,
      endDate: endDate,
      agreementNo: agreementNo,
      accountNo: accountNo,
    );
  }
}

extension LoanEntityMapper on Loan {
  DriftLoansCompanion toDrift() {
    return DriftLoansCompanion(
      id: Value(dbID),
      account: Value(account.dbID),
      institution: Value(institution),
      interestRate: Value(interestRate),
      startDate: Value(startDate),
      endDate: Value(endDate),
      agreementNo: Value(agreementNo),
      accountNo: Value(accountNo),
    );
  }
}

extension WalletMapper on DriftWallet {
  Wallet toDomain(Account account) {
    return Wallet(
      dbID: id,
      account: account,
    );
  }
}

extension WalletEntityMapper on Wallet {
  DriftWalletsCompanion toDrift() {
    return DriftWalletsCompanion(
      id: Value(dbID),
      account: Value(account.dbID),
    );
  }
}

extension BankMapper on DriftBank {
  Bank toDomain(Account account) {
    return Bank(
      dbID: id,
      account: account,
      holderName: holderName,
      institution: institution,
      branch: branch,
      branchCode: branchCode,
      accountNo: accountNo,
    );
  }
}

extension BankEntityMapper on Bank {
  DriftBanksCompanion toDrift() {
    return DriftBanksCompanion(
      id: Value(dbID),
      account: Value(account.dbID),
      holderName: Value(holderName),
      institution: Value(institution),
      branch: Value(branch),
      branchCode: Value(branchCode),
      accountNo: Value(accountNo),
    );
  }
}

extension CreditCardMapper on DriftCCard {
  CreditCard toDomain(Account account) {
    return CreditCard(
      dbID: id,
      account: account,
      institution: institution,
      statementDate: statementDate,
      cardNo: cardNo,
      cardNetwork: cardNetwork,
    );
  }
}

extension CreditCardEntityMapper on CreditCard {
  DriftCCardsCompanion toDrift() {
    return DriftCCardsCompanion(
      id: Value(dbID),
      account: Value(account.dbID),
      institution: Value(institution),
      statementDate: Value(statementDate),
      cardNo: Value(cardNo),
      cardNetwork: Value(cardNetwork),
    );
  }
}

extension ProfileMapper on DriftProfile {
  Profile toDomain() {
    return Profile(
      dbID: id,
      name: name,
      alias: alias,
      address: address,
      zip: zip,
      email: email,
      phone: phone,
      tin: tin,
      isSelected: isSelected,
      currency: currency,
      globalID: globalID,
      isLocal: isLocal,
      addedDate: addedDate,
      updateDate: updateDate,
    );
  }
}

extension ReceivableMapper on DriftReceivable {
  Receivable toDomain(Account account) {
    return Receivable(
      dbID: id,
      account: account,
      totalAmount: totalAmount,
      paidDate: paidDate,
    );
  }
}

extension ReceivableEntityMapper on Receivable {
  DriftReceivablesCompanion toDrift() {
    return DriftReceivablesCompanion(
      id: Value(dbID),
      accountId: Value(account.dbID),
      totalAmount: Value(totalAmount),
      paidDate: Value(paidDate),
    );
  }
}

extension PeopleMapper on DriftPeopleData {
  People toDomain(Account account) {
    return People(
      dbID: id,
      account: account,
      address: address,
      zip: zip,
      email: email,
      phone: phone,
      tin: tin,
    );
  }
}

extension PeopleEntityMapper on People {
  DriftPeopleCompanion toDrift() {
    return DriftPeopleCompanion(
      id: Value(dbID),
      accountId: Value(account.dbID),
      address: Value(address),
      zip: Value(zip),
      email: Value(email),
      phone: Value(phone),
      tin: Value(tin),
    );
  }
}

extension PaymentReminderMapper on DriftPaymentReminder {
  PaymentReminder toDomain(
      Account? account, Account? fund, List<String> filePaths) {
    return PaymentReminder(
        dbID: id,
        account: account,
        fund: fund,
        details: details,
        profile: profile,
        interval: interval,
        paymentStatus: status,
        day: day,
        amount: amount,
        addedDate: addedDate,
        updateDate: updateDate,
        filePaths: filePaths);
  }
}

extension PaymentReminderEntityMapper on PaymentReminder {
  DriftPaymentRemindersCompanion toDrift() {
    return DriftPaymentRemindersCompanion(
      id: Value(dbID),
      account: Value(account?.dbID),
      fund: Value(fund?.dbID),
      profile: Value(profile),
      details: Value(details),
      interval: Value(interval),
      day: Value(day ?? 1),
      amount: Value(amount),
      addedDate: Value(addedDate),
      status: Value(paymentStatus),
      updateDate: Value(updateDate),
    );
  }
}

extension UserMapper on DriftUser {
  User toDomain() {
    return User(
      dbID: id,
      name: name,
      deviceID: deviceID,
      photoPath: photoPath,
    );
  }
}

extension UserEntityMapper on User {
  DriftUsersCompanion toDrift() {
    return DriftUsersCompanion(
      id: Value(dbID),
      name: Value(name),
      deviceID: Value(deviceID),
      photoPath: Value(photoPath),
    );
  }
}
