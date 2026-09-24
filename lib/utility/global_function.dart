import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import 'app_colors.dart';
import 'app_theme.dart';
import 'change_value.dart';

void unFocus() => FocusManager.instance.primaryFocus?.unfocus();

/// Closes the top route (screen, dialog or bottom sheet).
///
/// Use this instead of Get.back(): in GetX 4, Get.back() only dismisses an
/// open snackbar and leaves the screen/dialog/sheet in place.
void closeRoute<T>([T? result]) => Get.key.currentState?.pop<T>(result);

// ---------------------------------------------------------------------------
// Messages
// ---------------------------------------------------------------------------

enum MessageType { success, error, info }

/// Shows a floating snackbar with an icon. Replaces the old toast().
void showMessage(String message, {MessageType type = MessageType.info, String? title}) {
  final (Color bg, IconData icon) = switch (type) {
    MessageType.success => (AppColors.success, Icons.check_circle_rounded),
    MessageType.error => (AppColors.error, Icons.error_rounded),
    MessageType.info => (AppColors.deep, Icons.info_rounded),
  };
  if (type == MessageType.error) {
    HapticFeedback.mediumImpact();
  } else {
    HapticFeedback.lightImpact();
  }
  Get.closeCurrentSnackbar();
  Get.showSnackbar(
    GetSnackBar(
      titleText: title == null
          ? null
          : Text(
              title,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 15),
            ),
      messageText: Text(
        message,
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14, height: 1.35),
      ),
      icon: Icon(icon, color: Colors.white),
      backgroundColor: bg,
      borderRadius: 16,
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      snackPosition: SnackPosition.TOP,
      duration: Duration(milliseconds: type == MessageType.error ? 3500 : 2400),
      animationDuration: const Duration(milliseconds: 380),
      forwardAnimationCurve: Curves.easeOutBack,
      isDismissible: true,
      dismissDirection: DismissDirection.up,
      boxShadows: [BoxShadow(color: bg.withValues(alpha: .35), blurRadius: 24, offset: const Offset(0, 10))],
    ),
  );
}

void showSuccess(String message, {String? title}) => showMessage(message, type: MessageType.success, title: title);
void showError(String message, {String? title}) => showMessage(message, type: MessageType.error, title: title);
void showInfo(String message, {String? title}) => showMessage(message, type: MessageType.info, title: title);

// ---------------------------------------------------------------------------
// Blocking loader
// ---------------------------------------------------------------------------

bool _loaderOpen = false;

void showLoader([String? message]) {
  if (_loaderOpen) return;
  _loaderOpen = true;
  Get.dialog(
    PopScope(canPop: false, child: _LoaderCard(message: message)),
    barrierDismissible: false,
    barrierColor: Colors.black.withValues(alpha: .35),
    transitionDuration: const Duration(milliseconds: 180),
  );
}

void hideLoader() {
  if (!_loaderOpen) return;
  _loaderOpen = false;
  if (Get.isDialogOpen ?? false) closeRoute();
}

class _LoaderCard extends StatelessWidget {
  const _LoaderCard({this.message});
  final String? message;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Center(
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: .85, end: 1),
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutBack,
        builder: (_, v, child) => Transform.scale(scale: v, child: child),
        child: Material(
          color: p.card,
          borderRadius: BorderRadius.circular(22),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(width: 40, height: 40, child: CircularProgressIndicator(strokeWidth: 4)),
                if (message != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    message!,
                    style: TextStyle(fontWeight: FontWeight.w700, color: p.ink),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Confirm dialog
// ---------------------------------------------------------------------------

Future<bool> confirmDialog({
  required String title,
  required String message,
  String confirmText = "Discard",
  String cancelText = "Keep editing",
  bool destructive = true,
}) async {
  final result = await Get.dialog<bool>(
    Builder(
      builder: (context) {
        final p = context.palette;
        return AlertDialog(
          title: Text(title, style: AppTheme.display(size: 21, color: p.ink)),
          content: Text(message, style: TextStyle(color: p.muted, fontSize: 15, height: 1.4)),
          actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          actions: [
            TextButton(onPressed: () => closeRoute(false), child: Text(cancelText)),
            FilledButton(
              style: FilledButton.styleFrom(
                minimumSize: const Size(0, 44),
                backgroundColor: destructive ? AppColors.error : p.accent,
              ),
              onPressed: () => closeRoute(true),
              child: Text(confirmText),
            ),
          ],
        );
      },
    ),
  );
  return result ?? false;
}

// ---------------------------------------------------------------------------
// Formatting
// ---------------------------------------------------------------------------

final _money = NumberFormat.currency(locale: 'en_GB', symbol: ChangeValue.currencySymbol, decimalDigits: 2);

String formatMoney(num value) => _money.format(value);

/// API date format (yyyy-MM-dd)
String toApiDate(DateTime date) => DateFormat('yyyy-MM-dd').format(date);

/// Parses the API's date strings, which may or may not carry a time part.
DateTime? parseApiDate(String? value) {
  if (value == null || value.isEmpty || value == 'null') return null;
  return DateTime.tryParse(value) ?? _tryFormat('dd/MM/yyyy', value);
}

DateTime? _tryFormat(String pattern, String value) {
  try {
    return DateFormat(pattern).parseStrict(value);
  } catch (_) {
    return null;
  }
}

String formatDate(DateTime? d, [String pattern = 'dd MMM yyyy']) => d == null ? '—' : DateFormat(pattern).format(d);
String formatDateShort(DateTime? d) => formatDate(d, 'dd MMM');
String formatDatePdf(DateTime? d) => formatDate(d, 'dd/MM/yyyy');

double parseAmount(String? value) => double.tryParse((value ?? '').replaceAll(',', '').trim()) ?? 0;

/// "Greenfield Primary School" -> "GP"
String initials(String name) {
  final parts = name.trim().split(RegExp(r'\s+')).where((e) => e.isNotEmpty && RegExp(r'[A-Za-z0-9]').hasMatch(e[0]));
  if (parts.isEmpty) return '?';
  return parts.take(2).map((e) => e[0].toUpperCase()).join();
}

String greeting() {
  final h = DateTime.now().hour;
  if (h < 12) return "Good morning";
  if (h < 17) return "Good afternoon";
  return "Good evening";
}

String cleanText(String? value) => (value == null || value == 'null') ? '' : value.trim();
