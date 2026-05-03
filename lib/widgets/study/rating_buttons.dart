import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../config/app_colors.dart';

class RatingButtons extends StatelessWidget {
  final void Function(int rating) onRate;

  const RatingButtons({super.key, required this.onRate});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _RatingButton(
            label: "Don't Know",
            sublabel: 'See again',
            color: AppColors.danger,
            bgColor: AppColors.dangerBg,
            onTap: () {
              HapticFeedback.vibrate();
              onRate(1);
            },
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _RatingButton(
            label: 'Hard',
            sublabel: 'Review soon',
            color: AppColors.amber,
            bgColor: AppColors.amberBg,
            onTap: () => onRate(2),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _RatingButton(
            label: 'Good',
            sublabel: 'Tomorrow',
            color: AppColors.sageMid,
            bgColor: AppColors.sageLight,
            onTap: () => onRate(3),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _RatingButton(
            label: 'Got It!',
            sublabel: 'Next week',
            color: AppColors.sageDark,
            bgColor: AppColors.sageLight,
            onTap: () => onRate(4),
          ),
        ),
      ],
    );
  }
}

class _RatingButton extends StatelessWidget {
  final String label;
  final String sublabel;
  final Color color;
  final Color bgColor;
  final VoidCallback onTap;

  const _RatingButton({
    required this.label,
    required this.sublabel,
    required this.color,
    required this.bgColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              textAlign: TextAlign.center,
              style: GoogleFonts.dmSans(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              sublabel,
              textAlign: TextAlign.center,
              style: GoogleFonts.dmSans(
                fontSize: 10,
                color: color.withOpacity(0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
