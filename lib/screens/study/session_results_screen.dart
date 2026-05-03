import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../config/app_colors.dart';
import '../../providers/session_provider.dart';
import '../../widgets/common/app_button.dart';

class SessionResultsScreen extends StatefulWidget {
  final String deckId;

  const SessionResultsScreen({super.key, required this.deckId});

  @override
  State<SessionResultsScreen> createState() => _SessionResultsScreenState();
}

class _SessionResultsScreenState extends State<SessionResultsScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scoreAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    final session = context.read<SessionProvider>();
    final score = session.lastSession?.scorePercent ?? 0.0;
    _scoreAnimation = Tween<double>(begin: 0.0, end: score).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color _scoreColor(double score) {
    if (score >= 0.8) return AppColors.sageDark;
    if (score >= 0.5) return AppColors.amber;
    return AppColors.danger;
  }

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionProvider>();
    final lastSession = session.lastSession;
    final score = lastSession?.scorePercent ?? 0.0;
    final wrongCards = session.getWrongCards();

    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        title: const Text('Session Complete'),
        automaticallyImplyLeading: false,
        actions: [
          TextButton(
            onPressed: () => context.go('/home'),
            child: const Text('Done'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            AnimatedBuilder(
              animation: _scoreAnimation,
              builder: (ctx, _) {
                final val = _scoreAnimation.value;
                final color = _scoreColor(val);
                return Container(
                  width: 140, height: 140,
                  decoration: BoxDecoration(shape: BoxShape.circle,
                      border: Border.all(color: AppColors.borderColor, width: 2)),
                  child: Stack(alignment: Alignment.center, children: [
                    CircularProgressIndicator(
                      value: val,
                      strokeWidth: 8,
                      backgroundColor: AppColors.warmGray,
                      valueColor: AlwaysStoppedAnimation<Color>(color),
                    ),
                    Text(
                      '${(val * 100).round()}%',
                      style: GoogleFonts.dmSans(fontSize: 28, fontWeight: FontWeight.w700, color: color),
                    ),
                  ]),
                );
              },
            ),
            const SizedBox(height: 20),
            Text(
              score >= 0.8 ? 'Excellent work! 🎉' : score >= 0.5 ? 'Good progress! 💪' : 'Keep practicing! 📚',
              style: GoogleFonts.dmSans(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.ink),
            ),
            const SizedBox(height: 20),
            Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
              _StatBox(label: 'Correct', value: '${lastSession?.correctCards ?? 0}', color: AppColors.sageDark),
              _StatBox(label: 'Wrong', value: '${lastSession?.wrongCards ?? 0}', color: AppColors.danger),
              _StatBox(
                label: 'Time',
                value: _formatTime(lastSession?.durationSeconds ?? 0),
                color: AppColors.amber,
              ),
            ]),
            if (wrongCards.isNotEmpty) ...[
              const SizedBox(height: 24),
              Align(alignment: Alignment.centerLeft,
                child: Text('Review These', style: GoogleFonts.dmSans(fontSize: 15, fontWeight: FontWeight.w700))),
              const SizedBox(height: 8),
              SizedBox(
                height: 40,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: wrongCards.length,
                  itemBuilder: (ctx, i) => Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.dangerBg,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.danger.withOpacity(0.3)),
                    ),
                    child: Text(
                      wrongCards[i].front,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.dmSans(fontSize: 12, color: AppColors.danger, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () {
                  session.startSession(wrongCards);
                  context.go('/home/study/${widget.deckId}/flashcard');
                },
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.danger),
                  foregroundColor: AppColors.danger,
                ),
                child: const Text('Study these again'),
              ),
            ],
            const SizedBox(height: 24),
            AppButton(
              label: 'Back to Deck',
              onPressed: () => context.go('/home/deck/${widget.deckId}'),
            ),
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: () {
                final text = 'I just scored ${(score * 100).round()}% on StudyCore! 📚';
                Share.share(text);
              },
              icon: const Icon(Icons.share_outlined),
              label: const Text('Share'),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m}m ${s}s';
  }
}

class _StatBox extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatBox({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(children: [
        Text(value, style: GoogleFonts.dmSans(fontSize: 22, fontWeight: FontWeight.w700, color: color)),
        Text(label, style: GoogleFonts.dmSans(fontSize: 12, color: color.withOpacity(0.8))),
      ]),
    );
  }
}
