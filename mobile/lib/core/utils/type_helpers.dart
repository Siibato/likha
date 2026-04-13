/// Type-safe helper functions for common type conversions
class TypeHelpers {
  /// Safely convert a dynamic value to int
  /// Returns null if conversion fails
  static int? toInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) {
      return int.tryParse(value);
    }
    return null;
  }
  
  /// Safely convert a dynamic value to int with default
  static int toIntOr(dynamic value, int defaultValue) {
    return toInt(value) ?? defaultValue;
  }
  
  /// Safely convert a dynamic value to double
  /// Returns null if conversion fails
  static double? toDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      return double.tryParse(value);
    }
    return null;
  }
  
  /// Safely convert a dynamic value to double with default
  static double toDoubleOr(dynamic value, double defaultValue) {
    return toDouble(value) ?? defaultValue;
  }
  
  /// Safely convert a dynamic value to bool
  /// Returns null if conversion fails
  static bool? toBool(dynamic value) {
    if (value == null) return null;
    if (value is bool) return value;
    if (value is int) return value == 1;
    if (value is String) {
      final lower = value.toLowerCase();
      return lower == 'true' || lower == '1';
    }
    return null;
  }
  
  /// Safely convert a dynamic value to bool with default
  static bool toBoolOr(dynamic value, bool defaultValue) {
    return toBool(value) ?? defaultValue;
  }
  
  /// Safely convert a dynamic value to DateTime
  /// Returns null if conversion fails
  static DateTime? toDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (e) {
        return null;
      }
    }
    return null;
  }
  
  /// Safely convert a dynamic value to DateTime with default
  static DateTime toDateTimeOr(dynamic value, DateTime defaultValue) {
    return toDateTime(value) ?? defaultValue;
  }
  
  /// Safely convert a dynamic value to String
  /// Returns null if value is null
  static String? asString(dynamic value) {
    if (value == null) return null;
    return value.toString();
  }
  
  /// Safely convert a dynamic value to String with default
  static String asStringOr(dynamic value, String defaultValue) {
    return asString(value) ?? defaultValue;
  }
}
