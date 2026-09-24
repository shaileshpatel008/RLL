import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../api/invoice_repository.dart';
import '../models/invoice_list_model.dart';
import '../routes/app_pages.dart';
import '../utility/app_messages.dart';
import '../utility/change_value.dart';
import '../utility/global_function.dart';
import 'invoice_list_controller.dart';
import 'setting_controller.dart';

/// Create and edit invoice — a four step flow:
/// 0 Customer · 1 Details · 2 Trips · 3 Review
class InvoiceFormController extends GetxController {
  final _repo = const InvoiceRepository();

  static const stepTitles = ["Customer", "Details", "Trips", "Review"];

  // ---- Mode ----------------------------------------------------------------
  int? invoiceId;
  bool get isEdit => invoiceId != null;
  final isLoadingInvoice = false.obs;
  final loadError = RxnString();

  // ---- Steps ---------------------------------------------------------------
  final step = 0.obs;
  bool forward = true;
  final stepError = RxnString();

  // ---- Customer ------------------------------------------------------------
  final nameController = TextEditingController();
  final addressController = TextEditingController();
  final cityController = TextEditingController();
  final postalController = TextEditingController();
  final countryController = TextEditingController(text: ChangeValue.defaultCountry);
  final customerName = ''.obs;

  // ---- Details -------------------------------------------------------------
  final existingInvoiceNumber = ''.obs;
  final refController = TextEditingController();
  final notesController = TextEditingController(text: ChangeValue.defaultNotes);
  final invoiceDate = DateTime.now().obs;
  final dueDate = Rxn<DateTime>(DateTime.now().add(const Duration(days: ChangeValue.defaultDueDays)));

  // ---- Trips ---------------------------------------------------------------
  final items = <InvoiceItems>[].obs;
  final tripDate = Rxn<DateTime>();
  final descController = TextEditingController();
  final priceController = TextEditingController();
  final vehicle = ''.obs;
  final quantity = 1.obs;
  final priceText = ''.obs;
  final tripError = RxnString();
  int? editingIndex;

