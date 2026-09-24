import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

import 'api/api_method.dart';
import 'controller/setting_controller.dart';
import 'routes/app_pages.dart';
import 'utility/app_theme.dart';
import 'utility/change_value.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Startup must never block the first screen: log and carry on.
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    kLog(title: "FLUTTER ERROR", content: "${details.exception}\n${details.stack}");
  };
  try {
    await GetStorage.init();
  } catch (e) {
    kLog(title: "STORAGE", content: e);
  }
  try {
    await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  } catch (e) {
    kLog(title: "ORIENTATION", content: e);
  }
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: ChangeValue.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: SettingController.themeFromStorage(),
      initialRoute: AppPages.initial,
      getPages: AppPages.routes,
      defaultTransition: Transition.cupertino,
      builder: (context, child) {
        // Keep text readable but stop very large system fonts breaking layouts.
        final mq = MediaQuery.of(context);
        return MediaQuery(
          data: mq.copyWith(textScaler: mq.textScaler.clamp(minScaleFactor: .9, maxScaleFactor: 1.25)),
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
            child: child,
          ),
        );
      },
    );
  }
}
