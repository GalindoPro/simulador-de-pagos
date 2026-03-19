import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../services/whatsapp_service.dart';

class WhatsAppButton extends StatelessWidget {
  final String telefono;
  final String mensaje;
  final bool mostrarTexto;

  const WhatsAppButton({
    super.key,
    required this.telefono,
    this.mensaje = '¡Hola!',
    this.mostrarTexto = false,
  });

  @override
  Widget build(BuildContext context) {
    if (mostrarTexto) {
      return ElevatedButton.icon(
        onPressed: () =>
            WhatsAppService.enviarMensaje(telefono, mensaje, context),
        icon: const Icon(Icons.chat, size: 18),
        label: const Text('WhatsApp'),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.whatsapp,
          foregroundColor: Colors.white,
        ),
      );
    }

    return IconButton(
      onPressed: () =>
          WhatsAppService.enviarMensaje(telefono, mensaje, context),
      icon: const Icon(Icons.chat),
      color: AppColors.whatsapp,
      tooltip: 'Enviar WhatsApp',
    );
  }
}
