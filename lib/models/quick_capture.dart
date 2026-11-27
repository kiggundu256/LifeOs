class QuickCapture {
  const QuickCapture({required this.id, required this.kind, required this.title, this.body='', this.dueAt, this.reminderAt, this.scheduledAt, this.reminderMinutes=0, this.projectId, this.status='inbox', this.convertedType, this.convertedId, required this.createdAt, required this.updatedAt});
  final int id;
  final String kind, title, body, status;
  final DateTime? dueAt, reminderAt, scheduledAt;
  final int reminderMinutes;
  final int? projectId, convertedId;
  final String? convertedType;
  final DateTime createdAt, updatedAt;
  bool get isProcessed => status == 'processed';
  factory QuickCapture.fromMap(Map<String,Object?> m) => QuickCapture(
    id:m['id'] as int, kind:m['kind'] as String, title:m['title'] as String,
    body:m['body'] as String? ?? '', dueAt:m['due_at']==null?null:DateTime.fromMillisecondsSinceEpoch(m['due_at'] as int),
    reminderAt:m['reminder_at']==null?null:DateTime.fromMillisecondsSinceEpoch(m['reminder_at'] as int),
    scheduledAt:m['scheduled_at']==null?null:DateTime.fromMillisecondsSinceEpoch(m['scheduled_at'] as int),
    reminderMinutes:m['reminder_minutes'] as int? ?? 0, projectId:m['project_id'] as int?, status:m['status'] as String? ?? 'inbox',
    convertedType:m['converted_type'] as String?, convertedId:m['converted_id'] as int?,
    createdAt:DateTime.fromMillisecondsSinceEpoch(m['created_at'] as int), updatedAt:DateTime.fromMillisecondsSinceEpoch(m['updated_at'] as int),
  );
}
