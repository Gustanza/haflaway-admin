import 'package:intl/intl.dart';

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

formatDate({required DateTime dtime}) {
  final DateFormat dftr = DateFormat('EEEE, d\'th\', MMMM, yyyy');
  return dftr.format(dtime);
}
