import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../../config/app_colors.dart';

class DeckCreationOptionsScreen extends StatelessWidget {
  const DeckCreationOptionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(title: const Text('Create New Deck')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'How would you like to create your deck?',
              style: GoogleFonts.dmSans(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Choose a method to get started',
              style: GoogleFonts.dmSans(
                fontSize: 14,
                color: AppColors.mutedText,
              ),
            ),
            const SizedBox(height: 32),
            // Option 1: Manual Entry
            _buildOptionCard(
              context,
              icon: Icons.edit_outlined,
              title: 'Manual Entry',
              subtitle:
                  'Add a topic name and describe it in 2-3 lines - AI generates flashcards',
              onTap: () => context.push('/home/deck/create-manual'),
            ),
            const SizedBox(height: 16),
            // Option 2: From PDF (only on non-web)
            if (!kIsWeb)
              _buildOptionCard(
                context,
                icon: Icons.picture_as_pdf_outlined,
                title: 'From PDF Content',
                subtitle:
                    'Upload or paste PDF content - AI generates flashcards and quizzes',
                onTap: () => context.push('/home/deck/create-pdf'),
              ),
            if (!kIsWeb) const SizedBox(height: 16),
            // Option 3: Paste Text
            _buildOptionCard(
              context,
              icon: Icons.text_fields,
              title: 'From Text',
              subtitle:
                  'Copy-paste a chapter or text - AI generates flashcards and quizzes',
              onTap: () => context.push('/home/deck/create-text'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.borderColor),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.sageLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: AppColors.sageDark, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.dmSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.ink,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: GoogleFonts.dmSans(
                      fontSize: 13,
                      color: AppColors.mutedText,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Icon(Icons.arrow_forward_ios, size: 16, color: AppColors.mutedText),
          ],
        ),
      ),
    );
  }
}
