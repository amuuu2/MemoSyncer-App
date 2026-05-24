import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/database_service.dart';
import '../services/ai_service.dart';
import '../models/deck.dart';
import '../models/flashcard.dart';

// ========== 主题切换 ==========
final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, ThemeMode>((ref) {
  return ThemeModeNotifier(ref.watch(databaseServiceProvider));
});

class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  final DatabaseService _db;

  ThemeModeNotifier(this._db) : super(_db.getThemeMode());

  void toggle() {
    state = state == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    _db.setThemeMode(state);
  }
}

bool isDark(WidgetRef ref) {
  return ref.watch(themeModeProvider) == ThemeMode.dark;
}

final databaseServiceProvider = Provider<DatabaseService>((ref) {
  return DatabaseService();
});

final aiServiceProvider = Provider<AiService?>((ref) {
  final db = ref.watch(databaseServiceProvider);
  final apiKey = db.getApiKey();
  if (apiKey == null || apiKey.isEmpty) return null;
  return AiService(
    apiKey: apiKey,
    baseUrl: db.getBaseUrl() ?? 'https://dashscope.aliyuncs.com/compatible-mode/v1',
    model: db.getModelName() ?? 'qwen3-max-preview',
  );
});

final decksProvider = StateNotifierProvider<DecksNotifier, List<Deck>>((ref) {
  return DecksNotifier(ref.watch(databaseServiceProvider));
});

class DecksNotifier extends StateNotifier<List<Deck>> {
  final DatabaseService _db;

  DecksNotifier(this._db) : super([]) {
    _load();
  }

  void _load() {
    state = _db.getDecks();
  }

  void refresh() {
    _load();
  }

  Future<void> deleteDeck(String deckId) async {
    await _db.deleteDeck(deckId);
    _load();
  }
}

final cardsByDeckProvider =
    Provider.family<List<Flashcard>, String>((ref, deckId) {
  final db = ref.watch(databaseServiceProvider);
  return db.getCardsByDeck(deckId);
});

final dueReviewCountProvider =
    Provider.family<int, String>((ref, deckId) {
  final db = ref.watch(databaseServiceProvider);
  return db.getDueReviewCountByDeck(deckId);
});

final statsProvider = Provider<Stats>((ref) {
  final db = ref.watch(databaseServiceProvider);
  return Stats(
    todayReviewed: db.getTodayReviewCount(),
    masteredCount: db.getMasteredCardCount(),
    streakDays: db.getStreakDays(),
    heatmapData: db.getReviewHeatmap(),
  );
});

class Stats {
  final int todayReviewed;
  final int masteredCount;
  final int streakDays;
  final Map<String, int> heatmapData;

  Stats({
    required this.todayReviewed,
    required this.masteredCount,
    required this.streakDays,
    required this.heatmapData,
  });
}
