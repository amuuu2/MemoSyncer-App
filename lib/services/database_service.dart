import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/deck.dart';
import '../models/flashcard.dart';
import '../models/review_state.dart';
import '../services/sm2_service.dart';

class DatabaseService {
  static const String _decksBox = 'decks';
  static const String _cardsBox = 'cards';
  static const String _reviewBox = 'review_states';
  static const String _settingsBox = 'settings';
  static const String _reviewLogBox = 'review_log';

  late Box<Deck> _decks;
  late Box<Flashcard> _cards;
  late Box<ReviewState> _reviewStates;
  late Box<dynamic> _settings;
  late Box<String> _reviewLog;

  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  Future<void> init() async {
    await Hive.initFlutter();

    Hive.registerAdapter(DeckAdapter());
    Hive.registerAdapter(FlashcardAdapter());
    Hive.registerAdapter(ReviewStateAdapter());

    _decks = await Hive.openBox<Deck>(_decksBox);
    _cards = await Hive.openBox<Flashcard>(_cardsBox);
    _reviewStates = await Hive.openBox<ReviewState>(_reviewBox);
    _settings = await Hive.openBox<dynamic>(_settingsBox);
    _reviewLog = await Hive.openBox<String>(_reviewLogBox);
  }

  // ========== Deck 操作 ==========

  Future<void> createDeck(Deck deck) async {
    await _decks.put(deck.id, deck);
  }

  List<Deck> getDecks() {
    final decks = _decks.values.toList();
    decks.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return decks;
  }

  Future<void> deleteDeck(String deckId) async {
    // 删除关联的卡片
    final cardsToDelete =
        _cards.values.where((c) => c.deckId == deckId).toList();
    for (final card in cardsToDelete) {
      await _reviewStates.delete(card.id);
      await _cards.delete(card.id);
    }
    await _decks.delete(deckId);
  }

  // ========== Flashcard 操作 ==========

  Future<void> createCards(List<Flashcard> cards) async {
    for (final card in cards) {
      await _cards.put(card.id, card);
      // 初始化复习状态
      await _reviewStates.put(
        card.id,
        ReviewState(cardId: card.id),
      );
    }
  }

  List<Flashcard> getCardsByDeck(String deckId) {
    return _cards.values.where((c) => c.deckId == deckId).toList();
  }

  int getCardCountByDeck(String deckId) {
    return _cards.values.where((c) => c.deckId == deckId).length;
  }

  /// 获取所有待复习的卡片 (nextReview <= 今天)
  List<Flashcard> getCardsDueForReview({String? deckId}) {
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);

    final dueCardIds = _reviewStates.values
        .where((rs) => !rs.nextReview.isAfter(todayDate))
        .map((rs) => rs.cardId)
        .toSet();

    return _cards.values
        .where((c) {
          if (!dueCardIds.contains(c.id)) return false;
          if (deckId != null && c.deckId != deckId) return false;
          return true;
        })
        .toList();
  }

  int getDueReviewCountByDeck(String deckId) {
    return getCardsDueForReview(deckId: deckId).length;
  }

  // ========== ReviewState 操作 ==========

  ReviewState? getReviewState(String cardId) {
    return _reviewStates.get(cardId);
  }

  /// 更新复习状态并记录复习历史
  Future<void> updateReviewState(String cardId, int quality) async {
    final current = _reviewStates.get(cardId);
    if (current == null) return;

    final result = Sm2Service.calculateNextReview(
      quality: quality,
      easinessFactor: current.easinessFactor,
      repetitions: current.repetitions,
      interval: current.interval,
    );

    current.easinessFactor = result.easinessFactor;
    current.repetitions = result.repetitions;
    current.interval = result.interval;
    current.nextReview = result.nextReview;

    // 记录复习时间
    current.reviewHistory.add(DateTime.now());

    await current.save();

    // 记录到复习日志（用于热力图）
    final now = DateTime.now();
    final dateKey =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    await _reviewLog.add(dateKey);
  }

  // ========== 统计数据 ==========

  /// 获取今日已复习卡片数
  int getTodayReviewCount() {
    final now = DateTime.now();
    final todayKey =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    return _reviewLog.values.where((d) => d == todayKey).length;
  }

  /// 获取已掌握的卡片总数（repetitions >= 3）
  int getMasteredCardCount() {
    return _reviewStates.values
        .where((rs) => rs.repetitions >= 3)
        .length;
  }

  /// 获取连续打卡天数
  int getStreakDays() {
    if (_reviewLog.isEmpty) return 0;

    // 收集所有复习日期
    final reviewDates = <String>{};
    for (final dateStr in _reviewLog.values) {
      reviewDates.add(dateStr);
    }

    // 从今天开始往前数
    int streak = 0;
    var checkDate = DateTime.now();

    while (true) {
      final key =
          '${checkDate.year}-${checkDate.month.toString().padLeft(2, '0')}-${checkDate.day.toString().padLeft(2, '0')}';
      if (reviewDates.contains(key)) {
        streak++;
        checkDate = checkDate.subtract(const Duration(days: 1));
      } else {
        break;
      }
    }

    return streak;
  }

  /// 获取热力图数据: Map<日期字符串, 复习次数>
  Map<String, int> getReviewHeatmap({int days = 365}) {
    final now = DateTime.now();
    final startDate = now.subtract(Duration(days: days));
    final result = <String, int>{};

    for (final dateStr in _reviewLog.values) {
      final parts = dateStr.split('-');
      final date = DateTime(
        int.parse(parts[0]),
        int.parse(parts[1]),
        int.parse(parts[2]),
      );
      if (date.isAfter(startDate)) {
        result[dateStr] = (result[dateStr] ?? 0) + 1;
      }
    }

    return result;
  }

  // ========== 设置 ==========

  String? getApiKey() {
    return _settings.get('api_key') as String?;
  }

  Future<void> setApiKey(String key) async {
    await _settings.put('api_key', key);
  }

  String? getModelName() {
    return _settings.get('model_name') as String?;
  }

  Future<void> setModelName(String name) async {
    await _settings.put('model_name', name);
  }

  String? getBaseUrl() {
    return _settings.get('base_url') as String?;
  }

  Future<void> setBaseUrl(String url) async {
    await _settings.put('base_url', url);
  }

  // ========== 主题 ==========
  ThemeMode getThemeMode() {
    final val = _settings.get('theme_mode') as String?;
    return val == 'dark' ? ThemeMode.dark : ThemeMode.light;
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    await _settings.put('theme_mode', mode == ThemeMode.dark ? 'dark' : 'light');
  }

  // ========== 按月热力图 ==========
  /// 获取指定月份的复习数据: Map<日期字符串, 复习次数>
  Map<String, int> getMonthHeatmap(int year, int month) {
    final prefix =
        '$year-${month.toString().padLeft(2, '0')}';
    final result = <String, int>{};
    for (final dateStr in _reviewLog.values) {
      if (dateStr.startsWith(prefix)) {
        result[dateStr] = (result[dateStr] ?? 0) + 1;
      }
    }
    return result;
  }
}
