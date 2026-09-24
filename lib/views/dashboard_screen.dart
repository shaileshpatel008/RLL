import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../controller/dashboard_controller.dart';
import '../controller/invoice_list_controller.dart';
import '../utility/app_colors.dart';
import '../utility/app_messages.dart';
import '../utility/app_theme.dart';
import '../utility/change_value.dart';
import '../utility/global_function.dart';
import '../widgets/common_widgets.dart';
import '../widgets/invoice_tile.dart';

class DashboardScreen extends GetView<DashboardController> {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: controller.refreshAll,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 130),
            physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
            children: [
              // ---- Header -----------------------------------------------------
              FadeSlideIn(
                child: Row(
                  children: [
                    const AppLogo(size: 52),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            greeting(),
                            style: TextStyle(fontSize: 13, color: p.muted, fontWeight: FontWeight.w600),
                          ),
                          Text(ChangeValue.mainTitle, style: AppTheme.display(size: 20, color: p.ink)),
                        ],
                      ),
                    ),
                    SquareIconButton(
                      icon: Icons.settings_rounded,
                      tooltip: "Settings",
                      onTap: () => controller.shell.changeTab(2),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              // ---- Hero stats card ---------------------------------------------
              FadeSlideIn(
                delay: const Duration(milliseconds: 60),
                child: _StatsCard(controller: controller),
              ),
              const SizedBox(height: 16),
              // ---- Quick actions ------------------------------------------------
              FadeSlideIn(
                delay: const Duration(milliseconds: 120),
                child: Row(
                  children: [
                    Expanded(
                      child: Obx(
                        () => _QuickAction(
                          icon: Icons.add_rounded,
                          title: "New invoice",
                          subtitle: controller.settings.nextNumber.isEmpty
                              ? "Tap to start"
                              : "Next · ${controller.settings.nextNumber}",
                          primary: true,
                          onTap: controller.shell.newInvoice,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _QuickAction(
                        icon: Icons.receipt_long_rounded,
                        title: "All invoices",
                        subtitle: "Search & share",
                        tone: AppColors.tones[3],
                        onTap: () => controller.shell.changeTab(1),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _QuickAction(
                        icon: Icons.tag_rounded,
                        title: "Numbering",
                        subtitle: "${ChangeValue.invoiceNoTitle}/${DateTime.now().year}",
                        tone: AppColors.tones[1],
                        onTap: () => controller.shell.changeTab(2),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 26),
              // ---- Recent invoices ----------------------------------------------
              SectionLabel(
                "Recent invoices",
                trailing: TextButton(onPressed: () => controller.shell.changeTab(1), child: const Text("See all")),
              ),
              const SizedBox(height: 6),
              Obx(() {
                final list = controller.invoices;
                if (list.isLoading.value) {
                  return Column(
                    children: List.generate(
                      3,
                      (_) => const Padding(padding: EdgeInsets.only(bottom: 10), child: InvoiceTileSkeleton()),
                    ),
                  );
                }
                if (list.error.value != null && list.invoices.isEmpty) {
                  return EmptyState(
                    icon: Icons.cloud_off_rounded,
                    title: AppMessages.loadErrorTitle,
                    message: list.error.value!,
                    actionText: "Try again",
                    onAction: () => list.fetchInvoices(showErrorMessage: true),
                  );
                }
                if (list.invoices.isEmpty) {
                  return EmptyState(
                    icon: Icons.receipt_long_rounded,
                    title: AppMessages.noInvoicesTitle,
                    message: AppMessages.noInvoicesBody,
                    actionText: "Create invoice",
                    onAction: controller.shell.newInvoice,
                  );
                }
                final recent = list.recent;
                return Column(
                  children: [
                    for (var i = 0; i < recent.length; i++)
                      FadeSlideIn(
                        delay: FadeSlideIn.stagger(i, stepMs: 60) + const Duration(milliseconds: 150),
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: InvoiceTile(invoice: recent[i], hero: false, onTap: () => list.openInvoice(recent[i])),
                        ),
                      ),
                  ],
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatsCard extends StatelessWidget {
  const _StatsCard({required this.controller});
  final DashboardController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.deep,
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(color: AppColors.deep.withValues(alpha: .35), blurRadius: 30, offset: const Offset(0, 16)),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
            child: Obx(() {
              final list = controller.invoices;
              final loading = list.isLoading.value && list.invoices.isEmpty;
              final count = list.thisMonth.length;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          "Billed in ${DateFormat('MMMM').format(DateTime.now())}",
                          style: const TextStyle(color: Color(0xFFC9BEF3), fontWeight: FontWeight.w700, fontSize: 13),
                        ),
                      ),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        child: Container(
                          key: ValueKey(count),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: .12),
                            borderRadius: BorderRadius.circular(99),
                          ),
                          child: Text(
                            loading ? "…" : "$count ${count == 1 ? 'invoice' : 'invoices'}",
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    height: 48,
                    child: loading
                        ? const Align(
                            alignment: Alignment.centerLeft,
                            child: SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(strokeWidth: 3, color: Colors.white54),
                            ),
                          )
                        : FittedBox(
                            alignment: Alignment.centerLeft,
                            fit: BoxFit.scaleDown,
                            child: CountUpText(
                              key: ValueKey(list.thisMonthTotal),
                              value: list.thisMonthTotal,
                              format: formatMoney,
                              style: AppTheme.display(size: 42, weight: FontWeight.w800, color: Colors.white),
                            ),
                          ),
                  ),
                  const SizedBox(height: 16),
                  _MonthBars(months: list.lastSixMonths, key: ValueKey(list.invoices.length)),
                ],
              );
            }),
          ),
          const RainbowStripe(height: 6),
        ],
      ),
    );
  }
}

class _MonthBars extends StatelessWidget {
  const _MonthBars({super.key, required this.months});
  final List<MonthTotal> months;

  @override
  Widget build(BuildContext context) {
    final max = months.fold<double>(0, (m, e) => e.total > m ? e.total : m);
    return Semantics(
      label: "Monthly totals: ${months.map((m) => '${m.label} ${formatMoney(m.total)}').join(', ')}",
      child: SizedBox(
        height: 64,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            for (var i = 0; i < months.length; i++) ...[
              if (i > 0) const SizedBox(width: 8),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: max == 0 ? 0 : months[i].total / max),
                      duration: Duration(milliseconds: 700 + i * 80),
                      curve: Curves.easeOutCubic,
                      builder: (_, v, _) => Container(
                        height: 6 + v * 38,
                        decoration: BoxDecoration(
                          color: months[i].isCurrent ? AppColors.yellow : Colors.white.withValues(alpha: .2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      months[i].label,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: months[i].isCurrent ? Colors.white : const Color(0xFFB7AAE8),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.primary = false,
    this.tone,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool primary;
  final (Color, Color)? tone;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final fg = primary ? Colors.white : p.ink;
    return Pressable(
      onTap: onTap,
      child: Container(
        height: 118,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: primary ? p.accent : p.card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: primary ? p.accent : p.line),
          boxShadow: primary
              ? [BoxShadow(color: p.accent.withValues(alpha: .4), blurRadius: 20, offset: const Offset(0, 10))]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconTile(
              icon: icon,
              bg: primary ? Colors.white.withValues(alpha: .18) : tone!.$1,
              fg: primary ? Colors.white : tone!.$2,
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: fg, fontWeight: FontWeight.w800, fontSize: 14),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: primary ? Colors.white70 : p.muted, fontSize: 11.5),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
