import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../config/app_colors.dart';
import '../../models/card_model.dart';
import '../../providers/card_provider.dart';
import '../../services/ai_service.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/common/error_snackbar.dart';

class AddEditCardScreen extends StatefulWidget {
  final String deckId;
  final CardModel? card;
  final String? cardId;

  const AddEditCardScreen({
    super.key,
    required this.deckId,
    this.card,
    this.cardId,
  });

  @override
  State<AddEditCardScreen> createState() => _AddEditCardScreenState();
}

class _AddEditCardScreenState extends State<AddEditCardScreen> {
  final _frontController = TextEditingController();
  final _backController = TextEditingController();
  final _aiService = AiService();
  double _easeFactor = 2.5;
  bool _isSaving = false;
  bool _isAiLoading = false;

  bool get _isEdit => widget.card != null;

  final _difficultyOptions = {
    'Easy': 2.8,
    'Normal': 2.5,
    'Hard': 2.2,
  };

  @override
  void initState() {
    super.initState();
    if (widget.card != null) {
      _frontController.text = widget.card!.front;
      _backController.text = widget.card!.back;
      _easeFactor = widget.card!.easeFactor;
    }
  }

  @override
  void dispose() {
    _frontController.dispose();
    _backController.dispose();
    super.dispose();
  }

  Future<void> _suggestAnswer() async {
    if (_frontController.text.trim().isEmpty) return;
    setState(() => _isAiLoading = true);
    try {
      final suggestion = await _aiService.suggestCardBack(_frontController.text.trim());
      if (mounted) _backController.text = suggestion;
    } catch (e) {
      if (mounted) showErrorSnackbar(context, 'AI suggestion failed. Please try again.');
    } finally {
      if (mounted) setState(() => _isAiLoading = false);
    }
  }

  Future<bool> _saveCard() async {
    if (_frontController.text.trim().isEmpty || _backController.text.trim().isEmpty) return false;
    setState(() => _isSaving = true);
    final cardProvider = context.read<CardProvider>();

    try {
      if (_isEdit) {
        await cardProvider.updateCard(
          deckId: widget.deckId,
          cardId: widget.card!.id,
          front: _frontController.text.trim(),
          back: _backController.text.trim(),
          easeFactor: _easeFactor,
        );
      } else {
        await cardProvider.createCard(
          deckId: widget.deckId,
          front: _frontController.text.trim(),
          back: _backController.text.trim(),
          easeFactor: _easeFactor,
        );
      }
      return true;
    } catch (_) {
      if (mounted) showErrorSnackbar(context, 'Could not save. Check your connection.');
      return false;
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final canSave = _frontController.text.trim().isNotEmpty &&
        _backController.text.trim().isNotEmpty;
    final selectedDifficulty = _difficultyOptions.entries
        .firstWhere((e) => (e.value - _easeFactor).abs() < 0.1,
            orElse: () => const MapEntry('Normal', 2.5))
        .key;

    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        title: Text(_isEdit ? 'Edit Card' : 'New Card'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.sageMid, width: 2),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('FRONT — TERM / QUESTION',
                      style: GoogleFonts.dmSans(
                          fontSize: 11, fontWeight: FontWeight.w700,
                          color: AppColors.sageMid, letterSpacing: 0.8)),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _frontController,
                    maxLines: 4,
                    onChanged: (_) => setState(() {}),
                    decoration: const InputDecoration(
                      hintText: 'Enter term or question...',
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      filled: false,
                    ),
                    style: GoogleFonts.dmSans(fontSize: 16, color: AppColors.ink),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.borderColor),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('BACK — DEFINITION / ANSWER',
                      style: GoogleFonts.dmSans(
                          fontSize: 11, fontWeight: FontWeight.w700,
                          color: AppColors.mutedText, letterSpacing: 0.8)),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _backController,
                    maxLines: 4,
                    onChanged: (_) => setState(() {}),
                    decoration: const InputDecoration(
                      hintText: 'Enter definition or answer...',
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      filled: false,
                    ),
                    style: GoogleFonts.dmSans(fontSize: 16, color: AppColors.ink),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Center(
              child: TextButton.icon(
                onPressed: _frontController.text.trim().isNotEmpty && !_isAiLoading
                    ? _suggestAnswer
                    : null,
                icon: _isAiLoading
                    ? const SizedBox(
                        width: 16, height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.sageDark),
                      )
                    : const Icon(Icons.auto_awesome, size: 18),
                label: Text(_isAiLoading ? 'Thinking...' : 'Suggest answer'),
                style: TextButton.styleFrom(
                  backgroundColor: AppColors.sageLight,
                  foregroundColor: AppColors.sageDark,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  shape: const StadiumBorder(),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text('INITIAL DIFFICULTY',
                style: GoogleFonts.dmSans(
                    fontSize: 13, fontWeight: FontWeight.w700,
                    color: AppColors.sageMid, letterSpacing: 0.8)),
            const SizedBox(height: 8),
            Row(
              children: _difficultyOptions.entries.map((entry) {
                final selected = entry.key == selectedDifficulty;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(entry.key),
                    selected: selected,
                    onSelected: (_) => setState(() => _easeFactor = entry.value),
                    selectedColor: AppColors.sageLight,
                    checkmarkColor: AppColors.sageDark,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 32),
            if (!_isEdit) ...[
              AppButton(
                label: 'Save & Add Another',
                variant: 'secondary',
                onPressed: canSave ? () async {
                  final ok = await _saveCard();
                  if (ok && mounted) {
                    _frontController.clear();
                    _backController.clear();
                    setState(() {});
                    showSuccessSnackbar(context, 'Card saved!');
                  }
                } : null,
                isLoading: _isSaving,
              ),
              const SizedBox(height: 12),
            ],
            AppButton(
              label: 'Save Card',
              onPressed: canSave ? () async {
                final ok = await _saveCard();
                if (ok && mounted) context.pop();
              } : null,
              isLoading: _isSaving,
            ),
          ],
        ),
      ),
    );
  }
}
