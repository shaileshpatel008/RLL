import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../controller/splash_controller.dart';
import '../utility/app_colors.dart';
import '../utility/app_theme.dart';
import '../utility/change_value.dart';
import '../utility/image_manager.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  final controller = Get.find<SplashController>();
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1600));
  Timer? _introTimer;

  @override
  void initState() {
    super.initState();
    _c.forward();
    // Wall-clock timer so it still fires when device animations are turned off.
    _introTimer = Timer(const Duration(milliseconds: 1800), controller.onIntroFinished);
  }

  static const _widths = [.55, .66, .47, .6, .42, .52];

  Animation<double> _interval(double begin, double end, [Curve curve = Curves.easeOutCubic]) => CurvedAnimation(
    parent: _c,
    curve: Interval(begin, end, curve: curve),
  );

  @override
  void dispose() {
    _introTimer?.cancel();
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: AppColors.splash,
        body: GestureDetector(
          behavior: HitTestBehavior.opaque,
          // Tapping anywhere skips the intro.
          onTap: controller.goNext,
          child: Stack(
            children: [
              // Soft glow behind the logo
              Positioned(
                left: -size.width * .2,
                top: size.height * .12,
                child: Container(
                  width: size.width * 1.4,
                  height: size.width * 1.4,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(colors: [Color(0x8C7E57C2), Color(0x001B0F45)], stops: [0, .65]),
                  ),
                ),
              ),
              // Rainbow streaks from the logo
              Positioned(
                left: 0,
                top: size.height * .3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (var i = 0; i < 6; i++)
                      AnimatedBuilder(
                        animation: _interval(i * .06, .5 + i * .06),
                        builder: (_, _) {
                          final t = _interval(i * .06, .5 + i * .06).value;
                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            height: 8,
                            width: size.width * _widths[i] * t,
                            decoration: BoxDecoration(
                              color: AppColors.rainbow[i],
                              borderRadius: const BorderRadius.horizontal(right: Radius.circular(8)),
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ),
              SafeArea(
                child: Column(
                  children: [
                    const Spacer(flex: 3),
                    ScaleTransition(
                      scale: _interval(.3, .75, Curves.elasticOut),
                      child: RotationTransition(
                        turns: Tween(begin: -.03, end: 0.0).animate(_interval(.3, .7)),
                        child: Container(
                          width: 132,
                          height: 132,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(36),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x99000000),
                                blurRadius: 60,
                                offset: Offset(0, 30),
                                spreadRadius: -20,
                              ),
                            ],
                          ),
                          child: Image.asset(ImageAsset.logo),
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),
                    FadeTransition(
                      opacity: _interval(.55, 1),
                      child: SlideTransition(
                        position: Tween(begin: const Offset(0, .3), end: Offset.zero).animate(_interval(.55, 1)),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 32),
                          child: Column(
                            children: [
                              Text(
                                ChangeValue.appName,
                                style: AppTheme.display(size: 38, weight: FontWeight.w800, color: Colors.white),
                              ),
                              const SizedBox(height: 10),
                              const Text(
                                "Create, send and track every trip invoice in under a minute.",
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Color(0xFFCFC6F2), fontSize: 16, height: 1.5),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const Spacer(flex: 4),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                      child: Obx(() {
                        return AnimatedSwitcher(
                          duration: const Duration(milliseconds: 400),
                          transitionBuilder: (child, a) => FadeTransition(
                            opacity: a,
                            child: SlideTransition(
                              position: Tween(begin: const Offset(0, .4), end: Offset.zero).animate(a),
                              child: child,
                            ),
                          ),
                          child: controller.showButton.value
                              ? Column(
                                  key: const ValueKey('cta'),
                                  children: [
                                    FilledButton(
                                      style: FilledButton.styleFrom(
                                        backgroundColor: Colors.white,
                                        foregroundColor: AppColors.splash,
                                      ),
                                      onPressed: controller.goNext,
                                      child: const Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Text("Get started"),
                                          SizedBox(width: 8),
                                          Icon(Icons.arrow_forward_rounded, size: 20),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 14),
                                    const Text(
                                      "${ChangeValue.companyFullName} · London",
                                      style: TextStyle(color: Color(0xFFA99CDB), fontSize: 12),
                                    ),
                                  ],
                                )
                              : SizedBox(
                                  key: const ValueKey('loader'),
                                  height: 80,
                                  child: controller.isFirstLaunch
                                      ? null
                                      : const Center(
                                          child: SizedBox(
                                            width: 26,
                                            height: 26,
                                            child: CircularProgressIndicator(strokeWidth: 3, color: Colors.white54),
                                          ),
                                        ),
                                ),
                        );
                      }),
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
