class DateFormatter {
  DateFormatter._();

  /// Formata strings ISO-8601 (ex: 2026-09-22T11:00:00.000000Z) para '22/09 às 11:00'
  static String formatDateTime(String? iso) {
    if (iso == null || iso.trim().isEmpty) return '';
    try {
      final dt = DateTime.parse(iso).toLocal();
      final day = dt.day.toString().padLeft(2, '0');
      final month = dt.month.toString().padLeft(2, '0');
      final hour = dt.hour.toString().padLeft(2, '0');
      final minute = dt.minute.toString().padLeft(2, '0');
      return '$day/$month às $hour:$minute';
    } catch (_) {
      return iso;
    }
  }

  /// Formata strings ISO-8601 para '22/09/2026 às 11:00'
  static String formatFullDateTime(String? iso) {
    if (iso == null || iso.trim().isEmpty) return '';
    try {
      final dt = DateTime.parse(iso).toLocal();
      final day = dt.day.toString().padLeft(2, '0');
      final month = dt.month.toString().padLeft(2, '0');
      final year = dt.year.toString();
      final hour = dt.hour.toString().padLeft(2, '0');
      final minute = dt.minute.toString().padLeft(2, '0');
      return '$day/$month/$year às $hour:$minute';
    } catch (_) {
      return iso;
    }
  }

  /// Formata strings ISO-8601 para '22/09/2026'
  static String formatDate(String? iso) {
    if (iso == null || iso.trim().isEmpty) return '';
    try {
      final dt = DateTime.parse(iso).toLocal();
      final day = dt.day.toString().padLeft(2, '0');
      final month = dt.month.toString().padLeft(2, '0');
      final year = dt.year.toString();
      return '$day/$month/$year';
    } catch (_) {
      return iso;
    }
  }
}
