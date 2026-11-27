import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/performance_data.dart';
import '../models/task_completion_record.dart';
import '../repositories/lifeos_repository.dart';

class PerformanceScreen extends StatefulWidget {
  const PerformanceScreen({super.key, required this.repository});
  final LifeosRepository repository;

  @override
  PerformanceScreenState createState() => PerformanceScreenState();
}

class PerformanceScreenState extends State<PerformanceScreen> {
  int _rangeDays = 30;
  late Future<PerformanceData> _future;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() => _future = widget.repository.getPerformanceData();

  Future<void> refreshData() async {
    setState(_load);
    await _future;
  }

  DateTime _day(DateTime date) => DateTime(date.year, date.month, date.day);
  int _key(DateTime date) => _day(date).millisecondsSinceEpoch;
  String _date(DateTime date) => date.day.toString() + '/' + date.month.toString();
  String _month(int value) => const ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'][value - 1];

  List<TaskCompletionRecord> _periodRecords(PerformanceData data, DateTime now) {
    if (_rangeDays == 0 || data.activity.isEmpty) return data.activity;
    final start = _day(now).subtract(Duration(days: _rangeDays - 1));
    return data.activity.where((item) => !_day(item.occurredAt).isBefore(start)).toList();
  }

  Map<int, int> _dailyCounts(Iterable<TaskCompletionRecord> records) {
    final result = <int, int>{};
    for (final record in records) {
      if (record.isCompletion) {
        final key = _key(record.occurredAt);
        result[key] = (result[key] ?? 0) + 1;
      }
    }
    return result;
  }

  int _streak(Map<int, int> counts, DateTime now) {
    var cursor = _day(now);
    if ((counts[_key(cursor)] ?? 0) == 0) cursor = cursor.subtract(const Duration(days: 1));
    var result = 0;
    while ((counts[_key(cursor)] ?? 0) > 0) {
      result++;
      cursor = cursor.subtract(const Duration(days: 1));
    }
    return result;
  }

  int _bestStreak(Map<int, int> counts) {
    final days = counts.keys.toList()..sort();
    var best = 0;
    var current = 0;
    var previous = -1;
    for (final day in days) {
      if (previous >= 0 && day - previous == const Duration(days: 1).inMilliseconds) {
        current++;
      } else {
        current = 1;
      }
      best = math.max(best, current);
      previous = day;
    }
    return best;
  }

