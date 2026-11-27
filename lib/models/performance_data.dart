import 'task_completion_record.dart';

class PerformanceData {
  const PerformanceData({required this.activeTasks, required this.completedTasks, required this.openTasks, required this.archivedTasks, required this.activity});
  final int activeTasks;
  final int completedTasks;
  final int openTasks;
  final int archivedTasks;
  final List<TaskCompletionRecord> activity;
}