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
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }
    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
    if (!emailRegex.hasMatch(value)) {
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
