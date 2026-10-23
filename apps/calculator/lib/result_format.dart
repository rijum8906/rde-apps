/// Formats an evaluated [value] for display without trailing floating-point
/// noise.
///
/// Whole numbers are shown without a decimal point, other values are rounded to
/// twelve significant digits, and scientific notation is preserved.
String formatResult(double value) {
  if (!value.isFinite) {
    return value.toString();
  }
  if (value == value.truncateToDouble() && value.abs() < 1e15) {
    return value.toStringAsFixed(0);
  }

  final text = value.toStringAsPrecision(12);
  if (text.contains('e')) {
    return text;
  }
  return text.replaceFirst(RegExp(r'\.?0+$'), '');
}
