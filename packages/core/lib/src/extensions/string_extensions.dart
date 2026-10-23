/// Formatting and validation helpers for [String].
extension StringX on String {
  /// Whether this string is empty or contains only whitespace.
  bool get isBlank => trim().isEmpty;

  /// Whether this string contains at least one non-whitespace character.
  bool get isNotBlank => !isBlank;

  /// Returns `null` when [isBlank], otherwise the original string.
  String? get nullIfBlank => isBlank ? null : this;

  /// Uppercases the first character and leaves the rest untouched.
  String get capitalized {
    if (isEmpty) {
      return this;
    }
    return '${this[0].toUpperCase()}${substring(1)}';
  }

  /// Converts `snake_case`, `kebab-case`, or `camelCase` into Title Case.
  String get titleCased =>
      split(RegExp(r'[_\-\s]+|(?=[A-Z])'))
          .where((part) => part.isNotEmpty)
          .map((part) => part.toLowerCase().capitalized)
          .join(' ');

  /// Shortens this string to at most [maxLength] characters.
  ///
  /// The returned value includes [ellipsis] and never exceeds [maxLength].
  /// When [maxLength] is smaller than [ellipsis], the ellipsis is truncated.
  String truncate(int maxLength, {String ellipsis = '…'}) {
    if (maxLength <= 0) {
      return '';
    }
    if (length <= maxLength) {
      return this;
    }
    if (ellipsis.length >= maxLength) {
      return ellipsis.substring(0, maxLength);
    }
    return '${substring(0, maxLength - ellipsis.length)}$ellipsis';
  }

  /// Converts this string into a URL-safe slug.
  ///
  /// Example: `'Hello, World!'` becomes `'hello-world'`.
  String get slugified => toLowerCase()
      .replaceAll(RegExp('[^a-z0-9]+'), '-')
      .replaceAll(RegExp(r'^-+|-+$'), '');
}
