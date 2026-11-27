import 'dart:async';
import 'package:flutter/material.dart';
import '../models/focus_session.dart';
import '../repositories/lifeos_repository.dart';
import '../services/usage_stats_service.dart';

class FocusGuardScreen extends StatefulWidget {
  const FocusGuardScreen({super.key, required this.repository});
  final LifeosRepository repository;
  @override
  State<FocusGuardScreen> createState() => _FocusGuardScreenState();
}

class _FocusGuardScreenState extends State<FocusGuardScreen> {
  static const _presets = [15, 25, 45, 60, 90];
  int _minutes = 25, _remaining = 1500, _elapsed = 0;
  bool _running = false, _paused = false;
  DateTime? _startedAt;
  Timer? _ticker;
  late Future<List<FocusSession>> _history;

  @override
  void initState() { super.initState(); _history = widget.repository.getFocusSessions(); }
  @override
  void dispose() { _ticker?.cancel(); super.dispose(); }
  String _clock(int seconds) => '${(seconds ~/ 60).toString().padLeft(2, '0')}:${(seconds % 60).toString().padLeft(2, '0')}';

  void _selectDuration(int value) {
    if (_running || _paused) return;
    setState(() { _minutes = value; _remaining = value * 60; _elapsed = 0; });
  }

  void _start() {
    if (_running) return;
    setState(() { _running = true; _paused = false; _startedAt ??= DateTime.now(); });
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      if (_remaining <= 1) {
        _ticker?.cancel();
        setState(() { _remaining = 0; _elapsed = _minutes * 60; _running = false; _paused = false; });
        _saveSession('completed');
      } else { setState(() { _remaining--; _elapsed++; }); }
    });
  }

  void _pause() { _ticker?.cancel(); setState(() { _running = false; _paused = true; }); }

  Future<void> _finish() async {
    _ticker?.cancel();
    final started = _startedAt, elapsed = _elapsed;
    setState(() { _running = false; _paused = false; _startedAt = null; _elapsed = 0; _remaining = _minutes * 60; });
    if (started != null && elapsed > 0) {
      await widget.repository.saveFocusSession(startedAt: started, endedAt: DateTime.now(), plannedMinutes: _minutes, focusedSeconds: elapsed, status: 'stopped');
      if (mounted) setState(() => _history = widget.repository.getFocusSessions());
    }
  }

  Future<void> _saveSession(String status) async {
    final started = _startedAt;
    if (started == null) return;
    await widget.repository.saveFocusSession(startedAt: started, endedAt: DateTime.now(), plannedMinutes: _minutes, focusedSeconds: _elapsed, status: status);
    _startedAt = null;
    if (mounted) setState(() => _history = widget.repository.getFocusSessions());
  }

  @override
  Widget build(BuildContext context) {
    final progress = 1 - (_remaining / (_minutes * 60));
    return Scaffold(
      appBar: AppBar(title: const Text('Focus Guard')),
      body: ListView(padding: const EdgeInsets.fromLTRB(20, 8, 20, 28), children: [
        Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF263F91), Color(0xFF315FE7)], begin: Alignment.topLeft, end: Alignment.bottomRight), borderRadius: BorderRadius.circular(26)),
          child: Column(children: [
            const Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.center_focus_strong_rounded, color: Colors.white70, size: 18), SizedBox(width: 8), Text('PROTECT YOUR ATTENTION', style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.2))]),
            const SizedBox(height: 24),
            SizedBox(width: 210, height: 210, child: Stack(alignment: Alignment.center, children: [
              SizedBox.expand(child: CircularProgressIndicator(value: progress, strokeWidth: 10, backgroundColor: Colors.white24, valueColor: const AlwaysStoppedAnimation<Color>(Colors.white))),
              Column(mainAxisSize: MainAxisSize.min, children: [Text(_clock(_remaining), style: const TextStyle(color: Colors.white, fontSize: 48, fontWeight: FontWeight.w800, letterSpacing: -1.5)), Text(_running ? 'STAY IN THE FLOW' : _paused ? 'SESSION PAUSED' : 'MINUTES OF FOCUS', style: const TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1))]),
            ])),
            const SizedBox(height: 24),
            if (!_running && !_paused) Wrap(spacing: 8, children: _presets.map((value) => ChoiceChip(label: Text('$value min'), selected: _minutes == value, onSelected: (_) => _selectDuration(value), selectedColor: Colors.white, backgroundColor: Colors.white24, labelStyle: TextStyle(color: _minutes == value ? const Color(0xFF263F91) : Colors.white, fontWeight: FontWeight.w700), side: BorderSide.none)).toList()),
            const SizedBox(height: 18),
            Row(children: [
              Expanded(child: FilledButton.icon(onPressed: _running ? _pause : _start, icon: Icon(_running ? Icons.pause_rounded : Icons.play_arrow_rounded), label: Text(_running ? 'Pause' : _paused ? 'Resume focus' : 'Start focus'), style: FilledButton.styleFrom(backgroundColor: Colors.white, foregroundColor: const Color(0xFF263F91), padding: const EdgeInsets.symmetric(vertical: 14)))),
              if (_running || _paused) ...[const SizedBox(width: 10), OutlinedButton(onPressed: _finish, style: OutlinedButton.styleFrom(foregroundColor: Colors.white, side: const BorderSide(color: Colors.white70), padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 18)), child: const Text('End'))],
            ]),
          ]),
        ),
        const SizedBox(height: 20),
        const _UsageMonitorCard(),
        const SizedBox(height: 22),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Recent focus sessions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)), TextButton(onPressed: () => setState(() => _history = widget.repository.getFocusSessions()), child: const Text('Refresh'))]),
        FutureBuilder<List<FocusSession>>(future: _history, builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()));
          final sessions = snapshot.data ?? [];
          if (sessions.isEmpty) return const Padding(padding: EdgeInsets.symmetric(vertical: 18), child: Text('Your focus sessions will appear here.', style: TextStyle(color: Color(0xFF7B879A))));
          return Column(children: sessions.take(12).map((session) => Card(margin: const EdgeInsets.only(bottom: 8), child: ListTile(
            leading: CircleAvatar(backgroundColor: const Color(0xFFEAF0FF), child: Icon(session.status == 'completed' ? Icons.check_rounded : Icons.timer_outlined, color: const Color(0xFF315FE7))),
            title: Text('${session.focusedSeconds ~/ 60} min focused', style: const TextStyle(fontWeight: FontWeight.w700)),
            subtitle: Text('${session.startedAt.day}/${session.startedAt.month}/${session.startedAt.year} • ${session.plannedMinutes} min planned'),
            trailing: Text(session.status == 'completed' ? 'Done' : 'Ended', style: const TextStyle(fontSize: 11, color: Color(0xFF718096))),
          ))).toList());
        }),
      ]),
    );
  }
}

