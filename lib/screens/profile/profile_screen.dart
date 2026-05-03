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
import '../../widgets/common/app_button.dart';
import '../../widgets/common/app_chip.dart';
import '../../widgets/common/app_input.dart';
import '../../widgets/common/error_snackbar.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  final _storageService = StorageService();
  final _picker = ImagePicker();

  bool _isUploading = false;
  double _uploadProgress = 0.0;

  late AnimationController _avatarPulse;
  late Animation<double> _avatarScale;

  @override
  void initState() {
    super.initState();
    _avatarPulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _avatarScale = Tween(begin: 1.0, end: 1.04).animate(
      CurvedAnimation(parent: _avatarPulse, curve: Curves.easeInOut),
    );
    _avatarPulse.stop();
  }

  @override
  void dispose() {
    _avatarPulse.dispose();
    super.dispose();
  }

  // ── Avatar Actions ────────────────────────────────────────────────────────

  void _showAvatarSheet() {
    final auth = context.read<AuthProvider>();
    final hasPhoto = auth.currentUser?.photoUrl != null;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36, height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: AppColors.borderColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Text('Profile Photo',
                  style: GoogleFonts.dmSans(
                      fontSize: 16, fontWeight: FontWeight.w700)),
              const SizedBox(height: 12),
              _SheetTile(
                icon: Icons.photo_library_outlined,
                label: 'Choose from library',
                onTap: () { Navigator.pop(context); _pickImage(ImageSource.gallery); },
              ),
              _SheetTile(
                icon: Icons.camera_alt_outlined,
                label: 'Take a photo',
                onTap: () { Navigator.pop(context); _pickImage(ImageSource.camera); },
              ),
              if (hasPhoto)
                _SheetTile(
                  icon: Icons.delete_outline,
                  label: 'Remove photo',
                  color: AppColors.danger,
                  onTap: () { Navigator.pop(context); _removePhoto(); },
                ),
              _SheetTile(
                icon: Icons.close,
                label: 'Cancel',
                onTap: () => Navigator.pop(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picked = await _picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 88,
      );
      if (picked == null || !mounted) return;
      await _uploadAvatar(File(picked.path));
    } catch (_) {
      if (mounted) showErrorSnackbar(context, 'Could not access photos.');
    }
  }

  Future<void> _uploadAvatar(File file) async {
    final auth = context.read<AuthProvider>();
    final uid = auth.currentUser?.uid;
    if (uid == null) return;

    setState(() {
      _isUploading = true;
      _uploadProgress = 0.0;
    });
    _avatarPulse.repeat(reverse: true);

    try {
      final url = await _storageService.uploadAvatar(
        uid,
        file,
        onProgress: (p) {
          if (mounted) setState(() => _uploadProgress = p);
        },
      );
      await auth.updateProfile(photoUrl: url);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(children: [
              const Icon(Icons.check_circle, color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Text('Photo updated!',
                  style: GoogleFonts.dmSans(color: Colors.white)),
            ]),
            backgroundColor: AppColors.sageDark,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    } catch (_) {
      if (mounted) showErrorSnackbar(context, 'Upload failed. Please try again.');
    } finally {
      if (mounted) {
        setState(() { _isUploading = false; _uploadProgress = 0.0; });
        _avatarPulse.stop();
        _avatarPulse.reset();
      }
    }
  }

  Future<void> _removePhoto() async {
    final auth = context.read<AuthProvider>();
    final uid = auth.currentUser?.uid;
    if (uid == null) return;

    setState(() => _isUploading = true);
    try {
      await _storageService.deleteAvatar(uid);
      await auth.updateProfile(removePhotoUrl: true);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Photo removed.',
                style: GoogleFonts.dmSans(color: Colors.white)),
            backgroundColor: AppColors.mutedText,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    } catch (_) {
      if (mounted) showErrorSnackbar(context, 'Could not remove photo.');
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  // ── Edit Profile Sheet ────────────────────────────────────────────────────

  void _showEditProfile() {
    final auth = context.read<AuthProvider>();
    final user = auth.currentUser;
    if (user == null) return;

    final nameCtrl = TextEditingController(text: user.displayName);
    final bioCtrl = TextEditingController(text: user.bio ?? '');
    final selectedSubjects = List<String>.from(user.subjects);
    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) => Padding(
          padding: EdgeInsets.only(
            left: 24, right: 24, top: 24,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 32,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle
                Center(
                  child: Container(
                    width: 36, height: 4,
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: AppColors.borderColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Text('Edit Profile',
                    style: GoogleFonts.dmSans(
                        fontSize: 20, fontWeight: FontWeight.w700)),
                const SizedBox(height: 20),
                AppInput(
                  label: 'Display Name',
                  controller: nameCtrl,
                  hint: 'Your name',
                ),
                const SizedBox(height: 14),
                AppInput(
                  label: 'Bio',
                  controller: bioCtrl,
                  maxLines: 3,
                  hint: 'Tell others what you study…',
                ),
                const SizedBox(height: 14),
                Text('SUBJECTS',
                    style: GoogleFonts.dmSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.sageMid,
                        letterSpacing: 0.8)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8, runSpacing: 8,
                  children: AppConstants.subjects.map((s) => AppChip(
                    label: s,
                    selected: selectedSubjects.contains(s),
                    onTap: () => setModal(() {
                      selectedSubjects.contains(s)
                          ? selectedSubjects.remove(s)
                          : selectedSubjects.add(s);
                    }),
                  )).toList(),
                ),
                const SizedBox(height: 24),
                AppButton(
                  label: isSaving ? 'Saving…' : 'Save changes',
                  onPressed: isSaving
                      ? null
                      : () async {
                          if (nameCtrl.text.trim().isEmpty) return;
                          setModal(() => isSaving = true);
                          await auth.updateProfile(
                            displayName: nameCtrl.text.trim(),
                            bio: bioCtrl.text.trim(),
                            subjects: selectedSubjects,
                          );
                          if (ctx.mounted) Navigator.pop(ctx);
                        },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────

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
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      body: ListView(padding: const EdgeInsets.all(20), children: [

        // ── Avatar ──────────────────────────────────────────────────────────
        Center(
          child: GestureDetector(
            onTap: _isUploading ? null : _showAvatarSheet,
            child: SizedBox(
              width: 96, height: 96,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Progress ring
                  if (_isUploading)
                    SizedBox(
                      width: 96, height: 96,
                      child: CircularProgressIndicator(
                        value: _uploadProgress > 0 ? _uploadProgress : null,
                        strokeWidth: 3,
                        color: AppColors.sageDark,
                        backgroundColor: AppColors.sageLight,
                      ),
                    ),

                  // Avatar circle
                  AnimatedBuilder(
                    animation: _avatarScale,
                    builder: (_, child) => Transform.scale(
                      scale: _isUploading ? _avatarScale.value : 1.0,
                      child: child,
                    ),
                    child: AnimatedOpacity(
                      opacity: _isUploading ? 0.7 : 1.0,
                      duration: const Duration(milliseconds: 200),
                      child: _AvatarCircle(
                        photoUrl: user.photoUrl,
                        displayName: user.displayName,
                        radius: 42,
                      ),
                    ),
                  ),

                  // Upload icon overlay
                  if (_isUploading && _uploadProgress > 0)
                    Positioned(
                      bottom: 6, right: 6,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: AppColors.sageDark,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          '${(_uploadProgress * 100).round()}%',
                          style: GoogleFonts.dmSans(
                              fontSize: 9,
                              color: Colors.white,
                              fontWeight: FontWeight.w700),
                        ),
                      ),
                    )
                  // Camera badge when idle
                  else if (!_isUploading)
                    Positioned(
                      bottom: 4, right: 4,
                      child: Container(
                        width: 28, height: 28,
                        decoration: BoxDecoration(
                          color: AppColors.sageDark,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: const Icon(Icons.camera_alt,
                            color: Colors.white, size: 14),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),

        const SizedBox(height: 4),
        Center(
          child: TextButton(
            onPressed: _isUploading ? null : _showAvatarSheet,
            child: Text(
              _isUploading
                  ? 'Uploading…'
                  : (user.photoUrl != null ? 'Change photo' : 'Add photo'),
              style: GoogleFonts.dmSans(
                  fontSize: 13,
                  color: _isUploading
                      ? AppColors.mutedText
                      : AppColors.sageDark,
                  fontWeight: FontWeight.w600),
            ),
          ),
        ),

        // ── Name / Email / Bio ───────────────────────────────────────────
        const SizedBox(height: 4),
        Center(child: Text(user.displayName,
            style: GoogleFonts.dmSans(
                fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.ink))),
        Center(child: Text(user.email,
            style: GoogleFonts.dmSans(fontSize: 14, color: AppColors.mutedText))),
        if (user.bio != null && user.bio!.isNotEmpty) ...[
          const SizedBox(height: 8),
          Center(
            child: Text(user.bio!,
                textAlign: TextAlign.center,
                style: GoogleFonts.dmSans(fontSize: 14, color: AppColors.mutedText)),
          ),
        ],

        // ── Subject chips ────────────────────────────────────────────────
        if (user.subjects.isNotEmpty) ...[
          const SizedBox(height: 12),
          Wrap(
            spacing: 8, runSpacing: 8,
            alignment: WrapAlignment.center,
            children: user.subjects
                .map((s) => AppChip(label: s, selected: true))
                .toList(),
          ),
        ],

        // ── Edit profile ─────────────────────────────────────────────────
        const SizedBox(height: 12),
        Center(
          child: OutlinedButton.icon(
            onPressed: _showEditProfile,
            icon: const Icon(Icons.edit_outlined, size: 16),
            label: const Text('Edit profile'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.sageDark,
              side: const BorderSide(color: AppColors.sageDark),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              textStyle: GoogleFonts.dmSans(fontWeight: FontWeight.w600),
            ),
          ),
        ),

        // ── Streak ───────────────────────────────────────────────────────
        if (user.currentStreak > 0)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.sageDark.withOpacity(0.1), AppColors.sageLight],
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(children: [
              const Text('🔥', style: TextStyle(fontSize: 32)),
              const SizedBox(width: 12),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('${user.currentStreak} day streak',
                    style: GoogleFonts.dmSans(fontSize: 16, fontWeight: FontWeight.w700)),
                Text('Keep it up!',
                    style: GoogleFonts.dmSans(fontSize: 12, color: AppColors.mutedText)),
              ]),
              const Spacer(),
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Text('Best: ${user.longestStreak}',
                    style: GoogleFonts.dmSans(fontSize: 12, fontWeight: FontWeight.w600)),
              ]),
            ]),
          ),

        if (user.currentStreak > 0) const SizedBox(height: 16),

        // ── Stats ────────────────────────────────────────────────────────
        const SizedBox(height: 8),
        Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
          _StatBox(label: 'Decks', value: '${deckProvider.decks.length}'),
          _StatBox(
            label: 'Cards',
            value: '${deckProvider.decks.fold(0, (s, d) => s + d.cardCount)}',
          ),
          _StatBox(label: 'Due', value: '${deckProvider.totalDueCards}'),
        ]),

        // ── Achievements ─────────────────────────────────────────────────
        if (user.achievements.isNotEmpty) ...[
          const SizedBox(height: 24),
          Text('Achievements',
              style: GoogleFonts.dmSans(fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12, runSpacing: 12,
            children: user.achievements.map((a) => Tooltip(
              message: a.title,
              child: Container(
                width: 60, height: 60,
                decoration: BoxDecoration(
                  color: AppColors.warmGray,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Text(a.icon, style: const TextStyle(fontSize: 24)),
                  Text(a.title.split(' ').first,
                      style: GoogleFonts.dmSans(fontSize: 10, fontWeight: FontWeight.w600),
                      textAlign: TextAlign.center),
                ]),
              ),
            )).toList(),
          ),
        ],

        // ── Sign out ─────────────────────────────────────────────────────
        const SizedBox(height: 24),
        const Divider(),
        ListTile(
          leading: const Icon(Icons.logout, color: AppColors.danger),
          title: Text('Sign out',
              style: GoogleFonts.dmSans(
                  color: AppColors.danger, fontWeight: FontWeight.w600)),
          onTap: () async {
            final confirm = await showDialog<bool>(
              context: context,
              builder: (d) => AlertDialog(
                title: const Text('Sign out?'),
                content: const Text('You can sign back in at any time.'),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(d, false),
                      child: const Text('Cancel')),
                  TextButton(
                      onPressed: () => Navigator.pop(d, true),
                      child: const Text('Sign out',
                          style: TextStyle(color: AppColors.danger))),
                ],
              ),
            );
            if (confirm == true && mounted) {
              await auth.signOut();
              if (mounted) context.go('/splash');
            }
          },
        ),
        const SizedBox(height: 20),
      ]),
    );
  }
}

