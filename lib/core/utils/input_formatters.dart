import 'package:flutter/services.dart';

/// Masks CNIC input as the user types → `#####-#######-#`
/// (e.g. 17301-1937353-5). Digits only, capped at 13 digits.
class CnicInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    final capped = digits.length > 13 ? digits.substring(0, 13) : digits;

    final buffer = StringBuffer();
    for (var i = 0; i < capped.length; i++) {
      if (i == 5 || i == 12) buffer.write('-');
      buffer.write(capped[i]);
    }

    final formatted = buffer.toString();
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

/// Masks Pakistani phone input as the user types → `0314 9498314`.
/// Digits only, capped at 11 digits, single space after the 4th digit.
class PhoneInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    final capped = digits.length > 11 ? digits.substring(0, 11) : digits;

    final buffer = StringBuffer();
    for (var i = 0; i < capped.length; i++) {
      if (i == 4) buffer.write(' ');
      buffer.write(capped[i]);
    }

    final formatted = buffer.toString();
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

/// Central home for reusable input formatters. Static getters return the
/// `List<TextInputFormatter>` to hand straight to a field's `inputFormatters`.
class AppInputFormatters {
  const AppInputFormatters._();

  static List<TextInputFormatter> get cnic => [CnicInputFormatter()];

  static List<TextInputFormatter> get phone => [PhoneInputFormatter()];

  static List<TextInputFormatter> get integer =>
      [FilteringTextInputFormatter.digitsOnly];

  static List<TextInputFormatter> get decimal =>
      [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))];

  /// Strips everything but digits — use when saving a masked value so storage
  /// keeps raw digits (e.g. '17301-1937353-5' → '1730119373535').
  static String digitsOnly(String value) =>
      value.replaceAll(RegExp(r'\D'), '');

  /// Re-applies the CNIC mask to a stored raw value when populating a
  /// controller in edit mode (the formatter only fires on user keystrokes).
  /// Tolerates already-formatted or partial legacy values.
  static String formatCnic(String value) {
    final digits = value.replaceAll(RegExp(r'\D'), '');
    final capped = digits.length > 13 ? digits.substring(0, 13) : digits;
    final buffer = StringBuffer();
    for (var i = 0; i < capped.length; i++) {
      if (i == 5 || i == 12) buffer.write('-');
      buffer.write(capped[i]);
    }
    return buffer.toString();
  }

  /// Re-applies the phone mask to a stored raw value for edit mode.
  static String formatPhone(String value) {
    final digits = value.replaceAll(RegExp(r'\D'), '');
    final capped = digits.length > 11 ? digits.substring(0, 11) : digits;
    final buffer = StringBuffer();
    for (var i = 0; i < capped.length; i++) {
      if (i == 4) buffer.write(' ');
      buffer.write(capped[i]);
    }
    return buffer.toString();
  }
}
