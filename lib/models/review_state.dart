import 'package:hive/hive.dart';

part 'review_state.g.dart';

@HiveType(typeId: 2)
class ReviewState extends HiveObject {
  @HiveField(0)
  String cardId;

  @HiveField(1)
  double easinessFactor;

  @HiveField(2)
  int interval;

  @HiveField(3)
  int repetitions;

  @HiveField(4)
  DateTime nextReview;

  /// 记录每次复习的时间，用于热力图统计
  @HiveField(5)
  List<DateTime> reviewHistory;

  ReviewState({
    required this.cardId,
    this.easinessFactor = 2.5,
    this.interval = 0,
    this.repetitions = 0,
    DateTime? nextReview,
    List<DateTime>? reviewHistory,
  })  : nextReview = nextReview ?? DateTime.now(),
        reviewHistory = reviewHistory ?? [];
}
