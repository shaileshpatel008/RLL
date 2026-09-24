import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../utility/app_colors.dart';
import '../utility/app_theme.dart';

/// Label above, filled field below — used on every form.
class TextFormFieldWidget extends StatelessWidget {
  const TextFormFieldWidget({
    super.key,
    required this.label,
    this.controller,
    this.hint,
    this.icon,
    this.keyboardType,
    this.textInputAction = TextInputAction.next,
    this.capitalization = TextCapitalization.words,
    this.maxLines = 1,
    this.maxLength,
    this.onChanged,
    this.onSubmitted,
    this.inputFormatters,
    this.autofocus = false,
    this.prefixText,
  });

  final String label;
  final TextEditingController? controller;
  final String? hint;
  final IconData? icon;
  final TextInputType? keyboardType;
  final TextInputAction textInputAction;
  final TextCapitalization capitalization;
  final int maxLines;
  final int? maxLength;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final List<TextInputFormatter>? inputFormatters;
  final bool autofocus;
  final String? prefixText;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: p.muted),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          autofocus: autofocus,
          keyboardType: keyboardType,
          textInputAction: maxLines > 1 ? TextInputAction.newline : textInputAction,
          textCapitalization: capitalization,
          maxLines: maxLines,
          maxLength: maxLength,
          onChanged: onChanged,
          onSubmitted: onSubmitted,
          inputFormatters: inputFormatters,
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: p.ink),
          decoration: InputDecoration(
            hintText: hint,
            counterText: '',
            prefixText: prefixText,
            prefixIcon: icon == null ? null : Icon(icon, size: 20),
          ),
        ),
      ],
    );
  }
}

/// Looks like a text field, opens a picker when tapped (dates).
class PickerField extends StatelessWidget {
  const PickerField({
    super.key,
    required this.label,
    required this.value,
    required this.onTap,
    this.icon = Icons.calendar_today_rounded,
    this.placeholder = "Select",
  });

  final String label;
  final String? value;
  final VoidCallback onTap;
  final IconData icon;
  final String placeholder;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final empty = value == null || value!.isEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: p.muted),
        ),
        const SizedBox(height: 6),
        Material(
          color: p.field,
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: onTap,
            child: Container(
              height: 52,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: p.line, width: 1.5),
              ),
              child: Row(
                children: [
                  Icon(icon, size: 18, color: p.muted),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      empty ? placeholder : value!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: empty ? p.muted : p.ink),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Red inline message that animates in/out under a form.
class InlineError extends StatelessWidget {
  const InlineError({super.key, required this.message});
  final String? message;

  @override
  Widget build(BuildContext context) {
    return AnimatedSize(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 220),
        child: message == null
            ? const SizedBox(width: double.infinity)
            : Padding(
                key: ValueKey(message),
                padding: const EdgeInsets.only(bottom: 10),
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 1, end: 0),
                  duration: const Duration(milliseconds: 420),
                  builder: (_, t, child) {
                    // small horizontal shake
                    final dx = t == 0 ? 0.0 : 6 * (t * 10 % 2 < 1 ? 1 : -1) * t;
                    return Transform.translate(offset: Offset(dx, 0), child: child);
                  },
                  child: Semantics(
                    liveRegion: true,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(color: AppColors.errorSoft, borderRadius: BorderRadius.circular(12)),
                      child: Row(
                        children: [
                          const Icon(Icons.info_rounded, size: 18, color: Color(0xFF8C1D18)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              message!,
                              style: const TextStyle(
                                color: Color(0xFF8C1D18),
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}
