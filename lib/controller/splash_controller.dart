import 'dart:async';

import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

import '../routes/app_pages.dart';
import '../utility/image_manager.dart';

class SplashController extends GetxController {
  final _box = GetStorage();

  /// First launch shows a "Get started" button; later launches continue
  /// automatically once the intro animation has played.
  late final bool isFirstLaunch = !(_box.read<bool>(StorageKey.onboarded) ?? false);
  final showButton = false.obs;
  Timer? _timer;

  @override
  void onReady() {
    super.onReady();
    _timer = Timer(const Duration(milliseconds: 1500), () {
      if (isFirstLaunch) {
        showButton.value = true;
      } else {
        _timer = Timer(const Duration(milliseconds: 600), goNext);
      }
    });
  }

  @override
  void onClose() {
    _timer?.cancel();
    super.onClose();
  }

  void goNext() {
    _timer?.cancel();
    _box.write(StorageKey.onboarded, true);
    Get.offAllNamed(Routes.main);
  }
}
