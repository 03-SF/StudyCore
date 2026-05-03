import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../config/app_colors.dart';
import '../../models/message_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/message_service.dart';
import '../../services/storage_service.dart';
import '../../widgets/common/empty_state.dart';
import '../../widgets/common/error_snackbar.dart';
import '../../widgets/groups/message_bubble.dart';

class GroupChatScreen extends StatefulWidget {
  final String groupId;

  const GroupChatScreen({super.key, required this.groupId});

  @override
  State<GroupChatScreen> createState() => _GroupChatScreenState();
}

class _GroupChatScreenState extends State<GroupChatScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  final _messageService = MessageService();
  final _storageService = StorageService();
  bool _isSending = false;

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage({String? imageUrl}) async {
    final text = _messageController.text.trim();
    if (text.isEmpty && imageUrl == null) return;
    final auth = context.read<AuthProvider>();
    final user = auth.currentUser;
    if (user == null) return;

    setState(() => _isSending = true);
    try {
      await _messageService.sendMessage(
        groupId: widget.groupId,
        userId: user.uid,
        senderName: user.displayName,
        senderPhotoUrl: user.photoUrl,
        text: text.isEmpty ? '' : text,
        imageUrl: imageUrl,
      );
      _messageController.clear();
      _scrollController.animateTo(0, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
    } catch (_) {
      if (mounted) showErrorSnackbar(context, 'Could not send message.');
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  Future<void> _attachImage() async {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => Column(mainAxisSize: MainAxisSize.min, children: [
        ListTile(
          leading: const Icon(Icons.photo_library_outlined),
          title: const Text('Gallery'),
          onTap: () async {
            Navigator.pop(ctx);
            try {
              final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
              if (picked == null) return;
              final url = await _storageService.uploadMessageImage(widget.groupId, DateTime.now().toString(), File(picked.path));
              await _sendMessage(imageUrl: url);
            } catch (_) {
              if (mounted) showErrorSnackbar(context, 'Could not upload image.');
            }
          },
        ),
        ListTile(
          leading: const Icon(Icons.camera_alt_outlined),
          title: const Text('Camera'),
          onTap: () async {
            Navigator.pop(ctx);
            try {
              final picked = await ImagePicker().pickImage(source: ImageSource.camera);
              if (picked == null) return;
              final url = await _storageService.uploadMessageImage(widget.groupId, DateTime.now().toString(), File(picked.path));
              await _sendMessage(imageUrl: url);
            } catch (_) {
              if (mounted) showErrorSnackbar(context, 'Could not upload image.');
            }
          },
        ),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(title: const Text('Group Chat')),
      body: Column(children: [
        Expanded(
          child: StreamBuilder<List<MessageModel>>(
            stream: _messageService.messagesStream(widget.groupId),
            builder: (ctx, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(color: AppColors.sageDark));
              }
              if (snapshot.hasError) {
                return const EmptyState(icon: Icons.error_outline, title: 'Error', subtitle: 'Could not load messages.');
              }
              final messages = snapshot.data ?? [];
              if (messages.isEmpty) {
                return const EmptyState(icon: Icons.chat_bubble_outline, title: 'No messages yet', subtitle: 'Be the first to send a message!');
              }
              return ListView.builder(
                controller: _scrollController,
                reverse: true,
                itemCount: messages.length,
                itemBuilder: (ctx, i) => MessageBubble(
                  message: messages[i],
                  isMe: messages[i].userId == auth.currentUser?.uid,
                ),
              );
            },
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: AppColors.borderColor)),
          ),
          child: SafeArea(
            child: Row(children: [
              IconButton(icon: const Icon(Icons.attach_file, color: AppColors.sageMid), onPressed: _attachImage),
              Expanded(
                child: TextField(
                  controller: _messageController,
                  maxLines: null,
                  textInputAction: TextInputAction.newline,
                  decoration: InputDecoration(
                    hintText: 'Message...',
                    hintStyle: GoogleFonts.dmSans(color: AppColors.mutedText),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    filled: false,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  ),
                ),
              ),
              GestureDetector(
                onTap: _isSending ? null : () => _sendMessage(),
                child: CircleAvatar(
                  radius: 20,
                  backgroundColor: _isSending ? AppColors.borderColor : AppColors.sageDark,
                  child: _isSending
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Icon(Icons.send, color: Colors.white, size: 18),
                ),
              ),
            ]),
          ),
        ),
      ]),
    );
  }
}
