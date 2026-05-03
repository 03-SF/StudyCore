import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../config/app_colors.dart';
import '../../config/constants.dart';
import '../../providers/auth_provider.dart';
import '../../providers/group_provider.dart';
import '../../services/storage_service.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/common/app_chip.dart';
import '../../widgets/common/app_input.dart';
import '../../widgets/common/error_snackbar.dart';

class CreateGroupScreen extends StatefulWidget {
  const CreateGroupScreen({super.key});

  @override
  State<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends State<CreateGroupScreen> {
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  final _storageService = StorageService();
  String _selectedSubject = 'Other';
  bool _isPublic = true;
  File? _photo;
  bool _isSaving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    try {
      final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
      if (picked != null) setState(() => _photo = File(picked.path));
    } catch (_) {
      if (mounted) showErrorSnackbar(context, 'Could not access gallery. Check permissions.');
    }
  }

  Future<void> _create() async {
    if (_nameController.text.trim().isEmpty) return;
    setState(() => _isSaving = true);

    final auth = context.read<AuthProvider>();
    final groupProvider = context.read<GroupProvider>();

    try {
      final group = await groupProvider.createGroup(
        adminId: auth.currentUser!.uid,
        name: _nameController.text.trim(),
        description: _descController.text.trim(),
        subject: _selectedSubject,
        isPublic: _isPublic,
      );
      if (group != null && _photo != null) {
        try {
          await _storageService.uploadGroupPhoto(group.id, _photo!);
        } catch (_) {}
      }
      if (mounted && group != null) {
        context.go('/groups/${group.id}');
      }
    } catch (e) {
      if (mounted) showErrorSnackbar(context, 'Could not create group. Check your connection.');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(title: const Text('Create Group')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Center(
            child: GestureDetector(
              onTap: _pickPhoto,
              child: Container(
                width: 80, height: 80,
                decoration: BoxDecoration(
                  color: AppColors.sageLight,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.borderColor),
                ),
                clipBehavior: Clip.hardEdge,
                child: _photo != null
                    ? Image.file(_photo!, fit: BoxFit.cover)
                    : const Icon(Icons.add_a_photo_outlined, color: AppColors.sageMid, size: 32),
              ),
            ),
          ),
          const SizedBox(height: 24),
          AppInput(label: 'Group Name', controller: _nameController, hint: 'e.g. Biochemistry Study Group', onChanged: (_) => setState(() {})),
          const SizedBox(height: 16),
          Text('SUBJECT', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.sageMid, letterSpacing: 0.8)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8, runSpacing: 8,
            children: AppConstants.subjects.map((s) => AppChip(
              label: s,
              selected: _selectedSubject == s,
              onTap: () => setState(() => _selectedSubject = s),
            )).toList(),
          ),
          const SizedBox(height: 16),
          AppInput(label: 'Description', controller: _descController, maxLines: 3, hint: 'What will this group study?'),
          const SizedBox(height: 16),
          SwitchListTile(
            value: _isPublic,
            onChanged: (v) => setState(() => _isPublic = v),
            activeColor: AppColors.sageDark,
            title: const Text('Public Group'),
            subtitle: const Text('Anyone can discover and join'),
            tileColor: AppColors.warmGray,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          const SizedBox(height: 32),
          AppButton(
            label: 'Create Group',
            onPressed: _nameController.text.trim().isNotEmpty ? _create : null,
            isLoading: _isSaving,
          ),
        ]),
      ),
    );
  }
}
