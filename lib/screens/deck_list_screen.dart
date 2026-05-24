import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/providers.dart';
import 'review_screen.dart';

class DeckListScreen extends ConsumerWidget {
  const DeckListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final decks = ref.watch(decksProvider);
    final dark = isDark(ref);

    return Scaffold(
      appBar: AppBar(
        title: const Text('卡片集'),
      ),
      body: decks.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.style_outlined,
                      size: 64,
                      color: dark ? Colors.grey.shade700 : Colors.grey.shade300),
                  const SizedBox(height: 16),
                  Text(
                    '还没有卡片集',
                    style: TextStyle(
                        color: dark ? Colors.grey.shade500 : Colors.grey,
                        fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '去"输入"页面粘贴文本生成吧',
                    style: TextStyle(
                        color: dark ? Colors.grey.shade700 : Colors.grey.shade400,
                        fontSize: 13),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: decks.length,
              itemBuilder: (context, index) {
                final deck = decks[index];
                final db = ref.read(databaseServiceProvider);
                final cardCount = db.getCardCountByDeck(deck.id);
                final dueCount = db.getDueReviewCountByDeck(deck.id);

                return Card(
                  color: dark ? const Color(0xFF1A1A1A) : Colors.white,
                  margin: const EdgeInsets.only(bottom: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: dark ? Colors.grey.shade800 : Colors.grey.shade200,
                    ),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    title: Text(
                      deck.title,
                      style: TextStyle(
                        color: dark ? Colors.white : Colors.black87,
                        fontSize: 16,
                      ),
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.blue.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '$cardCount 张卡片',
                              style: const TextStyle(
                                color: Colors.blue,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (dueCount > 0)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.orange.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '$dueCount 待复习',
                                style: const TextStyle(
                                  color: Colors.orange,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ReviewScreen(
                            deckId: deck.id,
                            deckTitle: deck.title,
                          ),
                        ),
                      ).then((_) => ref.read(decksProvider.notifier).refresh());
                    },
                    onLongPress: () =>
                        _confirmDelete(context, ref, deck.id, deck.title, dark),
                  ),
                );
              },
            ),
    );
  }

  void _confirmDelete(
      BuildContext context, WidgetRef ref, String deckId, String title, bool dark) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: dark ? const Color(0xFF1E1E1E) : Colors.white,
        title: Text('删除卡片集',
            style: TextStyle(color: dark ? Colors.white : Colors.black87)),
        content: Text(
          '确定要删除"$title"吗？\n此操作不可恢复。',
          style: const TextStyle(color: Colors.grey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              ref.read(decksProvider.notifier).deleteDeck(deckId);
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }
}
