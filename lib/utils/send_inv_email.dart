import 'dart:typed_data';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';

class EmailService {
  static Future<void> sendInvoiceEmail({
    required String to,
    required Uint8List pdfBytes,
    required String invoiceId,
  }) async {
    // Replace with your SMTP credentials or environment variables
    final smtpServer = gmail('weiquan9487@gmail.com', 'iqfu rhmy gqzk fsmn');

    final message = Message()
      ..from = Address('weiquan9487@gmail.com', 'AutoFix Garage')
      ..recipients.add(to)
      ..subject = 'Vehicle Repair Invoice'
      ..text = 'Hello,\n\nPlease find attached your invoice.\n\nThank you!'
      ..attachments = [
        StreamAttachment(
          Stream.fromIterable([pdfBytes]),
          'application/pdf',
          fileName: 'invoice_$invoiceId.pdf',
        ),
      ];

    try {
      await send(message, smtpServer);
      print('✅ Email sent to $to');
    } catch (e) {
      print('❌ Failed to send email: $e');
    }
  }
}
