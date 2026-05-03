import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../config/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/deck_provider.dart';
import '../../widgets/common/empty_state.dart';
import '../../widgets/deck/deck_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthProvider>();
      if (auth.currentUser != null) {
        context.read<DeckProvider>().startListening(auth.currentUser!.uid);
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showDeckOptions(BuildContext context, String deckId, String deckName) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 8),
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.borderColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          ListTile(
            leading: const Icon(Icons.edit_outlined, color: AppColors.sageDark),
            title: const Text('Edit Deck'),
            onTap: () {
              Navigator.pop(ctx);
              context.push('/home/deck/$deckId/edit');
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete_outline, color: AppColors.danger),
            title: Text('Delete Deck',
                style: GoogleFonts.dmSans(color: AppColors.danger)),
            onTap: () async {
              Navigator.pop(ctx);
              final confirm = await showDialog<bool>(
                context: context,
                builder: (d) => AlertDialog(
                  title: const Text('Delete Deck?'),
                  content: Text(
                      'This will permanently delete "$deckName" and all its cards.'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(d, false),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(d, true),
                      child: const Text('Delete',
                          style: TextStyle(color: AppColors.danger)),
                    ),
                  ],
                ),
              );
              if (confirm == true && mounted) {
                await context.read<DeckProvider>().deleteDeck(deckId);
              }
            },
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final deckProvider = context.watch<DeckProvider>();
    final user = auth.currentUser;
    final filteredDecks = deckProvider.search(_searchQuery);

    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _greeting(),
                          style: GoogleFonts.dmSans(
                            fontSize: 14,
                            color: AppColors.mutedText,
                          ),
                        ),
                        Text(
                          user?.displayName.split(' ').first ?? 'Student',
                          style: GoogleFonts.dmSans(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: AppColors.ink,
                          ),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () => context.push('/profile'),
                    child: CircleAvatar(
                      radius: 22,
                      backgroundColor: AppColors.sageLight,
                      backgroundImage: user?.photoUrl != null
                          ? CachedNetworkImageProvider(user!.photoUrl!)
                          : null,
                      child: user?.photoUrl == null
                          ? Text(
                              user?.displayName.isNotEmpty == true
                                  ? user!.displayName[0].toUpperCase()
                                  : 'S',
                              style: GoogleFonts.dmSans(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: AppColors.sageDark,
                              ),
                            )
                          : null,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  _StatChip(
                    label: 'Due',
                    value: '${deckProvider.totalDueCards}',
                    color: AppColors.amber,
                    bgColor: AppColors.amberBg,
                  ),
                  const SizedBox(width: 10),
                  _StatChip(
                    label: 'Decks',
                    value: '${deckProvider.decks.length}',
                    color: AppColors.sageDark,
                    bgColor: AppColors.sageLight,
                  ),
                  if ((user?.currentStreak ?? 0) > 0) ...[
                    const SizedBox(width: 10),
                    _StatChip(
                      label: 'streak',
                      value: '🔥 ${user!.currentStreak}',
                      color: const Color(0xFFE07B2A),
                      bgColor: const Color(0xFFFFF0E0),
                    ),
                  ],
                ],
              ),
            ),
            if (deckProvider.totalDueCards > 0) ...[
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: Container(
                    key: ValueKey(deckProvider.totalDueCards),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.amberBg,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.amber.withOpacity(0.4)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.timer_outlined,
                            color: AppColors.amber, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            '${deckProvider.totalDueCards} cards due for review today',
                            style: GoogleFonts.dmSans(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.amber,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: TextField(
                controller: _searchController,
                onChanged: (v) => setState(() => _searchQuery = v),
                decoration: InputDecoration(
                  hintText: 'Search decks...',
                  prefixIcon:
                      const Icon(Icons.search, color: AppColors.mutedText),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                        )
                      : null,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: deckProvider.isLoading
                  ? const Center(
                      child:
                          CircularProgressIndicator(color: AppColors.sageDark))
                  : filteredDecks.isEmpty
                      ? EmptyState(
                          icon: Icons.menu_book_outlined,
                          title: _searchQuery.isNotEmpty
                              ? 'No decks found'
                              : 'No decks yet',
                          subtitle: _searchQuery.isNotEmpty
                              ? 'Try a different search term.'
                              : 'Tap + to create your first flashcard deck.',
                          actionLabel: _searchQuery.isEmpty ? 'Create Deck' : null,
                          onAction: _searchQuery.isEmpty
                              ? () => context.push('/home/deck/create')
                              : null,
                        )
                      : GridView.builder(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 4),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: 0.95,
                          ),
                          itemCount: filteredDecks.length,
                          itemBuilder: (context, index) {
                            final deck = filteredDecks[index];
                            return DeckCard(
                              deck: deck,
                              onTap: () =>
                                  context.push('/home/deck/${deck.id}'),
                              onLongPress: () =>
                                  _showDeckOptions(context, deck.id, deck.name),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/home/deck/create'),
        child: const Icon(Icons.add),
      ),
    );
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning,';
    if (hour < 17) return 'Good afternoon,';
    return 'Good evening,';
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final Color bgColor;

  const _StatChip({
    required this.label,
    required this.value,
    required this.color,
    required this.bgColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Text(
            value,
            style: GoogleFonts.dmSans(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.dmSans(
              fontSize: 13,
              color: color.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }
}
