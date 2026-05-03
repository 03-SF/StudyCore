import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../config/app_colors.dart';
import '../../config/constants.dart';
import '../../providers/auth_provider.dart';
import '../../providers/deck_provider.dart';
import '../../providers/card_provider.dart';
import '../../services/ai_service.dart';
import '../../services/card_service.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/common/error_snackbar.dart';

class DeckFromContentScreen extends StatefulWidget {
  final String? type; // 'pdf', 'text', or 'manual'

  const DeckFromContentScreen({super.key, this.type});

  @override
  State<DeckFromContentScreen> createState() => _DeckFromContentScreenState();
}

class _DeckFromContentScreenState extends State<DeckFromContentScreen> {
  final _deckNameController = TextEditingController();
  final _contentController = TextEditingController();
  String _selectedSubject = 'Other';
  String _selectedColor = '#2D5A3D';
  String? _selectedPdfPath; // Changed from File to String for web compatibility
  bool _isProcessing = false;
  bool _isGeneratingCards = false;
  List<Map<String, String>> _generatedCards = [];
  Set<int> _selectedCardIndices = {};
  int _cardCount = 10;

  bool get _isManualMode => widget.type == 'manual';
  bool get _isPdfMode => widget.type == 'pdf';

  @override
  void initState() {
    super.initState();
    // On web, redirect PDF to text mode
    if (_isPdfMode && kIsWeb) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        showErrorSnackbar(
          context,
          'PDF upload is not available on web. Please paste content instead.',
        );
        context.pop();
      });
    }
  }

  @override
  void dispose() {
    _deckNameController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _pickPdf() async {
    if (kIsWeb) {
      showErrorSnackbar(context, 'PDF upload not available on web');
      return;
    }

    try {
      // Dynamic import only on non-web
      if (!kIsWeb) {
        // This code only runs on mobile/desktop
        // PDF picker would go here - for now, show message
        showErrorSnackbar(
          context,
          'PDF extraction on this platform - paste content instead',
        );
      }
    } catch (e) {
      if (mounted) showErrorSnackbar(context, 'Could not pick PDF file');
    }
  }

  Future<void> _generateCards() async {
    final content = _contentController.text.trim();
    if (content.isEmpty) {
      showErrorSnackbar(context, 'Please add content first');
      return;
    }

    setState(() => _isGeneratingCards = true);
    try {
      final aiService = AiService();
      final cards = await aiService.generateCardsFromText(content, _cardCount);
      setState(() {
        _generatedCards = cards;
        _selectedCardIndices = Set.from(List.generate(cards.length, (i) => i));
      });
      if (mounted && _generatedCards.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Generated ${_generatedCards.length} flashcards!',
              style: GoogleFonts.dmSans(color: Colors.white),
            ),
            backgroundColor: AppColors.sageDark,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        showErrorSnackbar(context, e.toString());
      }
    } finally {
      if (mounted) setState(() => _isGeneratingCards = false);
    }
  }

  Future<void> _createDeckAndCards() async {
    final deckName = _deckNameController.text.trim();
    if (deckName.isEmpty) {
      showErrorSnackbar(context, 'Please enter a deck name');
      return;
    }

    if (!_isManualMode && _generatedCards.isEmpty) {
      showErrorSnackbar(context, 'Please generate cards first');
      return;
    }

    setState(() => _isProcessing = true);
    try {
      final auth = context.read<AuthProvider>();
      final deckProvider = context.read<DeckProvider>();
      final cardService = CardService();

      // Create the deck
      final deck = await deckProvider.createDeck(
        userId: auth.currentUser!.uid,
        name: deckName,
        description: _contentController.text.length > 100
            ? _contentController.text.substring(0, 100)
            : _contentController.text,
        subject: _selectedSubject,
        accentColorHex: _selectedColor,
      );

      // If not manual mode, add the selected cards
      if (!_isManualMode && _selectedCardIndices.isNotEmpty && deck != null) {
        final selectedCards = _selectedCardIndices
            .map((i) => _generatedCards[i])
            .toList();
        await cardService.batchCreateCards(deck.id, selectedCards);
      }

      if (mounted && deck != null) {
        context.read<CardProvider>().startListening(deck.id);
        context.pop(); // Go back to home
        showSuccessSnackbar(context, 'Deck created successfully!');
      }
    } catch (e) {
      if (mounted) {
        showErrorSnackbar(context, 'Failed to create deck: ${e.toString()}');
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        title: Text(
          _isManualMode
              ? 'Create Deck'
              : _isPdfMode
              ? 'Create from PDF'
              : 'Create from Text',
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Deck Name Input
            TextField(
              controller: _deckNameController,
              decoration: InputDecoration(
                labelText: 'Deck Name *',
                hintText: 'e.g. Organic Chemistry Ch. 5',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              maxLength: AppConstants.maxDeckNameLength,
            ),
            const SizedBox(height: 16),

            // Subject Selection
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
                    child: FilterChip(
                      label: Text(s),
                      selected: _selectedSubject == s,
                      onSelected: (selected) {
                        setState(() => _selectedSubject = s);
                      },
                      selectedColor: AppColors.sageLight,
                      showCheckmark: false,
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 20),

            // Content Input Section (for non-manual modes)
            if (!_isManualMode && !(_isPdfMode && kIsWeb)) ...[
              if (_isPdfMode && _selectedPdfPath == null)
                GestureDetector(
                  onTap: _isProcessing ? null : _pickPdf,
                  child: Container(
                    height: 120,
                    decoration: BoxDecoration(
                      color: AppColors.warmGray,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.borderColor),
                    ),
                    child: _isProcessing
                        ? const Center(
                            child: CircularProgressIndicator(
                              color: AppColors.sageDark,
                            ),
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.picture_as_pdf_outlined,
                                size: 40,
                                color: AppColors.mutedText,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Tap to select PDF file',
                                style: GoogleFonts.dmSans(
                                  color: AppColors.mutedText,
                                ),
                              ),
                            ],
                          ),
                  ),
                )
              else
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Content to analyze:',
                      style: GoogleFonts.dmSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (_isPdfMode && _selectedPdfPath != null)
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.sageLight,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.description,
                              color: AppColors.sageDark,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _selectedPdfPath!.split('/').last,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.dmSans(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  _selectedPdfPath = null;
                                  _contentController.clear();
                                });
                              },
                              child: const Icon(Icons.close),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              const SizedBox(height: 12),
              TextField(
                controller: _contentController,
                maxLines: 6,
                maxLength: AppConstants.maxTextAreaLength,
                decoration: InputDecoration(
                  hintText: _isPdfMode
                      ? 'PDF content will appear here...'
                      : 'Paste your study material here...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Card Count
              Row(
                children: [
                  Text(
                    'Cards to generate:',
                    style: GoogleFonts.dmSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: _cardCount > 3
                        ? () => setState(() => _cardCount--)
                        : null,
                    icon: const Icon(Icons.remove_circle_outline),
                    color: AppColors.sageDark,
                  ),
                  Text(
                    '$_cardCount',
                    style: GoogleFonts.dmSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  IconButton(
                    onPressed: _cardCount < 50
                        ? () => setState(() => _cardCount++)
                        : null,
                    icon: const Icon(Icons.add_circle_outline),
                    color: AppColors.sageDark,
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Generate Button
              AppButton(
                label: _isGeneratingCards
                    ? 'Generating Cards...'
                    : 'Generate Cards with AI',
                onPressed: _isGeneratingCards ? null : _generateCards,
                isLoading: _isGeneratingCards,
                icon: Icons.auto_awesome,
              ),

              // Display generated cards
              if (_generatedCards.isNotEmpty) ...[
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Generated Cards',
                      style: GoogleFonts.dmSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      '${_selectedCardIndices.length}/${_generatedCards.length} selected',
                      style: GoogleFonts.dmSans(
                        fontSize: 12,
                        color: AppColors.mutedText,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ..._generatedCards.asMap().entries.map((entry) {
                  final index = entry.key;
                  final card = entry.value;
                  final isSelected = _selectedCardIndices.contains(index);
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.sageLight : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.sageMid
                            : AppColors.borderColor,
                      ),
                    ),
                    child: CheckboxListTile(
                      value: isSelected,
                      activeColor: AppColors.sageDark,
                      onChanged: (v) => setState(() {
                        if (v == true) {
                          _selectedCardIndices.add(index);
                        } else {
                          _selectedCardIndices.remove(index);
                        }
                      }),
                      title: Text(
                        card['front'] ?? '',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.dmSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      subtitle: Text(
                        card['back'] ?? '',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.dmSans(
                          fontSize: 12,
                          color: AppColors.mutedText,
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ],

            const SizedBox(height: 24),

            // Create Deck Button
            AppButton(
              label: _isProcessing
                  ? 'Creating Deck...'
                  : (_isManualMode ? 'Create Deck' : 'Create Deck with Cards'),
              onPressed:
                  _isProcessing || _deckNameController.text.trim().isEmpty
                  ? null
                  : _createDeckAndCards,
              isLoading: _isProcessing,
            ),
          ],
        ),
      ),
    );
  }
}

void showSuccessSnackbar(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message, style: GoogleFonts.dmSans(color: Colors.white)),
      backgroundColor: AppColors.sageDark,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(16),
    ),
  );
}
