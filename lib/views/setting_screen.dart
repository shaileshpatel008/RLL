import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../controller/setting_controller.dart';
import '../utility/app_colors.dart';
import '../utility/app_theme.dart';
import '../utility/global_function.dart';
import '../utility/change_value.dart';
import '../widgets/common_widgets.dart';

class SettingScreen extends GetView<SettingController> {
  const SettingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: controller.fetchNextNumber,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 130),
            physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
            children: [
              Text("Settings", style: AppTheme.display(size: 28, color: p.ink)),
              const SizedBox(height: 20),
              // ---- Invoice numbering ---------------------------------------------
              const SectionLabel("Invoice numbering"),
              const SizedBox(height: 10),
              FadeSlideIn(
                child: _Group(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Next invoice number",
                            style: TextStyle(fontSize: 13, color: p.muted, fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 8),
                          Obx(() {
                            if (controller.isLoading.value) return const Skeleton(height: 30, width: 200);
                            if (controller.error.value != null && controller.setting.value == null) {
                              return Row(
                                children: [
                                  const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 20),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      controller.error.value!,
                                      style: const TextStyle(color: AppColors.error, fontWeight: FontWeight.w600),
                                    ),
                                  ),
                                  TextButton(onPressed: controller.fetchNextNumber, child: const Text("Retry")),
                                ],
                              );
                            }
                            return AnimatedSwitcher(
                              duration: const Duration(milliseconds: 350),
                              transitionBuilder: (c, a) => FadeTransition(
                                opacity: a,
                                child: SlideTransition(
                                  position: Tween(begin: const Offset(0, .4), end: Offset.zero).animate(a),
                                  child: c,
                                ),
                              ),
                              child: Text(
                                controller.nextInvoiceNumber,
                                key: ValueKey(controller.nextInvoiceNumber),
                                style: AppTheme.mono(size: 24, weight: FontWeight.w800, color: p.accent),
                              ),
                            );
                          }),
                          const SizedBox(height: 8),
                          Text(
                            "Goes up by one after each invoice is created. The year updates on its own.",
                            style: TextStyle(fontSize: 12.5, color: p.muted, height: 1.4),
                          ),
                        ],
                      ),
                    ),
                    _Row(
                      icon: Icons.tag_rounded,
                      tone: AppColors.tones[1],
                      title: "Change starting number",
                      onTap: () {
                        if (controller.setting.value == null) {
                          controller.fetchNextNumber();
                          return;
                        }
                        controller.prepareEdit();
                        _showNumberSheet(context);
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              // ---- Company ---------------------------------------------------------
              const SectionLabel("Company on invoices"),
              const SizedBox(height: 10),
              FadeSlideIn(
                delay: const Duration(milliseconds: 60),
                child: _Group(
                  children: [
                    _Row(
                      icon: Icons.apartment_rounded,
                      tone: AppColors.tones[4],
                      title: ChangeValue.companyFullName,
                      subtitle: "VAT Reg. No. ${ChangeValue.companyNumber}",
                    ),
                    _Row(
                      icon: Icons.location_on_rounded,
                      tone: AppColors.tones[2],
                      title: ChangeValue.companyAddress1Line,
                      subtitle:
                          "${ChangeValue.companyAddress2Line} · ${ChangeValue.companyAddress3Line} · ${ChangeValue.companyAddress4Line}",
                    ),
                    _Row(
                      icon: Icons.call_rounded,
                      tone: AppColors.tones[3],
                      title: ChangeValue.companyTelPhone,
                      subtitle: "Telephone",
                    ),
                    _Row(
                      icon: Icons.account_balance_rounded,
                      tone: AppColors.tones[5],
                      title: "Payment details",
                      subtitle: ChangeValue.bankName,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              // ---- Appearance ------------------------------------------------------
              const SectionLabel("Appearance"),
              const SizedBox(height: 10),
              FadeSlideIn(
                delay: const Duration(milliseconds: 120),
                child: Obx(() => _ThemeSelector(value: controller.themeMode.value, onChanged: controller.setTheme)),
              ),
              const SizedBox(height: 36),
              Center(
                child: Column(
                  children: [
                    const AppLogo(size: 64, padding: 6),
                    const SizedBox(height: 10),
                    Text(
                      "${ChangeValue.appName} Invoices · Version ${ChangeValue.appVersion}",
                      style: TextStyle(fontSize: 12, color: p.muted, fontWeight: FontWeight.w600),
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

  void _showNumberSheet(BuildContext context) {
    Get.bottomSheet(
      const _NumberSheet(),
      isScrollControlled: true,
      enterBottomSheetDuration: const Duration(milliseconds: 320),
      exitBottomSheetDuration: const Duration(milliseconds: 220),
    );
  }
}

class _NumberSheet extends GetView<SettingController> {
  const _NumberSheet();

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      decoration: BoxDecoration(
        color: p.card,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.fromLTRB(20, 12, 20, 20 + MediaQuery.viewInsetsOf(context).bottom),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 5,
                decoration: BoxDecoration(color: p.line, borderRadius: BorderRadius.circular(9)),
              ),
            ),
            const SizedBox(height: 18),
            Text("Starting number", style: AppTheme.display(size: 22, color: p.ink)),
            const SizedBox(height: 4),
            Text(
              "Use this if you need to skip or continue a number series.",
              style: TextStyle(color: p.muted, fontSize: 14),
            ),
            const SizedBox(height: 18),
            TextField(
              controller: controller.numberController,
              autofocus: true,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(6)],
              onChanged: (v) {
                controller.onNumberChanged(v);
                controller.update();
              },
              onSubmitted: (_) => controller.saveNextNumber(),
              style: AppTheme.mono(size: 28, weight: FontWeight.w800, color: p.ink),
              decoration: const InputDecoration(hintText: "00000"),
            ),
            const SizedBox(height: 10),
            GetBuilder<SettingController>(
              builder: (_) => Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: "Next invoice: ",
                      style: TextStyle(color: p.muted),
                    ),
                    TextSpan(
                      text: controller.numberPreview,
                      style: AppTheme.mono(size: 13, weight: FontWeight.w700, color: p.ink),
                    ),
                  ],
                ),
                textAlign: TextAlign.center,
              ),
            ),
            Obx(
              () => AnimatedSize(
                duration: const Duration(milliseconds: 200),
                child: controller.numberError.value == null
                    ? const SizedBox(height: 16)
                    : Padding(
                        padding: const EdgeInsets.only(top: 12, bottom: 4),
                        child: _ErrorBanner(controller.numberError.value!),
                      ),
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(onPressed: closeRoute, child: const Text("Cancel")),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Obx(
                    () => FilledButton(
                      onPressed: controller.isSaving.value ? null : controller.saveNextNumber,
                      child: controller.isSaving.value
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                            )
                          : const Text("Save"),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner(this.message);
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(color: AppColors.errorSoft, borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, color: Color(0xFF8C1D18), size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: Color(0xFF8C1D18), fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

class _Group extends StatelessWidget {
  const _Group({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: p.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: p.line),
      ),
      child: Column(
        children: [
          for (var i = 0; i < children.length; i++) ...[if (i > 0) const Divider(), children[i]],
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.icon, required this.tone, required this.title, this.subtitle, this.onTap});
  final IconData icon;
  final (Color, Color) tone;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            IconTile(icon: icon, bg: tone.$1, fg: tone.$2, size: 38),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: p.ink),
                  ),
                  if (subtitle != null) Text(subtitle!, style: TextStyle(fontSize: 12, color: p.muted, height: 1.35)),
                ],
              ),
            ),
            if (onTap != null) Icon(Icons.chevron_right_rounded, color: p.muted),
          ],
        ),
      ),
    );
  }
}

