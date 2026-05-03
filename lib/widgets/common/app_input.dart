import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../config/app_colors.dart';

class AppInput extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String? hint;
  final TextInputType? keyboardType;
  final bool obscureText;
  final Widget? suffix;
  final Widget? prefix;
  final String? error;
  final int maxLines;
  final int? maxLength;
  final void Function(String)? onChanged;
  final FocusNode? focusNode;
  final bool enabled;
  final TextInputAction? textInputAction;
  final void Function(String)? onSubmitted;

  const AppInput({
    super.key,
    required this.label,
    required this.controller,
    this.hint,
    this.keyboardType,
    this.obscureText = false,
    this.suffix,
    this.prefix,
    this.error,
    this.maxLines = 1,
    this.maxLength,
    this.onChanged,
    this.focusNode,
    this.enabled = true,
    this.textInputAction,
    this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: GoogleFonts.dmSans(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppColors.sageMid,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          focusNode: focusNode,
          obscureText: obscureText,
          keyboardType: keyboardType,
          maxLines: obscureText ? 1 : maxLines,
          maxLength: maxLength,
          onChanged: onChanged,
          enabled: enabled,
          textInputAction: textInputAction,
          onFieldSubmitted: onSubmitted,
          style: GoogleFonts.dmSans(fontSize: 15, color: AppColors.ink),
          decoration: InputDecoration(
            hintText: hint,
            suffixIcon: suffix,
            prefixIcon: prefix,
            errorText: null,
            counterText: maxLength != null ? null : '',
          ),
        ),
        if (error != null) ...[
          const SizedBox(height: 4),
          Text(
            error!,
            style: GoogleFonts.dmSans(
              fontSize: 12,
              color: AppColors.danger,
            ),
          ),
        ],
      ],
    );
  }
}
