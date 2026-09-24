import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:rll/main.dart';
import 'package:rll/views/main_screen.dart';
import 'package:rll/views/splash_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (_) async => '/tmp/rll_test_storage',
    );
    await GetStorage.init();
    await GetStorage().erase();
    Get.reset();
  });

  testWidgets('first launch: splash -> Get started -> main', (tester) async {
    await tester.pumpWidget(const MyApp());
    expect(find.byType(SplashScreen), findsOneWidget);
    await tester.pump(const Duration(seconds: 2));
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.text("Get started"), findsOneWidget);
    await tester.tap(find.text("Get started"));
    for (var i = 0; i < 20; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.byType(MainScreen), findsOneWidget);
  });

  testWidgets('second launch: splash continues on its own', (tester) async {
    GetStorage().write('onboarded', true);
    await tester.pumpWidget(const MyApp());
    for (var i = 0; i < 40; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.byType(MainScreen), findsOneWidget);
  });

  testWidgets('tapping the splash skips the intro', (tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tapAt(const Offset(200, 300));
    for (var i = 0; i < 20; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.byType(MainScreen), findsOneWidget);
    await tester.pump(const Duration(seconds: 5)); // let pending timers finish
  });
}