  // ---- Save ----------------------------------------------------------------
  final isSaving = false.obs;
  final createdInvoice = Rxn<InvoiceData>();
  bool _dirty = false;

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments;
    if (args is Map && args['id'] is int) {
      invoiceId = args['id'];
      _loadInvoice();
    }
    for (final c in [nameController, addressController, cityController, postalController, refController]) {
      c.addListener(() => _dirty = true);
    }
    nameController.addListener(() => customerName.value = nameController.text.trim());
  }

  @override
  void onClose() {
    for (final c in [
      nameController,
      addressController,
      cityController,
      postalController,
      countryController,
      refController,
      notesController,
      descController,
      priceController,
    ]) {
      c.dispose();
    }
    super.onClose();
  }

  // ---- Load (edit) -----------------------------------------------------------

  Future<void> _loadInvoice() async {
    isLoadingInvoice.value = true;
    loadError.value = null;
    final result = await _repo.getInvoice(invoiceId!);
    if (result.isOk) {
      final d = result.value!;
      final c = d.customer ?? Customer();
      nameController.text = cleanText(c.name);
      addressController.text = cleanText(c.address);
      cityController.text = cleanText(c.city);
      postalController.text = cleanText(c.postalCode);
      countryController.text = cleanText(c.country);
      existingInvoiceNumber.value = cleanText(d.invoiceNumber);
      refController.text = cleanText(d.referenceNumber);
      notesController.text = cleanText(d.notes);
      invoiceDate.value = d.date ?? DateTime.now();
      dueDate.value = d.dueDate;
      items.assignAll(d.items.map((e) => e.copy()));
      _dirty = false;
    } else {
      loadError.value = result.error;
    }
    isLoadingInvoice.value = false;
  }

  void retryLoad() => _loadInvoice();

  // ---- Derived ---------------------------------------------------------------

  SettingController? get _settings => Get.isRegistered<SettingController>() ? Get.find<SettingController>() : null;

  String get invoiceNumber => isEdit ? existingInvoiceNumber.value : (_settings?.nextInvoiceNumber ?? '');

  double get total => items.fold(0.0, (s, i) => s + i.amountValue);

  double get tripAmount => quantity.value * parseAmount(priceText.value);

  List<Customer> get recentCustomers =>
      Get.isRegistered<InvoiceListController>() ? Get.find<InvoiceListController>().recentCustomers : const [];

  List<String> get vehicleOptions {
    final list = [...ChangeValue.vehicleTypes];
    if (vehicle.value.isNotEmpty && !list.any((v) => v.toLowerCase() == vehicle.value.toLowerCase())) {
      list.add(vehicle.value);
    }
    return list;
  }

  bool get hasUnsavedWork =>
      createdInvoice.value == null && (_dirty || (!isEdit && items.isNotEmpty) || (isEdit && _itemsChanged));
  bool _itemsChanged = false;

  // ---- Customer ------------------------------------------------------------

  void pickCustomer(Customer c) {
    HapticFeedback.selectionClick();
    nameController.text = cleanText(c.name);
    addressController.text = cleanText(c.address);
    cityController.text = cleanText(c.city);
    postalController.text = cleanText(c.postalCode);
    countryController.text = cleanText(c.country).isEmpty ? ChangeValue.defaultCountry : cleanText(c.country);
    stepError.value = null;
  }

  // ---- Dates ---------------------------------------------------------------

  Future<DateTime?> _pick(BuildContext context, DateTime initial, {DateTime? first}) {
    unFocus();
    return showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: first ?? DateTime(2000),
      lastDate: DateTime(DateTime.now().year + 5),
    );
  }

  Future<void> pickInvoiceDate(BuildContext context) async {
    final d = await _pick(context, invoiceDate.value);
    if (d == null) return;
    invoiceDate.value = d;
    _dirty = true;
    if (dueDate.value != null && dueDate.value!.isBefore(d)) {
      dueDate.value = d.add(const Duration(days: ChangeValue.defaultDueDays));
      showInfo("Due date moved to ${formatDate(dueDate.value)} so it's after the invoice date.");
    }
    stepError.value = null;
  }

  Future<void> pickDueDate(BuildContext context) async {
    final d = await _pick(context, dueDate.value ?? invoiceDate.value, first: invoiceDate.value);
    if (d == null) return;
    dueDate.value = d;
    _dirty = true;
    stepError.value = null;
  }

  void setDueInDays(int days) {
    HapticFeedback.selectionClick();
    dueDate.value = invoiceDate.value.add(Duration(days: days));
    _dirty = true;
    stepError.value = null;
  }

  // ---- Steps ---------------------------------------------------------------

  String? _validate(int s) {
    switch (s) {
      case 0:
        if (nameController.text.trim().isEmpty) return AppMessages.enterCustomerName;
      case 1:
        if (invoiceNumber.isEmpty) return AppMessages.invoiceNoMissing;
        if (dueDate.value == null) return AppMessages.selectDueDate;
        if (dueDate.value!.isBefore(DateUtils.dateOnly(invoiceDate.value))) return AppMessages.dueBeforeInvoice;
      case 2:
        if (items.isEmpty) return AppMessages.addOneTrip;
    }
    return null;
  }

  void next() {
    unFocus();
    final error = _validate(step.value);
    if (error != null) {
      stepError.value = error;
      HapticFeedback.heavyImpact();
      if (step.value == 1 && invoiceNumber.isEmpty) _settings?.fetchNextNumber();
      return;
    }
    stepError.value = null;
    if (step.value < 3) {
      forward = true;
      step.value++;
      HapticFeedback.selectionClick();
    } else {
      submit();
    }
  }

  void back() {
    unFocus();
    stepError.value = null;
    if (step.value > 0) {
      forward = false;
      step.value--;
    }
  }

  /// Jump back to a finished step from the progress bar or review screen.
  void goToStep(int s) {
    if (s >= step.value) return;
    unFocus();
    forward = false;
    stepError.value = null;
    step.value = s;
  }

  /// Returns true when the screen may close.
  Future<bool> confirmLeave() async {
    if (isSaving.value) return false;
    if (!hasUnsavedWork) return true;
    return confirmDialog(
      title: isEdit ? AppMessages.discardEditTitle : AppMessages.discardTitle,
      message: isEdit ? AppMessages.discardEditBody : AppMessages.discardBody,
    );
  }

  // ---- Trip sheet ------------------------------------------------------------

  void startTrip({int? index}) {
    editingIndex = index;
    tripError.value = null;
    if (index == null) {
      tripDate.value = items.isNotEmpty ? items.last.date : invoiceDate.value;
      descController.clear();
      priceController.clear();
      priceText.value = '';
      vehicle.value = items.isNotEmpty ? items.last.vehicle : ChangeValue.vehicleTypes.first;
      quantity.value = 1;
    } else {
      final i = items[index];
      tripDate.value = i.date;
      descController.text = cleanText(i.description);
      final price = i.priceValue;
      priceController.text = price == price.roundToDouble() ? price.toStringAsFixed(0) : price.toStringAsFixed(2);
      priceText.value = priceController.text;
      vehicle.value = i.vehicle;
      quantity.value = (i.quantity ?? 1) < 1 ? 1 : i.quantity!;
    }
  }

  Future<void> pickTripDate(BuildContext context) async {
    final d = await _pick(context, tripDate.value ?? invoiceDate.value);
    if (d != null) {
      tripDate.value = d;
      tripError.value = null;
    }
  }

  void selectVehicle(String v) {
    HapticFeedback.selectionClick();
    vehicle.value = v;
    tripError.value = null;
  }

  void incQty() {
    if (quantity.value >= 999) return;
    HapticFeedback.selectionClick();
    quantity.value++;
  }

  void decQty() {
    if (quantity.value <= 1) return;
    HapticFeedback.selectionClick();
    quantity.value--;
  }

  void onPriceChanged(String v) {
    priceText.value = v;
    tripError.value = null;
  }

  void saveTrip() {
    unFocus();
    String? error;
    final price = double.tryParse(priceController.text.trim());
    if (tripDate.value == null) {
      error = AppMessages.selectTripDate;
    } else if (descController.text.trim().isEmpty) {
      error = AppMessages.enterDescription;
    } else if (vehicle.value.trim().isEmpty) {
      error = AppMessages.selectVehicle;
    } else if (quantity.value < 1) {
      error = AppMessages.enterQuantity;
    } else if (priceController.text.trim().isNotEmpty && price == null) {
      error = AppMessages.enterValidPrice;
    } else if (price == null || price <= 0) {
      error = AppMessages.enterPrice;
    }
    if (error != null) {
      tripError.value = error;
      HapticFeedback.heavyImpact();
      return;
    }

    final item = InvoiceItems(
      id: 0,
      invoiceId: 0,
      dateInRange: 0,
      itemDate: toApiDate(tripDate.value!),
      description: descController.text.trim(),
      quantity: quantity.value,
      price: price!.toStringAsFixed(2),
      amount: (price * quantity.value).toStringAsFixed(2),
      minibusSuvSedan: vehicle.value,
    );
    if (editingIndex == null) {
      items.add(item);
    } else {
      items[editingIndex!] = item;
    }
    _itemsChanged = true;
    stepError.value = null;
    closeRoute();
    showSuccess(editingIndex == null ? AppMessages.tripAdded : AppMessages.tripUpdated);
  }

  Future<void> removeTrip(int index) async {
    final ok = await confirmDialog(
      title: AppMessages.removeTripTitle,
      message: AppMessages.removeTripBody,
      confirmText: "Remove",
      cancelText: "Cancel",
    );
    if (!ok) return;
    items.removeAt(index);
    _itemsChanged = true;
    showInfo(AppMessages.tripRemoved);
  }

  // ---- Submit ----------------------------------------------------------------

  InvoiceData _buildInvoice() => InvoiceData(
    id: invoiceId,
    invoiceNumber: invoiceNumber,
    referenceNumber: refController.text.trim(),
    invoiceDate: toApiDate(invoiceDate.value),
    invoiceDueDate: dueDate.value == null ? null : toApiDate(dueDate.value!),
    notes: notesController.text.trim(),
    customer: Customer(
      name: nameController.text.trim(),
      address: addressController.text.trim(),
      city: cityController.text.trim(),
      country: countryController.text.trim(),
      postalCode: postalController.text.trim(),
    ),
    invoiceItems: items.map((e) => e.copy()).toList(),
  );

  Future<void> submit() async {
    for (var s = 0; s < 3; s++) {
      final error = _validate(s);
      if (error != null) {
        goToStep(s);
        stepError.value = error;
        return;
      }
    }
    final invoice = _buildInvoice();
    isSaving.value = true;
    final result = isEdit ? await _repo.updateInvoice(invoice) : await _repo.createInvoice(invoice);

    if (!result.isOk) {
      isSaving.value = false;
      showError(result.error!, title: isEdit ? "Couldn't save changes" : "Couldn't create invoice");
      return;
    }

    if (Get.isRegistered<InvoiceListController>()) Get.find<InvoiceListController>().fetchInvoices();

    if (isEdit) {
      isSaving.value = false;
      _dirty = false;
      _itemsChanged = false;
      closeRoute(true);
      showSuccess(AppMessages.invoiceUpdated);
      return;
    }

    final increased = await _settings?.increaseNextNumber() ?? false;
    isSaving.value = false;
    HapticFeedback.heavyImpact();
    createdInvoice.value = invoice;
    if (!increased) showInfo(AppMessages.invoiceNoAutoIncreaseWarning);
  }

  // ---- After success -----------------------------------------------------------

  void viewPdf() => Get.offNamed(Routes.invoicePreview, arguments: createdInvoice.value);

  void createAnother() {
    for (final c in [nameController, addressController, cityController, postalController, refController]) {
      c.clear();
    }
    countryController.text = ChangeValue.defaultCountry;
    notesController.text = ChangeValue.defaultNotes;
    invoiceDate.value = DateTime.now();
    dueDate.value = DateTime.now().add(const Duration(days: ChangeValue.defaultDueDays));
    items.clear();
    forward = false;
    step.value = 0;
    stepError.value = null;
    _dirty = false;
    _itemsChanged = false;
    createdInvoice.value = null;
  }

  void backHome() => closeRoute(true);
}
