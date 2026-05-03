import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../config/app_colors.dart';
import '../../config/constants.dart';
import '../../providers/auth_provider.dart';
import '../../providers/deck_provider.dart';
import '../../services/storage_service.dart';
import '../../widgets/common/app_chip.dart';
import '../../widgets/common/app_input.dart';
import '../../widgets/common/error_snackbar.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _storageService = StorageService();

  Future<void> _pickAndUploadAvatar() async {
    try {
      final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
      if (picked == null) return;
      final auth = context.read<AuthProvider>();
      final url = await _storageService.uploadAvatar(auth.currentUser!.uid, File(picked.path));
      await auth.updateProfile(photoUrl: url);
    } catch (_) {
      if (mounted) showErrorSnackbar(context, 'Could not update photo.');
    }
  }

  void _showEditProfile(BuildContext context) {
    final auth = context.read<AuthProvider>();
    final user = auth.currentUser;
    if (user == null) return;
    final nameCtrl = TextEditingController(text: user.displayName);
    final bioCtrl = TextEditingController(text: user.bio ?? '');
    final selectedSubjects = List<String>.from(user.subjects);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) => Padding(
          padding: EdgeInsets.only(left: 24, right: 24, top: 24, bottom: MediaQuery.of(ctx).viewInsets.bottom + 24),
          child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Edit Profile', style: GoogleFonts.dmSans(fontSize: 20, fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),
            AppInput(label: 'Display Name', controller: nameCtrl),
            const SizedBox(height: 12),
            AppInput(label: 'Bio', controller: bioCtrl, maxLines: 2),
            const SizedBox(height: 12),
            Text('SUBJECTS', style: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.sageMid, letterSpacing: 0.8)),
            const SizedBox(height: 8),
            Wrap(spacing: 8, runSpacing: 8, children: AppConstants.subjects.map((s) => AppChip(
              label: s,
              selected: selectedSubjects.contains(s),
              onTap: () => setModal(() {
                if (selectedSubjects.contains(s)) { selectedSubjects.remove(s); }
                else { selectedSubjects.add(s); }
              }),
            )).toList()),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                await auth.updateProfile(
                  displayName: nameCtrl.text.trim(),
                  bio: bioCtrl.text.trim(),
                  subjects: selectedSubjects,
                );
                if (mounted) Navigator.pop(ctx);
              },
              child: const Text('Save'),
            ),
          ])),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final deckProvider = context.watch<DeckProvider>();
    final user = auth.currentUser;

    if (user == null) return const SizedBox();

    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(icon: const Icon(Icons.settings_outlined), onPressed: () => context.push('/settings')),
        ],
      ),
      body: ListView(padding: const EdgeInsets.all(20), children: [
        Center(child: Stack(children: [
          GestureDetector(
            onTap: _pickAndUploadAvatar,
            child: CircleAvatar(
              radius: 44,
              backgroundColor: AppColors.sageLight,
              backgroundImage: user.photoUrl != null ? CachedNetworkImageProvider(user.photoUrl!) : null,
              child: user.photoUrl == null ? Text(user.displayName.isNotEmpty ? user.displayName[0].toUpperCase() : 'S',
                  style: GoogleFonts.dmSans(fontSize: 32, fontWeight: FontWeight.w700, color: AppColors.sageDark)) : null,
            ),
          ),
          Positioned(bottom: 0, right: 0, child: Container(
            width: 26, height: 26,
            decoration: BoxDecoration(color: AppColors.sageDark, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2)),
            child: const Icon(Icons.add, color: Colors.white, size: 16),
          )),
        ])),
        const SizedBox(height: 16),
        Center(child: Text(user.displayName, style: GoogleFonts.dmSans(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.ink))),
        Center(child: Text(user.email, style: GoogleFonts.dmSans(fontSize: 14, color: AppColors.mutedText))),
        if (user.bio != null && user.bio!.isNotEmpty) ...[
          const SizedBox(height: 8),
          Center(child: Text(user.bio!, textAlign: TextAlign.center, style: GoogleFonts.dmSans(fontSize: 14, color: AppColors.mutedText))),
        ],
        if (user.subjects.isNotEmpty) ...[
          const SizedBox(height: 12),
          Wrap(spacing: 8, runSpacing: 8, alignment: WrapAlignment.center,
              children: user.subjects.map((s) => AppChip(label: s, selected: true)).toList()),
        ],
        const SizedBox(height: 12),
        Center(child: TextButton(onPressed: () => _showEditProfile(context), child: const Text('Edit profile'))),
        const SizedBox(height: 16),
        Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
          _StatBox(label: 'Decks', value: '${deckProvider.decks.length}'),
          _StatBox(label: 'Cards', value: '${deckProvider.decks.fold(0, (s, d) => s + d.cardCount)}'),
          _StatBox(label: 'Due', value: '${deckProvider.totalDueCards}'),
        ]),
        const SizedBox(height: 24),
        const Divider(),
        ListTile(
          leading: const Icon(Icons.logout, color: AppColors.danger),
          title: Text('Sign out', style: GoogleFonts.dmSans(color: AppColors.danger, fontWeight: FontWeight.w600)),
          onTap: () async {
            final confirm = await showDialog<bool>(
              context: context,
              builder: (d) => AlertDialog(
                title: const Text('Sign out?'),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(d, false), child: const Text('Cancel')),
                  TextButton(onPressed: () => Navigator.pop(d, true), child: const Text('Sign out', style: TextStyle(color: AppColors.danger))),
                ],
              ),
            );
            if (confirm == true && mounted) {
              await auth.signOut();
              if (mounted) context.go('/splash');
            }
          },
        ),
      ]),
    );
  }
}

class _StatBox extends StatelessWidget {
  final String label;
  final String value;

  const _StatBox({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(color: AppColors.warmGray, borderRadius: BorderRadius.circular(14)),
      child: Column(children: [
        Text(value, style: GoogleFonts.dmSans(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.ink)),
        Text(label, style: GoogleFonts.dmSans(fontSize: 12, color: AppColors.mutedText)),
      ]),
    );
  }
}
