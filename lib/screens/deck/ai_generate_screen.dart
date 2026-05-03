import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../../config/app_colors.dart';
import '../../config/constants.dart';
import '../../services/ai_service.dart';
import '../../services/card_service.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/common/error_snackbar.dart';

class AiGenerateScreen extends StatefulWidget {
  final String deckId;

  const AiGenerateScreen({super.key, required this.deckId});

  @override
  State<AiGenerateScreen> createState() => _AiGenerateScreenState();
}

class _AiGenerateScreenState extends State<AiGenerateScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _textController = TextEditingController();
  final _aiService = AiService();
  final _cardService = CardService();
  int _cardCount = 10;
  bool _isGenerating = false;
  bool _isAdding = false;
  List<Map<String, String>> _generatedCards = [];
  Set<int> _selectedIndices = {};
  File? _selectedImage;
  String? _extractedText;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _textController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
      if (picked != null) {
        setState(() { _selectedImage = File(picked.path); });
      }
    } catch (_) {
      if (mounted) showErrorSnackbar(context, 'Could not access gallery. Check permissions.');
    }
  }

  Future<void> _generate() async {
    final text = _tabController.index == 0
        ? _textController.text.trim()
        : _extractedText ?? '';
    if (text.isEmpty) return;

    setState(() { _isGenerating = true; _generatedCards = []; });
    try {
      List<Map<String, String>> cards;
      if (_tabController.index == 1 && _selectedImage != null) {
        final bytes = await _selectedImage!.readAsBytes();
        cards = await _aiService.generateCardsFromImage(bytes, _cardCount);
      } else {
        cards = await _aiService.generateCardsFromText(text, _cardCount);
      }
      setState(() {
        _generatedCards = cards;
        _selectedIndices = Set.from(List.generate(cards.length, (i) => i));
      });
    } catch (e) {
      if (mounted) showErrorSnackbar(context, 'AI generation failed. Please try again.');
    } finally {
      if (mounted) setState(() => _isGenerating = false);
    }
  }

  Future<void> _addToDeck() async {
    if (_selectedIndices.isEmpty) return;
    setState(() => _isAdding = true);
    try {
      final selectedCards = _selectedIndices
          .map((i) => _generatedCards[i])
          .toList();
      await _cardService.batchCreateCards(widget.deckId, selectedCards);
      if (mounted) {
        showSuccessSnackbar(context, '${selectedCards.length} cards added!');
        context.pop();
      }
    } catch (e) {
      if (mounted) showErrorSnackbar(context, 'Could not save. Check your connection.');
    } finally {
      if (mounted) setState(() => _isAdding = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(title: const Text('AI Generate Cards')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.warmGray,
                borderRadius: BorderRadius.circular(12),
              ),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  color: AppColors.sageDark,
                  borderRadius: BorderRadius.circular(10),
                ),
                labelColor: Colors.white,
                unselectedLabelColor: AppColors.mutedText,
                labelStyle: GoogleFonts.dmSans(fontWeight: FontWeight.w600, fontSize: 13),
                tabs: const [Tab(text: 'Paste Text'), Tab(text: 'Take Photo')],
              ),
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildTextTab(),
                _buildPhotoTab(),
              ],
            ),
          ),
          if (_generatedCards.isNotEmpty)
            _buildBottomBar(),
        ],
      ),
    );
  }

  Widget _buildTextTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Opacity(
            opacity: _isGenerating ? 0.5 : 1.0,
            child: TextField(
              controller: _textController,
              maxLines: 10,
              maxLength: AppConstants.maxTextAreaLength,
              enabled: !_isGenerating,
              decoration: InputDecoration(
                hintText: 'Paste your notes, textbook content, or any study material here...',
                hintStyle: GoogleFonts.dmSans(color: AppColors.mutedText),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Text('Number of cards:', style: GoogleFonts.dmSans(fontSize: 14, fontWeight: FontWeight.w600)),
              const Spacer(),
              IconButton(
                onPressed: _cardCount > AppConstants.minCardCount
                    ? () => setState(() => _cardCount--)
                    : null,
                icon: const Icon(Icons.remove_circle_outline),
                color: AppColors.sageDark,
              ),
              Text('$_cardCount', style: GoogleFonts.dmSans(fontSize: 16, fontWeight: FontWeight.w700)),
              IconButton(
                onPressed: _cardCount < AppConstants.maxCardCount
                    ? () => setState(() => _cardCount++)
                    : null,
                icon: const Icon(Icons.add_circle_outline),
                color: AppColors.sageDark,
              ),
            ],
          ),
          const SizedBox(height: 16),
          AppButton(
            label: _isGenerating ? 'Generating...' : 'Generate Cards',
            onPressed: _textController.text.trim().isNotEmpty && !_isGenerating ? _generate : null,
            isLoading: _isGenerating,
            icon: Icons.auto_awesome,
          ),
          if (_generatedCards.isNotEmpty) ...[
            const SizedBox(height: 24),
            Text('Generated Cards', style: GoogleFonts.dmSans(fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            ..._generatedCards.asMap().entries.map((entry) => _buildCardCheckbox(entry.key, entry.value)),
          ],
        ],
      ),
    );
  }

  Widget _buildPhotoTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          GestureDetector(
            onTap: _pickImage,
            child: Container(
              height: 180,
              decoration: BoxDecoration(
                color: AppColors.warmGray,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.borderColor, style: BorderStyle.solid),
              ),
              clipBehavior: Clip.hardEdge,
              child: _selectedImage != null
                  ? Image.file(_selectedImage!, fit: BoxFit.cover, width: double.infinity)
                  : Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      const Icon(Icons.add_photo_alternate_outlined, size: 48, color: AppColors.mutedText),
                      const SizedBox(height: 8),
                      Text('Tap to select image', style: GoogleFonts.dmSans(color: AppColors.mutedText)),
                    ]),
            ),
          ),
          const SizedBox(height: 16),
          Row(children: [
            Text('Cards:', style: GoogleFonts.dmSans(fontSize: 14, fontWeight: FontWeight.w600)),
            const Spacer(),
            IconButton(onPressed: _cardCount > 3 ? () => setState(() => _cardCount--) : null, icon: const Icon(Icons.remove_circle_outline), color: AppColors.sageDark),
            Text('$_cardCount', style: GoogleFonts.dmSans(fontSize: 16, fontWeight: FontWeight.w700)),
            IconButton(onPressed: _cardCount < 20 ? () => setState(() => _cardCount++) : null, icon: const Icon(Icons.add_circle_outline), color: AppColors.sageDark),
          ]),
          const SizedBox(height: 16),
          AppButton(
            label: _isGenerating ? 'Generating...' : 'Generate from Image',
            onPressed: _selectedImage != null && !_isGenerating ? _generate : null,
            isLoading: _isGenerating,
            icon: Icons.auto_awesome,
          ),
          if (_generatedCards.isNotEmpty) ...[
            const SizedBox(height: 24),
            ..._generatedCards.asMap().entries.map((entry) => _buildCardCheckbox(entry.key, entry.value)),
          ],
        ],
      ),
    );
  }

  Widget _buildCardCheckbox(int index, Map<String, String> card) {
    final isSelected = _selectedIndices.contains(index);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isSelected ? AppColors.sageLight : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isSelected ? AppColors.sageMid : AppColors.borderColor),
      ),
      child: CheckboxListTile(
        value: isSelected,
        activeColor: AppColors.sageDark,
        onChanged: (v) => setState(() {
          if (v == true) _selectedIndices.add(index);
          else _selectedIndices.remove(index);
        }),
        title: Text(card['front'] ?? '', style: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.w600)),
        subtitle: Text(card['back'] ?? '', style: GoogleFonts.dmSans(fontSize: 12, color: AppColors.mutedText)),
        controlAffinity: ListTileControlAffinity.leading,
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.borderColor)),
      ),
      child: Row(children: [
        Text('${_selectedIndices.length} selected',
            style: GoogleFonts.dmSans(fontWeight: FontWeight.w600, color: AppColors.sageDark)),
        const SizedBox(width: 16),
        Expanded(child: AppButton(
          label: 'Add to Deck',
          onPressed: _selectedIndices.isNotEmpty ? _addToDeck : null,
          isLoading: _isAdding,
        )),
      ]),
    );
  }
}
