class LifeProject {
  const LifeProject({required this.id, required this.title, this.description = '', this.objective = '', this.priority = 'medium', this.status = 'active', this.startAt, this.dueAt, this.isArchived = false, required this.createdAt, required this.updatedAt});
  final int id;
  final String title, description, objective, priority, status;
  final DateTime? startAt, dueAt;
  final bool isArchived;
  final DateTime createdAt, updatedAt;
  factory LifeProject.fromMap(Map<String, Object?> map) => LifeProject(
    id: map['id'] as int, title: map['title'] as String,
    description: (map['description'] as String?) ?? '',
    objective: (map['objective'] as String?) ?? '',
    priority: (map['priority'] as String?) ?? 'medium',
    status: (map['status'] as String?) ?? 'active',
    startAt: map['start_at'] == null ? null : DateTime.fromMillisecondsSinceEpoch(map['start_at'] as int),
    dueAt: map['due_at'] == null ? null : DateTime.fromMillisecondsSinceEpoch(map['due_at'] as int),
    isArchived: (map['is_archived'] as int? ?? 0) == 1,
    createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
    updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updated_at'] as int),
  );
}
