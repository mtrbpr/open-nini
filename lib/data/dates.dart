import 'package:shamsi_date/shamsi_date.dart';

/// Ninisite prints `datepublished` as a US clock time, for example
/// `10/5/2026 10:11:18 AM` (month/day/year).
DateTime? parseNiniDate(String? raw) {
  if (raw == null) return null;
  final match = RegExp(
    r'^(\d{1,2})/(\d{1,2})/(\d{4})\s+(\d{1,2}):(\d{2}):(\d{2})\s*(AM|PM)$',
    caseSensitive: false,
  ).firstMatch(raw.trim());
  if (match == null) return null;

  var hour = int.parse(match.group(4)!);
  final ampm = match.group(7)!.toUpperCase();
  if (ampm == 'PM' && hour != 12) hour += 12;
  if (ampm == 'AM' && hour == 12) hour = 0;

  return DateTime(
    int.parse(match.group(3)!),
    int.parse(match.group(1)!),
    int.parse(match.group(2)!),
    hour,
    int.parse(match.group(5)!),
    int.parse(match.group(6)!),
  );
}

String formatPostDate(DateTime published, {DateTime? now}) {
  final clock = now ?? DateTime.now();
  final time =
      '${published.hour.toString().padLeft(2, '0')}:${published.minute.toString().padLeft(2, '0')}';
  if (_sameJalaliDay(published, clock)) return 'امروز $time';
  if (_sameJalaliDay(published, clock.subtract(const Duration(days: 1)))) {
    return 'دیروز $time';
  }
  final jalali = Jalali.fromDateTime(published);
  final month = jalali.month.toString().padLeft(2, '0');
  final day = jalali.day.toString().padLeft(2, '0');
  return '${jalali.year}/$month/$day $time';
}

String? joinWhen(String? date, String? time) {
  final parts = [date, time]
      .whereType<String>()
      .map((part) => part.trim())
      .where((part) => part.isNotEmpty);
  final text = parts.join(' ');
  return text.isEmpty ? null : text;
}

String displayPostDate(DateTime? published, String? dateLabel, String? timeLabel, {DateTime? now}) {
  if (published != null) return formatPostDate(published, now: now);
  return joinWhen(dateLabel, timeLabel) ?? '';
}

bool _sameJalaliDay(DateTime a, DateTime b) {
  final left = Jalali.fromDateTime(a);
  final right = Jalali.fromDateTime(b);
  return left.year == right.year && left.month == right.month && left.day == right.day;
}
