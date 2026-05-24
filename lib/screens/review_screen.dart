import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/flashcard.dart';
import '../providers/providers.dart';

class ReviewScreen extends ConsumerStatefulWidget {
  final String deckId;
  final String deckTitle;

  const ReviewScreen({
    super.key,
    required this.deckId,
    required this.deckTitle,
  });

  @override
  ConsumerState<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends ConsumerState<ReviewScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _flipController;
  late Animation<double> _flipAnimation;

  List<Flashcard> _cards = [];
  int _currentIndex = 0;
  bool _isFlipped = false;
  bool _isEnglish = false;
  int _reviewedCount = 0;
  bool _isCompleted = false;

  @override
  void initState() {
    super.initState();
    _flipController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _flipAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _flipController, curve: Curves.easeInOut),
    );
    _loadCards();
  }

  @override
  void dispose() {
    _flipController.dispose();
    super.dispose();
  }

  void _loadCards() {
    final db = ref.read(databaseServiceProvider);
    _cards = db.getCardsDueForReview(deckId: widget.deckId);
    if (_cards.isEmpty) {
      _cards = db.getCardsByDeck(widget.deckId);
    }
    setState(() {});
  }

  void _flipCard() {
    if (_isFlipped) {
      _flipController.reverse();
    } else {
      _flipController.forward();
    }
    setState(() => _isFlipped = !_isFlipped);
  }

  Future<void> _rateCard(int quality) async {
    final card = _cards[_currentIndex];
    final db = ref.read(databaseServiceProvider);
    await db.updateReviewState(card.id, quality);

    _reviewedCount++;

    if (_currentIndex < _cards.length - 1) {
      setState(() {
        _currentIndex++;
        _isFlipped = false;
      });
      _flipController.reset();
    } else {
      setState(() => _isCompleted = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dark = isDark(ref);

    if (_cards.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.deckTitle)),
        body: const Center(
          child: Text('没有可复习的卡片',
              style: TextStyle(color: Colors.grey, fontSize: 16)),
        ),
      );
    }

    if (_isCompleted) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.deckTitle)),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.check_circle_outline,
                  color: Colors.green, size: 80),
              const SizedBox(height: 24),
              const Text(
                '复习完成！',
                style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Text(
                '本次复习 $_reviewedCount 张卡片',
                style: const TextStyle(color: Colors.grey, fontSize: 16),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                ),
                child: const Text('返回',
                    style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      );
    }

    final card = _cards[_currentIndex];
    final progress = (_currentIndex + 1) / _cards.length;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.deckTitle),
        actions: [
          IconButton(
            icon: Icon(
              _isEnglish ? Icons.translate : Icons.language,
              color: _isEnglish ? Colors.blue : Colors.grey,
            ),
            onPressed: () => setState(() => _isEnglish = !_isEnglish),
            tooltip: _isEnglish ? '切换中文' : '切换英文',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            LinearProgressIndicator(
              value: progress,
              backgroundColor: dark ? Colors.grey.shade900 : Colors.grey.shade200,
              valueColor: const AlwaysStoppedAnimation(Colors.blue),
            ),
            const SizedBox(height: 8),
            Text(
              '${_currentIndex + 1} / ${_cards.length}',
              style: const TextStyle(color: Colors.grey, fontSize: 13),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: GestureDetector(
                onTap: _flipCard,
                child: AnimatedBuilder(
                  animation: _flipAnimation,
                  builder: (context, child) {
                    final angle = _flipAnimation.value * pi;
                    final isFront = angle < pi / 2;

                    return Transform(
                      alignment: Alignment.center,
                      transform: Matrix4.identity()
                        ..setEntry(3, 2, 0.001)
                        ..rotateY(angle),
                      child: isFront
                          ? _buildCardSide(question: true, card: card, dark: dark)
                          : Transform(
                              alignment: Alignment.center,
                              transform: Matrix4.identity()..rotateY(pi),
                              child: _buildCardSide(
                                  question: false, card: card, dark: dark),
                            ),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 24),
            if (_isFlipped)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildRateButton(
                      label: '遗忘',
                      score: 1,
                      color: Colors.red.shade700,
                      icon: Icons.close),
                  _buildRateButton(
                      label: '勉强',
                      score: 3,
                      color: Colors.orange.shade700,
                      icon: Icons.help_outline),
                  _buildRateButton(
                      label: '记住',
                      score: 5,
                      color: Colors.green.shade700,
                      icon: Icons.check),
                ],
              )
            else
              const Text(
                '点击卡片翻转查看答案',
                style: TextStyle(color: Colors.grey, fontSize: 14),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardSide({
    required bool question,
    required Flashcard card,
    required bool dark,
  }) {
    final text = question
        ? (_isEnglish ? card.questionEn : card.questionZh)
        : (_isEnglish ? card.answerEn : card.answerZh);
    final label = question ? '问题' : '答案';

    Color bgColor;
    Color borderColor;
    Color labelBgColor;
    Color labelColor;

    if (dark) {
      bgColor = question ? const Color(0xFF1A1A2E) : const Color(0xFF1A2E1A);
      borderColor =
          question ? Colors.blue.shade800 : Colors.green.shade800;
      labelBgColor = (question ? Colors.blue : Colors.green).withOpacity(0.2);
      labelColor =
          question ? Colors.blue.shade300 : Colors.green.shade300;
    } else {
      bgColor = question ? Colors.blue.shade50 : Colors.green.shade50;
      borderColor =
          question ? Colors.blue.shade200 : Colors.green.shade200;
      labelBgColor = (question ? Colors.blue : Colors.green).withOpacity(0.1);
      labelColor =
          question ? Colors.blue.shade700 : Colors.green.shade700;
    }

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: 1.5),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: labelBgColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              label,
              style: TextStyle(color: labelColor, fontSize: 12),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            text,
            style: TextStyle(
              color: dark ? Colors.white : Colors.black87,
              fontSize: 18,
              height: 1.6,
            ),
            textAlign: TextAlign.center,
          ),
          if (card.knowledgeTag.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              card.knowledgeTag,
              style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRateButton({
    required String label,
    required int score,
    required Color color,
    required IconData icon,
  }) {
    return ElevatedButton.icon(
      onPressed: () => _rateCard(score),
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}