class _UsageMonitorCard extends StatefulWidget {
  const _UsageMonitorCard();
  @override
  State<_UsageMonitorCard> createState() => _UsageMonitorCardState();
}

class _UsageMonitorCardState extends State<_UsageMonitorCard> {
  bool _checking = true;
  bool _hasAccess = false;
  String? _error;
  List<AppUsageEntry> _apps = const [];

  @override
  void initState() { super.initState(); _refresh(); }

  Future<void> _refresh() async {
    setState(() { _checking = true; _error = null; });
    try {
      final access = await UsageStatsService.hasUsageAccess();
      final apps = access ? await UsageStatsService.getTodayUsage() : <AppUsageEntry>[];
      if (!mounted) return;
      setState(() { _hasAccess = access; _apps = apps; _checking = false; });
    } catch (error) {
      if (!mounted) return;
      setState(() { _error = 'Screen-time data is unavailable on this device right now.'; _checking = false; });
    }
  }

  String _duration(Duration value) {
    final hours = value.inHours;
    final minutes = value.inMinutes.remainder(60);
    return hours > 0 ? '${hours}h ${minutes}m' : '${minutes}m';
  }

  @override
  Widget build(BuildContext context) {
    final total = _apps.fold<int>(0, (sum, app) => sum + app.foregroundMillis);
    return Card(child: Padding(padding: const EdgeInsets.all(17), child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          const Icon(Icons.phone_android_rounded, color: Color(0xFF315FE7)),
          const SizedBox(width: 9),
          const Expanded(child: Text('Screen-time monitor', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16))),
          IconButton(tooltip: 'Refresh usage', onPressed: _checking ? null : _refresh, icon: const Icon(Icons.refresh_rounded)),
        ]),
        const SizedBox(height: 6),
        const Text('Usage is read from Android on this device. LifeOS does not upload app activity.', style: TextStyle(color: Color(0xFF6F7B8E), height: 1.4, fontSize: 12)),
        const SizedBox(height: 14),
        if (_checking) const Center(child: Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator()))
        else if (!_hasAccess) ...[
          const Text('Allow Usage Access to see today’s device screen time and the apps you use most.', style: TextStyle(height: 1.4)),
          const SizedBox(height: 12),
          SizedBox(width: double.infinity, child: FilledButton.icon(
            onPressed: () async {
              await UsageStatsService.openUsageAccessSettings();
              if (mounted) await _refresh();
            },
            icon: const Icon(Icons.settings_outlined), label: const Text('Grant Usage Access'),
          )),
          const SizedBox(height: 5),
          const Text('Android will open its system settings. Find LifeOS and enable “Permit usage access”. Return here and refresh.', style: TextStyle(fontSize: 11, color: Color(0xFF718096))),
        ] else ...[
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const Text('TODAY’S RECORDED USAGE', style: TextStyle(fontSize: 10, letterSpacing: 1, fontWeight: FontWeight.w800, color: Color(0xFF718096))),
            Text(_duration(Duration(milliseconds: total)), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Color(0xFF263F91))),
          ]),
          const SizedBox(height: 12),
          if (_apps.isEmpty) const Text('No app activity has been recorded yet today.', style: TextStyle(color: Color(0xFF718096)))
          else ..._apps.take(8).map((app) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(children: [
              const Icon(Icons.apps_rounded, size: 18, color: Color(0xFF718096)),
              const SizedBox(width: 10),
              Expanded(child: Text(app.appName, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600))),
              Text(_duration(app.duration), style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
            ]),
          )),
          const SizedBox(height: 8),
          TextButton.icon(onPressed: () async { await UsageStatsService.openUsageAccessSettings(); }, icon: const Icon(Icons.tune_rounded, size: 17), label: const Text('Manage Android permission')),
        ],
        if (_error != null) Padding(padding: const EdgeInsets.only(top: 8), child: Text(_error!, style: const TextStyle(color: Colors.red, fontSize: 12))),
      ],
    )));
  }
}

