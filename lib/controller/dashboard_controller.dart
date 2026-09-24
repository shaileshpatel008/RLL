import 'package:get/get.dart';

import 'invoice_list_controller.dart';
import 'main_controller.dart';
import 'setting_controller.dart';

/// Home tab. All numbers are worked out from the invoice list API and the
/// app-settings API — no extra backend work needed.
class DashboardController extends GetxController {
  InvoiceListController get invoices => Get.find<InvoiceListController>();
  SettingController get settings => Get.find<SettingController>();
  MainController get shell => Get.find<MainController>();

  Future<void> refreshAll() async {
    await Future.wait([invoices.fetchInvoices(showErrorMessage: true), settings.fetchNextNumber()]);
  }
}
