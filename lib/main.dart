import 'package:flutter/material.dart';

import 'models/idea.dart';
import 'models/life_task.dart';
import 'repositories/lifeos_repository.dart';

void main() => runApp(const LifeOsApp());

class LifeOsApp extends StatelessWidget {
  const LifeOsApp({super.key});

  @override
  Widget build(BuildContext context) {
    const seed = Color(0xFF4567D7);
    return MaterialApp(
      title: 'LifeOS',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: seed),
        scaffoldBackgroundColor: const Color(0xFFF7F8FC),
        cardTheme: const CardThemeData(elevation: 0, margin: EdgeInsets.zero),
        inputDecorationTheme: const InputDecorationTheme(border: OutlineInputBorder()),
      ),
      home: const LifeOsShell(),
    );
  }
}

class LifeOsShell extends StatefulWidget {
  const LifeOsShell({super.key});

  @override
  State<LifeOsShell> createState() => _LifeOsShellState();
}

class _LifeOsShellState extends State<LifeOsShell> {
  int _index = 0;
  final _homeKey = GlobalKey<_HomeScreenState>();
  final _repository = LifeosRepository();

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      HomeScreen(key: _homeKey, repository: _repository, onNavigate: (index) => setState(() => _index = index)),
      TasksScreen(repository: _repository),
      IdeasScreen(repository: _repository),
      CalendarScreen(repository: _repository),
    ];
    return Scaffold(
      body: SafeArea(child: IndexedStack(index: _index, children: pages)),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (value) {
          setState(() => _index = value);
          if (value == 0) _homeKey.currentState?.refreshData();
        },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.space_dashboard_outlined), selectedIcon: Icon(Icons.space_dashboard), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.checklist_outlined), selectedIcon: Icon(Icons.checklist), label: 'Tasks'),
          NavigationDestination(icon: Icon(Icons.lightbulb_outline), selectedIcon: Icon(Icons.lightbulb), label: 'Ideas'),
          NavigationDestination(icon: Icon(Icons.calendar_month_outlined), selectedIcon: Icon(Icons.calendar_month), label: 'Calendar'),
        ],
      ),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.repository, required this.onNavigate});
  final LifeosRepository repository;
  final ValueChanged<int> onNavigate;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<Map<String, int>> _summary;
  late Future<List<LifeTask>> _tasks;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _summary = widget.repository.getTaskSummary();
    _tasks = widget.repository.getTasks();
  }

  Future<void> refreshData() async {
    setState(_load);
  }

  @override
  Widget build(BuildContext context) {
    final hour = DateTime.now().hour;
    final greeting = hour < 12 ? 'Good morning' : hour < 17 ? 'Good afternoon' : 'Good evening';
    return RefreshIndicator(
      onRefresh: refreshData,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 22, 20, 28),
        children: [
          Text(greeting, style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.black54)),
          const SizedBox(height: 4),
          Text('Make today count.', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 20),
          FutureBuilder<Map<String, int>>(
            future: _summary,
            builder: (context, snapshot) {
              final data = snapshot.data ?? const {'total': 0, 'completed': 0, 'open': 0};
              return Row(children: [
                Expanded(child: _StatCard(label: 'Open tasks', value: '${data['open']}', icon: Icons.radio_button_unchecked)),
                const SizedBox(width: 10),
                Expanded(child: _StatCard(label: 'Completed', value: '${data['completed']}', icon: Icons.task_alt)),
              ]);
            },
          ),
          const SizedBox(height: 22),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('Today’s focus', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            TextButton(onPressed: () => widget.onNavigate(1), child: const Text('All tasks')),
          ]),
          FutureBuilder<List<LifeTask>>(
            future: _tasks,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) return const Padding(padding: EdgeInsets.all(24), child: Center(child: CircularProgressIndicator()));
              final tasks = (snapshot.data ?? []).where((task) => !task.isComplete).take(4).toList();
              if (tasks.isEmpty) return const _EmptyState(icon: Icons.celebration_outlined, title: 'A clear space to begin', message: 'Add a task to give today a direction.');
              return Column(children: tasks.map((task) => Card(
                child: ListTile(
                  leading: const Icon(Icons.circle_outlined),
                  title: Text(task.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                  subtitle: task.notes.isEmpty ? null : Text(task.notes, maxLines: 1, overflow: TextOverflow.ellipsis),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => widget.onNavigate(1),
                ),
              )).toList());
            },
          ),
          const SizedBox(height: 20),
          Text('Quick capture', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(child: _QuickAction(icon: Icons.add_task, label: 'New task', onTap: () => widget.onNavigate(1))),
            const SizedBox(width: 10),
            Expanded(child: _QuickAction(icon: Icons.lightbulb_outline, label: 'Capture idea', onTap: () => widget.onNavigate(2))),
          ]),
          const SizedBox(height: 22),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Icon(Icons.auto_awesome_outlined, size: 28),
                const SizedBox(width: 12),
                const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Your personal command center', style: TextStyle(fontWeight: FontWeight.bold)),
                  SizedBox(height: 4),
                  Text('Capture ideas quickly, plan your work, and build a record of what you accomplish. More insights and AI tools will arrive in later phases.'),
                ])),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key, required this.repository});
  final LifeosRepository repository;
  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  final _searchController = TextEditingController();
  bool _showArchived = false;
  late Future<List<LifeTask>> _future;

  @override
  void initState() { super.initState(); _load(); }
  @override
  void dispose() { _searchController.dispose(); super.dispose(); }
  void _load() => _future = widget.repository.getTasks(query: _searchController.text, includeArchived: _showArchived);
  Future<void> _refresh() async { setState(_load); await _future; }

  Future<void> _editTask([LifeTask? task]) async {
    final result = await showDialog<_TaskDraft>(context: context, builder: (_) => _TaskDialog(task: task));
    if (result == null) return;
    try {
      await widget.repository.saveTask(id: task?.id, title: result.title, notes: result.notes, dueAt: result.dueAt);
      if (mounted) { setState(_load); _message(task == null ? 'Task added' : 'Task updated'); }
    } catch (error) { if (mounted) _message(error.toString()); }
  }

  void _message(String message) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));

  Future<void> _delete(LifeTask task) async {
    final confirm = await showDialog<bool>(context: context, builder: (context) => AlertDialog(
      title: const Text('Delete task?'), content: Text('“${task.title}” will be permanently deleted.'),
      actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')), FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete'))],
    ));
    if (confirm != true) return;
    await widget.repository.deleteTask(task.id);
    if (mounted) setState(_load);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Tasks'), actions: [
      IconButton(tooltip: _showArchived ? 'Show active tasks' : 'Show archived tasks', onPressed: () => setState(() { _showArchived = !_showArchived; _load(); }), icon: Icon(_showArchived ? Icons.inventory_2 : Icons.archive_outlined)),
    ]),
    floatingActionButton: FloatingActionButton.extended(onPressed: () => _editTask(), icon: const Icon(Icons.add), label: const Text('New task')),
    body: Column(children: [
      Padding(padding: const EdgeInsets.fromLTRB(16, 4, 16, 12), child: TextField(
        controller: _searchController, onChanged: (_) => setState(_load),
        decoration: InputDecoration(hintText: 'Search tasks', prefixIcon: const Icon(Icons.search), suffixIcon: _searchController.text.isEmpty ? null : IconButton(icon: const Icon(Icons.clear), onPressed: () { _searchController.clear(); setState(_load); }), filled: true, fillColor: Colors.white,
      ))),
      Expanded(child: FutureBuilder<List<LifeTask>>(future: _future, builder: (context, snapshot) {
        if (snapshot.hasError) return Center(child: Text('Could not load tasks: ${snapshot.error}'));
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final tasks = snapshot.data!;
        if (tasks.isEmpty) return _EmptyState(icon: Icons.checklist, title: _showArchived ? 'No archived tasks' : 'No tasks yet', message: _showArchived ? 'Archived tasks will appear here.' : 'Create your first task to get started.');
        return RefreshIndicator(onRefresh: _refresh, child: ListView.separated(padding: const EdgeInsets.fromLTRB(16, 0, 16, 90), itemCount: tasks.length, separatorBuilder: (_, __) => const SizedBox(height: 8), itemBuilder: (context, index) {
          final task = tasks[index];
          return Card(child: ListTile(
            leading: _showArchived ? const Icon(Icons.archive_outlined) : Checkbox(value: task.isComplete, onChanged: (value) async { await widget.repository.setTaskComplete(task.id, value ?? false); if (mounted) setState(_load); }),
            title: Text(task.title, style: TextStyle(decoration: task.isComplete ? TextDecoration.lineThrough : null), maxLines: 2, overflow: TextOverflow.ellipsis),
            subtitle: task.notes.isEmpty ? null : Text(task.notes, maxLines: 2, overflow: TextOverflow.ellipsis),
            trailing: PopupMenuButton<String>(onSelected: (action) async {
              if (action == 'edit') await _editTask(task);
              if (action == 'archive') { await widget.repository.archiveTask(task.id, !_showArchived); if (mounted) setState(_load); }
              if (action == 'delete') await _delete(task);
            }, itemBuilder: (_) => [
              if (!_showArchived) const PopupMenuItem(value: 'edit', child: Text('Edit')),
              PopupMenuItem(value: 'archive', child: Text(_showArchived ? 'Restore' : 'Archive')),
              const PopupMenuItem(value: 'delete', child: Text('Delete')),
            ]),
          ));
        }));
      })),
    ]),
  );
}

