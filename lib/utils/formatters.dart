import 'package:intl/intl.dart';

final NumberFormat rmCurrency = NumberFormat.currency(locale: 'en_MY', symbol: 'RM', decimalDigits: 2);
final DateFormat dateShort = DateFormat('y-MM-dd');
final DateFormat dateLong = DateFormat('MMMM d, y');