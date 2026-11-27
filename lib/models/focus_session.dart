class FocusSession {
  const FocusSession({required this.id, required this.startedAt, required this.endedAt, required this.plannedMinutes, required this.focusedSeconds, required this.status});
  final int id; final DateTime startedAt; final DateTime? endedAt; final int plannedMinutes; final int focusedSeconds; final String status;
  factory FocusSession.fromMap(Map<String, Object?> map) => FocusSession(id: map['id'] as int, startedAt: DateTime.fromMillisecondsSinceEpoch(map['started_at'] as int), endedAt: map['ended_at'] == null ? null : DateTime.fromMillisecondsSinceEpoch(map['ended_at'] as int), plannedMinutes: map['planned_minutes'] as int, focusedSeconds: map['focused_seconds'] as int, status: map['status'] as String);
  Duration get duration => Duration(seconds: focusedSeconds);
}