class IdeasScreen extends StatefulWidget {
  const IdeasScreen({super.key, required this.repository});
  final LifeosRepository repository;
  @override
  State<IdeasScreen> createState() => _IdeasScreenState();
}

class _IdeasScreenState extends State<IdeasScreen> {
  final _searchController = TextEditingController();
  bool _showArchived = false;
  late Future<List<Idea>> _future;
  @override
  void initState() { super.initState(); _load(); }
  @override
  void dispose() { _searchController.dispose(); super.dispose(); }
  void _load() => _future = widget.repository.getIdeas(query: _searchController.text, includeArchived: _showArchived);

  Future<void> _editIdea([Idea? idea]) async {
    final titleController = TextEditingController(text: idea?.title ?? '');
    final bodyController = TextEditingController(text: idea?.body ?? '');
    final result = await showDialog<bool>(context: context, builder: (context) => AlertDialog(
      title: Text(idea == null ? 'Capture an idea' : 'Edit idea'),
      content: SizedBox(width: 420, child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: titleController, autofocus: true, textCapitalization: TextCapitalization.sentences, decoration: const InputDecoration(labelText: 'Title', hintText: 'What is the idea?')),
        const SizedBox(height: 12), TextField(controller: bodyController, minLines: 3, maxLines: 6, textCapitalization: TextCapitalization.sentences, decoration: const InputDecoration(labelText: 'Details', hintText: 'Add context or next steps')),
      ]))),
      actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')), FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Save'))],
    ));
    if (result == true) {
      try {
        await widget.repository.saveIdea(id: idea?.id, title: titleController.text, body: bodyController.text);
        if (mounted) { setState(_load); _message(idea == null ? 'Idea captured' : 'Idea updated'); }
      } catch (error) { if (mounted) _message(error.toString()); }
    }
    titleController.dispose(); bodyController.dispose();
  }

  void _message(String message) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Idea vault'), actions: [IconButton(tooltip: 'Toggle archive', onPressed: () => setState(() { _showArchived = !_showArchived; _load(); }), icon: Icon(_showArchived ? Icons.inventory_2 : Icons.archive_outlined))]),
    floatingActionButton: FloatingActionButton.extended(onPressed: () => _editIdea(), icon: const Icon(Icons.add), label: const Text('Capture idea')),
    body: Column(children: [
      Padding(padding: const EdgeInsets.fromLTRB(16, 4, 16, 12), child: TextField(controller: _searchController, onChanged: (_) => setState(_load), decoration: InputDecoration(hintText: 'Search ideas', prefixIcon: const Icon(Icons.search), filled: true, fillColor: Colors.white))),
      Expanded(child: FutureBuilder<List<Idea>>(future: _future, builder: (context, snapshot) {
        if (snapshot.hasError) return Center(child: Text('Could not load ideas: ${snapshot.error}'));
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final ideas = snapshot.data!;
        if (ideas.isEmpty) return _EmptyState(icon: Icons.lightbulb_outline, title: 'Save the spark', message: 'Capture ideas before they disappear.');
        return ListView.separated(padding: const EdgeInsets.fromLTRB(16, 0, 16, 90), itemCount: ideas.length, separatorBuilder: (_, __) => const SizedBox(height: 8), itemBuilder: (context, index) {
          final idea = ideas[index];
          return Card(child: ListTile(
            leading: const CircleAvatar(child: Icon(Icons.lightbulb_outline)),
            title: Text(idea.title, maxLines: 2, overflow: TextOverflow.ellipsis),
            subtitle: idea.body.isEmpty ? null : Text(idea.body, maxLines: 3, overflow: TextOverflow.ellipsis),
            onTap: () => _editIdea(idea),
            trailing: PopupMenuButton<String>(onSelected: (action) async {
              if (action == 'edit') await _editIdea(idea);
              if (action == 'archive') { await widget.repository.archiveIdea(idea.id, !_showArchived); if (mounted) setState(_load); }
              if (action == 'delete') { await widget.repository.deleteIdea(idea.id); if (mounted) setState(_load); }
            }, itemBuilder: (_) => [
              const PopupMenuItem(value: 'edit', child: Text('Edit')),
              PopupMenuItem(value: 'archive', child: Text(_showArchived ? 'Restore' : 'Archive')),
              const PopupMenuItem(value: 'delete', child: Text('Delete')),
            ]),
          ));
        });
      })),
    ]),
  );
}

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key, required this.repository});
  final LifeosRepository repository;
  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  late Future<List<Map<String, Object?>>> _future;
  @override
  void initState() { super.initState(); _load(); }
  void _load() => _future = widget.repository.getEvents();

  Future<void> _addEvent() async {
    final title = TextEditingController();
    final notes = TextEditingController();
    DateTime startsAt = DateTime.now().add(const Duration(hours: 1));
    String recurrence = 'none';
    final result = await showDialog<bool>(context: context, builder: (context) => StatefulBuilder(builder: (context, setDialogState) => AlertDialog(
      title: const Text('New appointment'),
      content: SizedBox(width: 420, child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: title, autofocus: true, decoration: const InputDecoration(labelText: 'Title')),
        const SizedBox(height: 12), TextField(controller: notes, minLines: 2, maxLines: 4, decoration: const InputDecoration(labelText: 'Notes')),
        const SizedBox(height: 12), ListTile(contentPadding: EdgeInsets.zero, leading: const Icon(Icons.event), title: const Text('Starts'), subtitle: Text('${startsAt.day}/${startsAt.month}/${startsAt.year} ${startsAt.hour.toString().padLeft(2, '0')}:${startsAt.minute.toString().padLeft(2, '0')}'), onTap: () async {
          final date = await showDatePicker(context: context, initialDate: startsAt, firstDate: DateTime(2020), lastDate: DateTime(2100));
          if (date == null || !context.mounted) return;
          final time = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(startsAt));
          if (time == null) return;
          setDialogState(() => startsAt = DateTime(date.year, date.month, date.day, time.hour, time.minute));
        }),
        DropdownButtonFormField<String>(value: recurrence, decoration: const InputDecoration(labelText: 'Repeat'), items: const [DropdownMenuItem(value: 'none', child: Text('Does not repeat')), DropdownMenuItem(value: 'daily', child: Text('Daily')), DropdownMenuItem(value: 'weekly', child: Text('Weekly')), DropdownMenuItem(value: 'monthly', child: Text('Monthly'))], onChanged: (value) => setDialogState(() => recurrence = value ?? 'none')),
      ]))),
      actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')), FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Save'))],
    )));
    if (result == true) {
      try {
        await widget.repository.saveEvent(title: title.text, notes: notes.text, startsAt: startsAt, recurrenceRule: recurrence == 'none' ? null : recurrence);
        if (mounted) { setState(_load); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Appointment saved'))); }
      } catch (error) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.toString()))); }
    }
    title.dispose(); notes.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Calendar')),
    floatingActionButton: FloatingActionButton.extended(onPressed: _addEvent, icon: const Icon(Icons.add), label: const Text('Appointment')),
    body: FutureBuilder<List<Map<String, Object?>>>(future: _future, builder: (context, snapshot) {
      if (snapshot.hasError) return Center(child: Text('Could not load appointments: ${snapshot.error}'));
      if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
      final events = snapshot.data!;
      if (events.isEmpty) return const _EmptyState(icon: Icons.calendar_month_outlined, title: 'Make room for what matters', message: 'Add an appointment or schedule an event.');
      return ListView.separated(padding: const EdgeInsets.fromLTRB(16, 8, 16, 90), itemCount: events.length, separatorBuilder: (_, __) => const SizedBox(height: 8), itemBuilder: (context, index) {
        final event = events[index];
        final starts = DateTime.fromMillisecondsSinceEpoch(event['starts_at'] as int);
        final repeat = event['recurrence_rule'] as String?;
        return Card(child: ListTile(leading: const Icon(Icons.event_available_outlined), title: Text(event['title'] as String), subtitle: Text('${starts.day}/${starts.month}/${starts.year} · ${starts.hour.toString().padLeft(2, '0')}:${starts.minute.toString().padLeft(2, '0')}${repeat == null ? '' : ' · Repeats $repeat'}')));
      });
    }),
  );
}

