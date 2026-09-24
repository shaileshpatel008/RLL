import '../utility/change_value.dart';

class ApiString {
  ApiString._();

  static const String baseUrl = "${ChangeValue.domain}/api/";

  /// GET  -> all invoices
  /// POST -> create invoice
  static const String invoiceList = "${baseUrl}invoice";

  /// GET  invoice/{id} -> invoice detail
  /// PUT  invoice/{id} -> update invoice
  static const String invoiceDetail = "${baseUrl}invoice/";

  /// GET  -> next invoice number
  /// POST -> set next invoice number
  static const String appSetting = "${baseUrl}app-settings";
}
