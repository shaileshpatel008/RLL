import 'package:get/get.dart';

import '../controller/dashboard_controller.dart';
import '../controller/invoice_list_controller.dart';
import '../controller/main_controller.dart';
import '../controller/setting_controller.dart';

/// The shell and its three tabs. These live as long as the main screen,
/// so the form and preview screens can read and refresh them.
class MainBinding extends Bindings {
  @override
  void dependencies() {
    Get.put<MainController>(MainController());
    Get.put<SettingController>(SettingController());
    Get.put<InvoiceListController>(InvoiceListController());
    Get.put<DashboardController>(DashboardController());
  }
}
