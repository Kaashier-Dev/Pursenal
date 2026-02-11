import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en')
  ];

  /// Displayed when the application is successfully launched.
  ///
  /// In en, this message translates to:
  /// **'Application started'**
  String get applicationStarted;

  /// Title for the Flutter demo section.
  ///
  /// In en, this message translates to:
  /// **'Flutter Demo'**
  String get flutterDemo;

  /// Label for selecting the type of transaction.
  ///
  /// In en, this message translates to:
  /// **'Transaction Type'**
  String get transactionType;

  /// Transaction Types title
  ///
  /// In en, this message translates to:
  /// **'Transaction Types'**
  String get transactionTypes;

  /// Label indicating the fund used for a transaction.
  ///
  /// In en, this message translates to:
  /// **'Fund for Transaction'**
  String get fundForTransaction;

  /// Label indicating the account associated with a transaction.
  ///
  /// In en, this message translates to:
  /// **'Account for Transaction'**
  String get accountForTransaction;

  /// Generic label for selecting an item.
  ///
  /// In en, this message translates to:
  /// **'Select {title}'**
  String select(Object title);

  /// The current transaction number.
  ///
  /// In en, this message translates to:
  /// **'Transaction #{no}'**
  String transactionNo(Object no);

  /// The current transaction date.
  ///
  /// In en, this message translates to:
  /// **'Transaction Date'**
  String get transactionDate;

  /// The date of payment.
  ///
  /// In en, this message translates to:
  /// **'Payment Date'**
  String get paymentDate;

  /// Generic label for account lists.
  ///
  /// In en, this message translates to:
  /// **'My {account} Accounts'**
  String myXAccounts(Object account);

  /// Button label for skipping an action.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get skip;

  /// Label for displaying the number of cash accounts.
  ///
  /// In en, this message translates to:
  /// **'Cash Accounts : {count}'**
  String cashAccounts(Object count);

  /// Label for displaying the number of bank accounts.
  ///
  /// In en, this message translates to:
  /// **'Bank Accounts : {count}'**
  String bankAccounts(Object count);

  /// Section title for user profiles.
  ///
  /// In en, this message translates to:
  /// **'My Profiles'**
  String get myProfiles;

  /// Expenses.
  ///
  /// In en, this message translates to:
  /// **'Expenses'**
  String get expenses;

  /// Incomes.
  ///
  /// In en, this message translates to:
  /// **'Incomes'**
  String get incomes;

  /// Cash.
  ///
  /// In en, this message translates to:
  /// **'Cash'**
  String get cash;

  /// Bank.
  ///
  /// In en, this message translates to:
  /// **'Bank'**
  String get bank;

  /// Expense.
  ///
  /// In en, this message translates to:
  /// **'Expense'**
  String get expense;

  /// Income.
  ///
  /// In en, this message translates to:
  /// **'Income'**
  String get income;

  /// My Dashboard.
  ///
  /// In en, this message translates to:
  /// **'My Dashboard'**
  String get myDashboard;

  /// My Budgets.
  ///
  /// In en, this message translates to:
  /// **'My Budgets'**
  String get myBudgets;

  /// Budget calculated balance.
  ///
  /// In en, this message translates to:
  /// **'Balance'**
  String get balance;

  /// Budget Form title
  ///
  /// In en, this message translates to:
  /// **'Budget Form'**
  String get budgetForm;

  /// Theme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get theme;

  /// Question to use system theme.
  ///
  /// In en, this message translates to:
  /// **'Use System Theme?'**
  String get useSystemTheme;

  /// My Funds.
  ///
  /// In en, this message translates to:
  /// **'My Funds'**
  String get myFunds;

  /// My Credits.
  ///
  /// In en, this message translates to:
  /// **'My Credits'**
  String get myCredits;

  /// Other Accounts.
  ///
  /// In en, this message translates to:
  /// **'Other Accounts'**
  String get otherAccounts;

  /// My Funds & Credits.
  ///
  /// In en, this message translates to:
  /// **'My Funds & Credits'**
  String get myFundsAndCredits;

  /// My Insights title.
  ///
  /// In en, this message translates to:
  /// **'My Insights'**
  String get myInsights;

  /// Fund.
  ///
  /// In en, this message translates to:
  /// **'Fund'**
  String get fund;

  /// Fund Type.
  ///
  /// In en, this message translates to:
  /// **'Fund Type'**
  String get fundType;

  /// My Balance.
  ///
  /// In en, this message translates to:
  /// **'Funds Balance'**
  String get myBalance;

  /// Receipt.
  ///
  /// In en, this message translates to:
  /// **'Receipt'**
  String get receipt;

  /// Receipts.
  ///
  /// In en, this message translates to:
  /// **'Receipts'**
  String get receipts;

  /// Accounts.
  ///
  /// In en, this message translates to:
  /// **'Accounts'**
  String get accounts;

  /// Account.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get account;

  /// Label to add Account.
  ///
  /// In en, this message translates to:
  /// **'Add Account'**
  String get addAccount;

  /// Amount.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get amount;

  /// Payment.
  ///
  /// In en, this message translates to:
  /// **'Payment'**
  String get payment;

  /// Payments.
  ///
  /// In en, this message translates to:
  /// **'Payments'**
  String get payments;

  /// Currency.
  ///
  /// In en, this message translates to:
  /// **'Currency'**
  String get currency;

  /// Narration.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get narration;

  /// Reference for transaction.
  ///
  /// In en, this message translates to:
  /// **'Reference #'**
  String get referenceNo;

  /// Not enough data available for insights.
  ///
  /// In en, this message translates to:
  /// **'Not Enough Data'**
  String get notEnoughData;

  /// Title for expenses split pie chart
  ///
  /// In en, this message translates to:
  /// **'Expenses Split'**
  String get expensesSplit;

  /// Title for expense-income daily bar chart
  ///
  /// In en, this message translates to:
  /// **'Daily Transactions '**
  String get dailyTransactions;

  /// Title for expense average bar chart
  ///
  /// In en, this message translates to:
  /// **'Average Expenses '**
  String get averageExpenses;

  /// Title for budgeted expense comparison bar chart
  ///
  /// In en, this message translates to:
  /// **'Budgeted Expenses '**
  String get budgetedExpenses;

  /// Title for funds balance line chart
  ///
  /// In en, this message translates to:
  /// **'Funds Balance '**
  String get fundsBalance;

  /// Add.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add;

  /// Profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// Add.
  ///
  /// In en, this message translates to:
  /// **'Add New +'**
  String get addNew;

  /// My Transactions.
  ///
  /// In en, this message translates to:
  /// **'My Transactions'**
  String get myTransactions;

  /// Filter menu title
  ///
  /// In en, this message translates to:
  /// **'Filters'**
  String get filters;

  /// Button label for switching between light and dark themes.
  ///
  /// In en, this message translates to:
  /// **'Toggle Theme'**
  String get toggleTheme;

  /// Indicates an ongoing submission process.
  ///
  /// In en, this message translates to:
  /// **'Submitting..'**
  String get submitting;

  /// Label for selecting the source account for a transfer.
  ///
  /// In en, this message translates to:
  /// **'Transfer - {account}'**
  String transferFrom(Object account);

  /// Label for selecting the source account for a payment.
  ///
  /// In en, this message translates to:
  /// **'Paid from {account}'**
  String paidFrom(Object account);

  /// Dates filter
  ///
  /// In en, this message translates to:
  /// **'From {startDate} to {endDate}'**
  String fromToDate(Object startDate, Object endDate);

  /// Label indicating the destination account for received funds.
  ///
  /// In en, this message translates to:
  /// **'Received in {account}'**
  String receivedIn(Object account);

  /// Placeholder text for a search field.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

  /// Button label for uploading images.
  ///
  /// In en, this message translates to:
  /// **'Add Photos'**
  String get addPhotos;

  /// Application name or branding text.
  ///
  /// In en, this message translates to:
  /// **'Pursenal'**
  String get pursenal;

  /// Label for the main section of the application.
  ///
  /// In en, this message translates to:
  /// **'Main'**
  String get main;

  /// Standard label for navigating to more accounts, transactions etc.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get more;

  /// Label for recent transactions.
  ///
  /// In en, this message translates to:
  /// **'Recent Transactions'**
  String get recentTransactions;

  /// Section title for funds management.
  ///
  /// In en, this message translates to:
  /// **'Funds'**
  String get funds;

  /// Copy something
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get copy;

  /// Edit something
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// Section for dates
  ///
  /// In en, this message translates to:
  /// **'Dates'**
  String get dates;

  /// Label for viewing all transactions.
  ///
  /// In en, this message translates to:
  /// **'Transactions'**
  String get transactions;

  /// Label to edit current transaction.
  ///
  /// In en, this message translates to:
  /// **'Edit this Transaction'**
  String get editThisTransaction;

  /// Label to create new profile.
  ///
  /// In en, this message translates to:
  /// **'New Profile'**
  String get newProfile;

  /// Label to edit current profile.
  ///
  /// In en, this message translates to:
  /// **'Edit this Profile'**
  String get editThisProfile;

  /// Label to copy current transaction.
  ///
  /// In en, this message translates to:
  /// **'Copy this Transaction'**
  String get copyThisTransaction;

  /// Label to delete current transaction.
  ///
  /// In en, this message translates to:
  /// **'Delete this Transaction'**
  String get deleteThisTransaction;

  /// Label to copy current profile.
  ///
  /// In en, this message translates to:
  /// **'Copy this Profile'**
  String get copyThisProfile;

  /// Label to delete current profile.
  ///
  /// In en, this message translates to:
  /// **'Delete this Transaction'**
  String get deleteThisProfile;

  /// Label for list of all profiles.
  ///
  /// In en, this message translates to:
  /// **'All Profiles'**
  String get allProfiles;

  /// Query to confirm deletion of current transaction.
  ///
  /// In en, this message translates to:
  /// **'Delete this transaction?'**
  String get deleteThisTransactionQn;

  /// Query to confirm deletion of current project.
  ///
  /// In en, this message translates to:
  /// **'Delete this project?'**
  String get deleteThisProjectQn;

  /// Query to confirm deletion of current account.
  ///
  /// In en, this message translates to:
  /// **'Delete this account?'**
  String get deleteThisAccountQn;

  /// Account deletion warning
  ///
  /// In en, this message translates to:
  /// **'WARNING: This action will delete all related transactions and budget entries'**
  String get deleteAccountWarning;

  /// Query to confirm deletion of current budget.
  ///
  /// In en, this message translates to:
  /// **'Delete this Budget?'**
  String get deleteThisBudgetQn;

  /// Budget deletion warning
  ///
  /// In en, this message translates to:
  /// **'WARNING: This action will delete this budget and related entries'**
  String get deleteBudgetWarning;

  /// Query to confirm deletion of current payment reminder.
  ///
  /// In en, this message translates to:
  /// **'Delete this Reminder?'**
  String get deleteThisReminderQn;

  /// Displayed when the currency type is not recognized.
  ///
  /// In en, this message translates to:
  /// **'Unknown Currency'**
  String get unknownCurrency;

  /// Label for specifying the type of an account.
  ///
  /// In en, this message translates to:
  /// **'Account Type'**
  String get accountType;

  /// Label for selecting the date an account was opened.
  ///
  /// In en, this message translates to:
  /// **'Opening Date'**
  String get openingDate;

  /// Field label for entering the initial balance of an account.
  ///
  /// In en, this message translates to:
  /// **'Opening Balance'**
  String get openingBalance;

  /// Field label for entering the ending balance of an account.
  ///
  /// In en, this message translates to:
  /// **'Closing Balance'**
  String get closingBalance;

  /// Label for selecting a start date.
  ///
  /// In en, this message translates to:
  /// **'Start Date'**
  String get startDate;

  /// Label for selecting an end date.
  ///
  /// In en, this message translates to:
  /// **'End Date'**
  String get endDate;

  /// Title for the account creation or editing form.
  ///
  /// In en, this message translates to:
  /// **'Account Form'**
  String get accountForm;

  /// Label for entering the name of an account.
  ///
  /// In en, this message translates to:
  /// **'Account Name'**
  String get accountName;

  /// Label for specifying the account holder's name.
  ///
  /// In en, this message translates to:
  /// **'Holder Name'**
  String get holderName;

  /// Label for entering the name of a financial institution.
  ///
  /// In en, this message translates to:
  /// **'Institution'**
  String get institution;

  /// Label for specifying a bank branch.
  ///
  /// In en, this message translates to:
  /// **'Branch'**
  String get branch;

  /// Label for entering a branch code.
  ///
  /// In en, this message translates to:
  /// **'Branch Code'**
  String get branchCode;

  /// Label for specifying the card network (e.g., Visa, MasterCard).
  ///
  /// In en, this message translates to:
  /// **'Card Network'**
  String get cardNetwork;

  /// Label for entering the card number.
  ///
  /// In en, this message translates to:
  /// **'Card No.'**
  String get cardNo;

  /// Label for selecting the date of a financial statement.
  ///
  /// In en, this message translates to:
  /// **'Statement Date'**
  String get statementDate;

  /// Label for entering an account number.
  ///
  /// In en, this message translates to:
  /// **'Account No.'**
  String get accountNo;

  /// Label for specifying an agreement number.
  ///
  /// In en, this message translates to:
  /// **'Agreement No.'**
  String get agreementNo;

  /// Label for entering the interest rate of an account.
  ///
  /// In en, this message translates to:
  /// **'Interest Rate'**
  String get interestRate;

  /// Button label for saving changes.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// Button label for deleting an item.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// Button label for canceling an action.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// Title for the user profile form.
  ///
  /// In en, this message translates to:
  /// **'Profile Form'**
  String get profileForm;

  /// Label for entering the profile name.
  ///
  /// In en, this message translates to:
  /// **'Profile Name'**
  String get profileName;

  /// Label for entering the budget name.
  ///
  /// In en, this message translates to:
  /// **'Budget Name'**
  String get budgetName;

  /// Label for specifying a nickname.
  ///
  /// In en, this message translates to:
  /// **'Nick Name'**
  String get nickName;

  /// Label for specifying the number of decimal points to display.
  ///
  /// In en, this message translates to:
  /// **'Decimal Points'**
  String get decimalPoints;

  /// Label for entering a street address.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get address;

  /// Label for entering a ZIP or postal code.
  ///
  /// In en, this message translates to:
  /// **'ZIP Code'**
  String get zip;

  /// Label for entering an email address.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// Label for entering a phone number.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get phone;

  /// Label for specifying a unique profile ID.
  ///
  /// In en, this message translates to:
  /// **'Profile ID'**
  String get profileId;

  /// Welcome to app text.
  ///
  /// In en, this message translates to:
  /// **'Welcome to'**
  String get welcomeTo;

  /// Short introduction about app on welcome screen.
  ///
  /// In en, this message translates to:
  /// **'Your free and open-source cash management app. \nPrivate. Offline. Accurate.'**
  String get appIntroduction;

  /// Ask the user to create the first profile.
  ///
  /// In en, this message translates to:
  /// **'Create a profile for your personal or business transactions first.'**
  String get createInitialProfile;

  /// To navigate user to profile creation page.
  ///
  /// In en, this message translates to:
  /// **'Go to profile creation'**
  String get goToProfileCreation;

  /// Select accounts user want to create from default list.
  ///
  /// In en, this message translates to:
  /// **'Select accounts you want to create.'**
  String get selectAccountsToCreate;

  /// Data
  ///
  /// In en, this message translates to:
  /// **'Data'**
  String get data;

  /// Details
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get details;

  /// Settings
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// About us
  ///
  /// In en, this message translates to:
  /// **'About us'**
  String get aboutUs;

  /// Contact us
  ///
  /// In en, this message translates to:
  /// **'Contact us'**
  String get contactUs;

  /// Support us
  ///
  /// In en, this message translates to:
  /// **'Support us'**
  String get supportUs;

  /// Import
  ///
  /// In en, this message translates to:
  /// **'Import data'**
  String get import;

  /// Import Accounts page title.
  ///
  /// In en, this message translates to:
  /// **'Import Accounts'**
  String get importAccounts;

  /// Export
  ///
  /// In en, this message translates to:
  /// **'Export your data'**
  String get export;

  /// Personalisation option in settings
  ///
  /// In en, this message translates to:
  /// **'Personalisation'**
  String get personalisation;

  /// Primary color option in settings
  ///
  /// In en, this message translates to:
  /// **'Primary color'**
  String get primaryColor;

  /// Payment color option in settings
  ///
  /// In en, this message translates to:
  /// **'Payment color'**
  String get paymentColor;

  /// Receipt color option in settings
  ///
  /// In en, this message translates to:
  /// **'Receipt color'**
  String get receiptColor;

  /// Select color prompt
  ///
  /// In en, this message translates to:
  /// **'Select a color'**
  String get selectAColor;

  /// Reminder section in settings
  ///
  /// In en, this message translates to:
  /// **'Reminder'**
  String get reminder;

  /// Expected - values for budget
  ///
  /// In en, this message translates to:
  /// **'Expected'**
  String get expected;

  /// Budgeted - values for budget
  ///
  /// In en, this message translates to:
  /// **'Budgeted'**
  String get budgeted;

  /// Actual - values for budget
  ///
  /// In en, this message translates to:
  /// **'Actual'**
  String get actual;

  /// Savings - for budget
  ///
  /// In en, this message translates to:
  /// **'Savings'**
  String get savings;

  /// Project
  ///
  /// In en, this message translates to:
  /// **'Project'**
  String get project;

  /// Project
  ///
  /// In en, this message translates to:
  /// **'Project name'**
  String get projectName;

  /// Payment reminders
  ///
  /// In en, this message translates to:
  /// **'Reminders'**
  String get reminders;

  /// Budgets
  ///
  /// In en, this message translates to:
  /// **'Budgets'**
  String get budgets;

  /// Projects
  ///
  /// In en, this message translates to:
  /// **'Projects'**
  String get projects;

  /// Project status
  ///
  /// In en, this message translates to:
  /// **'Project status'**
  String get projectStatus;

  /// General status for reminders, projects etc
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get status;

  /// Project form
  ///
  /// In en, this message translates to:
  /// **'Project form'**
  String get projectForm;

  /// Projects
  ///
  /// In en, this message translates to:
  /// **'My Projects'**
  String get myProjects;

  /// Payment Reminders
  ///
  /// In en, this message translates to:
  /// **'My Payment Reminders'**
  String get myPaymentReminders;

  /// Payment Reminder time
  ///
  /// In en, this message translates to:
  /// **'Payment reminder time'**
  String get paymentReminderTime;

  /// Proceed with payment
  ///
  /// In en, this message translates to:
  /// **'Pay'**
  String get pay;

  /// To note a payment is not recurring
  ///
  /// In en, this message translates to:
  /// **'One-time'**
  String get oneTime;

  /// Advance amount paid to a 'receivable' in total
  ///
  /// In en, this message translates to:
  /// **'Total advance paid'**
  String get totalAdvancePaid;

  /// Date of payment
  ///
  /// In en, this message translates to:
  /// **'Paid date'**
  String get paidDate;

  /// Budget performance
  ///
  /// In en, this message translates to:
  /// **'Budget Performance'**
  String get budgetPerformance;

  /// Label indicating the time the reminder rings.
  ///
  /// In en, this message translates to:
  /// **'Reminder set time : {time}'**
  String reminderSetTime(Object time);

  /// Prompt to ask for daily reminder to enter transactions.
  ///
  /// In en, this message translates to:
  /// **'Set Daily Entry Reminder?'**
  String get setDailyReminder;
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {


  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en': return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.'
  );
}
