import 'package:flutter/material.dart';

import '../models/brain_attachment.dart';
import '../models/idea.dart';
import '../repositories/lifeos_repository.dart';
import '../services/brain_attachment_service.dart';

class BrainVaultScreen extends StatefulWidget {
  const BrainVaultScreen({super.key, required this.repository});
  final LifeosRepository repository;

  @override
  State<BrainVaultScreen> createState() => _BrainVaultScreenState();
}

class _BrainVaultScreenState extends State<BrainVaultScreen> {
  final _search = TextEditingController();
  bool _archived = false;
  bool _pinnedOnly = false;
  int? _folderId;
  int? _tagId;
  late Future<List<Map<String, Object?>>> _notes;
  late Future<List<Map<String, Object?>>> _folders;
  late Future<List<Map<String, Object?>>> _tags;

  @override
  void initState() { super.initState(); _refresh(); }
  @override
  void dispose() { _search.dispose(); super.dispose(); }

  void _refresh() {
    _notes = widget.repository.getBrainNotes(
      query: _search.text, includeArchived: _archived, pinnedOnly: _pinnedOnly,
      folderId: _folderId, tagId: _tagId,
    );
    _folders = widget.repository.getBrainFolders();
    _tags = widget.repository.getBrainTags();
  }

  Future<void> _reload() async { setState(_refresh); await Future.wait([_notes, _folders, _tags]); }
  void _message(String value) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(value)));

  Future<void> _newFolder() async {
    final controller = TextEditingController();
    final name = await showDialog<String>(context: context, builder: (context) => AlertDialog(
      title: const Text('Create folder'),
      content: TextField(controller: controller, autofocus: true, decoration: const InputDecoration(labelText: 'Folder name')),
      actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')), FilledButton(onPressed: () => Navigator.pop(context, controller.text.trim()), child: const Text('Create'))],
    ));
    controller.dispose();
    if (name == null || name.isEmpty) return;
    try { await widget.repository.saveBrainFolder(name); await _reload(); }
    catch (error) { _message(error.toString()); }
  }

  Future<void> _editNote([Idea? note]) async {
    final title = TextEditingController(text: note?.title ?? '');
    final body = TextEditingController(text: note?.body ?? '');
    final tags = TextEditingController(text: note == null ? '' : await widget.repository.getIdeaTagNames(note.id).then((v) => v.join(', ')));
    final folders = await widget.repository.getBrainFolders();
    if (!mounted) { title.dispose(); body.dispose(); tags.dispose(); return; }
    int? folder = note == null ? _folderId : note.folderId;
    bool pinned = note?.isPinned ?? false;
    final draft = await showDialog<_BrainDraft>(context: context, builder: (context) => StatefulBuilder(builder: (context, setDialogState) => AlertDialog(
      title: Text(note == null ? 'New note' : 'Edit note'),
      content: SizedBox(width: 480, child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        TextField(controller: title, autofocus: true, textCapitalization: TextCapitalization.sentences, decoration: const InputDecoration(labelText: 'Title', hintText: 'Give this note a clear name')),
        const SizedBox(height: 12),
        TextField(controller: body, minLines: 6, maxLines: 12, textCapitalization: TextCapitalization.sentences, decoration: const InputDecoration(labelText: 'Note', hintText: 'Write thoughts, research, plans, meeting notes or anything worth keeping')),
        const SizedBox(height: 12),
        TextField(controller: tags, decoration: const InputDecoration(labelText: 'Tags', hintText: 'work, ideas, learning (comma separated)')),
        const SizedBox(height: 12),
        DropdownButtonFormField<int?>(
          initialValue: folder, decoration: const InputDecoration(labelText: 'Folder'),
          items: [const DropdownMenuItem<int?>(value: null, child: Text('Unfiled')), ...folders.map((f) => DropdownMenuItem<int?>(value: f['id'] as int, child: Text(f['name'] as String)))],
          onChanged: (value) => setDialogState(() => folder = value),
        ),
        SwitchListTile(contentPadding: EdgeInsets.zero, title: const Text('Pin this note'), value: pinned, onChanged: (value) => setDialogState(() => pinned = value)),
      ]))),
      actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')), FilledButton(onPressed: () {
        if (title.text.trim().isEmpty) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('A note needs a title.'))); return; }
        Navigator.pop(context, _BrainDraft(title.text, body.text, tags.text, folder, pinned));
      }, child: const Text('Save note'))],
    )));
    if (draft != null) {
      try {
        final id = await widget.repository.saveIdea(id: note?.id, title: draft.title, body: draft.body, folderId: draft.folderId, isPinned: draft.pinned, tags: draft.tags.split(','));
        if (mounted) { await _reload(); _message(note == null ? 'Note saved' : 'Note updated'); }
        if (note == null && mounted) await _manageAttachments(id);
      } catch (error) { if (mounted) _message(error.toString()); }
    }
    title.dispose(); body.dispose(); tags.dispose();
  }

  Future<void> _manageAttachments(int noteId) async {
    try {
      final files = await BrainAttachmentService.instance.importFiles();
      for (final file in files) {
        await widget.repository.addIdeaAttachment(
          ideaId: noteId, displayName: file['display_name'] as String,
          storedPath: file['stored_path'] as String, mimeType: file['mime_type'] as String?,
          sizeBytes: file['size_bytes'] as int,
        );
      }
      if (files.isNotEmpty && mounted) { await _reload(); _message('${files.length} file(s) saved privately'); }
    } catch (error) { if (mounted) _message('Could not add attachment: $error'); }
  }

  Future<void> _openNote(Idea note) async {
    final attachments = await widget.repository.getIdeaAttachments(note.id);
    if (!mounted) return;
    await showModalBottomSheet<void>(context: context, isScrollControlled: true, showDragHandle: true, builder: (context) => SafeArea(child: Padding(
      padding: EdgeInsets.fromLTRB(20, 8, 20, MediaQuery.of(context).viewInsets.bottom + 24),
      child: ListView(shrinkWrap: true, children: [
        Text(note.title, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
        const SizedBox(height: 12),
        SelectableText(note.body.isEmpty ? 'No note content yet.' : note.body, style: const TextStyle(height: 1.55)),
        const SizedBox(height: 18),
        Row(children: [const Expanded(child: Text('ATTACHMENTS', style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 1))), TextButton.icon(onPressed: () async { Navigator.pop(context); await _manageAttachments(note.id); }, icon: const Icon(Icons.attach_file), label: const Text('Add files'))]),
        if (attachments.isEmpty) const Text('No attachments yet', style: TextStyle(color: Colors.black54)),
        ...attachments.map((item) {
          final attachment = BrainAttachment.fromMap(item);
          return ListTile(
            contentPadding: EdgeInsets.zero, leading: const Icon(Icons.insert_drive_file_outlined),
            title: Text(attachment.displayName, maxLines: 1, overflow: TextOverflow.ellipsis),
            subtitle: Text(attachment.readableSize),
            onTap: () async { try { await BrainAttachmentService.instance.open(attachment.storedPath); } catch (error) { if (mounted) _message(error.toString()); } },
            trailing: IconButton(icon: const Icon(Icons.delete_outline), onPressed: () async {
              await widget.repository.deleteIdeaAttachment(attachment.id);
              await BrainAttachmentService.instance.deletePrivateCopy(attachment.storedPath);
              if (context.mounted) Navigator.pop(context);
              if (mounted) await _openNote(note);
            }),
          );
        }),
        const SizedBox(height: 12),
        Wrap(spacing: 8, children: [
          OutlinedButton.icon(onPressed: () { Navigator.pop(context); _editNote(note); }, icon: const Icon(Icons.edit_outlined), label: const Text('Edit note')),
          OutlinedButton.icon(onPressed: () { Navigator.pop(context); _message('Saved in your private LifeOS vault'); }, icon: const Icon(Icons.lock_outline), label: const Text('Private storage')),
        ]),
      ]),
    )));
  }

  Future<void> _toggleArchive(Idea note) async {
    await widget.repository.archiveIdea(note.id, !_archived);
    await _reload();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Second Brain'), actions: [
      IconButton(tooltip: 'Create folder', onPressed: _newFolder, icon: const Icon(Icons.create_new_folder_outlined)),
      IconButton(tooltip: _archived ? 'Show active notes' : 'Show archive', onPressed: () { setState(() { _archived = !_archived; _refresh(); }); }, icon: Icon(_archived ? Icons.inventory_2 : Icons.archive_outlined)),
    ]),
    floatingActionButton: FloatingActionButton.extended(onPressed: () => _editNote(), icon: const Icon(Icons.add), label: const Text('Capture note')),
    body: Column(children: [
      Padding(padding: const EdgeInsets.fromLTRB(16, 4, 16, 8), child: TextField(
        controller: _search, onChanged: (_) => setState(_refresh),
        decoration: InputDecoration(hintText: 'Search your knowledge vault', prefixIcon: const Icon(Icons.search), suffixIcon: _search.text.isEmpty ? null : IconButton(onPressed: () { _search.clear(); setState(_refresh); }, icon: const Icon(Icons.close))),
      )),
      SizedBox(height: 48, child: FutureBuilder<List<Map<String, Object?>>>(
        future: _folders, builder: (context, snapshot) {
          final folders = snapshot.data ?? [];
          return ListView(scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 16), children: [
            _FilterChip(label: 'All notes', selected: _folderId == null, onTap: () => setState(() { _folderId = null; _refresh(); })),
            ...folders.map((folder) => _FilterChip(label: folder['name'] as String, selected: _folderId == folder['id'], onTap: () => setState(() { _folderId = folder['id'] as int; _refresh(); }))),
          ]);
        },
      )),
      Padding(padding: const EdgeInsets.fromLTRB(16, 6, 16, 8), child: Row(children: [
        Expanded(child: FutureBuilder<List<Map<String, Object?>>>(
          future: _tags, builder: (context, snapshot) {
            final tags = snapshot.data ?? [];
            return DropdownButtonFormField<int?>(
              initialValue: _tagId, isExpanded: true, decoration: const InputDecoration(labelText: 'Filter by tag', contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
              items: [const DropdownMenuItem<int?>(value: null, child: Text('Every tag')), ...tags.map((tag) => DropdownMenuItem<int?>(value: tag['id'] as int, child: Text('#${tag['name']}')))],
              onChanged: (value) => setState(() { _tagId = value; _refresh(); }),
            );
          },
        )),
        const SizedBox(width: 8),
        FilterChip(label: const Text('Pinned'), selected: _pinnedOnly, onSelected: (value) => setState(() { _pinnedOnly = value; _refresh(); })),
      ])),
      Expanded(child: FutureBuilder<List<Map<String, Object?>>>(
        future: _notes, builder: (context, snapshot) {
          if (snapshot.hasError) return Center(child: Text('Could not load your vault: ${snapshot.error}'));
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final notes = snapshot.data!;
          if (notes.isEmpty) return _BrainEmpty(archived: _archived, search: _search.text.isNotEmpty, onCapture: () => _editNote());
          return RefreshIndicator(onRefresh: _reload, child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 100), itemCount: notes.length,
            separatorBuilder: (_, __) => const SizedBox(height: 9),
            itemBuilder: (context, index) {
              final row = notes[index];
              final note = Idea.fromMap(row);
              final tagNames = (row['tag_names'] as String? ?? '').split(',').where((v) => v.isNotEmpty).toList();
              final folder = row['folder_name'] as String?;
              final count = row['attachment_count'] as int? ?? 0;
              return Card(child: InkWell(
                borderRadius: BorderRadius.circular(18), onTap: () => _openNote(note),
                child: Padding(padding: const EdgeInsets.fromLTRB(15, 13, 8, 13), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Expanded(child: Text(note.title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15), maxLines: 2, overflow: TextOverflow.ellipsis)),
                    if (note.isPinned) const Padding(padding: EdgeInsets.only(right: 4), child: Icon(Icons.push_pin, size: 17, color: Color(0xFF315FE7))),
                    PopupMenuButton<String>(onSelected: (action) async {
                      if (action == 'edit') await _editNote(note);
                      if (action == 'pin') { await widget.repository.setIdeaPinned(note.id, !note.isPinned); await _reload(); }
                      if (action == 'archive') await _toggleArchive(note);
                      if (action == 'attach') await _manageAttachments(note.id);
                      if (action == 'delete') {
                        final paths = await widget.repository.getIdeaAttachments(note.id);
                        await widget.repository.deleteIdea(note.id);
                        for (final path in paths) { await BrainAttachmentService.instance.deletePrivateCopy(path['stored_path'] as String); }
                        await _reload();
                      }
                    }, itemBuilder: (_) => [
                      const PopupMenuItem(value: 'edit', child: Text('Edit')),
                      PopupMenuItem(value: 'pin', child: Text(note.isPinned ? 'Unpin' : 'Pin')),
                      const PopupMenuItem(value: 'attach', child: Text('Add attachments')),
                      PopupMenuItem(value: 'archive', child: Text(_archived ? 'Restore' : 'Archive')),
                      const PopupMenuItem(value: 'delete', child: Text('Delete permanently')),
                    ]),
                  ]),
                  if (note.body.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 4), child: Text(note.body, maxLines: 3, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Color(0xFF667287), height: 1.4))),
                  const SizedBox(height: 9),
                  Wrap(spacing: 6, runSpacing: 6, children: [
                    if (folder != null) _MetaPill(icon: Icons.folder_outlined, label: folder),
                    if (count > 0) _MetaPill(icon: Icons.attach_file, label: '$count files'),
                    ...tagNames.take(4).map((tag) => _MetaPill(icon: Icons.tag, label: tag)),
                  ]),
                ])),
              ));
            },
          ));
        },
      )),
    ]),
  );
}

