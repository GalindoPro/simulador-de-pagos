import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class AppSnackBar {
  AppSnackBar._();

  static void exito(BuildContext context, String mensaje) {
    _show(context, mensaje, AppColors.success, Icons.check_circle);
  }

  static void error(BuildContext context, String mensaje) {
    _show(context, mensaje, AppColors.error, Icons.error);
  }

  static void advertencia(BuildContext context, String mensaje) {
    _show(context, mensaje, AppColors.warning, Icons.warning);
  }

  static void info(BuildContext context, String mensaje) {
    _show(context, mensaje, AppColors.info, Icons.info);
  }

  static void _show(
    BuildContext context,
    String mensaje,
    Color color,
    IconData icono,
  ) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icono, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                mensaje,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      ),
    );
  }
}