class _ThemeSelector extends StatelessWidget {
  const _ThemeSelector({required this.value, required this.onChanged});
  final ThemeMode value;
  final ValueChanged<ThemeMode> onChanged;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    const options = [
      (ThemeMode.light, "Light", Icons.light_mode_rounded),
      (ThemeMode.dark, "Dark", Icons.dark_mode_rounded),
      (ThemeMode.system, "Auto", Icons.brightness_auto_rounded),
    ];
    final index = options.indexWhere((o) => o.$1 == value);
    return Container(
      height: 52,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: p.field,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: p.line),
      ),
      child: LayoutBuilder(
        builder: (context, c) {
          final w = c.maxWidth / options.length;
          return Stack(
            fit: StackFit.expand,
            children: [
              AnimatedPositioned(
                duration: const Duration(milliseconds: 280),
                curve: Curves.easeOutBack,
                left: w * index,
                top: 0,
                bottom: 0,
                width: w,
                child: Container(
                  decoration: BoxDecoration(
                    color: p.card,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withValues(alpha: .08), blurRadius: 8, offset: const Offset(0, 2)),
                    ],
                  ),
                ),
              ),
              Row(
                children: [
                  for (final o in options)
                    Expanded(
                      child: Semantics(
                        button: true,
                        selected: o.$1 == value,
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () {
                            HapticFeedback.selectionClick();
                            onChanged(o.$1);
                          },
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(o.$3, size: 18, color: o.$1 == value ? p.ink : p.muted),
                              const SizedBox(width: 6),
                              Text(
                                o.$2,
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                  color: o.$1 == value ? p.ink : p.muted,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}
