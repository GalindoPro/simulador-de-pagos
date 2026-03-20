import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class WhatsAppService {
  WhatsAppService._();

  static Future<void> enviarMensaje(
    String telefono,
    String mensaje,
    BuildContext context,
  ) async {
    final numero = '502${telefono.replaceAll(RegExp(r'\D'), '')}';
    final url = Uri.parse(
      'https://wa.me/$numero?text=${Uri.encodeComponent(mensaje)}',
    );

    try {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } catch (e) {
      debugPrint('Error al abrir WhatsApp: $e');
    }
  }

  static String mensajeBienvenida(String nombre) {
    return '¡Hola $nombre! Bienvenido/a. Tu registro en Capital Pro ha sido exitoso.';
  }

  static String mensajePrestamoAprobado({
    required String nombre,
    required String monto,
    required String cuota,
    required String plazo,
  }) {
    return '¡Hola $nombre! Tu préstamo por $monto ha sido aprobado.\n'
        'Cuota mensual: $cuota\n'
        'Plazo: $plazo meses\n'
        '¡Gracias por tu confianza!';
  }

  static String mensajeConfirmacionPago({
    required String nombre,
    required String monto,
    required String concepto,
  }) {
    return '¡Hola $nombre! Tu pago de $monto por concepto "$concepto" '
        'ha sido registrado exitosamente.'
        '\n¡Gracias por tu puntualidad!';
  }

  static String mensajeFiniquito(String nombre) {
    return '¡Felicidades $nombre! Has completado todos los pagos de tu préstamo. '
        'Tu finiquito ha sido generado. ¡Gracias por tu confianza!';
  }
}
