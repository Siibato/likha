import 'package:flutter_test/flutter_test.dart';
import 'package:likha/core/utils/type_helpers.dart';

void main() {
  group('TypeHelpers', () {
    group('toInt', () {
      test('returns null for null input', () {
        expect(TypeHelpers.toInt(null), isNull);
      });

      test('returns int for int input', () {
        expect(TypeHelpers.toInt(42), equals(42));
        expect(TypeHelpers.toInt(-5), equals(-5));
        expect(TypeHelpers.toInt(0), equals(0));
      });

      test('converts double to int by truncation', () {
        expect(TypeHelpers.toInt(42.0), equals(42));
        expect(TypeHelpers.toInt(42.9), equals(42)); // truncates, not rounds
        expect(TypeHelpers.toInt(42.1), equals(42));
        expect(TypeHelpers.toInt(-5.7), equals(-5));
      });

      test('parses valid string to int', () {
        expect(TypeHelpers.toInt('42'), equals(42));
        expect(TypeHelpers.toInt('-5'), equals(-5));
        expect(TypeHelpers.toInt('0'), equals(0));
      });

      test('returns null for invalid string', () {
        expect(TypeHelpers.toInt('abc'), isNull);
        expect(TypeHelpers.toInt(''), isNull);
        expect(TypeHelpers.toInt('42.5'), isNull); // not a valid int string
      });

      test('returns null for other types', () {
        expect(TypeHelpers.toInt(true), isNull);
        expect(TypeHelpers.toInt([1, 2, 3]), isNull);
        expect(TypeHelpers.toInt({'key': 'value'}), isNull);
      });
    });

    group('toIntOr', () {
      test('returns value when valid', () {
        expect(TypeHelpers.toIntOr(42, 0), equals(42));
        expect(TypeHelpers.toIntOr('100', 0), equals(100));
      });

      test('returns default when null', () {
        expect(TypeHelpers.toIntOr(null, 999), equals(999));
      });

      test('returns default when conversion fails', () {
        expect(TypeHelpers.toIntOr('abc', -1), equals(-1));
        expect(TypeHelpers.toIntOr(true, 0), equals(0));
      });
    });

    group('toDouble', () {
      test('returns null for null input', () {
        expect(TypeHelpers.toDouble(null), isNull);
      });

      test('returns double for double input', () {
        expect(TypeHelpers.toDouble(42.5), equals(42.5));
        expect(TypeHelpers.toDouble(-5.7), equals(-5.7));
        expect(TypeHelpers.toDouble(0.0), equals(0.0));
      });

      test('converts int to double', () {
        expect(TypeHelpers.toDouble(42), equals(42.0));
        expect(TypeHelpers.toDouble(-5), equals(-5.0));
        expect(TypeHelpers.toDouble(0), equals(0.0));
      });

      test('parses valid string to double', () {
        expect(TypeHelpers.toDouble('42.5'), equals(42.5));
        expect(TypeHelpers.toDouble('42'), equals(42.0));
        expect(TypeHelpers.toDouble('-5.7'), equals(-5.7));
        expect(TypeHelpers.toDouble('0'), equals(0.0));
      });

      test('returns null for invalid string', () {
        expect(TypeHelpers.toDouble('abc'), isNull);
        expect(TypeHelpers.toDouble(''), isNull);
        expect(TypeHelpers.toDouble('12.34.56'), isNull);
      });

      test('returns null for other types', () {
        expect(TypeHelpers.toDouble(true), isNull);
        expect(TypeHelpers.toDouble([1, 2, 3]), isNull);
      });
    });

    group('toDoubleOr', () {
      test('returns value when valid', () {
        expect(TypeHelpers.toDoubleOr(42.5, 0.0), equals(42.5));
        expect(TypeHelpers.toDoubleOr('3.14', 0.0), equals(3.14));
      });

      test('returns default when null', () {
        expect(TypeHelpers.toDoubleOr(null, 99.9), equals(99.9));
      });

      test('returns default when conversion fails', () {
        expect(TypeHelpers.toDoubleOr('abc', -1.0), equals(-1.0));
      });
    });

    group('toBool', () {
      test('returns null for null input', () {
        expect(TypeHelpers.toBool(null), isNull);
      });

      test('returns bool for bool input', () {
        expect(TypeHelpers.toBool(true), isTrue);
        expect(TypeHelpers.toBool(false), isFalse);
      });

      test('converts int to bool (1=true, other=false)', () {
        expect(TypeHelpers.toBool(1), isTrue);
        expect(TypeHelpers.toBool(0), isFalse);
        expect(TypeHelpers.toBool(2), isFalse); // only exactly 1 is true
        expect(TypeHelpers.toBool(-1), isFalse);
      });

      test('parses valid string to bool case-insensitively', () {
        expect(TypeHelpers.toBool('true'), isTrue);
        expect(TypeHelpers.toBool('TRUE'), isTrue);
        expect(TypeHelpers.toBool('True'), isTrue);
        expect(TypeHelpers.toBool('false'), isFalse);
        expect(TypeHelpers.toBool('FALSE'), isFalse);
        expect(TypeHelpers.toBool('False'), isFalse);
        expect(TypeHelpers.toBool('1'), isTrue);
        expect(TypeHelpers.toBool('0'), isFalse);
      });

      test('returns false for invalid string', () {
        expect(TypeHelpers.toBool('abc'), isFalse);
        expect(TypeHelpers.toBool(''), isFalse);
        expect(TypeHelpers.toBool('yes'), isFalse);
        expect(TypeHelpers.toBool('no'), isFalse);
      });

      test('returns null for other types', () {
        expect(TypeHelpers.toBool(3.14), isNull);
        expect(TypeHelpers.toBool([true]), isNull);
      });
    });

    group('toBoolOr', () {
      test('returns value when valid', () {
        expect(TypeHelpers.toBoolOr(true, false), isTrue);
        expect(TypeHelpers.toBoolOr('true', false), isTrue);
      });

      test('returns default when null', () {
        expect(TypeHelpers.toBoolOr(null, true), isTrue);
        expect(TypeHelpers.toBoolOr(null, false), isFalse);
      });

      test('returns default when conversion fails', () {
        expect(TypeHelpers.toBoolOr('abc', false), isFalse);
        expect(TypeHelpers.toBoolOr(3.14, true), isTrue);
      });
    });

    group('toDateTime', () {
      test('returns null for null input', () {
        expect(TypeHelpers.toDateTime(null), isNull);
      });

      test('returns DateTime for DateTime input', () {
        final dt = DateTime(2024, 1, 15, 10, 30);
        expect(TypeHelpers.toDateTime(dt), equals(dt));
      });

      test('parses valid ISO 8601 string', () {
        final result = TypeHelpers.toDateTime('2024-01-15T10:30:00');
        expect(result, isNotNull);
        expect(result!.year, equals(2024));
        expect(result.month, equals(1));
        expect(result.day, equals(15));
        expect(result.hour, equals(10));
        expect(result.minute, equals(30));
      });

      test('parses valid date-only string', () {
        final result = TypeHelpers.toDateTime('2024-01-15');
        expect(result, isNotNull);
        expect(result!.year, equals(2024));
        expect(result.month, equals(1));
        expect(result.day, equals(15));
      });

      test('returns null for invalid date string', () {
        expect(TypeHelpers.toDateTime('abc'), isNull);
        expect(TypeHelpers.toDateTime(''), isNull);
        expect(TypeHelpers.toDateTime('15-01-2024'), isNull); // wrong format
        expect(TypeHelpers.toDateTime('2024/01/15'), isNull); // wrong separator
      });

      test('returns null for other types', () {
        expect(TypeHelpers.toDateTime(1705312200), isNull); // timestamp not supported
        expect(TypeHelpers.toDateTime([2024, 1, 15]), isNull);
      });
    });

    group('toDateTimeOr', () {
      test('returns value when valid', () {
        final dt = DateTime(2024, 1, 15);
        expect(TypeHelpers.toDateTimeOr('2024-01-15', DateTime.now()), equals(dt));
      });

      test('returns default when null', () {
        final defaultDt = DateTime(2024, 1, 1);
        expect(TypeHelpers.toDateTimeOr(null, defaultDt), equals(defaultDt));
      });

      test('returns default when conversion fails', () {
        final defaultDt = DateTime(2024, 1, 1);
        expect(TypeHelpers.toDateTimeOr('invalid', defaultDt), equals(defaultDt));
      });
    });

    group('asString', () {
      test('returns null for null input', () {
        expect(TypeHelpers.asString(null), isNull);
      });

      test('converts int to string', () {
        expect(TypeHelpers.asString(42), equals('42'));
        expect(TypeHelpers.asString(-5), equals('-5'));
        expect(TypeHelpers.asString(0), equals('0'));
      });

      test('converts double to string', () {
        expect(TypeHelpers.asString(42.5), equals('42.5'));
        expect(TypeHelpers.asString(-5.7), equals('-5.7'));
        expect(TypeHelpers.asString(0.0), equals('0.0'));
      });

      test('converts bool to string', () {
        expect(TypeHelpers.asString(true), equals('true'));
        expect(TypeHelpers.asString(false), equals('false'));
      });

      test('returns string for string input', () {
        expect(TypeHelpers.asString('hello'), equals('hello'));
        expect(TypeHelpers.asString(''), equals(''));
      });

      test('converts DateTime to string', () {
        final dt = DateTime(2024, 1, 15, 10, 30, 0);
        expect(TypeHelpers.asString(dt), equals(dt.toString()));
      });
    });

    group('asStringOr', () {
      test('returns value when valid', () {
        expect(TypeHelpers.asStringOr(42, 'default'), equals('42'));
        expect(TypeHelpers.asStringOr('hello', 'default'), equals('hello'));
      });

      test('returns default when null', () {
        expect(TypeHelpers.asStringOr(null, 'default'), equals('default'));
      });

      test('returns default when conversion fails (should not happen with asString)', () {
        // asString should handle any type, but testing consistency
        expect(TypeHelpers.asStringOr(null, ''), equals(''));
      });
    });
  });
}
