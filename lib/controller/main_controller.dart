import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../routes/app_pages.dart';
import '../utility/global_function.dart';
import 'invoice_list_controller.dart';
import 'setting_controller.dart';

/// Bottom navigation shell: Home, Invoices, Settings (+ New invoice button).
class MainController extends GetxController {
  final tabIndex = 0.obs;

  void changeTab(int index) {
    if (tabIndex.value == index) return;
    unFocus();
    HapticFeedback.selectionClick();
    tabIndex.value = index;
  }

  Future<void> newInvoice() async {
    HapticFeedback.mediumImpact();
    final created = await Get.toNamed(Routes.invoiceForm);
    if (created == true) {
      Get.find<InvoiceListController>().fetchInvoices();
      Get.find<SettingController>().fetchNextNumber();
    }
  }

  /// Android back button on another tab goes to Home before leaving the app.
  bool handleBack() {
    if (tabIndex.value != 0) {
      changeTab(0);
      return false;
    }
    return true;
  }
}
