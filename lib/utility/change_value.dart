/// Client specific values. Change these to re-brand the app for another
/// company — everything else in the app reads from here.
class ChangeValue {
  ChangeValue._();

  static const String mainTitle = "Rainbow Line LTD";
  static const String appName = "Rainbow Line";
  static const String appVersion = "2.0.0";
  static const String domain = "https://rainbowline.soluspottechnolabs.com";

  // ex : RLL/2026/00142
  static const String invoiceNoTitle = "RLL";

  // Company details printed on the PDF
  static const String companyFullName = "Rainbow Line LTD";
  static const String companyShortName = "RLL";
  static const String companyNumber = "465 3355 80";
  static const String companyAddress1Line = "5 South Esk Road";
  static const String companyAddress2Line = "London";
  static const String companyAddress3Line = "UK";
  static const String companyAddress4Line = "E7 8EZ";
  static const String companyTelPhone = "07834535706";

  // Bank details printed at the bottom of the PDF
  static const String bankName = "LLOYDS Bank, 98 Victoria St, London SW1E5JL";
  static const String bankAccount =
      "Sort Code. 309897, Account no. 80446262,\nBIC:LOYDGB21031, IBAN:GB69LOYD 3098 9780 4462 62";

  static const String currencySymbol = "£";
  static const String defaultCountry = "UK";
  static const int defaultDueDays = 14;
  static const String defaultNotes = "Thank you for travelling with Rainbow Line.";

  static const List<String> vehicleTypes = ["Minibus", "SUV", "Sedan"];
}
