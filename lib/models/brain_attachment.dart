class BrainAttachment {
  const BrainAttachment({
    required this.id,
    required this.ideaId,
    required this.displayName,
    required this.storedPath,
    this.mimeType,
    required this.sizeBytes,
    required this.createdAt,
  });

  final int id;
  final int ideaId;
  final String displayName;
  final String storedPath;
  final String? mimeType;
  final int sizeBytes;
  final DateTime createdAt;

  factory BrainAttachment.fromMap(Map<String, Object?> map) => BrainAttachment(
        id: map['id'] as int,
        ideaId: map['idea_id'] as int,
        displayName: map['display_name'] as String,
        storedPath: map['stored_path'] as String,
        mimeType: map['mime_type'] as String?,
        sizeBytes: (map['size_bytes'] as int?) ?? 0,
        createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
      );

  String get readableSize {
    if (sizeBytes < 1024) return '$sizeBytes B';
    if (sizeBytes < 1024 * 1024) return '${(sizeBytes / 1024).toStringAsFixed(1)} KB';
    return '${(sizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
