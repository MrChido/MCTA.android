int parseCustomTimeFormat(String text) {
  if (text.isEmpty) return -1;

  try {
    // Normalize and split: '10.00PM' → '10:00 PM'
    String normalized = text.replaceAll('.', ':').toUpperCase();
    RegExp timeRegex = RegExp(r'^(\d{1,2}):?(\d{0,2})\s*(AM|PM)$');
    Match? match = timeRegex.firstMatch(normalized);

    if (match == null) return -1;

    int hour = int.parse(match.group(1)!);
    int minute =
        match.group(2)?.isNotEmpty == true ? int.parse(match.group(2)!) : 0;
    String meridian = match.group(3)!;

    if (meridian == 'PM' && hour < 12) hour += 12;
    if (meridian == 'AM' && hour == 12) hour = 0;

    return hour * 60 + minute;
  } catch (_) {
    return -1;
  }
}
