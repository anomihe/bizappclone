const _months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
const _fullMonths = [
  'January', 'February', 'March', 'April', 'May', 'June',
  'July', 'August', 'September', 'October', 'November', 'December',
];
const _weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

class Fmt {
  static String monthShort(int m) => _months[m - 1];
  static String monthFull(int m) => _fullMonths[m - 1];
  static String weekday(int w) => _weekdays[w - 1];

  /// 37000 -> "37,000"
  static String thousands(num value) {
    final s = value.abs().truncate().toString();
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
      buf.write(s[i]);
    }
    return (value < 0 ? '-' : '') + buf.toString();
  }

  /// 37000 -> "₦37,000.00"
  static String money(num value) {
    final cents = ((value.abs() * 100).round() % 100).toString().padLeft(2, '0');
    return '${value < 0 ? '-' : ''}₦${thousands(value.abs())}.$cents';
  }

  /// Splits into ("₦37,000", ".00") so the decimals can be rendered lighter.
  static (String, String) moneyParts(num value) {
    final m = money(value);
    final dot = m.lastIndexOf('.');
    return (m.substring(0, dot), m.substring(dot));
  }

  /// "17 Nov 2026"
  static String date(DateTime d) => '${d.day} ${monthShort(d.month)} ${d.year}';

  /// "dd/mm/yyyy"
  static String dateNumeric(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  /// "Jul 05 2026 | 10:34AM"
  static String dateTime(DateTime d) =>
      '${monthShort(d.month)} ${d.day.toString().padLeft(2, '0')} ${d.year} | ${time(d)}';

  /// "10:34AM"
  static String time(DateTime d) {
    final h = d.hour % 12 == 0 ? 12 : d.hour % 12;
    return '${h.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}${d.hour < 12 ? 'AM' : 'PM'}';
  }

  /// "Today, 11:02" / "Yesterday, 09:10" / "12 Nov, 09:10"
  static String relativeDay(DateTime d) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(d.year, d.month, d.day);
    final hm = '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
    final diff = today.difference(day).inDays;
    if (diff == 0) return 'Today, $hm';
    if (diff == 1) return 'Yesterday, $hm';
    return '${d.day} ${monthShort(d.month)}, $hm';
  }

  /// "2hrs ago"
  static String ago(DateTime d) {
    final diff = DateTime.now().difference(d);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}hrs ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return date(d);
  }

  /// "Sun, Aug 8"
  static String dayHeader(DateTime d) => '${weekday(d.weekday)}, ${monthShort(d.month)} ${d.day}';

  /// "AO" from "Ada Obi"
  static String initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+')).where((s) => s.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts[0][0] + parts[1][0]).toUpperCase();
  }

  /// "+234 ****** 484"
  static String maskPhone(String dial, String number) {
    final digits = number.replaceAll(RegExp(r'\D'), '');
    if (digits.length < 4) return '$dial $digits';
    return '$dial ****** ${digits.substring(digits.length - 3)}';
  }

  static bool isEmail(String v) => RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v.trim());
}
