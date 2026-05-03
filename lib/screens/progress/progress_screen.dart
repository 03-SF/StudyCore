import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../config/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/deck_provider.dart';
import '../../models/study_session_model.dart';
import '../../widgets/common/empty_state.dart';

class ProgressScreen extends StatelessWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final uid = auth.currentUser?.uid;

    if (uid == null) {
      return const EmptyState(icon: Icons.bar_chart_outlined, title: 'Not signed in', subtitle: 'Please sign in to see your progress.');
    }

    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(title: const Text('Progress')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('studySessions')
            .where('userId', isEqualTo: uid)
            .orderBy('completedAt', descending: true)
            .limit(50)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppColors.sageDark));
          }
          if (snapshot.hasError) {
            return const EmptyState(icon: Icons.error_outline, title: 'Error', subtitle: 'Could not load progress data.');
          }
          final sessions = snapshot.data?.docs
              .map((d) => StudySessionModel.fromMap(d.data() as Map<String, dynamic>, id: d.id))
              .toList() ?? [];

          if (sessions.isEmpty) {
            return const EmptyState(icon: Icons.bar_chart_outlined, title: 'No sessions yet', subtitle: 'Complete a study session to see your progress here.');
          }

          return _ProgressContent(sessions: sessions);
        },
      ),
    );
  }
}

class _ProgressContent extends StatelessWidget {
  final List<StudySessionModel> sessions;

  const _ProgressContent({required this.sessions});

  int _getStreak() {
    if (sessions.isEmpty) return 0;
    final today = DateTime.now();
    final days = <String>{};
    for (final s in sessions) {
      days.add('${s.completedAt.year}-${s.completedAt.month}-${s.completedAt.day}');
    }
    int streak = 0;
    for (int i = 0; i < 30; i++) {
      final d = today.subtract(Duration(days: i));
      final key = '${d.year}-${d.month}-${d.day}';
      if (days.contains(key)) { streak++; } else { break; }
    }
    return streak;
  }

  List<int> _last7DaysCards() {
    final today = DateTime.now();
    return List.generate(7, (i) {
      final day = today.subtract(Duration(days: 6 - i));
      return sessions
          .where((s) => s.completedAt.year == day.year &&
              s.completedAt.month == day.month &&
              s.completedAt.day == day.day)
          .fold<int>(0, (sum, s) => sum + s.totalCards);
    });
  }

  @override
  Widget build(BuildContext context) {
    final deckProvider = context.watch<DeckProvider>();
    final streak = _getStreak();
    final last7 = _last7DaysCards();
    final totalCards = sessions.fold<int>(0, (s, e) => s + e.totalCards);
    final totalCorrect = sessions.fold<int>(0, (s, e) => s + e.correctCards);
    final accuracy = totalCards > 0 ? (totalCorrect / totalCards * 100).round() : 0;
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final today = DateTime.now().weekday - 1;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [AppColors.sageDark, AppColors.sageMid]),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              const Icon(Icons.local_fire_department, color: AppColors.amber, size: 24),
              const SizedBox(width: 8),
              Text('$streak day streak',
                  style: GoogleFonts.dmSans(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white)),
            ]),
            const SizedBox(height: 12),
            Row(children: List.generate(7, (i) {
              final isActive = i <= today && streak > today - i;
              return Expanded(child: Container(
                height: 8,
                margin: EdgeInsets.only(right: i < 6 ? 4 : 0),
                decoration: BoxDecoration(
                  color: isActive ? AppColors.amber : Colors.white.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(4),
                ),
              ));
            })),
          ]),
        ),
        const SizedBox(height: 16),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.5,
          children: [
            _StatCard(label: 'Sessions', value: '${sessions.length}', icon: Icons.play_circle_outline, color: AppColors.sageDark),
            _StatCard(label: 'Cards Studied', value: '$totalCards', icon: Icons.style_outlined, color: AppColors.sageMid),
            _StatCard(label: 'Accuracy', value: '$accuracy%', icon: Icons.check_circle_outline, color: AppColors.amber),
            _StatCard(label: 'Decks', value: '${deckProvider.decks.length}', icon: Icons.menu_book_outlined, color: AppColors.sageDark),
          ],
        ),
        const SizedBox(height: 20),
        Text('Last 7 Days', style: GoogleFonts.dmSans(fontSize: 16, fontWeight: FontWeight.w700)),
        const SizedBox(height: 12),
        Container(
          height: 160,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
          child: BarChart(BarChartData(
            alignment: BarChartAlignment.spaceAround,
            maxY: (last7.reduce((a, b) => a > b ? a : b) + 5).toDouble(),
            barGroups: List.generate(7, (i) => BarChartGroupData(x: i, barRods: [
              BarChartRodData(
                toY: last7[i].toDouble(),
                color: i == today ? AppColors.sageDark : AppColors.sageMid,
                width: 16,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
              ),
            ])),
            gridData: const FlGridData(show: false),
            borderData: FlBorderData(show: false),
            titlesData: FlTitlesData(
              bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, getTitlesWidget: (v, m) {
                final idx = v.toInt();
                return Text(days[idx % 7], style: GoogleFonts.dmSans(fontSize: 10, color: AppColors.mutedText));
              })),
              leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            ),
          )),
        ),
        const SizedBox(height: 20),
        Text('Deck Mastery', style: GoogleFonts.dmSans(fontSize: 16, fontWeight: FontWeight.w700)),
        const SizedBox(height: 12),
        ...deckProvider.decks.map((deck) => Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(child: Text(deck.name, style: GoogleFonts.dmSans(fontSize: 14, fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis)),
              Text('${(deck.masteryPercent * 100).round()}%',
                  style: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.sageDark)),
            ]),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: deck.masteryPercent,
                backgroundColor: AppColors.warmGray,
                valueColor: const AlwaysStoppedAnimation<Color>(AppColors.sageDark),
                minHeight: 6,
              ),
            ),
          ]),
        )),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({required this.label, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: AppColors.ink.withOpacity(0.06), blurRadius: 8)],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Icon(icon, color: color, size: 24),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(value, style: GoogleFonts.dmSans(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.ink)),
          Text(label, style: GoogleFonts.dmSans(fontSize: 12, color: AppColors.mutedText)),
        ]),
      ]),
    );
  }
}
