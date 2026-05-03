import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../config/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/session_provider.dart';
import '../../services/card_service.dart';
import '../../services/deck_service.dart';
import '../../widgets/common/empty_state.dart';
import '../../widgets/study/flashcard_widget.dart';
import '../../widgets/study/rating_buttons.dart';

class FlashcardStudyScreen extends StatefulWidget {
  final String deckId;

  const FlashcardStudyScreen({super.key, required this.deckId});

  @override
  State<FlashcardStudyScreen> createState() => _FlashcardStudyScreenState();
}

class _FlashcardStudyScreenState extends State<FlashcardStudyScreen> {
  final _cardService = CardService();
  final _deckService = DeckService();
  bool _loading = true;
  bool _showRating = false;
  String _deckName = '';

  @override
  void initState() {
    super.initState();
    _loadCards();
  }

  Future<void> _loadCards() async {
    try {
      final cards = await _cardService.getCards(widget.deckId);
      final deck = await _deckService.getDeck(widget.deckId);
      if (!mounted) return;
      _deckName = deck?.name ?? '';
      context.read<SessionProvider>().startSession(cards);
    } catch (_) {} finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _rate(int rating) async {
    final session = context.read<SessionProvider>();
    session.rateCard(rating);
    setState(() => _showRating = false);

    if (session.isComplete) {
      final auth = context.read<AuthProvider>();
      await session.finalizeSession(
        userId: auth.currentUser!.uid,
        deckId: widget.deckId,
        deckName: _deckName,
        sessionType: 'flashcard',
      );
      if (mounted) context.go('/home/study/${widget.deckId}/results');
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionProvider>();

    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator(color: AppColors.sageDark)));
    }

    if (session.cards.isEmpty) {
      return Scaffold(
        body: SafeArea(child: Column(children: [
          Align(alignment: Alignment.topLeft, child: IconButton(icon: const Icon(Icons.close), onPressed: () => context.pop())),
          const Expanded(child: EmptyState(icon: Icons.style_outlined, title: 'No cards to study', subtitle: 'Add some cards to this deck first.')),
        ])),
      );
    }

    final card = session.currentCard;
    if (card == null) return const SizedBox();

    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(children: [
                IconButton(icon: const Icon(Icons.close), onPressed: () => context.pop()),
                Expanded(child: Column(children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: session.progress,
                      backgroundColor: AppColors.warmGray,
                      valueColor: const AlwaysStoppedAnimation<Color>(AppColors.sageDark),
                      minHeight: 4,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${session.currentIndex + 1} / ${session.cards.length}',
                    style: GoogleFonts.dmSans(fontSize: 12, color: AppColors.mutedText),
                  ),
                ])),
                PopupMenuButton<String>(
                  onSelected: (_) {},
                  itemBuilder: (_) => [
                    const PopupMenuItem(value: 'mark', child: Text('Mark for review')),
                  ],
                ),
              ]),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: FlashcardWidget(
                  front: card.front,
                  back: card.back,
                  onFlip: () => setState(() => _showRating = true),
                ),
              ),
            ),
            AnimatedOpacity(
              duration: const Duration(milliseconds: 300),
              opacity: _showRating ? 1.0 : 0.0,
              child: AnimatedSlide(
                duration: const Duration(milliseconds: 300),
                offset: _showRating ? Offset.zero : const Offset(0, 0.5),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: RatingButtons(onRate: _rate),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
