import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:printing/printing.dart';

import '../controller/invoice_preview_controller.dart';
import '../utility/app_colors.dart';
import '../utility/app_theme.dart';
import '../utility/global_function.dart';
import '../widgets/common_widgets.dart';

class InvoicePreviewScreen extends GetView<InvoicePreviewController> {
  const InvoicePreviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // ---- Header ------------------------------------------------------
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
              child: Obx(() {
                final inv = controller.invoice.value;
                final name = inv.customerName.isEmpty ? "Invoice" : inv.customerName;
                return Row(
                  children: [
                    SquareIconButton(icon: Icons.arrow_back_rounded, tooltip: "Back", onTap: closeRoute),
                    const SizedBox(width: 12),
                    Hero(
                      tag: 'avatar-${inv.id ?? inv.invoiceNumber}',
                      child: InitialsAvatar(text: initials(name), seed: name, size: 40),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: p.ink),
                          ),
                          Text(inv.invoiceNumber ?? '', style: AppTheme.mono(size: 12, color: p.muted)),
                        ],
                      ),
                    ),
                    if (inv.id != null)
                      SquareIconButton(icon: Icons.edit_rounded, tooltip: "Edit invoice", onTap: controller.edit),
                  ],
                );
              }),
            ),
            // ---- Summary strip -------------------------------------------------
            Obx(() {
              final inv = controller.invoice.value;
              return FadeSlideIn(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      _Stat(label: "Total", value: formatMoney(inv.total), strong: true),
                      const SizedBox(width: 8),
                      _Stat(label: "Issued", value: formatDate(inv.date, 'dd MMM')),
                      const SizedBox(width: 8),
                      _Stat(label: "Due", value: formatDate(inv.dueDate, 'dd MMM')),
                    ],
                  ),
                ),
              );
            }),
            const SizedBox(height: 12),
            // ---- PDF -------------------------------------------------------------
            Expanded(
              child: Obx(() {
                if (controller.error.value != null) {
                  return EmptyState(
                    icon: Icons.picture_as_pdf_rounded,
                    title: "Couldn't create the PDF",
                    message: controller.error.value!,
                    actionText: "Try again",
                    onAction: controller.buildPdf,
                  );
                }
                final bytes = controller.bytes.value;
                return AnimatedSwitcher(
                  duration: const Duration(milliseconds: 350),
                  child: bytes == null
                      ? const Center(
                          key: ValueKey('loading'),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CircularProgressIndicator(),
                              SizedBox(height: 14),
                              Text("Preparing PDF…", style: TextStyle(fontWeight: FontWeight.w700)),
                            ],
                          ),
                        )
                      : PdfPreview(
                          key: ValueKey(bytes.hashCode),
                          build: (_) async => bytes,
                          useActions: false,
                          canChangeOrientation: false,
                          canChangePageFormat: false,
                          canDebug: false,
                          allowPrinting: false,
                          allowSharing: false,
                          scrollViewDecoration: BoxDecoration(color: p.bg),
                          pdfPreviewPageDecoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.deep.withValues(alpha: .18),
                                blurRadius: 30,
                                offset: const Offset(0, 14),
                              ),
                            ],
                          ),
                          previewPageMargin: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                          loadingWidget: const Center(child: CircularProgressIndicator()),
                          pdfFileName: controller.invoice.value.invoiceNumber,
                        ),
                );
              }),
            ),
            // ---- Actions ---------------------------------------------------------
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              decoration: BoxDecoration(
                color: p.card,
                border: Border(top: BorderSide(color: p.line)),
              ),
              child: Obx(() {
                final ready = controller.bytes.value != null;
                return Row(
                  children: [
                    _ActionIcon(
                      icon: Icons.download_rounded,
                      tooltip: "Save PDF",
                      onTap: ready ? controller.download : null,
                    ),
                    const SizedBox(width: 10),
                    _ActionIcon(icon: Icons.print_rounded, tooltip: "Print", onTap: ready ? controller.printPdf : null),
                    const SizedBox(width: 10),
                    _ActionIcon(icon: Icons.copy_rounded, tooltip: "Copy invoice number", onTap: controller.copyNumber),
                    const SizedBox(width: 10),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: ready ? controller.share : null,
                        icon: const Icon(Icons.ios_share_rounded, size: 20),
                        label: const Text("Share"),
                      ),
                    ),
                  ],
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value, this.strong = false});
  final String label;
  final String value;
  final bool strong;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Expanded(
      flex: strong ? 3 : 2,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: strong ? AppColors.deep : p.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: strong ? AppColors.deep : p.line),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: strong ? const Color(0xFFC9BEF3) : p.muted,
              ),
            ),
            const SizedBox(height: 2),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(value, style: AppTheme.display(size: 17, color: strong ? Colors.white : p.ink)),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionIcon extends StatelessWidget {
  const _ActionIcon({required this.icon, required this.tooltip, required this.onTap});
  final IconData icon;
  final String tooltip;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Tooltip(
      message: tooltip,
      child: Pressable(
        onTap: onTap,
        scale: .9,
        child: AnimatedOpacity(
          opacity: onTap == null ? .4 : 1,
          duration: const Duration(milliseconds: 200),
          child: Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: p.card,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: p.line, width: 1.5),
            ),
            child: Icon(icon, color: p.ink, size: 22),
          ),
        ),
      ),
    );
  }
}