class _BrainDraft {
  const _BrainDraft(this.title, this.body, this.tags, this.folderId, this.pinned);
  final String title, body, tags;
  final int? folderId;
  final bool pinned;
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({required this.label, required this.selected, required this.onTap});
  final String label; final bool selected; final VoidCallback onTap;
  @override Widget build(BuildContext context) => Padding(padding: const EdgeInsets.only(right: 7), child: ChoiceChip(label: Text(label), selected: selected, onSelected: (_) => onTap()));
}

class _MetaPill extends StatelessWidget {
  const _MetaPill({required this.icon, required this.label});
  final IconData icon; final String label;
  @override Widget build(BuildContext context) => Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5), decoration: BoxDecoration(color: const Color(0xFFF0F3FA), borderRadius: BorderRadius.circular(20)), child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(icon, size: 12, color: const Color(0xFF64728A)), const SizedBox(width: 4), Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF526078)))]));
}

class _BrainEmpty extends StatelessWidget {
  const _BrainEmpty({required this.archived, required this.search, required this.onCapture});
  final bool archived, search; final VoidCallback onCapture;
  @override Widget build(BuildContext context) => Center(child: Padding(padding: const EdgeInsets.all(28), child: Column(mainAxisSize: MainAxisSize.min, children: [
    const Icon(Icons.auto_awesome_mosaic_outlined, size: 48, color: Color(0xFF4567D7)),
    const SizedBox(height: 12),
    Text(search ? 'No matching notes' : archived ? 'Your archive is clear' : 'Build your second brain', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
    const SizedBox(height: 6),
    Text(search ? 'Try another search term or clear your filters.' : 'Save knowledge, research, plans and ideas in one private place.', textAlign: TextAlign.center, style: const TextStyle(color: Colors.black54)),
    if (!archived && !search) Padding(padding: const EdgeInsets.only(top: 14), child: FilledButton.icon(onPressed: onCapture, icon: const Icon(Icons.add), label: const Text('Capture your first note'))),
  ])));
}
