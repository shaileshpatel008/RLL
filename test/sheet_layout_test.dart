import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:rll/controller/setting_controller.dart';
import 'package:rll/models/invoice_detail_model.dart';
import 'package:rll/utility/app_theme.dart';
import 'package:rll/main.dart';
import 'package:rll/views/setting_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (_) async => '/tmp/rll_test_storage',
    );
    await GetStorage.init();
    Get.reset();
  });

  // (width, height, keyboard, text scale, whole sheet must be visible)
  // The last case is extreme (300px left): the sheet may scroll there, but must not overflow.
  for (final (w, h, keyboard, scale, mustFit) in [
    (360.0, 640.0, 260.0, 1.0, true),
    (360.0, 800.0, 300.0, 1.0, true), // e.g. the phone in the bug report
    (393.0, 852.0, 330.0, 1.25, true),
    (360.0, 640.0, 340.0, 1.25, false),
  ]) {
    testWidgets('number sheet fits ${w.toInt()}x${h.toInt()}, keyboard ${keyboard.toInt()}, text x$scale', (
      tester,
    ) async {
      tester.view.physicalSize = Size(w, h);
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = scale;
      addTearDown(tester.view.reset);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

      final controller = Get.put(SettingController());
      await tester.pumpWidget(GetMaterialApp(theme: AppTheme.light, home: const SettingScreen()));
      await tester.pump(const Duration(seconds: 1));
      controller.setting.value = AppSettingModel(invoiceNumber: 142);
      await tester.pump();

      await tester.tap(find.text("Change starting number"));
      await tester.pump(const Duration(milliseconds: 500));
      tester.view.viewInsets = FakeViewPadding(bottom: keyboard);
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text("Starting number"), findsOneWidget);
      expect(tester.takeException(), isNull);

      if (!mustFit) return;
      // The whole sheet must sit between the top of the screen and the keyboard.
      final save = tester.getRect(find.text("Save"));
      final title = tester.getRect(find.text("Starting number"));
      expect(save.bottom, lessThanOrEqualTo(h - keyboard), reason: "Save button is hidden behind the keyboard");
      // …and really visible/tappable (not clipped by the sheet).
      expect(find.text("Save").hitTestable(), findsOneWidget, reason: "Save button is cut off");
      expect(find.text("Cancel").hitTestable(), findsOneWidget, reason: "Cancel button is cut off");
      expect(title.top, greaterThanOrEqualTo(0), reason: "Sheet is pushed off the top of the screen");
    });
  }

  testWidgets('+ button sits on its own slot and does not cover a tab', (tester) async {
    tester.view.physicalSize = const Size(360, 780);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    GetStorage().write('onboarded', true);
    await tester.pumpWidget(const MyApp());
    for (var i = 0; i < 40; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    final nav = find.byWidgetPredicate((w) => w.runtimeType.toString() == '_BottomNav');
    final icon = tester.getRect(
      find.byWidgetPredicate((w) => w is Icon && w.icon == Icons.add_rounded && w.size == 30),
    );
    final fab = Rect.fromCenter(center: icon.center, width: 60, height: 60); // the + button
    Rect tab(String label) => tester.getRect(find.descendant(of: nav, matching: find.text(label)));
    for (final label in ["Home", "Invoices", "Settings"]) {
      expect(fab.overlaps(tab(label)), isFalse, reason: "+ button covers $label");
    }
    expect(fab.center.dx, greaterThan(tab("Invoices").right));
    expect(fab.center.dx, lessThan(tab("Settings").left));
    await tester.pump(const Duration(seconds: 5));
  });
}