class _TaskDraft {
  const _TaskDraft(this.title, this.notes, this.dueAt);
  final String title;
  final String notes;
  final DateTime? dueAt;
}

class _TaskDialog extends StatefulWidget {
  const _TaskDialog({this.task});
  final LifeTask? task;
  @override
  State<_TaskDialog> createState() => _TaskDialogState();
}

class _TaskDialogState extends State<_TaskDialog> {
  late final TextEditingController _title;
  late final TextEditingController _notes;
  DateTime? _dueAt;
  @override
  void initState() { super.initState(); _title = TextEditingController(text: widget.task?.title ?? ''); _notes = TextEditingController(text: widget.task?.notes ?? ''); _dueAt = widget.task?.dueAt; }
  @override
  void dispose() { _title.dispose(); _notes.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(widget.task == null ? 'New task' : 'Edit task'),
    content: SizedBox(width: 420, child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
      TextField(controller: _title, autofocus: true, textCapitalization: TextCapitalization.sentences, decoration: const InputDecoration(labelText: 'Task title', hintText: 'What needs to get done?')),
      const SizedBox(height: 12), TextField(controller: _notes, minLines: 2, maxLines: 4, textCapitalization: TextCapitalization.sentences, decoration: const InputDecoration(labelText: 'Notes (optional)')),
      const SizedBox(height: 12), Align(alignment: Alignment.centerLeft, child: Wrap(spacing: 8, crossAxisAlignment: WrapCrossAlignment.center, children: [
        OutlinedButton.icon(onPressed: () async { final picked = await showDatePicker(context: context, initialDate: _dueAt ?? DateTime.now(), firstDate: DateTime(2020), lastDate: DateTime(2100)); if (picked != null) setState(() => _dueAt = DateTime(picked.year, picked.month, picked.day)); }, icon: const Icon(Icons.calendar_today), label: Text(_dueAt == null ? 'Set due date' : '${_dueAt!.day}/${_dueAt!.month}/${_dueAt!.year}')),
        if (_dueAt != null) IconButton(tooltip: 'Clear due date', onPressed: () => setState(() => _dueAt = null), icon: const Icon(Icons.close)),
      ])),
    ]))),
    actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')), FilledButton(onPressed: () {
      if (_title.text.trim().isEmpty) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter a task title.'))); return; }
      Navigator.pop(context, _TaskDraft(_title.text, _notes.text, _dueAt));
    }, child: const Text('Save'))],
  );
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.label, required this.value, required this.icon});
  final String label; final String value; final IconData icon;
  @override
  Widget build(BuildContext context) => Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Icon(icon, size: 24), const SizedBox(height: 12), Text(value, style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)), Text(label, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.black54))])));
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({required this.icon, required this.label, required this.onTap});
  final IconData icon; final String label; final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Card(child: InkWell(borderRadius: BorderRadius.circular(16), onTap: onTap, child: Padding(padding: const EdgeInsets.all(16), child: Row(children: [Icon(icon), const SizedBox(width: 10), Expanded(child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)))]))));
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.icon, required this.title, required this.message});
  final IconData icon; final String title; final String message;
  @override
  Widget build(BuildContext context) => Center(child: Padding(padding: const EdgeInsets.all(32), child: Column(mainAxisSize: MainAxisSize.min, children: [Icon(icon, size: 48, color: Theme.of(context).colorScheme.primary), const SizedBox(height: 12), Text(title, textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)), const SizedBox(height: 6), Text(message, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.black54))])));
}
