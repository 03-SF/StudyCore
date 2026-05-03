import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../models/group_model.dart';
import '../../config/app_colors.dart';

class GroupCard extends StatelessWidget {
  final GroupModel group;
  final VoidCallback onTap;
  final String? currentUserId;
  final VoidCallback? onJoin;

  const GroupCard({
    super.key,
    required this.group,
    required this.onTap,
    this.currentUserId,
    this.onJoin,
  });

  @override
  Widget build(BuildContext context) {
    final isMember = currentUserId != null &&
        group.memberIds.contains(currentUserId);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.borderColor),
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: AppColors.sageLight,
                borderRadius: BorderRadius.circular(14),
              ),
              clipBehavior: Clip.hardEdge,
              child: group.photoUrl != null
                  ? CachedNetworkImage(
                      imageUrl: group.photoUrl!,
                      fit: BoxFit.cover,
                    )
                  : Center(
                      child: Text(
                        group.name.isNotEmpty
                            ? group.name[0].toUpperCase()
                            : 'G',
                        style: GoogleFonts.dmSans(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: AppColors.sageDark,
                        ),
                      ),
                    ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    group.name,
                    style: GoogleFonts.dmSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.ink,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${group.memberCount} members · ${group.subject}',
                    style: GoogleFonts.dmSans(
                      fontSize: 12,
                      color: AppColors.mutedText,
                    ),
                  ),
                ],
              ),
            ),
            if (!isMember && onJoin != null)
              TextButton(
                onPressed: onJoin,
                child: const Text('Join'),
              )
            else
              const Icon(Icons.chevron_right, color: AppColors.mutedText),
          ],
        ),
      ),
    );
  }
}
