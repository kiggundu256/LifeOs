class LifeTask {
  const LifeTask({
    required this.id,
    required this.title,
    this.notes = '',
    this.isComplete = false,
    this.isArchived = false,
    this.dueAt,
    required this.createdAt,
    required this.updatedAt,
  });

  final int id;
  final String title;
  final String notes;
  final bool isComplete;
  final bool isArchived;
  final DateTime? dueAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory LifeTask.fromMap(Map<String, Object?> map) => LifeTask(
        id: map['id'] as int,
        title: map['title'] as String,
        notes: (map['notes'] as String?) ?? '',
        isComplete: (map['is_complete'] as int? ?? 0) == 1,
        isArchived: (map['is_archived'] as int? ?? 0) == 1,
        dueAt: map['due_at'] == null
            ? null
            : DateTime.fromMillisecondsSinceEpoch(map['due_at'] as int),
        createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
        updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updated_at'] as int),
      );
}
