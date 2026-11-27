class TaskCompletionRecord {
  const TaskCompletionRecord({required this.id, required this.taskId, required this.taskTitle, required this.action, required this.occurredAt});

  final int id;
  final int taskId;
  final String taskTitle;
  final String action;
  final DateTime occurredAt;

  bool get isCompletion => action == 'completed';

  factory TaskCompletionRecord.fromMap(Map<String, Object?> map) => TaskCompletionRecord(
    id: map['id'] as int,
    taskId: map['task_id'] as int,
    taskTitle: map['task_title'] as String,
    action: map['action'] as String,
    occurredAt: DateTime.fromMillisecondsSinceEpoch(map['occurred_at'] as int),
  );
}