  List<_Bucket> _buckets(Map<int, int> daily, DateTime now, List<TaskCompletionRecord> records) {
    final today = _day(now);
    if (_rangeDays == 7) {
      return List.generate(7, (i) {
        final date = today.subtract(Duration(days: 6 - i));
        return _Bucket(const ['M', 'T', 'W', 'T', 'F', 'S', 'S'][0 + date.weekday - 1], daily[_key(date)] ?? 0);
      });
    }
    if (_rangeDays == 30 || _rangeDays == 90) {
      final width = _rangeDays == 30 ? 2 : 7;
      final count = _rangeDays == 30 ? 15 : 13;
      return List.generate(count, (i) {
        final start = today.subtract(Duration(days: _rangeDays - 1 - i * width));
        final end = start.add(Duration(days: width));
        var total = 0;
        for (var offset = 0; offset < width; offset++) {
          total += daily[_key(start.add(Duration(days: offset)))] ?? 0;
        }
        return _Bucket(start.day.toString(), total);
      });
    }
    if (records.isEmpty) return const [];
    final firstDate = records.map((e) => _day(e.occurredAt)).reduce((a, b) => a.isBefore(b) ? a : b);
    var cursor = DateTime(firstDate.year, firstDate.month);
    final last = DateTime(today.year, today.month);
    final months = <DateTime>[];
    while (!cursor.isAfter(last)) {
      months.add(cursor);
      cursor = DateTime(cursor.year, cursor.month + 1);
    }
    final visible = months.length > 12 ? months.sublist(months.length - 12) : months;
    return visible.map((month) {
      var total = 0;
      daily.forEach((key, value) {
        final date = DateTime.fromMillisecondsSinceEpoch(key);
        if (date.year == month.year && date.month == month.month) total += value;
      });
      return _Bucket(_month(month.month), total);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Performance & Growth'),
          Text('YOUR PROGRESS, MADE VISIBLE', style: TextStyle(fontSize: 9, letterSpacing: 1.2, color: Color(0xFF7A8497), fontWeight: FontWeight.w700)),
        ]),
        actions: [IconButton(tooltip: 'Refresh insights', onPressed: refreshData, icon: const Icon(Icons.refresh_rounded))],
      ),
      body: FutureBuilder<PerformanceData>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.hasError) return Center(child: Padding(padding: const EdgeInsets.all(24), child: Text('Could not load your progress: ' + snapshot.error.toString(), textAlign: TextAlign.center)));
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          return _dashboard(snapshot.data!);
        },
      ),
    );
  }

  Widget _dashboard(PerformanceData data) {
    final now = DateTime.now();
    final records = _periodRecords(data, now);
    final completed = records.where((e) => e.isCompletion).length;
    final reopened = records.where((e) => !e.isCompletion).length;
    final daily = _dailyCounts(data.activity);
    final streak = _streak(daily, now);
    final best = _bestStreak(daily);
    final firstTracked = data.activity.isEmpty ? _day(now) : _day(data.activity.last.occurredAt);
    final daysInPeriod = _rangeDays == 0 ? math.max(1, _day(now).difference(firstTracked).inDays + 1) : _rangeDays;
    final average = completed / daysInPeriod;
    final activeDays = daily.entries.where((entry) {
      if (_rangeDays == 0) return true;
      return entry.key >= _key(_day(now).subtract(Duration(days: _rangeDays - 1)));
    }).length;
    final buckets = _buckets(daily, now, records);
    final maxCount = buckets.fold<int>(0, (value, item) => math.max(value, item.count));
    final lifetime = data.activity.where((e) => e.isCompletion).length;
    final recent = records.take(8).toList();
    final previous = _rangeDays == 0 ? null : data.activity.where((e) {
      final date = _day(e.occurredAt);
      final end = _day(now).subtract(Duration(days: _rangeDays - 1));
      final start = end.subtract(Duration(days: _rangeDays));
      return e.isCompletion && !date.isBefore(start) && date.isBefore(end);
    }).length;
    final difference = previous == null ? null : completed - previous;

    return RefreshIndicator(
      onRefresh: refreshData,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 32),
        children: [
          _hero(lifetime, streak, best),
          const SizedBox(height: 20),
          _heading('Your progress', 'Choose a period to explore'),
          const SizedBox(height: 11),
          _rangePicker(),
          const SizedBox(height: 14),
          Row(children: [
            Expanded(child: _metric('Completed', completed.toString(), Icons.check_circle_outline, const Color(0xFF23865A), difference == null ? 'In selected period' : (difference >= 0 ? '+' : '') + difference.toString() + ' vs previous')),
            const SizedBox(width: 10),
            Expanded(child: _metric('Reopened', reopened.toString(), Icons.replay_rounded, const Color(0xFFB7791F), 'Returned to open')),
          ]),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(child: _metric('Daily average', average.toStringAsFixed(1), Icons.trending_up_rounded, const Color(0xFF315FE7), 'Completions per day')),
            const SizedBox(width: 10),
            Expanded(child: _metric('Active days', activeDays.toString(), Icons.calendar_month_rounded, const Color(0xFF7654B8), 'Days with progress')),
          ]),
          const SizedBox(height: 22),
          _heading('Completion trend', _rangeLabel()),
          const SizedBox(height: 12),
          _panel(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              const Text('Tasks completed', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF27344B))),
              Text(completed.toString() + ' total', style: const TextStyle(fontSize: 12, color: Color(0xFF778397), fontWeight: FontWeight.w700)),
            ]),
            const SizedBox(height: 18),
            SizedBox(height: 150, child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: buckets.map((bucket) {
              final factor = maxCount == 0 ? 0.0 : bucket.count / maxCount;
              return Expanded(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 2), child: Column(mainAxisAlignment: MainAxisAlignment.end, children: [
                Text(bucket.count == 0 ? '' : bucket.count.toString(), style: const TextStyle(fontSize: 9, color: Color(0xFF66748B), fontWeight: FontWeight.w700)),
                const SizedBox(height: 5),
                Expanded(child: Align(alignment: Alignment.bottomCenter, child: FractionallySizedBox(heightFactor: factor == 0 ? 0.025 : factor, child: Container(decoration: BoxDecoration(color: bucket.count == 0 ? const Color(0xFFE9EDF5) : const Color(0xFF4770E8), borderRadius: BorderRadius.circular(7))))),
                const SizedBox(height: 7),
                Text(bucket.label, style: const TextStyle(fontSize: 9, color: Color(0xFF7A879A), fontWeight: FontWeight.w600)),
              ])));
            }).toList())),
            const SizedBox(height: 8),
            const Text('Only recorded completion events are charted. Earlier activity was not backfilled.', style: TextStyle(fontSize: 10, color: Color(0xFF8A95A7), height: 1.4)),
          ])),
          const SizedBox(height: 22),
          _heading('Consistency map', 'Your last 28 days'),
          const SizedBox(height: 12),
          _panel(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text('Show up for your goals', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF27344B))),
              Text('Less   ·   More', style: TextStyle(fontSize: 10, color: Color(0xFF7A879A))),
            ]),
            const SizedBox(height: 14),
            Wrap(spacing: 6, runSpacing: 6, children: List.generate(28, (index) {
              final date = _day(now).subtract(Duration(days: 27 - index));
              final count = daily[_key(date)] ?? 0;
              final color = count == 0 ? const Color(0xFFEEF1F6) : count == 1 ? const Color(0xFFC8D5FF) : count <= 3 ? const Color(0xFF8EA8F7) : const Color(0xFF315FE7);
              return Tooltip(message: _date(date) + ': ' + count.toString() + ' completed', child: Container(width: 25, height: 25, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(6))));
            })),
            const SizedBox(height: 16),
            Row(children: [
              Expanded(child: _smallStat('Current streak', streak.toString() + ' days')),
              Expanded(child: _smallStat('Best streak', best.toString() + ' days')),
              Expanded(child: _smallStat('Active days', activeDays.toString())),
            ]),
          ])),
          const SizedBox(height: 22),
          _heading('Task balance', 'Where things stand right now'),
          const SizedBox(height: 12),
          _panel(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              const Text('Active task completion', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF27344B))),
              Text((data.activeTasks == 0 ? 0 : (data.completedTasks / data.activeTasks * 100).round()).toString() + '%', style: const TextStyle(fontSize: 14, color: Color(0xFF315FE7), fontWeight: FontWeight.w900)),
            ]),
            const SizedBox(height: 10),
            ClipRRect(borderRadius: BorderRadius.circular(8), child: LinearProgressIndicator(value: data.activeTasks == 0 ? 0 : data.completedTasks / data.activeTasks, minHeight: 10, backgroundColor: const Color(0xFFE9EDF5), valueColor: const AlwaysStoppedAnimation(Color(0xFF315FE7)))),
            const SizedBox(height: 15),
            _balanceRow('Completed', data.completedTasks, const Color(0xFF315FE7)),
            const SizedBox(height: 8),
            _balanceRow('Still open', data.openTasks, const Color(0xFFB8C2D3)),
            const SizedBox(height: 8),
            _balanceRow('Archived', data.archivedTasks, const Color(0xFF9A83CA)),
          ])),
          const SizedBox(height: 22),
          _heading('Recent activity', 'Your latest task changes'),
          const SizedBox(height: 12),
          _panel(recent.isEmpty
              ? const Padding(padding: EdgeInsets.symmetric(vertical: 14), child: Column(children: [
                  Icon(Icons.insights_outlined, size: 34, color: Color(0xFF9AA6B8)),
                  SizedBox(height: 8),
                  Text('Your progress story starts here', style: TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF27344B))),
                  SizedBox(height: 4),
                  Text('Complete a task and it will appear in this activity feed.', textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: Color(0xFF7A879A))),
                ]))
              : Column(children: recent.asMap().entries.map((entry) {
                  final record = entry.value;
                  final isDone = record.isCompletion;
                  return Padding(padding: EdgeInsets.only(bottom: entry.key == recent.length - 1 ? 0 : 12), child: Row(children: [
                    Container(width: 36, height: 36, decoration: BoxDecoration(color: isDone ? const Color(0xFFE7F5EE) : const Color(0xFFFFF3DF), borderRadius: BorderRadius.circular(11)), child: Icon(isDone ? Icons.check_rounded : Icons.replay_rounded, color: isDone ? const Color(0xFF23865A) : const Color(0xFFB7791F), size: 19)),
                    const SizedBox(width: 11),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(record.taskTitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF27344B))),
                      const SizedBox(height: 2),
                      Text(isDone ? 'Marked complete' : 'Reopened', style: const TextStyle(fontSize: 10, color: Color(0xFF7A879A))),
                    ])),
                    Text(_relative(record.occurredAt, now), style: const TextStyle(fontSize: 10, color: Color(0xFF8A95A7))),
                  ]));
                }).toList())),
          const SizedBox(height: 22),
          _heading('Milestones', 'Celebrate every step forward'),
          const SizedBox(height: 12),
          _panel(Wrap(spacing: 9, runSpacing: 9, children: [10, 25, 50, 100, 250, 500].map((target) {
            final reached = lifetime >= target;
            return Container(width: 94, padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8), decoration: BoxDecoration(color: reached ? const Color(0xFFEAF0FF) : const Color(0xFFF6F8FC), borderRadius: BorderRadius.circular(13), border: Border.all(color: reached ? const Color(0xFFD6E1FF) : const Color(0xFFEDF0F5))), child: Column(children: [
              Icon(reached ? Icons.emoji_events_rounded : Icons.flag_outlined, color: reached ? const Color(0xFF315FE7) : const Color(0xFFA5AFBE), size: 20),
              const SizedBox(height: 6),
              Text(target.toString(), style: TextStyle(fontWeight: FontWeight.w900, color: reached ? const Color(0xFF2448B8) : const Color(0xFF7A879A))),
              Text(reached ? 'Reached' : 'Completions', style: const TextStyle(fontSize: 9, color: Color(0xFF7A879A))),
            ]));
          }).toList())),
          const SizedBox(height: 16),
          Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: const Color(0xFFEFF3FF), borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFDCE5FF))), child: const Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Icon(Icons.info_outline_rounded, color: Color(0xFF315FE7), size: 18),
            SizedBox(width: 9),
            Expanded(child: Text('LifeOS began recording task history with this update. Existing tasks appear in the task balance, but completions from before tracking began are not counted in charts, streaks or milestones.', style: TextStyle(fontSize: 11, color: Color(0xFF53688F), height: 1.45))),
          ])),
        ],
      ),
    );
  }

  Widget _hero(int lifetime, int streak, int best) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF315FE7), Color(0xFF203E9E)]), borderRadius: BorderRadius.circular(24), boxShadow: [BoxShadow(color: const Color(0xFF315FE7).withValues(alpha: 0.16), blurRadius: 20, offset: const Offset(0, 8))]),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('KEEP SHOWING UP.', style: TextStyle(color: Color(0xFFDCE5FF), fontSize: 10, letterSpacing: 1.5, fontWeight: FontWeight.w800)),
      const SizedBox(height: 8),
      Text(lifetime.toString(), style: const TextStyle(color: Colors.white, fontSize: 38, height: 1, fontWeight: FontWeight.w900, letterSpacing: -1.2)),
      const SizedBox(height: 5),
      const Text('tracked task completions', style: TextStyle(color: Color(0xFFE2E9FF), fontSize: 13)),
      const SizedBox(height: 17),
      Row(children: [
        _heroMetric(Icons.local_fire_department_rounded, streak.toString() + ' day streak', 'CURRENT'),
        const SizedBox(width: 22),
        _heroMetric(Icons.emoji_events_outlined, best.toString() + ' days', 'BEST STREAK'),
      ]),
    ]),
  );

  Widget _rangePicker() => Container(padding: const EdgeInsets.all(4), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFFE8ECF4))), child: Row(children: [
    _rangeOption('7 days', 7), _rangeOption('30 days', 30), _rangeOption('90 days', 90), _rangeOption('All', 0),
  ]));

  Widget _rangeOption(String label, int days) => Expanded(child: GestureDetector(onTap: () => setState(() => _rangeDays = days), child: AnimatedContainer(duration: const Duration(milliseconds: 160), padding: const EdgeInsets.symmetric(vertical: 10), decoration: BoxDecoration(color: _rangeDays == days ? const Color(0xFFEAF0FF) : Colors.transparent, borderRadius: BorderRadius.circular(10)), child: Text(label, textAlign: TextAlign.center, style: TextStyle(fontSize: 11, fontWeight: _rangeDays == days ? FontWeight.w800 : FontWeight.w600, color: _rangeDays == days ? const Color(0xFF315FE7) : const Color(0xFF778397))))));

  Widget _heroMetric(IconData icon, String value, String label) => Expanded(child: Row(children: [Icon(icon, color: const Color(0xFFFFD66B), size: 20), const SizedBox(width: 7), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13)), Text(label, style: const TextStyle(color: Color(0xFFDCE5FF), fontSize: 8, letterSpacing: 1.1, fontWeight: FontWeight.w700))]))]));

  Widget _metric(String label, String value, IconData icon, Color color, String note) => Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), border: Border.all(color: const Color(0xFFE8ECF4))), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Container(width: 31, height: 31, decoration: BoxDecoration(color: color.withValues(alpha: 0.10), borderRadius: BorderRadius.circular(10)), child: Icon(icon, color: color, size: 18)),
    const SizedBox(height: 11),
    Text(value, style: const TextStyle(fontSize: 23, fontWeight: FontWeight.w900, color: Color(0xFF19243A), letterSpacing: -0.6)),
    Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF344158))),
    const SizedBox(height: 3),
    Text(note, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 9, color: Color(0xFF8792A5))),
  ]));

  Widget _heading(String title, String subtitle) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: Color(0xFF19243A), letterSpacing: -0.3)),
    const SizedBox(height: 2),
    Text(subtitle, style: const TextStyle(fontSize: 11, color: Color(0xFF7A879A))),
  ]);

  Widget _panel(Widget child) => Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(19), border: Border.all(color: const Color(0xFFE8ECF4))), child: child);

  Widget _smallStat(String label, String value) => Column(children: [
    Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Color(0xFF27344B))),
    const SizedBox(height: 3),
    Text(label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 9, color: Color(0xFF7A879A))),
  ]);

  Widget _balanceRow(String label, int value, Color color) => Row(children: [
    Container(width: 8, height: 8, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4))),
    const SizedBox(width: 8),
    Expanded(child: Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF66748B)))),
    Text(value.toString(), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF27344B))),
  ]);

  String _rangeLabel() => _rangeDays == 0 ? 'All recorded history' : 'Last ' + _rangeDays.toString() + ' days';

  String _relative(DateTime date, DateTime now) {
    final difference = _day(now).difference(_day(date)).inDays;
    if (difference == 0) return 'Today';
    if (difference == 1) return 'Yesterday';
    if (difference < 7) return difference.toString() + ' days ago';
    return _date(date);
  }
}

class _Bucket {
  const _Bucket(this.label, this.count);
  final String label;
  final int count;
}
