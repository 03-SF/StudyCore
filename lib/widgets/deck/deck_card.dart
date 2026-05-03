import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/deck_model.dart';
import '../../config/app_colors.dart';

class DeckCard extends StatelessWidget {
  final DeckModel deck;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  const DeckCard({
    super.key,
    required this.deck,
    required this.onTap,
    this.onLongPress,
  });

  Color _parseColor(String hex) {
    try {
      final clean = hex.replaceAll('#', '');
      return Color(int.parse('FF$clean', radix: 16));
    } catch (_) {
      return AppColors.sageDark;
    }
  }

  @override
  Widget build(BuildContext context) {
    final accentColor = _parseColor(deck.accentColorHex);

    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        height: 140,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.ink.withOpacity(0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        clipBehavior: Clip.hardEdge,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 4,
              width: double.infinity,
              color: accentColor,
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.sageLight,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        deck.subject,
                        style: GoogleFonts.dmSans(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: AppColors.sageDark,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      deck.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.dmSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.ink,
                      ),
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        Text(
                          '${deck.cardCount} cards',
                          style: GoogleFonts.dmSans(
                            fontSize: 12,
                            color: AppColors.mutedText,
                          ),
                        ),
                        if (deck.dueCount > 0) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.amberBg,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '${deck.dueCount} due',
                              style: GoogleFonts.dmSans(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: AppColors.amber,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: deck.masteryPercent,
                        backgroundColor: AppColors.warmGray,
                        valueColor:
                            AlwaysStoppedAnimation<Color>(accentColor),
                        minHeight: 4,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
