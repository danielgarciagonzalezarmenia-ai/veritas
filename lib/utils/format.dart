const List<String> _months = [
  'ene',
  'feb',
  'mar',
  'abr',
  'may',
  'jun',
  'jul',
  'ago',
  'sep',
  'oct',
  'nov',
  'dic',
];

String friendlyDay(DateTime date) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final target = DateTime(date.year, date.month, date.day);
  final difference = today.difference(target).inDays;
  if (difference == 0) return 'Hoy';
  if (difference == 1) return 'Ayer';
  if (difference < 7) return 'Hace $difference días';
  return '${date.day} ${_months[date.month - 1]}';
}

String clockTime(DateTime date) {
  final hour = date.hour.toString().padLeft(2, '0');
  final minute = date.minute.toString().padLeft(2, '0');
  return '$hour:$minute';
}

String friendlyDateTime(DateTime date) =>
    '${friendlyDay(date)}, ${clockTime(date)}';

String durationLabel(double seconds) {
  final total = seconds.round();
  final minutes = total ~/ 60;
  final rest = total % 60;
  if (minutes == 0) return '${rest}s';
  return '${minutes}m ${rest.toString().padLeft(2, '0')}s';
}

String percentLabel(double value, {int decimals = 0}) {
  return '${value.toStringAsFixed(decimals)}%';
}

String sensitivityLabel(double value) {
  if (value < 0.85) return 'Conservador';
  if (value < 1.15) return 'Equilibrado';
  if (value < 1.4) return 'Sensible';
  return 'Muy sensible';
}
