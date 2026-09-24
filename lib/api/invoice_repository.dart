import '../models/invoice_detail_model.dart';
import '../models/invoice_list_model.dart';
import '../utility/app_messages.dart';
import '../utility/global_function.dart';
import 'api_list.dart';
import 'api_method.dart';

/// Either a value or a user-facing error message.
class Result<T> {
  const Result.ok(this.value) : error = null;
  const Result.fail(this.error) : value = null;

  final T? value;
  final String? error;

  bool get isOk => error == null;
}

/// All calls to the Rainbow Line backend. Request bodies are identical to
/// the ones the previous app sent, so the backend needs no changes.
class InvoiceRepository {
  const InvoiceRepository();

  Future<Result<List<InvoiceData>>> getInvoices() async {
    final res = await callGetApi(endURl: ApiString.invoiceList);
    if (!res.isSuccess) return Result.fail(res.errorMessage);
    if (res.data is! Map<String, dynamic>) return const Result.fail(AppMessages.badResponse);
    final list = InvoiceListModel.fromJson(res.data).data ?? [];
    list.sort((a, b) {
      final byDate = (b.date ?? DateTime(1900)).compareTo(a.date ?? DateTime(1900));
      return byDate != 0 ? byDate : (b.id ?? 0).compareTo(a.id ?? 0);
    });
    return Result.ok(list);
  }

  Future<Result<InvoiceData>> getInvoice(int id) async {
    final res = await callGetApi(endURl: "${ApiString.invoiceDetail}$id");
    if (!res.isSuccess) return Result.fail(res.errorMessage);
    if (res.data is! Map<String, dynamic>) return const Result.fail(AppMessages.badResponse);
    final data = InvoiceDetailModel.fromJson(res.data).data;
    return data == null ? const Result.fail(AppMessages.badResponse) : Result.ok(data);
  }

  Future<Result<void>> createInvoice(InvoiceData invoice) async {
    final res = await callPostApi(endURl: ApiString.invoiceList, body: _body(invoice));
    return res.isSuccess ? const Result.ok(null) : Result.fail(res.errorMessage);
  }

  Future<Result<void>> updateInvoice(InvoiceData invoice) async {
    final body = _body(invoice);
    // The previous app sent the invoice id as customer.id on update — kept as is.
    (body['customer'] as Map<String, dynamic>)['id'] = invoice.id.toString();
    final res = await callPutApi(endURl: "${ApiString.invoiceDetail}${invoice.id}", body: body);
    return res.isSuccess ? const Result.ok(null) : Result.fail(res.errorMessage);
  }

  Future<Result<AppSettingModel>> getNextInvoiceNumber() async {
    final res = await callGetApi(endURl: ApiString.appSetting);
    return _setting(res);
  }

  Future<Result<AppSettingModel>> setNextInvoiceNumber(int number) async {
    final res = await callPostApi(endURl: ApiString.appSetting, body: {"invoice_number": "$number"});
    return _setting(res);
  }

  Result<AppSettingModel> _setting(ApiResponse res) {
    if (!res.isSuccess) return Result.fail(res.errorMessage);
    if (res.data is! Map<String, dynamic>) return const Result.fail(AppMessages.badResponse);
    final model = AppSettingModel.fromJson(res.data);
    return model.invoiceNumber == null ? const Result.fail(AppMessages.badResponse) : Result.ok(model);
  }

  Map<String, dynamic> _body(InvoiceData invoice) {
    final c = invoice.customer ?? Customer();
    return {
      "customer": {
        "name": cleanText(c.name),
        "address": cleanText(c.address),
        "city": cleanText(c.city),
        "country": cleanText(c.country),
        "postal_code": cleanText(c.postalCode),
      },
      "invoice": {
        "invoice_number": invoice.invoiceNumber,
        "reference_number": cleanText(invoice.referenceNumber),
        "invoice_date": invoice.invoiceDate,
        "invoice_due_date": invoice.invoiceDueDate,
        "notes": cleanText(invoice.notes),
      },
      "invoice_items": invoice.items
          .map(
            (i) => InvoiceItems(
              id: 0,
              invoiceId: 0,
              dateInRange: 0,
              itemDate: i.itemDate,
              description: i.description,
              quantity: i.quantity,
              price: i.price,
              amount: i.amount,
              minibusSuvSedan: i.minibusSuvSedan,
            ).toJson(),
          )
          .toList(),
    };
  }
}
