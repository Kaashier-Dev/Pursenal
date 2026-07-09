const appName = "Pursenal";
const appVersion = "v1.4.0";
const notoSansFontPath = "assets/fonts/NotoSans-Regular.ttf";
const gitHubURL = "https://github.com/Kaashier-Dev/Pursenal";
const appURL = "https://github.com/Kaashier-Dev/Pursenal";
const supportURL = "https://buymeacoffee.com/kaashier";

// DB related

const int walletTypeID = 0;
const int bankTypeID = 1;
const int cCardTypeID = 2;
const int loanTypeID = 3;
const int incomeTypeID = 4;
const int expenseTypeID = 5;
const int advanceTypeID = 6;
const int peopleTypeID = 7;
const String backupKey = "pursenal_db_backup_key_yep_this_is_it";

const List<int> incExpIDs = [incomeTypeID, expenseTypeID];

const List<int> fundIDs = [walletTypeID, bankTypeID];
const List<int> creditIDs = [loanTypeID, cCardTypeID];
const List<int> fundingAccountIDs = [
  walletTypeID,
  bankTypeID,
  loanTypeID,
  cCardTypeID
];
const List<int> balanceAccountIDs = [
  walletTypeID,
  bankTypeID,
  loanTypeID,
  cCardTypeID,
  advanceTypeID,
  peopleTypeID,
];
