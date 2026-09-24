import 'invoice_list_model.dart';

/// Response of GET /invoice/{id}. The detail has the same shape as a list
/// entry, so it reuses [InvoiceData].
class InvoiceDetailModel {
  String? status;
  String? message;
  InvoiceData? data;

  InvoiceDetailModel({this.status, this.message, this.data});

  InvoiceDetailModel.fromJson(Map<String, dynamic> json) {
    status = json['status']?.toString();
    message = json['message']?.toString();
    data = json['data'] is Map<String, dynamic> ? InvoiceData.fromJson(json['data']) : null;
  }
}

/// Response of GET/POST /app-settings
class AppSettingModel {
  AppSettingModel({this.invoiceNumber});

  /// Next invoice number, e.g. 142 (shown as 00142)
  int? invoiceNumber;

  AppSettingModel.fromJson(Map<String, dynamic> json) {
    final data = json['data'];
    if (data is Map) {
      invoiceNumber = int.tryParse(data['invoice_number']?.toString() ?? '');
    }
  }

  String get padded => invoiceNumber == null ? '' : invoiceNumber.toString().padLeft(5, '0');
}
