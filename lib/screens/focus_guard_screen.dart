import 'dart:async';
import 'package:flutter/material.dart';
import '../models/focus_session.dart';
import '../repositories/lifeos_repository.dart';

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
        const Card(child: Padding(padding: EdgeInsets.all(17), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [Icon(Icons.shield_outlined, color: Color(0xFF315FE7)), SizedBox(width: 9), Text('App restrictions', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16))]),
          SizedBox(height: 8),
          Text('App usage monitoring and optional blocking are the next part of Focus Guard. This first release provides a focus timer and keeps session history on this device.', style: TextStyle(color: Color(0xFF6F7B8E), height: 1.45, fontSize: 13)),
        ]))),
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
