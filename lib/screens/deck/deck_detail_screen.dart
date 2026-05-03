import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../config/app_colors.dart';
import '../../providers/card_provider.dart';
import '../../providers/deck_provider.dart';
import '../../services/deck_service.dart';
import '../../models/deck_model.dart';
import '../../widgets/common/empty_state.dart';
import '../../widgets/common/error_snackbar.dart';
import '../../widgets/deck/card_list_item.dart';

class DeckDetailScreen extends StatefulWidget {
  final String deckId;

  const DeckDetailScreen({super.key, required this.deckId});

  @override
  State<DeckDetailScreen> createState() => _DeckDetailScreenState();
}

class _DeckDetailScreenState extends State<DeckDetailScreen> {
  DeckModel? _deck;
  bool _loadingDeck = true;
  final _deckService = DeckService();

  @override
  void initState() {
    super.initState();
    _loadDeck();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CardProvider>().startListening(widget.deckId);
    });
  }

  Future<void> _loadDeck() async {
    try {
      final deck = await _deckService.getDeck(widget.deckId);
      if (mounted) setState(() { _deck = deck; _loadingDeck = false; });
    } catch (_) {
      if (mounted) setState(() => _loadingDeck = false);
    }
  }

  Color _parseColor(String hex) {
    try {
      return Color(int.parse('FF${hex.replaceAll('#', '')}', radix: 16));
    } catch (_) { return AppColors.sageDark; }
  }

  @override
  Widget build(BuildContext context) {
    final cardProvider = context.watch<CardProvider>();
    final deckProvider = context.watch<DeckProvider>();

    if (_loadingDeck) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: AppColors.sageDark)),
      );
    }

    if (_deck == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const EmptyState(
          icon: Icons.error_outline,
          title: 'Deck not found',
          subtitle: 'This deck may have been deleted.',
        ),
      );
    }

    final deck = _deck!;
    final accentColor = _parseColor(deck.accentColorHex);

    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        title: Text(deck.name),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) async {
              if (value == 'edit') {
                context.push('/home/deck/${deck.id}/edit');
              } else if (value == 'delete') {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (d) => AlertDialog(
                    title: const Text('Delete Deck?'),
                    content: const Text('All cards will be permanently deleted.'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(d, false), child: const Text('Cancel')),
                      TextButton(onPressed: () => Navigator.pop(d, true), child: const Text('Delete', style: TextStyle(color: AppColors.danger))),
                    ],
                  ),
                );
                if (confirm == true && mounted) {
                  await deckProvider.deleteDeck(deck.id);
                  if (mounted) context.pop();
                }
              }
            },
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'edit', child: Text('Edit')),
              const PopupMenuItem(value: 'delete', child: Text('Delete', style: TextStyle(color: AppColors.danger))),
            ],
          ),
        ],
      ),
      body: cardProvider.isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.sageDark))
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
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
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.sageLight,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(deck.subject, style: GoogleFonts.dmSans(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.sageDark)),
                      ),
                      const SizedBox(height: 8),
                      Text(deck.name, style: GoogleFonts.dmSans(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.ink)),
                      if (deck.description.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(deck.description, style: GoogleFonts.dmSans(fontSize: 14, color: AppColors.mutedText)),
                      ],
                      const SizedBox(height: 12),
                      Row(children: [
                        Text('${(deck.masteryPercent * 100).round()}% mastered',
                            style: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.w600, color: accentColor)),
                        const Spacer(),
                        Text('${deck.cardCount} cards', style: GoogleFonts.dmSans(fontSize: 13, color: AppColors.mutedText)),
                      ]),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: deck.masteryPercent,
                          backgroundColor: AppColors.warmGray,
                          valueColor: AlwaysStoppedAnimation<Color>(accentColor),
                          minHeight: 6,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Row(children: [
                  Expanded(child: OutlinedButton.icon(
                    onPressed: cardProvider.cards.isEmpty ? null : () => context.push('/home/study/${deck.id}/flashcard'),
                    icon: const Icon(Icons.style_outlined, size: 18),
                    label: const Text('Flashcards'),
                  )),
                  const SizedBox(width: 10),
                  Expanded(child: OutlinedButton.icon(
                    onPressed: cardProvider.cards.length < 4 ? null : () => context.push('/home/study/${deck.id}/quiz'),
                    icon: const Icon(Icons.quiz_outlined, size: 18),
                    label: const Text('Quiz'),
                  )),
                  const SizedBox(width: 10),
                  Expanded(child: OutlinedButton.icon(
                    onPressed: () => context.push('/home/deck/${deck.id}/generate'),
                    icon: const Icon(Icons.auto_awesome, size: 18),
                    label: const Text('AI'),
                  )),
                ]),
                const SizedBox(height: 16),
                GestureDetector(
                  onTap: () => context.push('/home/deck/${deck.id}/card/new'),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.sageMid, width: 1.5, style: BorderStyle.solid),
                    ),
                    child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      const Icon(Icons.add, color: AppColors.sageMid, size: 20),
                      const SizedBox(width: 6),
                      Text('Add a card', style: GoogleFonts.dmSans(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.sageMid)),
                    ]),
                  ),
                ),
                const SizedBox(height: 12),
                if (cardProvider.errorMessage != null)
                  EmptyState(
                    icon: Icons.error_outline,
                    title: 'Error loading cards',
                    subtitle: cardProvider.errorMessage!,
                    actionLabel: 'Retry',
                    onAction: () => context.read<CardProvider>().startListening(widget.deckId),
                  )
                else if (cardProvider.cards.isEmpty)
                  EmptyState(
                    icon: Icons.style_outlined,
                    title: 'No cards yet',
                    subtitle: 'Add cards manually or use AI to generate them.',
                  )
                else
                  ...cardProvider.cards.map((card) => CardListItem(
                    card: card,
                    onTap: () => context.push('/home/deck/${deck.id}/card/${card.id}', extra: card),
                    onDelete: () async {
                      final ok = await context.read<CardProvider>().deleteCard(deck.id, card.id);
                      if (!ok && mounted) showErrorSnackbar(context, 'Could not delete card.');
                    },
                  )),
              ],
            ),
    );
  }
}
