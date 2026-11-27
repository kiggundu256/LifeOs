import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class BrainAttachmentService {
  BrainAttachmentService._();
  static final instance = BrainAttachmentService._();

  Future<List<Map<String, Object?>>> importFiles() async {
    final result = await FilePicker.platform.pickFiles(allowMultiple: true, withData: false);
    if (result == null) return [];
    final directory = await getApplicationSupportDirectory();
    final target = Directory(p.join(directory.path, 'second_brain', 'attachments'));
    await target.create(recursive: true);
    final imported = <Map<String, Object?>>[];
    for (final item in result.files) {
      final sourcePath = item.path;
      if (sourcePath == null) continue;
      final source = File(sourcePath);
      if (!await source.exists()) continue;
      final safeName = p.basename(item.name).replaceAll(RegExp(r'[^A-Za-z0-9._ -]'), '_');
      final storedName = '${DateTime.now().microsecondsSinceEpoch}_$safeName';
      final destination = await source.copy(p.join(target.path, storedName));
      imported.add({
        'display_name': item.name,
        'stored_path': destination.path,
        'mime_type': _mimeType(item.extension),
        'size_bytes': await destination.length(),
      });
    }
    return imported;
  }

  Future<void> open(String path) async {
    final file = File(path);
    if (!await file.exists()) throw StateError('This attachment is no longer available.');
    final result = await OpenFilex.open(path);
    if (result.type != ResultType.done) throw StateError(result.message);
  }

  Future<void> deletePrivateCopy(String path) async {
    final directory = await getApplicationSupportDirectory();
    final root = p.normalize(p.join(directory.path, 'second_brain', 'attachments'));
    final candidate = p.normalize(path);
    if (!p.isWithin(root, candidate)) return;
    final file = File(candidate);
    if (await file.exists()) await file.delete();
  }

  String? _mimeType(String? extension) {
    switch ((extension ?? '').toLowerCase()) {
      case 'pdf': return 'application/pdf';
      case 'jpg':
      case 'jpeg': return 'image/jpeg';
      case 'png': return 'image/png';
      case 'webp': return 'image/webp';
      case 'txt': return 'text/plain';
      case 'doc': return 'application/msword';
      case 'docx': return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      case 'xls': return 'application/vnd.ms-excel';
      case 'xlsx': return 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
      case 'mp3': return 'audio/mpeg';
      case 'mp4': return 'video/mp4';
      default: return null;
    }
  }
}
