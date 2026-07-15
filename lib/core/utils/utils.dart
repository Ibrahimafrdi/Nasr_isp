import 'package:intl/intl.dart';

class DateTimeUtils {
  /// Company-configurable currency symbol. Kept in sync with AppSettings by
  /// SettingsBloc whenever settings are loaded/saved; defaults to the
  /// original hardcoded value so behavior is unchanged until Settings loads.
  static String currencySymbol = 'Rs ';

  static String formatDate(DateTime date) {
    return DateFormat('MMM dd, yyyy').format(date);
  }

  static String formatDateTime(DateTime dateTime) {
    return DateFormat('MMM dd, yyyy HH:mm').format(dateTime);
  }

  static String formatTime(DateTime dateTime) {
    return DateFormat('HH:mm').format(dateTime);
  }

  static String formatCurrency(double amount) {
    return NumberFormat.currency(
      locale: 'ur_PK',
      symbol: currencySymbol,
      decimalDigits: 0,
    ).format(amount);
  }

  static int daysUntilExpiry(DateTime expiryDate) {
    return expiryDate.difference(DateTime.now()).inDays;
  }

  static bool isExpired(DateTime expiryDate) {
    return expiryDate.isBefore(DateTime.now());
  }

  static bool isExpiringSoon(DateTime expiryDate, {int daysThreshold = 7}) {
    final daysLeft = daysUntilExpiry(expiryDate);
    return daysLeft > 0 && daysLeft <= daysThreshold;
  }
}

class ValidationUtils {
  static final RegExp _emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }
    if (!_emailRegex.hasMatch(value)) {
      return 'Please enter a valid email';
    }
    return null;
  }

  /// Email that may be left blank; validated only when a value is present.
  static String? validateOptionalEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null;
    }
    if (!_emailRegex.hasMatch(value.trim())) {
      return 'Please enter a valid email';
    }
    return null;
  }

  static String? validatePhone(String? value) {
    if (value == null || value.isEmpty) {
      return 'Phone number is required';
    }
    if (value.length < 10) {
      return 'Phone number must be at least 10 digits';
    }
    return null;
  }

  /// Pakistani mobile number — exactly 11 digits starting with 0
  /// (e.g. 0314 9498314). Ignores the display space/formatting.
  static String? validatePhonePk(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Phone number is required';
    }
    final digits = value.replaceAll(RegExp(r'\D'), '');
    if (digits.length != 11 || !digits.startsWith('0')) {
      return 'Enter a valid phone (e.g. 0314 9498314)';
    }
    return null;
  }

  /// CNIC — exactly 13 digits (e.g. 17301-1937353-5). Ignores dashes.
  static String? validateCnic(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'CNIC is required';
    }
    final digits = value.replaceAll(RegExp(r'\D'), '');
    if (digits.length != 13) {
      return 'Enter a valid CNIC (e.g. 17301-1937353-5)';
    }
    return null;
  }

  static String? validateName(String? value, [String fieldName = 'Name']) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    if (value.trim().length < 2) {
      return '$fieldName must be at least 2 characters';
    }
    return null;
  }

  /// Money/amount field — required, parseable, and > 0 (>= 0 when allowZero).
  static String? validateAmount(
    String? value, {
    String fieldName = 'Amount',
    bool allowZero = false,
  }) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    final parsed = double.tryParse(value.trim());
    if (parsed == null) {
      return 'Enter a valid $fieldName';
    }
    if (allowZero ? parsed < 0 : parsed <= 0) {
      return allowZero
          ? '$fieldName cannot be negative'
          : '$fieldName must be greater than 0';
    }
    return null;
  }

  /// Whole-number field — required and parseable as an int.
  static String? validateInteger(
    String? value, {
    String fieldName = 'Value',
    bool allowZero = true,
  }) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    final parsed = int.tryParse(value.trim());
    if (parsed == null) {
      return 'Enter a valid $fieldName';
    }
    if (allowZero ? parsed < 0 : parsed <= 0) {
      return allowZero
          ? '$fieldName cannot be negative'
          : '$fieldName must be greater than 0';
    }
    return null;
  }

  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }

  static String? validateRequired(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }
}

class StringUtils {
  static String capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }

  static String truncate(String text, int length) {
    if (text.length <= length) return text;
    return '${text.substring(0, length)}...';
  }

  static String formatPhoneNumber(String phone) {
    // Format: +92 3XX XXX XXXX
    final cleaned = phone.replaceAll(RegExp(r'\D'), '');
    if (cleaned.length == 10) {
      return '+92 ${cleaned.substring(0, 3)} ${cleaned.substring(3, 6)} ${cleaned.substring(6)}';
    }
    if (cleaned.length == 12) {
      return '+${cleaned.substring(0, 2)} ${cleaned.substring(2, 5)} ${cleaned.substring(5, 8)} ${cleaned.substring(8)}';
    }
    return phone;
  }
}
