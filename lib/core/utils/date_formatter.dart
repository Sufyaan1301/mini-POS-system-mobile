import 'package:intl/intl.dart';

class DateFormatter {
  DateFormatter._();

  static final DateFormat _receiptFormat = DateFormat('dd MMM yyyy, HH:mm');
  static final DateFormat _dateOnlyFormat = DateFormat('dd MMM yyyy');

  static String formatReceipt(DateTime dateTime) =>
      _receiptFormat.format(dateTime);

  static String formatDateOnly(DateTime dateTime) =>
      _dateOnlyFormat.format(dateTime);
}
