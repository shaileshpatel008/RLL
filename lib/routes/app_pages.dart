import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../bindings/invoice_form_binding.dart';
import '../bindings/invoice_preview_binding.dart';
import '../bindings/main_binding.dart';
import '../bindings/splash_binding.dart';
import '../views/invoice_form_screen.dart';
import '../views/invoice_preview_screen.dart';
import '../views/main_screen.dart';
import '../views/splash_screen.dart';

part 'app_routes.dart';

class AppPages {
  AppPages._();

  static const initial = Routes.splash;

  static final routes = [
    GetPage(name: _Paths.splash, page: () => const SplashScreen(), binding: SplashBinding()),
    GetPage(
      name: _Paths.main,
      page: () => const MainScreen(),
      binding: MainBinding(),
      transition: Transition.fadeIn,
      transitionDuration: const Duration(milliseconds: 500),
    ),
    GetPage(
      name: _Paths.invoiceForm,
      page: () => const InvoiceFormScreen(),
      binding: InvoiceFormBinding(),
      transition: Transition.downToUp,
      curve: Curves.easeOutCubic,
      transitionDuration: const Duration(milliseconds: 380),
    ),
    GetPage(
      name: _Paths.invoicePreview,
      page: () => const InvoicePreviewScreen(),
      binding: InvoicePreviewBinding(),
      transition: Transition.rightToLeftWithFade,
      curve: Curves.easeOutCubic,
    ),
  ];
}
