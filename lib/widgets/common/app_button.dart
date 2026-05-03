import 'package:flutter/material.dart';
import '../../config/app_colors.dart';

class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final String variant;
  final IconData? icon;

  const AppButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.variant = 'primary',
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    Widget child = isLoading
        ? const SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              color: Colors.white,
              strokeWidth: 2.5,
            ),
          )
        : icon != null
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 20),
                  const SizedBox(width: 8),
                  Text(label),
                ],
              )
            : Text(label);

    switch (variant) {
      case 'secondary':
        return OutlinedButton(
          onPressed: isLoading ? null : onPressed,
          child: isLoading
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    color: AppColors.sageDark,
                    strokeWidth: 2.5,
                  ),
                )
              : child,
        );
      case 'text':
        return TextButton(
          onPressed: isLoading ? null : onPressed,
          child: child,
        );
      default:
        return ElevatedButton(
          onPressed: isLoading ? null : onPressed,
          child: child,
        );
    }
  }
}
