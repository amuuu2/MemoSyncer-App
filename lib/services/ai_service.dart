import 'dart:convert';
import 'package:http/http.dart' as http;

/// AI 服务 - 通义千问 DashScope OpenAI 兼容接口
class AiService {
  final String apiKey;
  final String baseUrl;
  final String model;

  AiService({
    required this.apiKey,
    this.baseUrl = 'https://dashscope.aliyuncs.com/compatible-mode/v1',
    this.model = 'qwen3-max-preview',
  });

  /// 调用 AI 将长文本解构为闪卡 JSON
  ///
  /// 返回格式: List<Map<String, dynamic>>
  /// 每个 map 包含: questionZh, questionEn, answerZh, answerEn, knowledgeTag
  Future<List<Map<String, dynamic>>> generateFlashcards(String inputText) async {
    final prompt = _buildPrompt(inputText);

    final response = await http.post(
      Uri.parse('$baseUrl/chat/completions'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $apiKey',
      },
      body: jsonEncode({
        'model': model,
        'messages': [
          {
            'role': 'system',
            'content': '你是一个专业的学习助手，擅长将长文本提炼为结构化的双语闪卡。'
                '你必须只返回 JSON 数组，不要包含任何其他文字、解释或 markdown 代码块标记。',
          },
          {
            'role': 'user',
            'content': prompt,
          },
        ],
        'temperature': 0.3,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('AI 请求失败 (${response.statusCode}): ${response.body}');
    }

    final data = jsonDecode(response.body);
    final content = data['choices'][0]['message']['content'] as String;

    // 清理可能的 markdown 代码块包裹
    String cleaned = content.trim();
    if (cleaned.startsWith('```')) {
      final firstNewline = cleaned.indexOf('\n');
      if (firstNewline != -1) {
        cleaned = cleaned.substring(firstNewline + 1);
      }
      if (cleaned.endsWith('```')) {
        cleaned = cleaned.substring(0, cleaned.length - 3);
      }
      cleaned = cleaned.trim();
    }

    final List<dynamic> parsed = jsonDecode(cleaned);

    // 校验每个卡片的字段
    final cards = <Map<String, dynamic>>[];
    for (final item in parsed) {
      if (item is Map<String, dynamic> &&
          item.containsKey('questionZh') &&
          item.containsKey('questionEn') &&
          item.containsKey('answerZh') &&
          item.containsKey('answerEn')) {
        cards.add({
          'questionZh': item['questionZh'] as String,
          'questionEn': item['questionEn'] as String,
          'answerZh': item['answerZh'] as String,
          'answerEn': item['answerEn'] as String,
          'knowledgeTag': (item['knowledgeTag'] as String?) ?? '通用',
        });
      }
    }

    if (cards.isEmpty) {
      throw Exception('AI 返回的数据无法解析为有效的闪卡，请重试');
    }

    return cards;
  }

  /// 生成卡片集标题
  Future<String> generateDeckTitle(String inputText) async {
    final snippet = inputText.length > 200
        ? inputText.substring(0, 200)
        : inputText;

    final response = await http.post(
      Uri.parse('$baseUrl/chat/completions'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $apiKey',
      },
      body: jsonEncode({
        'model': model,
        'messages': [
          {
            'role': 'system',
            'content': '根据以下文本内容，生成一个简短的中文标题（15字以内）。只返回标题文字，不要加引号或任何其他内容。',
          },
          {
            'role': 'user',
            'content': snippet,
          },
        ],
        'temperature': 0.3,
      }),
    );

    if (response.statusCode != 200) {
      return '未命名卡片集';
    }

    final data = jsonDecode(response.body);
    final title = (data['choices'][0]['message']['content'] as String).trim();
    return title.isEmpty ? '未命名卡片集' : title;
  }

  String _buildPrompt(String text) {
    return '''请将以下文本提炼为 5-15 张核心闪卡。每张卡片必须包含以下字段：
- questionZh: 中文问题或概念
- questionEn: 英文问题或概念
- answerZh: 中文精炼解答
- answerEn: 英文精炼解答
- knowledgeTag: 细分知识点标签（如"#计算机网络"）

请直接返回一个 JSON 数组，格式如下：
[
  {
    "questionZh": "...",
    "questionEn": "...",
    "answerZh": "...",
    "answerEn": "...",
    "knowledgeTag": "#..."
  }
]

文本内容：
$text''';
  }
}
