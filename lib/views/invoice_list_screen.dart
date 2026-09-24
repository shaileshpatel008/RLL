import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controller/invoice_list_controller.dart';
import '../controller/main_controller.dart';
import '../utility/app_messages.dart';
import '../utility/app_theme.dart';
import '../utility/global_function.dart';
import '../widgets/common_widgets.dart';
import '../widgets/invoice_tile.dart';

class InvoiceListScreen extends GetView<InvoiceListController> {
  const InvoiceListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final shell = Get.find<MainController>();
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // ---- Title bar ------------------------------------------------------
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: Row(
                children: [
                  Expanded(
                    child: Text("Invoices", style: AppTheme.display(size: 28, color: p.ink)),
                  ),
                  SquareIconButton(
                    icon: Icons.add_rounded,
                    tooltip: "New invoice",
                    filled: true,
                    onTap: shell.newInvoice,
                  ),
                ],
              ),
            ),
            // ---- Search --------------------------------------------------------
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Obx(
                () => TextField(
                  controller: controller.searchController,
                  onChanged: controller.onSearch,
                  textInputAction: TextInputAction.search,
                  decoration: InputDecoration(
                    hintText: "Search customer or invoice no.",
                    prefixIcon: const Icon(Icons.search_rounded),
                    suffixIcon: controller.query.value.isEmpty
                        ? null
                        : IconButton(
                            tooltip: "Clear search",
                            icon: const Icon(Icons.close_rounded),
                            onPressed: controller.clearSearch,
                          ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            // ---- Filter chips ----------------------------------------------------
            SizedBox(
              height: 38,
              child: Obx(() {
                final f = controller.filter.value;
                return ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    for (final (value, label) in [
                      (InvoiceFilter.all, "All"),
                      (InvoiceFilter.thisMonth, "This month"),
                      (InvoiceFilter.lastMonth, "Last month"),
                    ])
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: _FilterChip(
                          label: label,
                          selected: f == value,
                          onTap: () => controller.setFilter(value),
                        ),
                      ),
                  ],
                );
              }),
            ),
            const SizedBox(height: 8),
            // ---- List ------------------------------------------------------------
            Expanded(
              child: RefreshIndicator(
                onRefresh: () => controller.fetchInvoices(showErrorMessage: true),
                child: Obx(() {
                  if (controller.isLoading.value && controller.invoices.isEmpty) {
                    return ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 130),
                      itemCount: 6,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (_, _) => const InvoiceTileSkeleton(),
                    );
                  }
                  if (controller.error.value != null && controller.invoices.isEmpty) {
                    return _Scrollable(
                      child: EmptyState(
                        icon: Icons.cloud_off_rounded,
                        title: AppMessages.loadErrorTitle,
                        message: controller.error.value!,
                        actionText: "Try again",
                        onAction: () => controller.fetchInvoices(showErrorMessage: true),
                      ),
                    );
                  }
                  if (controller.invoices.isEmpty) {
                    return _Scrollable(
                      child: EmptyState(
                        icon: Icons.receipt_long_rounded,
                        title: AppMessages.noInvoicesTitle,
                        message: AppMessages.noInvoicesBody,
                        actionText: "Create invoice",
                        onAction: shell.newInvoice,
                      ),
                    );
                  }
                  final groups = controller.groups;
                  if (groups.isEmpty) {
                    return const _Scrollable(
                      child: EmptyState(
                        icon: Icons.search_off_rounded,
                        title: AppMessages.noResultsTitle,
                        message: AppMessages.noResultsBody,
                      ),
                    );
                  }
                  var index = 0;
                  return AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    child: ListView(
                      key: ValueKey("${controller.filter.value}-${controller.query.value}"),
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 130),
                      physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                      children: [
                        for (final g in groups) ...[
                          Padding(
                            padding: const EdgeInsets.only(top: 12, bottom: 10),
                            child: SectionLabel(
                              g.title,
                              trailing: Text(
                                "${g.invoices.length} · ${formatMoney(g.total)}",
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: p.muted),
                              ),
                            ),
                          ),
                          for (final inv in g.invoices)
                            FadeSlideIn(
                              delay: FadeSlideIn.stagger(index++),
                              child: Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: InvoiceTile(
                                  invoice: inv,
                                  onTap: () => controller.openInvoice(inv),
                                  onShare: () => controller.shareInvoice(inv),
                                  onEdit: inv.id == null ? null : () => controller.editInvoice(inv),
                                ),
                              ),
                            ),
                        ],
                      ],
                    ),
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Lets pull-to-refresh work on empty and error states.
class _Scrollable extends StatelessWidget {
  const _Scrollable({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 130),
      children: [child],
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({required this.label, required this.selected, required this.onTap});
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Pressable(
      onTap: onTap,
      scale: .94,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? p.ink : p.card,
          borderRadius: BorderRadius.circular(99),
          border: Border.all(color: selected ? p.ink : p.line, width: 1.5),
        ),
        child: Text(
          label,
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: selected ? p.bg : p.ink),
        ),
      ),
    );
  }
}
