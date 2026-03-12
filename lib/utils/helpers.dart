import 'package:haflaway/utils/globalfns.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

String transformNumber(String input) {
  // Remove spaces and dashes
  input = input.replaceAll(' ', '').replaceAll('-', '');

  // Replace leading 0 with 255
  if (input.startsWith('0')) {
    input = '255${input.substring(1)}';
  }

  // Remove decimal point and everything after it
  if (input.contains('.')) {
    input = input.split('.')[0];
  }

  return input;
}

Future<void> callNumber(String phoneNumber) async {
  final Uri phoneUri = Uri(scheme: "tel", path: phoneNumber);
  if (await canLaunchUrl(phoneUri)) {
    await launchUrl(phoneUri);
  } else {
    showToast(isGood: false, msg: "Could not launch phone dialer");
  }
}

formatDate({required DateTime dtime}) {
  final DateFormat dftr = DateFormat('EEEE, d\'th\', MMMM, yyyy');
  return dftr.format(dtime);
}

/// Formats a numeric amount with thousands separators and optional currency.
///
/// Examples:
///   formatMoney(2000, currency: 'TZS') -> "2,000 TZS"
///   formatMoney(34000.5, currency: 'USD', decimals: 2) -> "34,000.50 USD"
///
/// Parameters:
/// - [amount]: the numeric amount to format (can be int/double). Null treated as 0.
/// - [currency]: optional currency code (e.g., 'TZS', 'USD'). If provided it is appended
///   (or prepended when [currencyBefore] is true) with a space separator.
/// - [decimals]: number of fractional digits to show (default 0).
/// - [currencyBefore]: if true, currency appears before the number (e.g., "USD 1,000").
/// - [locale]: locale used for grouping (default 'en_US' to ensure comma separators).
String formatMoney(
  num? amount, {
  String currency = '',
  int decimals = 0,
  bool currencyBefore = false,
  String locale = 'en_US',
}) {
  final val = amount ?? 0;
  final nf = NumberFormat.decimalPattern(locale);
  nf.minimumFractionDigits = decimals;
  nf.maximumFractionDigits = decimals;
  final formatted = nf.format(val);
  if (currency.isEmpty) return formatted;
  return currencyBefore ? '$currency $formatted' : '$formatted $currency';
}
