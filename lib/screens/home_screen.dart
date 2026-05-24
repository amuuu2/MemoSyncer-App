import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/providers.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  late int _viewYear;
  late int _viewMonth;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _viewYear = now.year;
    _viewMonth = now.month;
  }

  void _prevMonth() {
    setState(() {
      if (_viewMonth == 1) {
        _viewMonth = 12;
        _viewYear--;
      } else {
        _viewMonth--;
      }
    });
  }

  void _nextMonth() {
    final now = DateTime.now();
    if (_viewYear == now.year && _viewMonth == now.month) return;
    setState(() {
      if (_viewMonth == 12) {
        _viewMonth = 1;
        _viewYear++;
      } else {
        _viewMonth++;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final stats = ref.watch(statsProvider);
    final db = ref.read(databaseServiceProvider);
    final monthData = db.getMonthHeatmap(_viewYear, _viewMonth);
    final dark = isDark(ref);
    final now = DateTime.now();
    final isCurrentMonth = _viewYear == now.year && _viewMonth == now.month;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'MemoSyncer',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: Icon(dark ? Icons.light_mode : Icons.dark_mode),
            onPressed: () => ref.read(themeModeProvider.notifier).toggle(),
            tooltip: dark ? '切换浅色' : '切换深色',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 统计卡片行
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    icon: Icons.today,
                    label: '今日已复习',
                    value: '${stats.todayReviewed}',
                    color: Colors.blue,
                    dark: dark,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildStatCard(
                    icon: Icons.emoji_events,
                    label: '已掌握',
                    value: '${stats.masteredCount}',
                    color: Colors.green,
                    dark: dark,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildStatCard(
                    icon: Icons.local_fire_department,
                    label: '连续打卡',
                    value: '${stats.streakDays}天',
                    color: Colors.orange,
                    dark: dark,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // 月份切换标题行
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: _prevMonth,
                ),
                Expanded(
                  child: Center(
                    child: Text(
                      '$_viewYear 年 $_viewMonth 月',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(
                    Icons.chevron_right,
                    color: isCurrentMonth ? Colors.grey : null,
                  ),
                  onPressed: _nextMonth,
                ),
              ],
            ),

            const SizedBox(height: 12),

            // 月度热力图
            _buildMonthHeatmap(monthData, _viewYear, _viewMonth, dark),

            const SizedBox(height: 12),

            // 图例
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('少', style: TextStyle(color: Colors.grey, fontSize: 11)),
                const SizedBox(width: 4),
                ...List.generate(5, (i) {
                  final colors = dark
                      ? [
                          const Color(0xFF1A1A1A),
                          const Color(0xFF0E4429),
                          const Color(0xFF006D32),
                          const Color(0xFF26A641),
                          const Color(0xFF39D353),
                        ]
                      : [
                          Colors.grey.shade200,
                          const Color(0xFF9BE9A8),
                          const Color(0xFF40C463),
                          const Color(0xFF30A14E),
                          const Color(0xFF216E39),
                        ];
                  return Container(
                    width: 14,
                    height: 14,
                    margin: const EdgeInsets.symmetric(horizontal: 1),
                    decoration: BoxDecoration(
                      color: colors[i],
                      borderRadius: BorderRadius.circular(3),
                    ),
                  );
                }),
                const SizedBox(width: 4),
                Text('多', style: TextStyle(color: Colors.grey, fontSize: 11)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    required bool dark,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: dark ? const Color(0xFF1A1A1A) : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: dark ? Colors.grey.shade800 : Colors.grey.shade200,
        ),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: dark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: Colors.grey,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthHeatmap(
      Map<String, int> data, int year, int month, bool dark) {
    final daysInMonth = DateTime(year, month + 1, 0).day;
    final firstWeekday = DateTime(year, month, 1).weekday; // 1=Mon..7=Sun
    // 转换为 0=Mon..6=Sun 的网格
    final startOffset = firstWeekday - 1;

    int maxCount = 1;
    for (final count in data.values) {
      if (count > maxCount) maxCount = count;
    }

    final weekDays = ['一', '二', '三', '四', '五', '六', '日'];
    final totalCells = startOffset + daysInMonth;
    final rows = (totalCells / 7).ceil();

    return Column(
      children: [
        // 星期标题
        Row(
          children: weekDays
              .map((d) => Expanded(
                    child: Center(
                      child: Text(
                        d,
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ))
              .toList(),
        ),
        const SizedBox(height: 4),
        // 日期格子
        ...List.generate(rows, (row) {
          return Row(
            children: List.generate(7, (col) {
              final cellIndex = row * 7 + col;
              final dayNum = cellIndex - startOffset + 1;
              final isValid = dayNum >= 1 && dayNum <= daysInMonth;
              final isFuture = isValid &&
                  DateTime(year, month, dayNum)
                      .isAfter(DateTime.now());

              if (!isValid) {
                return const Expanded(child: SizedBox(height: 36));
              }

              final dateKey =
                  '$year-${month.toString().padLeft(2, '0')}-${dayNum.toString().padLeft(2, '0')}';
              final count = data[dateKey] ?? 0;

              Color cellColor;
              if (isFuture) {
                cellColor = Colors.transparent;
              } else if (count == 0) {
                cellColor = dark ? const Color(0xFF1A1A1A) : Colors.grey.shade100;
              } else {
                final intensity = (count / maxCount).clamp(0.0, 1.0);
                if (dark) {
                  cellColor = Color.lerp(
                    const Color(0xFF0E4429),
                    const Color(0xFF39D353),
                    intensity,
                  )!;
                } else {
                  cellColor = Color.lerp(
                    const Color(0xFF9BE9A8),
                    const Color(0xFF216E39),
                    intensity,
                  )!;
                }
              }

              return Expanded(
                child: Container(
                  height: 36,
                  margin: const EdgeInsets.all(1.5),
                  decoration: BoxDecoration(
                    color: cellColor,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Center(
                    child: Text(
                      '$dayNum',
                      style: TextStyle(
                        fontSize: 11,
                        color: (isFuture || (count == 0))
                            ? (dark ? Colors.grey.shade700 : Colors.grey.shade400)
                            : (dark ? Colors.white : Colors.white),
                      ),
                    ),
                  ),
                ),
              );
            }),
          );
        }),
      ],
    );
  }
}
