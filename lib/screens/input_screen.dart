import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models/deck.dart';
import '../models/flashcard.dart';
import '../providers/providers.dart';

class InputScreen extends ConsumerStatefulWidget {
  const InputScreen({super.key});

  @override
  ConsumerState<InputScreen> createState() => _InputScreenState();
}

class _InputScreenState extends ConsumerState<InputScreen> {
  final _textController = TextEditingController();
  bool _isLoading = false;
  String? _error;

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _pasteFromClipboard() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data?.text != null) {
      _textController.text = data!.text!;
    }
  }

  Future<void> _generate() async {
    final text = _textController.text.trim();
    if (text.isEmpty) {
      setState(() => _error = '请输入文本内容');
      return;
    }

    final aiService = ref.read(aiServiceProvider);
    if (aiService == null) {
      _showApiKeyDialog();
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final results = await Future.wait([
        aiService.generateDeckTitle(text),
        aiService.generateFlashcards(text),
      ]);

      final title = results[0] as String;
      final cards = results[1] as List<Map<String, dynamic>>;

      if (!mounted) return;

      final db = ref.read(databaseServiceProvider);
      const uuid = Uuid();
      final deckId = uuid.v4();
      final deck = Deck(
        id: deckId,
        title: title,
        createdAt: DateTime.now(),
      );
      await db.createDeck(deck);

      final flashcards = cards
          .map((c) => Flashcard(
                id: uuid.v4(),
                deckId: deckId,
                questionZh: c['questionZh'],
                questionEn: c['questionEn'],
                answerZh: c['answerZh'],
                answerEn: c['answerEn'],
                knowledgeTag: c['knowledgeTag'],
              ))
          .toList();
      await db.createCards(flashcards);

      ref.read(decksProvider.notifier).refresh();

      if (!mounted) return;
      _textController.clear();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('已生成 ${flashcards.length} 张卡片: $title'),
          backgroundColor: Colors.green.shade800,
        ),
      );
    } catch (e) {
      setState(() => _error = '生成失败: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showApiKeyDialog() {
    final controller = TextEditingController();
    final dark = isDark(ref);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: dark ? const Color(0xFF1E1E1E) : Colors.white,
        title: Text('配置 API Key',
            style: TextStyle(color: dark ? Colors.white : Colors.black87)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              '请输入通义千问 API Key',
              style: TextStyle(color: Colors.grey, fontSize: 13),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              style: TextStyle(color: dark ? Colors.white : Colors.black87),
              decoration: InputDecoration(
                hintText: 'sk-xxxxxxxx',
                hintStyle: TextStyle(color: Colors.grey.shade400),
                filled: true,
                fillColor: dark ? const Color(0xFF2A2A2A) : Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
              ),
              obscureText: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              if (controller.text.trim().isNotEmpty) {
                await ref
                    .read(databaseServiceProvider)
                    .setApiKey(controller.text.trim());
                if (ctx.mounted) Navigator.pop(ctx);
                setState(() {});
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dark = isDark(ref);

    return Scaffold(
      appBar: AppBar(
        title: const Text('输入文本'),
        actions: [
          IconButton(
            icon: const Icon(Icons.key),
            onPressed: _showApiKeyDialog,
            tooltip: 'API Key 设置',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Expanded(
              child: TextField(
                controller: _textController,
                maxLines: null,
                expands: true,
                style: TextStyle(
                  color: dark ? Colors.white : Colors.black87,
                  fontSize: 15,
                ),
                decoration: InputDecoration(
                  hintText: '粘贴你的学习材料、笔记或文章...',
                  hintStyle: TextStyle(color: Colors.grey.shade400),
                  filled: true,
                  fillColor: dark ? const Color(0xFF1A1A1A) : Colors.grey.shade50,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: dark ? Colors.grey.shade800 : Colors.grey.shade300,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: dark ? Colors.grey.shade800 : Colors.grey.shade300,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.blue),
                  ),
                ),
              ),
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  _error!,
                  style: const TextStyle(color: Colors.redAccent, fontSize: 13),
                ),
              ),
            const SizedBox(height: 12),
            Row(
              children: [
                OutlinedButton.icon(
                  onPressed: _pasteFromClipboard,
                  icon: const Icon(Icons.paste, size: 18),
                  label: const Text('粘贴'),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: () {
                    _textController.clear();
                    setState(() => _error = null);
                  },
                  icon: const Icon(Icons.clear, size: 18),
                  label: const Text('清除'),
                ),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: _isLoading ? null : _generate,
                  icon: _isLoading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.auto_awesome, size: 18),
                  label: Text(_isLoading ? '生成中...' : '生成卡片'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
