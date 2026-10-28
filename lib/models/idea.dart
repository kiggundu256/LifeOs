class Idea {
  const Idea({
    required this.id,
    required this.title,
    this.body = '',
    this.isArchived = false,
    required this.createdAt,
    required this.updatedAt,
  });

  final int id;
  final String title;
  final String body;
  final bool isArchived;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory Idea.fromMap(Map<String, Object?> map) => Idea(
        id: map['id'] as int,
        title: map['title'] as String,
        body: (map['body'] as String?) ?? '',
        isArchived: (map['is_archived'] as int? ?? 0) == 1,
        createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
        updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updated_at'] as int),
      );
}