// ── Reusable avatar circle ────────────────────────────────────────────────────

class _AvatarCircle extends StatelessWidget {
  final String? photoUrl;
  final String displayName;
  final double radius;

  const _AvatarCircle({
    required this.photoUrl,
    required this.displayName,
    required this.radius,
  });

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: radius,
      backgroundColor: AppColors.sageLight,
      backgroundImage: photoUrl != null
          ? CachedNetworkImageProvider(photoUrl!)
          : null,
      child: photoUrl == null
          ? Text(
              displayName.isNotEmpty
                  ? displayName[0].toUpperCase()
                  : 'S',
              style: GoogleFonts.dmSans(
                fontSize: radius * 0.75,
                fontWeight: FontWeight.w700,
                color: AppColors.sageDark,
              ),
            )
          : null,
    );
  }
}

// ── Bottom sheet tile ─────────────────────────────────────────────────────────

class _SheetTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  const _SheetTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.ink;
    return ListTile(
      leading: Icon(icon, color: c, size: 22),
      title: Text(label,
          style: GoogleFonts.dmSans(
              fontSize: 15, fontWeight: FontWeight.w500, color: c)),
      onTap: onTap,
    );
  }
}

// ── Stat box ──────────────────────────────────────────────────────────────────

class _StatBox extends StatelessWidget {
  final String label;
  final String value;

  const _StatBox({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.warmGray,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(children: [
        Text(value,
            style: GoogleFonts.dmSans(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.ink)),
        Text(label,
            style: GoogleFonts.dmSans(
                fontSize: 12, color: AppColors.mutedText)),
      ]),
    );
  }
}
