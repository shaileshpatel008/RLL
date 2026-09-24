import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

import '../api/invoice_repository.dart';
import '../models/invoice_detail_model.dart';
import '../utility/app_messages.dart';
import '../utility/change_value.dart';
import '../utility/global_function.dart';
import '../utility/image_manager.dart';

class SettingController extends GetxController {
  final _repo = const InvoiceRepository();
  final _box = GetStorage();

  final setting = Rxn<AppSettingModel>();
  final isLoading = true.obs;
  final error = RxnString();
  final themeMode = ThemeMode.light.obs;

  final numberController = TextEditingController();
  final numberError = RxnString();
  final isSaving = false.obs;

  @override
  void onInit() {
    super.onInit();
    themeMode.value = themeFromStorage();
    fetchNextNumber();
  }

  @override
  void onClose() {
    numberController.dispose();
    super.onClose();
  }

  static ThemeMode themeFromStorage() {
    final value = GetStorage().read<String>(StorageKey.themeMode);
    return ThemeMode.values.firstWhere((m) => m.name == value, orElse: () => ThemeMode.light);
  }

  /// "00142"
  String get nextNumber => setting.value?.padded ?? '';

  /// "RLL/2026/00142"
  String get nextInvoiceNumber =>
      nextNumber.isEmpty ? '' : "${ChangeValue.invoiceNoTitle}/${DateTime.now().year}/$nextNumber";

  Future<void> fetchNextNumber() async {
    if (setting.value == null) isLoading.value = true;
    final result = await _repo.getNextInvoiceNumber();
    if (result.isOk) {
      setting.value = result.value;
      error.value = null;
    } else {
      error.value = result.error;
    }
    isLoading.value = false;
  }

  /// Called after an invoice is created — same behaviour as the old app.
  Future<bool> increaseNextNumber() async {
    final current = setting.value?.invoiceNumber;
    if (current == null) return false;
    final result = await _repo.setNextInvoiceNumber(current + 1);
    if (result.isOk) setting.value = result.value;
    return result.isOk;
  }

  void prepareEdit() {
    numberController.text = nextNumber;
    numberError.value = null;
  }

  void onNumberChanged(String _) => numberError.value = null;

  String get numberPreview {
    final raw = numberController.text.trim();
    final padded = raw.isEmpty ? '•••••' : raw.padLeft(5, '0');
    return "${ChangeValue.invoiceNoTitle}/${DateTime.now().year}/$padded";
  }

  Future<void> saveNextNumber() async {
    final value = int.tryParse(numberController.text.trim());
    if (value == null || value <= 0) {
      numberError.value = AppMessages.enterInvoiceNo;
      return;
    }
    if (value == setting.value?.invoiceNumber) {
      numberError.value = AppMessages.invoiceNoSame;
      return;
    }
    unFocus();
    isSaving.value = true;
    final result = await _repo.setNextInvoiceNumber(value);
    isSaving.value = false;
    if (result.isOk) {
      setting.value = result.value;
      closeRoute();
      showSuccess("Next invoice will be $nextInvoiceNumber", title: AppMessages.invoiceNoUpdated);
    } else {
      numberError.value = result.error;
    }
  }

  void setTheme(ThemeMode mode) {
    if (themeMode.value == mode) return;
    themeMode.value = mode;
    _box.write(StorageKey.themeMode, mode.name);
    Get.changeThemeMode(mode);
  }
}
