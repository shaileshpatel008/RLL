import 'package:get/get.dart';

import '../controller/invoice_preview_controller.dart';

class InvoicePreviewBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<InvoicePreviewController>(() => InvoicePreviewController());
  }
}
