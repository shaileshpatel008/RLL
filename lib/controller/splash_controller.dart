import 'dart:async';

import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

import '../api/api_method.dart';
import '../routes/app_pages.dart';
import '../utility/global_function.dart';
import '../utility/image_manager.dart';

class SplashController extends GetxController {
  final _box = GetStorage();

  /// First launch shows a "Get started" button; later launches continue
  /// automatically once the intro animation has played.
  late final bool isFirstLaunch = !(_box.read<bool>(StorageKey.onboarded) ?? false);
  final showButton = false.obs;
  bool _leaving = false;
  Timer? _fallback;

  /// Called by the splash screen when the intro animation has finished.
  /// Driven by the widget (not onReady) so it can never be missed.
  void onIntroFinished() {
    if (_leaving) return;
    if (isFirstLaunch) {
      showButton.value = true;
    } else {
      goNext();
    }
    // Safety net: if we are somehow still here, let the user continue.
    _fallback ??= Timer(const Duration(seconds: 3), () {
      if (!isClosed) showButton.value = true;
    });
  }

  @override
  void onClose() {
    _fallback?.cancel();
    super.onClose();
  }

  Future<void> goNext() async {
    if (_leaving) return;
    _leaving = true;
    try {
      await _box.write(StorageKey.onboarded, true);
    } catch (e) {
      kLog(title: "SPLASH", content: e); // not fatal — only affects the next launch
    }
    try {
      Get.offAllNamed(Routes.main);
    } catch (e, s) {
      kLog(title: "SPLASH NAVIGATION", content: "$e\n$s");
      _leaving = false;
      showButton.value = true;
      showError("Couldn't open the app. Please tap Get started again.");
    }
  }
}
