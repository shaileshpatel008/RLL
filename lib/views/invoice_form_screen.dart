import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../controller/invoice_form_controller.dart';
import '../models/invoice_list_model.dart';
import '../utility/app_colors.dart';
import '../utility/app_messages.dart';
import '../utility/app_theme.dart';
import '../utility/global_function.dart';
import '../widgets/common_widgets.dart';
import '../widgets/custom_text_field.dart';

class InvoiceFormScreen extends GetView<InvoiceFormController> {
  const InvoiceFormScreen({super.key});

  Future<void> _close() async {
    if (await controller.confirmLeave()) closeRoute();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Obx(() {
      final saving = controller.isSaving.value;
      final created = controller.createdInvoice.value;
      return PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) async {
          if (didPop) return;
          if (created != null) return controller.backHome();
          if (controller.step.value > 0 && !saving) return controller.back();
          await _close();
        },
        child: Stack(
          children: [
            Scaffold(
              body: SafeArea(
                child: Column(
                  children: [
                    _Header(onClose: _close),
                    const _StepBar(),
                    Expanded(child: _body(context)),
                    const _Footer(),
                  ],
                ),
              ),
            ),
            // Saving overlay
            IgnorePointer(
              ignoring: !saving,
              child: AnimatedOpacity(
                opacity: saving ? 1 : 0,
                duration: const Duration(milliseconds: 200),
                child: Container(
                  color: p.bg.withValues(alpha: .88),
                  alignment: Alignment.center,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 54,
                        height: 54,
                        child: CircularProgressIndicator(strokeWidth: 5, backgroundColor: p.soft),
                      ),
                      const SizedBox(height: 18),
                      Material(
                        type: MaterialType.transparency,
                        child: Text(
                          controller.isEdit ? AppMessages.updatingInvoice : AppMessages.creatingInvoice,
                          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: p.ink),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // Success
            if (created != null) _SuccessView(invoice: created),
          ],
        ),
      );
    });
  }

  Widget _body(BuildContext context) {
    if (controller.isLoadingInvoice.value) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Skeleton(height: 28, width: 240),
            SizedBox(height: 24),
            Skeleton(height: 52),
            SizedBox(height: 14),
            Skeleton(height: 52),
            SizedBox(height: 14),
            Skeleton(height: 52),
          ],
        ),
      );
    }
    if (controller.loadError.value != null) {
      return EmptyState(
        icon: Icons.cloud_off_rounded,
        title: "Couldn't open invoice",
        message: controller.loadError.value!,
        actionText: "Try again",
        onAction: controller.retryLoad,
      );
    }
    final step = controller.step.value;
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 320),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (child, animation) {
        final incoming = child.key == ValueKey(step);
        final dir = controller.forward ? 1.0 : -1.0;
        final begin = Offset((incoming ? .12 : -.12) * dir, 0);
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween(begin: begin, end: Offset.zero).animate(animation),
            child: child,
          ),
        );
      },
      child: KeyedSubtree(
        key: ValueKey(step),
        child: switch (step) {
          0 => const _CustomerStep(),
          1 => const _DetailsStep(),
          2 => const _TripsStep(),
          _ => const _ReviewStep(),
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Header / progress / footer
// ---------------------------------------------------------------------------

class _Header extends GetView<InvoiceFormController> {
  const _Header({required this.onClose});
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
      child: Row(
        children: [
          SquareIconButton(icon: Icons.close_rounded, tooltip: "Close", onTap: onClose),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  controller.isEdit ? "Edit invoice" : "New invoice",
                  style: AppTheme.display(size: 20, color: p.ink),
                ),
                Obx(() {
                  final no = controller.invoiceNumber;
                  return Text(
                    no.isEmpty ? "Getting invoice number…" : no,
                    style: AppTheme.mono(size: 12, color: p.muted),
                  );
                }),
              ],
            ),
          ),
          Obx(() {
            final show = controller.items.isNotEmpty;
            return AnimatedScale(
              scale: show ? 1 : 0,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutBack,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(color: p.soft, borderRadius: BorderRadius.circular(12)),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  transitionBuilder: (c, a) => ScaleTransition(scale: a, child: c),
                  child: Text(
                    formatMoney(controller.total),
                    key: ValueKey(controller.total),
                    style: AppTheme.display(size: 15, color: p.accent),
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _StepBar extends GetView<InvoiceFormController> {
  const _StepBar();

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Obx(() {
        final current = controller.step.value;
        return Row(
          children: [
            for (var i = 0; i < InvoiceFormController.stepTitles.length; i++) ...[
              if (i > 0) const SizedBox(width: 6),
              Expanded(
                child: Semantics(
                  label: "Step ${i + 1} of 4, ${InvoiceFormController.stepTitles[i]}",
                  button: i < current,
                  child: GestureDetector(
                    onTap: i < current ? () => controller.goToStep(i) : null,
                    behavior: HitTestBehavior.opaque,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(9),
                          child: SizedBox(
                            height: 5,
                            child: Stack(
                              children: [
                                Container(color: p.line),
                                AnimatedFractionallySizedBox(
                                  duration: const Duration(milliseconds: 380),
                                  curve: Curves.easeOutCubic,
                                  widthFactor: i <= current ? 1 : 0,
                                  child: Container(color: p.accent),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 7),
                        Row(
                          children: [
                            if (i < current) ...[
                              Icon(Icons.check_rounded, size: 13, color: p.ink),
                              const SizedBox(width: 2),
                            ],
                            Flexible(
                              child: Text(
                                i < current
                                    ? InvoiceFormController.stepTitles[i]
                                    : "${i + 1} ${InvoiceFormController.stepTitles[i]}",
                                maxLines: 1,
                                overflow: TextOverflow.fade,
                                softWrap: false,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: i == current ? p.accent : (i < current ? p.ink : p.muted),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ],
        );
      }),
    );
  }
}

class _Footer extends GetView<InvoiceFormController> {
  const _Footer();

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Obx(() {
      if (controller.isLoadingInvoice.value || controller.loadError.value != null) return const SizedBox.shrink();
      final step = controller.step.value;
      final last = step == 3;
      return Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        decoration: BoxDecoration(
          color: p.card,
          border: Border(top: BorderSide(color: p.line)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            InlineError(message: controller.stepError.value),
            Row(
              children: [
                AnimatedSize(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeOutCubic,
                  child: step == 0
                      ? const SizedBox.shrink()
                      : Padding(
                          padding: const EdgeInsets.only(right: 10),
                          child: SizedBox(
                            width: 108,
                            child: OutlinedButton(onPressed: controller.back, child: const Text("Back")),
                          ),
                        ),
                ),
                Expanded(
                  child: FilledButton(
                    onPressed: controller.isSaving.value ? null : controller.next,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(last ? (controller.isEdit ? "Save changes" : "Generate invoice") : "Continue"),
                        const SizedBox(width: 8),
                        Icon(last ? Icons.check_rounded : Icons.arrow_forward_rounded, size: 20),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    });
  }
}

class _StepScroll extends StatelessWidget {
  const _StepScroll({required this.title, required this.subtitle, required this.children});
  final String title;
  final String subtitle;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 22, 16, 24),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      physics: const BouncingScrollPhysics(),
      children: [
        Text(title, style: AppTheme.display(size: 26, color: p.ink, height: 1.15)),
        const SizedBox(height: 6),
        Text(subtitle, style: TextStyle(fontSize: 14, color: p.muted)),
        const SizedBox(height: 18),
        ...children,
      ],
    );
  }
}

const _gap = SizedBox(height: 14);

// ---------------------------------------------------------------------------
// Step 1 — Customer
// ---------------------------------------------------------------------------

class _CustomerStep extends GetView<InvoiceFormController> {
  const _CustomerStep();

  @override
  Widget build(BuildContext context) {
    final recent = controller.recentCustomers;
    return _StepScroll(
      title: "Who is this invoice for?",
      subtitle: recent.isEmpty ? "Enter the customer's details." : "Pick a recent customer or type new details.",
      children: [
        if (recent.isNotEmpty) ...[
          SizedBox(
            height: 40,
            child: Obx(() {
              final selected = controller.customerName.value.toLowerCase();
              return ListView.separated(
                scrollDirection: Axis.horizontal,
                clipBehavior: Clip.none,
                itemCount: recent.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (_, i) => _CustomerChip(
                  customer: recent[i],
                  selected: cleanText(recent[i].name).toLowerCase() == selected,
                  onTap: () => controller.pickCustomer(recent[i]),
                ),
              );
            }),
          ),
          const SizedBox(height: 18),
        ],
        TextFormFieldWidget(
          label: "Customer name",
          hint: "e.g. Greenfield Primary School",
          icon: Icons.person_rounded,
          controller: controller.nameController,
          onChanged: (_) => controller.stepError.value = null,
        ),
        _gap,
        TextFormFieldWidget(
          label: "Address",
          hint: "Street and number",
          icon: Icons.location_on_rounded,
          controller: controller.addressController,
          keyboardType: TextInputType.streetAddress,
        ),
        _gap,
        Row(
          children: [
            Expanded(
              child: TextFormFieldWidget(label: "City", controller: controller.cityController),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormFieldWidget(
                label: "Postcode",
                controller: controller.postalController,
                capitalization: TextCapitalization.characters,
              ),
            ),
          ],
        ),
        _gap,
        TextFormFieldWidget(
          label: "Country",
          controller: controller.countryController,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => controller.next(),
        ),
      ],
    );
  }
}

class _CustomerChip extends StatelessWidget {
  const _CustomerChip({required this.customer, required this.selected, required this.onTap});
  final Customer customer;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final name = cleanText(customer.name);
    return Pressable(
      onTap: onTap,
      scale: .94,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: const EdgeInsets.fromLTRB(5, 5, 14, 5),
        decoration: BoxDecoration(
          color: selected ? p.ink : p.card,
          borderRadius: BorderRadius.circular(99),
          border: Border.all(color: selected ? p.ink : p.line, width: 1.5),
        ),
        child: Row(
          children: [
            InitialsAvatar(text: initials(name), seed: name, size: 28),
            const SizedBox(width: 8),
            Text(
              name,
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: selected ? p.bg : p.ink),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Step 2 — Details
// ---------------------------------------------------------------------------

class _DetailsStep extends GetView<InvoiceFormController> {
  const _DetailsStep();

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return _StepScroll(
      title: "Invoice details",
      subtitle: controller.isEdit
          ? "The invoice number stays the same when you edit."
          : "The number is issued automatically from Settings.",
      children: [
        Text(
          "Invoice number",
          style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: p.muted),
        ),
        const SizedBox(height: 6),
        Container(
          height: 52,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(color: p.soft, borderRadius: BorderRadius.circular(14)),
          child: Row(
            children: [
              Icon(Icons.lock_rounded, size: 18, color: p.accent),
              const SizedBox(width: 10),
              Expanded(
                child: Obx(
                  () => Text(
                    controller.invoiceNumber.isEmpty ? "Loading…" : controller.invoiceNumber,
                    style: AppTheme.mono(size: 15, weight: FontWeight.w700, color: p.ink),
                  ),
                ),
              ),
              Text(
                controller.isEdit ? "FIXED" : "AUTO",
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: p.accent, letterSpacing: .8),
              ),
            ],
          ),
        ),
        _gap,
        TextFormFieldWidget(
          label: "Reference no. (optional)",
          hint: "e.g. PO-2291",
          icon: Icons.tag_rounded,
          controller: controller.refController,
          capitalization: TextCapitalization.characters,
        ),
        _gap,
        Obx(
          () => Row(
            children: [
              Expanded(
                child: PickerField(
                  label: "Invoice date",
                  value: formatDate(controller.invoiceDate.value),
                  onTap: () => controller.pickInvoiceDate(context),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: PickerField(
                  label: "Due date",
                  value: controller.dueDate.value == null ? null : formatDate(controller.dueDate.value),
                  icon: Icons.event_available_rounded,
                  onTap: () => controller.pickDueDate(context),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Obx(() {
          final due = controller.dueDate.value;
          final days = due == null
              ? null
              : DateUtils.dateOnly(due).difference(DateUtils.dateOnly(controller.invoiceDate.value)).inDays;
          return Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final d in const [0, 7, 14, 30])
                ChoiceChip(
                  label: Text(d == 0 ? "On receipt" : "$d days"),
                  selected: days == d,
                  onSelected: (_) => controller.setDueInDays(d),
                  showCheckmark: false,
                  labelStyle: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 12.5,
                    color: days == d ? Colors.white : p.ink,
                  ),
                  selectedColor: p.accent,
                  backgroundColor: p.card,
                  side: BorderSide(color: days == d ? p.accent : p.line),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(99)),
                ),
            ],
          );
        }),
        _gap,
        TextFormFieldWidget(
          label: "Notes on invoice",
          hint: "Anything the customer should know",
          controller: controller.notesController,
          capitalization: TextCapitalization.sentences,
          maxLines: 3,
          keyboardType: TextInputType.multiline,
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Step 3 — Trips
// ---------------------------------------------------------------------------

class _TripsStep extends GetView<InvoiceFormController> {
  const _TripsStep();

  void _openSheet({int? index}) {
    controller.startTrip(index: index);
    Get.bottomSheet(
      const _TripSheet(),
      isScrollControlled: true,
      enterBottomSheetDuration: const Duration(milliseconds: 340),
      exitBottomSheetDuration: const Duration(milliseconds: 220),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return _StepScroll(
      title: "Trips & services",
      subtitle: "Add each journey. The amount is worked out for you.",
      children: [
        Obx(() {
          final items = controller.items;
          return Column(
            children: [
              for (var i = 0; i < items.length; i++)
                FadeSlideIn(
                  key: ValueKey(items[i]),
                  delay: FadeSlideIn.stagger(i),
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _TripCard(
                      item: items[i],
                      onEdit: () => _openSheet(index: i),
                      onRemove: () => controller.removeTrip(i),
                    ),
                  ),
                ),
            ],
          );
        }),
        Pressable(
          onTap: () => _openSheet(),
          child: DashedBox(
            color: p.line,
            child: SizedBox(
              height: 58,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_rounded, color: p.accent),
                  const SizedBox(width: 8),
                  Text(
                    "Add trip",
                    style: TextStyle(color: p.accent, fontWeight: FontWeight.w800, fontSize: 15),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Obx(
          () => _TotalCard(
            label: "Invoice total",
            caption: "${controller.items.length} ${controller.items.length == 1 ? 'trip' : 'trips'}",
            total: controller.total,
          ),
        ),
      ],
    );
  }
}

class _TripCard extends StatelessWidget {
  const _TripCard({required this.item, required this.onEdit, required this.onRemove});
  final InvoiceItems item;
  final VoidCallback onEdit;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return AppCard(
      onTap: onEdit,
      padding: const EdgeInsets.fromLTRB(14, 12, 4, 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IconTile(icon: Icons.airport_shuttle_rounded, bg: p.soft, fg: p.accent, size: 42),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  cleanText(item.description),
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: p.ink),
                ),
                const SizedBox(height: 3),
                Text("${formatDate(item.date)} · ${item.vehicle}", style: TextStyle(fontSize: 12, color: p.muted)),
                Text(
                  "${item.quantity ?? 1} × ${formatMoney(item.priceValue)}",
                  style: TextStyle(fontSize: 12, color: p.muted),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Padding(
                padding: const EdgeInsets.only(right: 10),
                child: Text(formatMoney(item.amountValue), style: AppTheme.display(size: 15, color: p.ink)),
              ),
              Row(
                children: [
                  IconButton(
                    tooltip: "Edit trip",
                    visualDensity: VisualDensity.compact,
                    onPressed: onEdit,
                    icon: Icon(Icons.edit_rounded, size: 18, color: p.muted),
                  ),
                  IconButton(
                    tooltip: "Remove trip",
                    visualDensity: VisualDensity.compact,
                    onPressed: onRemove,
                    icon: const Icon(Icons.delete_outline_rounded, size: 19, color: AppColors.error),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TotalCard extends StatelessWidget {
  const _TotalCard({required this.label, required this.caption, required this.total});
  final String label;
  final String caption;
  final double total;

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(color: AppColors.deep, borderRadius: BorderRadius.circular(20)),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: const TextStyle(color: Color(0xFFC9BEF3), fontWeight: FontWeight.w700, fontSize: 13),
                      ),
                      Text(caption, style: const TextStyle(color: Color(0xFFC9BEF3), fontSize: 12)),
                    ],
                  ),
                ),
                TweenAnimationBuilder<double>(
                  tween: Tween(end: total),
                  duration: const Duration(milliseconds: 500),
                  curve: Curves.easeOutCubic,
                  builder: (_, v, _) => Text(
                    formatMoney(v),
                    style: AppTheme.display(size: 28, weight: FontWeight.w800, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
          const RainbowStripe(height: 5),
        ],
      ),
    );
  }
}

/// Dashed rounded border for the "Add trip" button.
class DashedBox extends StatelessWidget {
  const DashedBox({super.key, required this.child, required this.color});
  final Widget child;
  final Color color;

  @override
  Widget build(BuildContext context) => CustomPaint(painter: _DashPainter(color), child: child);
}

class _DashPainter extends CustomPainter {
  _DashPainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final rrect = RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(18));
    final path = Path()..addRRect(rrect.deflate(1));
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    for (final metric in path.computeMetrics()) {
      var d = 0.0;
      while (d < metric.length) {
        canvas.drawPath(metric.extractPath(d, math.min(d + 8, metric.length)), paint);
        d += 14;
      }
    }
  }

  @override
  bool shouldRepaint(_DashPainter old) => old.color != color;
}

// ---------------------------------------------------------------------------
// Trip bottom sheet
// ---------------------------------------------------------------------------

class _TripSheet extends GetView<InvoiceFormController> {
  const _TripSheet();

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final editing = controller.editingIndex != null;
    final keyboard = MediaQuery.viewInsetsOf(context).bottom;
    // Always fits between the status bar and the keyboard; the list scrolls.
    final maxHeight = (MediaQuery.sizeOf(context).height - keyboard - MediaQuery.paddingOf(context).top) * .95;
    return Padding(
      padding: EdgeInsets.only(bottom: keyboard),
      child: Container(
        constraints: BoxConstraints(maxHeight: maxHeight),
        decoration: BoxDecoration(
          color: p.card,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 10),
              Container(
                width: 40,
                height: 5,
                decoration: BoxDecoration(color: p.line, borderRadius: BorderRadius.circular(9)),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 8, 4),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(editing ? "Edit trip" : "Add trip", style: AppTheme.display(size: 22, color: p.ink)),
                    ),
                    IconButton(tooltip: "Close", onPressed: closeRoute, icon: const Icon(Icons.close_rounded)),
                  ],
                ),
              ),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                  keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                  children: [
                    Obx(
                      () => PickerField(
                        label: "Trip date",
                        value: controller.tripDate.value == null ? null : formatDate(controller.tripDate.value),
                        onTap: () => controller.pickTripDate(context),
                      ),
                    ),
                    _gap,
                    TextFormFieldWidget(
                      label: "Description",
                      hint: "e.g. Airport transfer – Gatwick",
                      controller: controller.descController,
                      capitalization: TextCapitalization.sentences,
                      onChanged: (_) => controller.tripError.value = null,
                    ),
                    _gap,
                    Text(
                      "Vehicle",
                      style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: p.muted),
                    ),
                    const SizedBox(height: 6),
                    Obx(() {
                      final options = controller.vehicleOptions;
                      return Row(
                        children: [
                          for (var i = 0; i < options.length; i++) ...[
                            if (i > 0) const SizedBox(width: 8),
                            Expanded(
                              child: _VehicleOption(
                                label: options[i],
                                icon: switch (options[i].toLowerCase()) {
                                  'minibus' => Icons.airport_shuttle_rounded,
                                  'suv' => Icons.directions_car_filled_rounded,
                                  'sedan' => Icons.local_taxi_rounded,
                                  _ => Icons.commute_rounded,
                                },
                                selected: controller.vehicle.value == options[i],
                                onTap: () => controller.selectVehicle(options[i]),
                              ),
                            ),
                          ],
                        ],
                      );
                    }),
                    _gap,
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Quantity",
                                style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: p.muted),
                              ),
                              const SizedBox(height: 6),
                              Container(
                                height: 52,
                                decoration: BoxDecoration(
                                  color: p.field,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(color: p.line, width: 1.5),
                                ),
                                child: Obx(
                                  () => Row(
                                    children: [
                                      IconButton(
                                        tooltip: "Decrease",
                                        onPressed: controller.quantity.value > 1 ? controller.decQty : null,
                                        icon: Icon(Icons.remove_rounded, color: p.accent),
                                      ),
                                      Expanded(
                                        child: AnimatedSwitcher(
                                          duration: const Duration(milliseconds: 180),
                                          transitionBuilder: (c, a) => ScaleTransition(scale: a, child: c),
                                          child: Text(
                                            "${controller.quantity.value}",
                                            key: ValueKey(controller.quantity.value),
                                            textAlign: TextAlign.center,
                                            style: AppTheme.display(size: 18, color: p.ink),
                                          ),
                                        ),
                                      ),
                                      IconButton(
                                        tooltip: "Increase",
                                        onPressed: controller.incQty,
                                        icon: Icon(Icons.add_rounded, color: p.accent),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormFieldWidget(
                            label: "Price",
                            hint: "0.00",
                            prefixText: "£ ",
                            controller: controller.priceController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            textInputAction: TextInputAction.done,
                            inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d{0,7}(\.\d{0,2})?'))],
                            onChanged: controller.onPriceChanged,
                            onSubmitted: (_) => controller.saveTrip(),
                          ),
                        ),
                      ],
                    ),
                    _gap,
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(color: p.soft, borderRadius: BorderRadius.circular(14)),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              "Amount",
                              style: TextStyle(fontWeight: FontWeight.w700, color: p.muted),
                            ),
                          ),
                          Obx(
                            () => TweenAnimationBuilder<double>(
                              tween: Tween(end: controller.tripAmount),
                              duration: const Duration(milliseconds: 300),
                              builder: (_, v, _) =>
                                  Text(formatMoney(v), style: AppTheme.display(size: 22, color: p.accent)),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    Obx(() => InlineError(message: controller.tripError.value)),
                    FilledButton(
                      onPressed: controller.saveTrip,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.check_rounded, size: 20),
                          const SizedBox(width: 8),
                          Text(editing ? "Update trip" : "Add to invoice"),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _VehicleOption extends StatelessWidget {
  const _VehicleOption({required this.label, required this.icon, required this.selected, required this.onTap});
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Semantics(
      button: true,
      selected: selected,
      child: Pressable(
        onTap: onTap,
        scale: .94,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          height: 68,
          decoration: BoxDecoration(
            color: selected ? p.soft : p.field,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: selected ? p.accent : p.line, width: selected ? 2 : 1.5),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedScale(
                scale: selected ? 1.15 : 1,
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutBack,
                child: Icon(icon, size: 22, color: selected ? p.accent : p.muted),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: selected ? p.accent : p.ink),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Step 4 — Review
// ---------------------------------------------------------------------------

class _ReviewStep extends GetView<InvoiceFormController> {
  const _ReviewStep();

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final address = [
      controller.addressController.text,
      controller.cityController.text,
      controller.countryController.text,
      controller.postalController.text,
    ].map((e) => e.trim()).where((e) => e.isNotEmpty).join(', ');

    Widget kv(String k, String v, {bool mono = false}) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            k,
            style: TextStyle(color: p.muted, fontWeight: FontWeight.w600, fontSize: 14),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              v,
              textAlign: TextAlign.right,
              style: mono
                  ? AppTheme.mono(size: 13, weight: FontWeight.w700, color: p.ink)
                  : TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: p.ink),
            ),
          ),
        ],
      ),
    );

    Widget editLink(int step) => TextButton(onPressed: () => controller.goToStep(step), child: const Text("Edit"));

    return _StepScroll(
      title: "Looks good?",
      subtitle: controller.isEdit ? "Check your changes before saving." : "Check everything before the PDF is created.",
      children: [
        FadeSlideIn(
          child: AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SectionLabel("Bill to", trailing: editLink(0)),
                Text(
                  controller.nameController.text.trim(),
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: p.ink),
                ),
                if (address.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(address, style: TextStyle(color: p.muted, fontSize: 13)),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        FadeSlideIn(
          delay: const Duration(milliseconds: 60),
          child: AppCard(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
            child: Column(
              children: [
                SectionLabel("Details", trailing: editLink(1)),
                kv("Invoice no.", controller.invoiceNumber, mono: true),
                kv(
                  "Reference",
                  controller.refController.text.trim().isEmpty ? "—" : controller.refController.text.trim(),
                ),
                kv("Invoice date", formatDate(controller.invoiceDate.value)),
                kv("Due date", formatDate(controller.dueDate.value)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        FadeSlideIn(
          delay: const Duration(milliseconds: 120),
          child: AppCard(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
            child: Column(
              children: [
                SectionLabel("Trips", trailing: editLink(2)),
                for (final i in controller.items)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                cleanText(i.description),
                                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: p.ink),
                              ),
                              Text(
                                "${formatDateShort(i.date)} · ${i.vehicle} · ${i.quantity} × ${formatMoney(i.priceValue)}",
                                style: TextStyle(fontSize: 12, color: p.muted),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          formatMoney(i.amountValue),
                          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: p.ink),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        FadeSlideIn(
          delay: const Duration(milliseconds: 180),
          child: _TotalCard(
            label: "Total due",
            caption: "Due ${formatDate(controller.dueDate.value)}",
            total: controller.total,
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Success
// ---------------------------------------------------------------------------

class _SuccessView extends StatefulWidget {
  const _SuccessView({required this.invoice});
  final InvoiceData invoice;

  @override
  State<_SuccessView> createState() => _SuccessViewState();
}

class _SuccessViewState extends State<_SuccessView> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))
    ..forward();

  Animation<double> _i(double a, double b, [Curve c = Curves.easeOutCubic]) => CurvedAnimation(
    parent: _c,
    curve: Interval(a, b, curve: c),
  );

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final controller = Get.find<InvoiceFormController>();
    return Material(
      color: p.bg,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Spacer(),
              // Rainbow ring that spins in, then the check draws itself
              AnimatedBuilder(
                animation: _c,
                builder: (_, _) {
                  final ring = _i(0, .55, Curves.easeOutBack).value;
                  return Transform.rotate(
                    angle: (1 - _i(0, .6).value) * -math.pi,
                    child: Transform.scale(
                      scale: .3 + .7 * ring,
                      child: Container(
                        width: 136,
                        height: 136,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: SweepGradient(colors: [...AppColors.rainbow, AppColors.red]),
                        ),
                        padding: const EdgeInsets.all(11),
                        child: Container(
                          decoration: BoxDecoration(shape: BoxShape.circle, color: p.bg),
                          child: CustomPaint(painter: _CheckPainter(_i(.45, .85).value, p.accent)),
                        ),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 28),
              FadeTransition(
                opacity: _i(.5, 1),
                child: SlideTransition(
                  position: Tween(begin: const Offset(0, .3), end: Offset.zero).animate(_i(.5, 1)),
                  child: Column(
                    children: [
                      Text(AppMessages.invoiceCreated, style: AppTheme.display(size: 28, color: p.ink)),
                      const SizedBox(height: 8),
                      Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: widget.invoice.invoiceNumber ?? '',
                              style: AppTheme.mono(size: 14, weight: FontWeight.w700, color: p.ink),
                            ),
                            TextSpan(
                              text: " for ${widget.invoice.customerName}",
                              style: TextStyle(color: p.muted),
                            ),
                          ],
                        ),
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 15),
                      ),
                      const SizedBox(height: 10),
                      CountUpText(
                        value: widget.invoice.total,
                        format: formatMoney,
                        style: AppTheme.display(size: 36, weight: FontWeight.w800, color: p.accent),
                      ),
                    ],
                  ),
                ),
              ),
              const Spacer(),
              FadeTransition(
                opacity: _i(.7, 1),
                child: Column(
                  children: [
                    FilledButton.icon(
                      onPressed: controller.viewPdf,
                      icon: const Icon(Icons.picture_as_pdf_rounded, size: 20),
                      label: const Text("View & share PDF"),
                    ),
                    const SizedBox(height: 10),
                    FilledButton.icon(
                      style: FilledButton.styleFrom(backgroundColor: p.soft, foregroundColor: p.accent),
                      onPressed: controller.createAnother,
                      icon: const Icon(Icons.add_rounded, size: 20),
                      label: const Text("Create another"),
                    ),
                    const SizedBox(height: 10),
                    OutlinedButton(onPressed: controller.backHome, child: const Text("Back to home")),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CheckPainter extends CustomPainter {
  _CheckPainter(this.progress, this.color);
  final double progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;
    final path = Path()
      ..moveTo(size.width * .28, size.height * .52)
      ..lineTo(size.width * .44, size.height * .67)
      ..lineTo(size.width * .74, size.height * .36);
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 9
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    for (final m in path.computeMetrics()) {
      canvas.drawPath(m.extractPath(0, m.length * progress), paint);
    }
  }

  @override
  bool shouldRepaint(_CheckPainter old) => old.progress != progress || old.color != color;
}
