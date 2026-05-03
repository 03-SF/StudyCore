import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../config/app_colors.dart';
import '../../models/card_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/session_provider.dart';
import '../../services/card_service.dart';
import '../../services/deck_service.dart';
import '../../widgets/common/empty_state.dart';

class QuizScreen extends StatefulWidget {
  final String deckId;

  const QuizScreen({super.key, required this.deckId});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> with SingleTickerProviderStateMixin {
  final _cardService = CardService();
  final _deckService = DeckService();
  bool _loading = true;
  List<CardModel> _allCards = [];
  String _deckName = '';
  int _currentQ = 0;
  List<String> _options = [];
  int? _selectedIndex;
  bool _confirmed = false;
  int _correctIndex = 0;
  Timer? _timer;
  int _timeLeft = 30;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _loadCards();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _loadCards() async {
    try {
      final cards = await _cardService.getCards(widget.deckId);
      final deck = await _deckService.getDeck(widget.deckId);
      if (!mounted) return;
      _allCards = cards..shuffle();
      _deckName = deck?.name ?? '';
      context.read<SessionProvider>().startSession(_allCards);
      _buildQuestion();
    } catch (_) {} finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _buildQuestion() {
    if (_allCards.isEmpty || _currentQ >= _allCards.length) return;
    final correct = _allCards[_currentQ];
    final others = List<CardModel>.from(_allCards)..remove(correct);
    others.shuffle();
    final distractors = others.take(3).toList();
    final all = [correct, ...distractors]..shuffle();
    _options = all.map((c) => c.back).toList();
    _correctIndex = all.indexOf(correct);
    _selectedIndex = null;
    _confirmed = false;
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    _timeLeft = 30;
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) { t.cancel(); return; }
      setState(() => _timeLeft--);
      if (_timeLeft <= 0) {
        t.cancel();
        _confirm(-1);
      }
    });
  }

  void _select(int index) {
    if (_confirmed) return;
    setState(() => _selectedIndex = index);
  }

  void _confirm(int selected) {
    _timer?.cancel();
    final isCorrect = selected == _correctIndex;
    if (isCorrect) {
      _pulseController.forward().then((_) => _pulseController.reverse());
    }
    setState(() { _selectedIndex = selected; _confirmed = true; });
    context.read<SessionProvider>().rateCard(isCorrect ? 4 : 1);

    Future.delayed(const Duration(seconds: 1), () {
      if (!mounted) return;
      if (_currentQ + 1 >= _allCards.length) {
        _finishQuiz();
      } else {
        setState(() { _currentQ++; _buildQuestion(); });
      }
    });
  }

  Future<void> _finishQuiz() async {
    final auth = context.read<AuthProvider>();
    await context.read<SessionProvider>().finalizeSession(
      userId: auth.currentUser!.uid,
      deckId: widget.deckId,
      deckName: _deckName,
      sessionType: 'quiz',
    );
    if (mounted) context.go('/home/study/${widget.deckId}/results');
  }

  Color _optionColor(int index) {
    if (!_confirmed) return _selectedIndex == index ? AppColors.sageLight : Colors.white;
    if (index == _correctIndex) return AppColors.sageLight;
    if (index == _selectedIndex && index != _correctIndex) return AppColors.dangerBg;
    return Colors.white;
  }

  Color _optionBorderColor(int index) {
    if (!_confirmed) return _selectedIndex == index ? AppColors.sageMid : AppColors.borderColor;
    if (index == _correctIndex) return AppColors.sageMid;
    if (index == _selectedIndex && index != _correctIndex) return AppColors.danger;
    return AppColors.borderColor;
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator(color: AppColors.sageDark)));
    }

    if (_allCards.length < 4) {
      return Scaffold(
        appBar: AppBar(title: const Text('Quiz')),
        body: const EmptyState(icon: Icons.quiz_outlined, title: 'Not enough cards', subtitle: 'You need at least 4 cards to start a quiz.'),
      );
    }

    final card = _currentQ < _allCards.length ? _allCards[_currentQ] : null;
    if (card == null) return const SizedBox();

    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.close), onPressed: () => context.pop()),
        title: Text('Question ${_currentQ + 1} of ${_allCards.length}'),
        actions: [
          Container(
            width: 36, height: 36,
            margin: const EdgeInsets.only(right: 12),
            child: Stack(alignment: Alignment.center, children: [
              CircularProgressIndicator(
                value: _timeLeft / 30,
                color: _timeLeft > 10 ? AppColors.amber : AppColors.danger,
                backgroundColor: AppColors.borderColor,
                strokeWidth: 3,
              ),
              Text('$_timeLeft', style: GoogleFonts.dmSans(fontSize: 11, fontWeight: FontWeight.w700)),
            ]),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            ScaleTransition(
              scale: _pulseAnimation,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [BoxShadow(color: AppColors.ink.withOpacity(0.06), blurRadius: 12, offset: const Offset(0, 2))],
                ),
                child: Text(
                  card.front,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.dmSans(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.ink),
                ),
              ),
            ),
            const SizedBox(height: 24),
            ...List.generate(_options.length, (i) {
              final label = String.fromCharCode(65 + i);
              return GestureDetector(
                onTap: () {
                  if (!_confirmed) {
                    _select(i);
                    _confirm(i);
                  }
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _optionColor(i),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: _optionBorderColor(i), width: 1.5),
                  ),
                  child: Row(children: [
                    Expanded(child: Text(_options[i], style: GoogleFonts.dmSans(fontSize: 15, color: AppColors.ink))),
                    Container(
                      width: 28, height: 28,
                      decoration: BoxDecoration(
                        color: _confirmed && i == _correctIndex ? AppColors.sageDark
                            : _confirmed && i == _selectedIndex ? AppColors.danger
                            : AppColors.warmGray,
                        shape: BoxShape.circle,
                      ),
                      child: Center(child: Text(label,
                          style: GoogleFonts.dmSans(
                            fontSize: 13, fontWeight: FontWeight.w700,
                            color: _confirmed && (i == _correctIndex || i == _selectedIndex) ? Colors.white : AppColors.ink,
                          ))),
                    ),
                  ]),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
