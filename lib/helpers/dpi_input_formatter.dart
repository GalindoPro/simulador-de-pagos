import 'package:flutter/services.dart';

class DpiInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll('-', '');
    if (digits.length > 13) {
      return oldValue;
    }
    String result = '';
    for (int i = 0; i < digits.length; i++) {
      if (i == 4 || i == 9) {
        result += '-';
      }
      result += digits[i];
    }
    return TextEditingValue(
      text: result,
      selection: TextSelection.collapsed(offset: result.length),
    );
  }
}
