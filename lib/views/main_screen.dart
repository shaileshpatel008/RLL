import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../controller/main_controller.dart';
import '../utility/app_theme.dart';
import '../widgets/common_widgets.dart';
import 'dashboard_screen.dart';
import 'invoice_list_screen.dart';
import 'setting_screen.dart';

class MainScreen extends GetView<MainController> {
  const MainScreen({super.key});

  static const _tabs = [DashboardScreen(), InvoiceListScreen(), SettingScreen()];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Obx(() {
        final index = controller.tabIndex.value;
        return PopScope(
          canPop: index == 0,
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop) controller.handleBack();
          },
          child: Scaffold(
            extendBody: true,
            body: Stack(
              children: [
                for (var i = 0; i < _tabs.length; i++)
                  IgnorePointer(
                    ignoring: i != index,
                    child: AnimatedOpacity(
                      opacity: i == index ? 1 : 0,
                      duration: const Duration(milliseconds: 220),
                      child: AnimatedSlide(
                        offset: i == index ? Offset.zero : const Offset(0, .015),
                        duration: const Duration(milliseconds: 260),
                        curve: Curves.easeOutCubic,
                        child: TickerMode(enabled: i == index, child: _tabs[i]),
                      ),
                    ),
                  ),
              ],
            ),
            bottomNavigationBar: const _BottomNav(),
          ),
        );
      }),
    );
  }
}

class _BottomNav extends GetView<MainController> {
  const _BottomNav();

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return SafeArea(
      minimum: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      child: SizedBox(
        height: 92,
        child: Stack(
          alignment: Alignment.bottomCenter,
          clipBehavior: Clip.none,
          children: [
            Container(
              height: 68,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                color: p.card,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: p.line),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF221450).withValues(alpha: .18),
                    blurRadius: 40,
                    offset: const Offset(0, 18),
                  ),
                ],
              ),
              child: Obx(() {
                final i = controller.tabIndex.value;
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _NavItem(
                      icon: Icons.home_rounded,
                      label: "Home",
                      active: i == 0,
                      onTap: () => controller.changeTab(0),
                    ),
                    _NavItem(
                      icon: Icons.receipt_long_rounded,
                      label: "Invoices",
                      active: i == 1,
                      onTap: () => controller.changeTab(1),
                    ),
                    const SizedBox(width: 64),
                    _NavItem(
                      icon: Icons.settings_rounded,
                      label: "Settings",
                      active: i == 2,
                      onTap: () => controller.changeTab(2),
                    ),
                  ],
                );
              }),
            ),
            Positioned(
              top: 0,
              child: Tooltip(
                message: "New invoice",
                child: Pressable(
                  onTap: controller.newInvoice,
                  scale: .9,
                  child: Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: p.accent,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: p.bg, width: 4),
                      boxShadow: [
                        BoxShadow(color: p.accent.withValues(alpha: .55), blurRadius: 24, offset: const Offset(0, 12)),
                      ],
                    ),
                    child: const Icon(Icons.add_rounded, color: Colors.white, size: 30),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({required this.icon, required this.label, required this.active, required this.onTap});
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final color = active ? p.accent : p.muted;
    return Semantics(
      selected: active,
      button: true,
      label: label,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: SizedBox(
          width: 72,
          height: 60,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedScale(
                scale: active ? 1.12 : 1,
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutBack,
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(height: 3),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 200),
                style: TextStyle(fontSize: 11, fontWeight: active ? FontWeight.w800 : FontWeight.w600, color: color),
                child: Text(label),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
