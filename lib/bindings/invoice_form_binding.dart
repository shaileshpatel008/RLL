import 'package:get/get.dart';

import '../controller/invoice_form_controller.dart';

class InvoiceFormBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<InvoiceFormController>(() => InvoiceFormController());
  }
}
