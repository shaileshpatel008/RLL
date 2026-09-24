import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../api/invoice_repository.dart';
import '../models/invoice_list_model.dart';
import '../routes/app_pages.dart';
import '../utility/app_messages.dart';
import '../utility/global_function.dart';
import '../widgets/pdf_generate_widget.dart';

enum InvoiceFilter { all, thisMonth, lastMonth }

class InvoiceGroup {
  InvoiceGroup(this.title, this.invoices);
  final String title;
  final List<InvoiceData> invoices;
  double get total => invoices.fold(0.0, (s, i) => s + i.total);
}

class MonthTotal {
  MonthTotal(this.label, this.total, this.isCurrent);
  final String label;
  final double total;
  final bool isCurrent;
}

/// Owns the invoice list. The dashboard reads its stats from here too, so
/// the list is fetched once and shared.
class InvoiceListController extends GetxController {
  final _repo = const InvoiceRepository();

  final invoices = <InvoiceData>[].obs;
  final isLoading = true.obs;
  final error = RxnString();
  final query = ''.obs;
  final filter = InvoiceFilter.all.obs;
  final searchController = TextEditingController();

  @override
  void onInit() {
    super.onInit();
    fetchInvoices();
  }

  @override
  void onClose() {
    searchController.dispose();
    super.onClose();
  }

  Future<void> fetchInvoices({bool showErrorMessage = false}) async {
    if (invoices.isEmpty) isLoading.value = true;
    final result = await _repo.getInvoices();
    if (result.isOk) {
      invoices.assignAll(result.value!);
      error.value = null;
    } else {
      error.value = result.error;
      if (showErrorMessage || invoices.isNotEmpty) showError(result.error!);
    }
    isLoading.value = false;
  }

  void onSearch(String value) => query.value = value.trim().toLowerCase();

  void clearSearch() {
    searchController.clear();
    query.value = '';
    unFocus();
  }

  void setFilter(InvoiceFilter f) => filter.value = f;

  // ---- Derived data --------------------------------------------------------

  bool _sameMonth(DateTime? d, DateTime m) => d != null && d.year == m.year && d.month == m.month;

  List<InvoiceData> get filtered {
    final now = DateTime.now();
    final lastMonth = DateTime(now.year, now.month - 1);
    final q = query.value;
    return invoices.where((i) {
      final matchesFilter = switch (filter.value) {
        InvoiceFilter.all => true,
        InvoiceFilter.thisMonth => _sameMonth(i.date, now),
        InvoiceFilter.lastMonth => _sameMonth(i.date, lastMonth),
      };
      if (!matchesFilter) return false;
      if (q.isEmpty) return true;
      return i.customerName.toLowerCase().contains(q) ||
          (i.invoiceNumber ?? '').toLowerCase().contains(q) ||
          (i.referenceNumber ?? '').toLowerCase().contains(q);
    }).toList();
  }

  /// Filtered invoices grouped by month, newest first.
  List<InvoiceGroup> get groups {
    final map = <String, List<InvoiceData>>{};
    for (final i in filtered) {
      final key = i.date == null ? 'No date' : DateFormat('MMMM yyyy').format(i.date!);
      map.putIfAbsent(key, () => []).add(i);
    }
    return map.entries.map((e) => InvoiceGroup(e.key, e.value)).toList();
  }

  List<InvoiceData> get thisMonth => invoices.where((i) => _sameMonth(i.date, DateTime.now())).toList();
  double get thisMonthTotal => thisMonth.fold(0.0, (s, i) => s + i.total);

  List<InvoiceData> get recent => invoices.take(5).toList();

  /// Totals for the last six months, oldest first.
  List<MonthTotal> get lastSixMonths {
    final now = DateTime.now();
    return List.generate(6, (index) {
      final m = DateTime(now.year, now.month - (5 - index));
      final total = invoices.where((i) => _sameMonth(i.date, m)).fold(0.0, (s, i) => s + i.total);
      return MonthTotal(DateFormat('MMM').format(m), total, index == 5);
    });
  }

  /// Unique customers from past invoices, most recent first — used for
  /// one-tap fill on the new invoice form.
  List<Customer> get recentCustomers {
    final seen = <String>{};
    final list = <Customer>[];
    for (final i in invoices) {
      final c = i.customer;
      final key = cleanText(c?.name).toLowerCase();
      if (c == null || key.isEmpty || !seen.add(key)) continue;
      list.add(c);
      if (list.length == 8) break;
    }
    return list;
  }

  // ---- Actions -------------------------------------------------------------

  void openInvoice(InvoiceData invoice) => Get.toNamed(Routes.invoicePreview, arguments: invoice);

  Future<void> editInvoice(InvoiceData invoice) async {
    final changed = await Get.toNamed(Routes.invoiceForm, arguments: {'id': invoice.id});
    if (changed == true) fetchInvoices();
  }

  Future<void> shareInvoice(InvoiceData invoice) async {
    showLoader(AppMessages.preparingPdf);
    try {
      final file = await FileHandleApi.saveInvoice(invoice);
      hideLoader();
      await FileHandleApi.shareFile(file, invoice);
    } catch (e) {
      hideLoader();
      showError(AppMessages.unknownError);
    }
  }
}
