import 'package:core/core.dart';
import 'package:test/test.dart';

/// Verifies the string, iterable, and date helpers shipped by `core`.
void main() {
  group('StringX', () {
    test('detects blank strings', () {
      expect('   '.isBlank, isTrue);
      expect(''.nullIfBlank, isNull);
      expect('value'.isNotBlank, isTrue);
    });

    test('produces readable titles and slugs', () {
      expect('hello world'.capitalized, 'Hello world');
      expect('app_theme_variant'.titleCased, 'App Theme Variant');
      expect('Hello, World!'.slugified, 'hello-world');
    });

    test('truncates without exceeding the limit', () {
      expect('short'.truncate(10), 'short');
      expect('a very long value'.truncate(10), 'a very lo…');
      expect('abcdef'.truncate(0), '');
      expect('abcdef'.truncate(1), '…');
    });
  });

  group('IterableX', () {
    test('firstWhereOrNull returns null instead of throwing', () {
      expect([1, 2, 3].firstWhereOrNull((value) => value > 1), 2);
      expect([1, 2, 3].firstWhereOrNull((value) => value > 9), isNull);
    });

    test('chunked splits into fixed-size groups', () {
      expect([1, 2, 3, 4, 5].chunked(2).toList(), [
        [1, 2],
        [3, 4],
        [5],
      ]);
      expect(() => [1].chunked(0), throwsArgumentError);
    });

    test('distinctBy keeps the first element per key', () {
      final people = [
        (name: 'Ada', role: 'engineer'),
        (name: 'Grace', role: 'engineer'),
        (name: 'Alan', role: 'scientist'),
      ];

      final distinct = people.distinctBy((person) => person.role);

      expect(distinct, hasLength(2));
      expect(distinct.first.name, 'Ada');
    });

    test('mapIndexed exposes the index', () {
      expect(['a', 'b'].mapIndexed((index, value) => '$index$value').toList(), [
        '0a',
        '1b',
      ]);
    });
  });

  group('DateTimeX', () {
    test('computes day boundaries', () {
      final date = DateTime(2026, 10, 22, 15, 30);

      expect(date.startOfDay, DateTime(2026, 10, 22));
      expect(date.endOfDay.day, 22);
      expect(date.endOfDay.hour, 23);
    });

    test('compares calendar days and measures months', () {
      final date = DateTime(2026, 2, 10, 8);

      expect(date.isSameDayAs(DateTime(2026, 2, 10, 23)), isTrue);
      expect(date.isSameDayAs(DateTime(2026, 2, 11)), isFalse);
      expect(date.daysInMonth, 28);
      expect(DateTime(2024, 2).daysInMonth, 29);
      expect(date.plusDays(2).day, 12);
    });

    test('isToday matches the current date', () {
      expect(DateTime.now().isToday, isTrue);
    });
  });
}
