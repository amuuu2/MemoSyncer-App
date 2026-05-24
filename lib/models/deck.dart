import 'package:hive/hive.dart';

part 'deck.g.dart';

@HiveType(typeId: 0)
class Deck extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String title;

  @HiveField(2)
  DateTime createdAt;

  Deck({
    required this.id,
    required this.title,
    required this.createdAt,
  });
}
