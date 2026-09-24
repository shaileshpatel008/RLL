import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:rll/controller/setting_controller.dart';
import 'package:rll/models/invoice_detail_model.dart';
import 'package:rll/utility/app_theme.dart';
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

  for (final (w, h, keyboard, scale) in [
    (360.0, 640.0, 300.0, 1.0),
    (360.0, 640.0, 340.0, 1.25),
    (393.0, 852.0, 380.0, 1.25),
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
    });
  }
}
