import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../models/invoice_list_model.dart';
import '../routes/app_pages.dart';
import '../utility/app_messages.dart';
import '../utility/global_function.dart';
import '../widgets/pdf_generate_widget.dart';
import 'invoice_list_controller.dart';

class InvoicePreviewController extends GetxController {
  late final Rx<InvoiceData> invoice;
  final bytes = Rxn<Uint8List>();
  final error = RxnString();

  @override
  void onInit() {
    super.onInit();
    invoice = (Get.arguments as InvoiceData).obs;
    buildPdf();
  }

  Future<void> buildPdf() async {
    error.value = null;
    bytes.value = null;
    try {
      bytes.value = await PdfInvoiceApi.generate(invoice.value);
    } catch (e) {
      error.value = AppMessages.unknownError;
    }
  }

  Future<void> share() async {
    if (bytes.value == null) return;
    try {
      final file = await FileHandleApi.saveInvoice(invoice.value, bytes: bytes.value);
      await FileHandleApi.shareFile(file, invoice.value);
    } catch (_) {
      showError(AppMessages.unknownError);
    }
  }

  Future<void> download() async {
    if (bytes.value == null) return;
    try {
      final file = await FileHandleApi.saveInvoice(invoice.value, bytes: bytes.value);
      showSuccess(FileHandleApi.fileName(invoice.value), title: AppMessages.pdfSaved);
      final opened = await FileHandleApi.openFile(file);
      if (!opened) showInfo(AppMessages.cannotOpenPdf);
    } catch (_) {
      showError(AppMessages.unknownError);
    }
  }

  Future<void> printPdf() async {
    if (bytes.value == null) return;
    try {
      await FileHandleApi.printInvoice(invoice.value, bytes.value!);
    } catch (_) {
      showError(AppMessages.unknownError);
    }
  }

  void copyNumber() {
    Clipboard.setData(ClipboardData(text: invoice.value.invoiceNumber ?? ''));
    showSuccess(invoice.value.invoiceNumber ?? '', title: AppMessages.copied);
  }

  Future<void> edit() async {
    final id = invoice.value.id;
    if (id == null) return;
    final changed = await Get.toNamed(Routes.invoiceForm, arguments: {'id': id});
    if (changed != true) return;
    // Reload the invoice so the preview shows the saved version.
    if (Get.isRegistered<InvoiceListController>()) {
      final list = Get.find<InvoiceListController>();
      await list.fetchInvoices();
      final updated = list.invoices.firstWhereOrNull((i) => i.id == id);
      if (updated != null) {
        invoice.value = updated;
        buildPdf();
      }
    }
  }
}
