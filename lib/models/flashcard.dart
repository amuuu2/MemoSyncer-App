import 'package:hive/hive.dart';

part 'flashcard.g.dart';

@HiveType(typeId: 1)
class Flashcard extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String deckId;

  @HiveField(2)
  String questionZh;

  @HiveField(3)
  String questionEn;

  @HiveField(4)
  String answerZh;

  @HiveField(5)
  String answerEn;

  @HiveField(6)
  String knowledgeTag;

  Flashcard({
    required this.id,
    required this.deckId,
    required this.questionZh,
    required this.questionEn,
    required this.answerZh,
    required this.answerEn,
    required this.knowledgeTag,
  });
}
