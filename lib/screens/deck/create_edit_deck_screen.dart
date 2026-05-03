import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../config/app_colors.dart';
import '../../config/constants.dart';
import '../../models/deck_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/deck_provider.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/common/app_input.dart';
import '../../widgets/common/app_chip.dart';
import '../../widgets/common/error_snackbar.dart';

class CreateEditDeckScreen extends StatefulWidget {
  final DeckModel? deck;
  final String? deckId;

  const CreateEditDeckScreen({super.key, this.deck, this.deckId});

  @override
  State<CreateEditDeckScreen> createState() => _CreateEditDeckScreenState();
}

class _CreateEditDeckScreenState extends State<CreateEditDeckScreen> {
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  String _selectedSubject = 'Other';
  String _selectedColor = '#2D5A3D';
  bool _isSaving = false;

  bool get _isEdit => widget.deck != null || widget.deckId != null;

  @override
  void initState() {
    super.initState();
    if (widget.deck != null) {
      _nameController.text = widget.deck!.name;
      _descController.text = widget.deck!.description;
      _selectedSubject = widget.deck!.subject;
      _selectedColor = widget.deck!.accentColorHex;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Color _parseColor(String hex) {
    try {
      return Color(int.parse('FF${hex.replaceAll('#', '')}', radix: 16));
    } catch (_) {
      return AppColors.sageDark;
    }
  }

  Future<void> _save() async {
    if (_nameController.text.trim().isEmpty) return;
    setState(() => _isSaving = true);

    final deckProvider = context.read<DeckProvider>();
    final auth = context.read<AuthProvider>();

    try {
      if (_isEdit && widget.deck != null) {
        await deckProvider.updateDeck(
          deckId: widget.deck!.id,
          name: _nameController.text.trim(),
          description: _descController.text.trim(),
          subject: _selectedSubject,
          accentColorHex: _selectedColor,
        );
      } else {
        await deckProvider.createDeck(
          userId: auth.currentUser!.uid,
          name: _nameController.text.trim(),
          description: _descController.text.trim(),
          subject: _selectedSubject,
          accentColorHex: _selectedColor,
        );
      }
      if (mounted) context.pop();
    } catch (e) {
      if (mounted) showErrorSnackbar(context, 'Could not save. Check your connection.');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final canSave = _nameController.text.trim().isNotEmpty;

    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        title: Text(_isEdit ? 'Edit Deck' : 'New Deck'),
        actions: [
          TextButton(
            onPressed: canSave && !_isSaving ? _save : null,
            child: Text(
              'Save',
              style: GoogleFonts.dmSans(
                fontWeight: FontWeight.w700,
                color: canSave ? AppColors.sageDark : AppColors.mutedText,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppInput(
              label: 'Deck Name',
              controller: _nameController,
              hint: 'e.g. Organic Chemistry Ch. 5',
              maxLength: AppConstants.maxDeckNameLength,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 20),
            Text(
              'SUBJECT',
              style: GoogleFonts.dmSans(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.sageMid,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: AppConstants.subjects.map((s) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: AppChip(
                      label: s,
                      selected: _selectedSubject == s,
                      onTap: () => setState(() => _selectedSubject = s),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 20),
            AppInput(
              label: 'Description (optional)',
              controller: _descController,
              maxLines: 3,
              maxLength: AppConstants.maxDescriptionLength,
              hint: 'What is this deck about?',
            ),
            const SizedBox(height: 20),
            Text(
              'COLOR',
              style: GoogleFonts.dmSans(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.sageMid,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: AppConstants.accentColors.map((hex) {
                final color = _parseColor(hex);
                final isSelected = _selectedColor == hex;
                return GestureDetector(
                  onTap: () => setState(() => _selectedColor = hex),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 36,
                    height: 36,
                    margin: const EdgeInsets.only(right: 10),
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected ? AppColors.ink : Colors.transparent,
                        width: 2.5,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: color.withOpacity(0.4),
                                blurRadius: 8,
                              )
                            ]
                          : null,
                    ),
                    child: isSelected
                        ? const Icon(Icons.check, color: Colors.white, size: 18)
                        : null,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 40),
            AppButton(
              label: _isEdit ? 'Save Deck' : 'Create Deck',
              onPressed: canSave ? _save : null,
              isLoading: _isSaving,
            ),
          ],
        ),
      ),
    );
  }
}
