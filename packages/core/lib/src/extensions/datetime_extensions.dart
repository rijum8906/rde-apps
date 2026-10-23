/// Calendar helpers for [DateTime].
extension DateTimeX on DateTime {
  /// Midnight at the start of this day, preserving the local time zone.
  DateTime get startOfDay => DateTime(year, month, day);

  /// The last representable instant of this day.
  DateTime get endOfDay => DateTime(year, month, day, 23, 59, 59, 999, 999);

  /// Whether [other] falls on the same calendar day as this value.
  bool isSameDayAs(DateTime other) =>
      year == other.year && month == other.month && day == other.day;

  /// Whether this value falls on the current calendar day.
  bool get isToday => isSameDayAs(DateTime.now());

  /// The number of days in the month that contains this value.
  ///
  /// Handles leap years correctly.
  int get daysInMonth => DateTime(year, month + 1, 0).day;

  /// A new value shifted by [days], keeping the time of day.
  DateTime plusDays(int days) =>
      DateTime(year, month, day + days, hour, minute, second, millisecond);
}
