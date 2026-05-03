import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../models/message_model.dart';
import '../../config/app_colors.dart';

class MessageBubble extends StatelessWidget {
  final MessageModel message;
  final bool isMe;

  const MessageBubble({
    super.key,
    required this.message,
    required this.isMe,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (!isMe) ...[
              CircleAvatar(
                radius: 16,
                backgroundColor: AppColors.sageLight,
                backgroundImage: message.senderPhotoUrl != null
                    ? CachedNetworkImageProvider(message.senderPhotoUrl!)
                    : null,
                child: message.senderPhotoUrl == null
                    ? Text(
                        message.senderName.isNotEmpty
                            ? message.senderName[0].toUpperCase()
                            : '?',
                        style: GoogleFonts.dmSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.sageDark,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 8),
            ],
            ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.65,
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: isMe ? AppColors.sageDark : Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(18),
                    topRight: const Radius.circular(18),
                    bottomLeft:
                        isMe ? const Radius.circular(18) : const Radius.circular(4),
                    bottomRight:
                        isMe ? const Radius.circular(4) : const Radius.circular(18),
                  ),
                  border: isMe
                      ? null
                      : Border.all(color: AppColors.borderColor),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (!isMe) ...[
                      Text(
                        message.senderName,
                        style: GoogleFonts.dmSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.sageMid,
                        ),
                      ),
                      const SizedBox(height: 2),
                    ],
                    if (message.imageUrl != null)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: CachedNetworkImage(
                          imageUrl: message.imageUrl!,
                          width: 200,
                          fit: BoxFit.cover,
                        ),
                      ),
                    if (message.text.isNotEmpty)
                      Text(
                        message.text,
                        style: GoogleFonts.dmSans(
                          fontSize: 14,
                          color: isMe ? Colors.white : AppColors.ink,
                        ),
                      ),
                    const SizedBox(height: 4),
                    Text(
                      timeago.format(message.createdAt),
                      style: GoogleFonts.dmSans(
                        fontSize: 10,
                        color: isMe
                            ? Colors.white.withOpacity(0.7)
                            : AppColors.mutedText,
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
