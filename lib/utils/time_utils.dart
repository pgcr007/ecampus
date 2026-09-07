/// Hand-rolled timestamp formatting so we don't need to add the `intl`
/// package just for chat/announcement timestamps.
class TimeUtils {
  TimeUtils._();

  static const _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  static String _clockTime(DateTime dt) {
    final hour = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final minute = dt.minute.toString().padLeft(2, '0');
    final period = dt.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }

  /// "10:32 AM" for today, "Yesterday", or "12 Sep" otherwise.
  static String chatTimestamp(DateTime? dt) {
    if (dt == null) return '';
    final now = DateTime.now();

    final isToday = dt.year == now.year && dt.month == now.month && dt.day == now.day;
    if (isToday) return _clockTime(dt);

    final yesterday = now.subtract(const Duration(days: 1));
    final isYesterday =
        dt.year == yesterday.year && dt.month == yesterday.month && dt.day == yesterday.day;
    if (isYesterday) return 'Yesterday';

    return '${dt.day} ${_months[dt.month - 1]}';
  }

  /// "12 Sep · 10:32 AM" — used on announcement cards.
  static String fullTimestamp(DateTime? dt) {
    if (dt == null) return '';
    return '${dt.day} ${_months[dt.month - 1]} · ${_clockTime(dt)}';
  }

  /// "Good morning" / "Good afternoon" / "Good evening" based on the
  /// device clock — used for the dashboard hero header.
  static String greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }
}