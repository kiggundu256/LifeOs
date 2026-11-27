import 'package:flutter_test/flutter_test.dart';
import 'package:lifeos/models/brain_attachment.dart';
import 'package:lifeos/models/idea.dart';

void main() {
  test('Idea maps Second Brain pin and folder metadata while keeping legacy defaults', () {
    final now = DateTime(2026, 11, 27).millisecondsSinceEpoch;
    final legacy = Idea.fromMap({
      'id': 1, 'title': 'Legacy idea', 'body': 'Preserved content',
      'is_archived': 0, 'created_at': now, 'updated_at': now,
    });
    expect(legacy.isPinned, isFalse);
    expect(legacy.folderId, isNull);

    final organized = Idea.fromMap({
      'id': 2, 'title': 'Research', 'body': 'Useful notes',
      'is_pinned': 1, 'folder_id': 4, 'is_archived': 0,
      'created_at': now, 'updated_at': now,
    });
    expect(organized.isPinned, isTrue);
    expect(organized.folderId, 4);
  });

  test('BrainAttachment maps private file metadata and formats sizes', () {
    final now = DateTime(2026, 11, 27).millisecondsSinceEpoch;
    final attachment = BrainAttachment.fromMap({
      'id': 9, 'idea_id': 2, 'display_name': 'research.pdf',
      'stored_path': '/private/second_brain/attachments/research.pdf',
      'mime_type': 'application/pdf', 'size_bytes': 1536, 'created_at': now,
    });
    expect(attachment.ideaId, 2);
    expect(attachment.displayName, 'research.pdf');
    expect(attachment.readableSize, '1.5 KB');
  });
}
