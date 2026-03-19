import 'package:intl/intl.dart';

class AppFormatters {
  AppFormatters._();

  static final _currencyFormat = NumberFormat('#,##0.00', 'es_GT');
  static final _dateShort = DateFormat('dd/MM/yyyy');
  static final _dateLong = DateFormat("d 'de' MMMM 'de' yyyy", 'es');
  static final _dateMonth = DateFormat('MMMM yyyy', 'es');

  /// Q 1,250.50
  static String moneda(double monto) {
    return 'Q ${_currencyFormat.format(monto)}';
  }

  /// 15/01/2024
  static String fechaCorta(DateTime fecha) {
    return _dateShort.format(fecha);
  }

  /// 15 de enero de 2024
  static String fechaLarga(DateTime fecha) {
    return _dateLong.format(fecha);
  }

  /// enero 2024
  static String fechaMes(DateTime fecha) {
    return _dateMonth.format(fecha);
  }

  /// 5555-1234
  static String telefono(String tel) {
    final digits = tel.replaceAll(RegExp(r'\D'), '');
    if (digits.length == 8) {
      return '${digits.substring(0, 4)}-${digits.substring(4)}';
    }
    return tel;
  }

  /// 7.0%
  static String porcentaje(double valor) {
    return '${valor.toStringAsFixed(1)}%';
  }

  /// 3274-32047-1405
  static String formatearDPI(String dpi) {
    final digits = dpi.replaceAll('-', '');
    if (digits.length != 13) {
      return dpi;
    }
    return '${digits.substring(0, 4)}-${digits.substring(4, 9)}-${digits.substring(9)}';
  }

  /// Saludo según hora
  static String saludo() {
    final hora = DateTime.now().hour;
    if (hora < 12) {
      return 'Buenos días';
    } else if (hora < 18) {
      return 'Buenas tardes';
    } else {
      return 'Buenas noches';
    }
  }

  /// Fecha actual en formato largo con día de semana
  static String fechaActual() {
    final now = DateTime.now();
    final dayOfWeek = DateFormat('EEEE', 'es').format(now);
    final capitalized = dayOfWeek[0].toUpperCase() + dayOfWeek.substring(1);
    return '$capitalized, ${fechaLarga(now)}';
  }
}
