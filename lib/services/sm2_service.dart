/// SM-2 间隔重复算法引擎
///
/// 根据用户评分动态调整复习间隔。
/// quality: 1=完全遗忘, 3=勉强想起, 5=完美记住
class Sm2Service {
  /// 根据 SM-2 算法计算下一次复习状态
  ///
  /// [quality] 用户评分 (1, 3, 5)
  /// [easinessFactor] 当前难度系数
  /// [repetitions] 连续正确次数
  /// [interval] 当前间隔天数
  ///
  /// 返回: (新的easinessFactor, 新的repetitions, 新的interval, 新的nextReview日期)
  static ({
    double easinessFactor,
    int repetitions,
    int interval,
    DateTime nextReview,
  }) calculateNextReview({
    required int quality,
    required double easinessFactor,
    required int repetitions,
    required int interval,
  }) {
    double newEf = easinessFactor;
    int newReps = repetitions;
    int newInterval = interval;

    if (quality < 3) {
      // 遗忘: 重置
      newReps = 0;
      newInterval = 0;
    } else {
      // 正确回忆
      if (newReps == 0) {
        newInterval = 1;
      } else if (newReps == 1) {
        newInterval = 6;
      } else {
        newInterval = (newInterval * newEf).round();
      }
      newReps++;
    }

    // 更新难度系数
    newEf = newEf + (0.1 - (5 - quality) * (0.08 + (5 - quality) * 0.02));
    if (newEf < 1.3) newEf = 1.3;

    // 计算下次复习日期 (纯日期，去掉时分秒)
    final now = DateTime.now();
    final nextReview = DateTime(now.year, now.month, now.day).add(
      Duration(days: newInterval),
    );

    return (
      easinessFactor: newEf,
      repetitions: newReps,
      interval: newInterval,
      nextReview: nextReview,
    );
  }
}
