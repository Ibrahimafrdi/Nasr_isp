import 'package:url_launcher/url_launcher.dart';

/// Opens a WhatsApp chat with a prefilled message (wa.me deep link).
///
/// UI-side helper only: it talks to the browser/OS, never to Firestore, so it
/// sits outside the repository layer.
class WhatsAppLauncher {
  const WhatsAppLauncher._();

  /// Pakistan; applied when a stored number has no country code.
  static const String defaultCountryCode = '92';

  /// Turns a stored phone ("0300 1234567", "+92 300 1234567", "923001234567")
  /// into the digits-only international form wa.me expects, or null when the
  /// number cannot be a real phone number.
  static String? normalizePhone(String raw) {
    var digits = raw.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) return null;

    if (digits.startsWith('00')) {
      digits = digits.substring(2); // 0092... -> 92...
    } else if (digits.startsWith('0')) {
      digits = '$defaultCountryCode${digits.substring(1)}'; // 0300... -> 92300...
    } else if (digits.length == 10 && digits.startsWith('3')) {
      digits = '$defaultCountryCode$digits'; // 300... -> 92300...
    }

    if (digits.length < 11 || digits.length > 15) return null;
    if (digits.startsWith(defaultCountryCode) && digits.length != 12) return null;
    return digits;
  }

  /// Opens WhatsApp for [phone] with [message] prefilled. Returns false when
  /// the number is unusable or the link could not be opened. Nothing is sent
  /// until the operator presses send in WhatsApp.
  static Future<bool> send({
    required String phone,
    required String message,
  }) async {
    final number = normalizePhone(phone);
    if (number == null) return false;
    final uri = Uri.https('wa.me', '/$number', {'text': message});
    try {
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      return false;
    }
  }
}
