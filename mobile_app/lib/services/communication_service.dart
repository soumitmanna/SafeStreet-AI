import 'package:url_launcher/url_launcher.dart';

class CommunicationService {
  /// Make a phone call
  static Future<void> callContact(String phoneNumber) async {
    final Uri uri = Uri(
      scheme: 'tel',
      path: phoneNumber,
    );

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      throw Exception('Could not launch phone dialer');
    }
  }

  /// Send an SMS
  static Future<void> sendSms(
    String phoneNumber, {
    String message = '',
  }) async {
    final Uri uri = Uri(
      scheme: 'sms',
      path: phoneNumber,
      queryParameters: message.isNotEmpty
          ? {'body': message}
          : null,
    );

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      throw Exception('Could not launch SMS application');
    }
  }
}