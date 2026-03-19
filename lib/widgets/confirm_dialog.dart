import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_strings.dart';

class ConfirmDialog {
  ConfirmDialog._();

  static Future<bool> show(
    BuildContext context, {
    required String titulo,
    required String mensaje,
    String textoConfirmar = AppStrings.confirmar,
    String textoCancelar = AppStrings.cancelar,
    Color colorConfirmar = AppColors.error,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text(titulo),
          content: Text(mensaje),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text(textoCancelar),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: colorConfirmar,
              ),
              child: Text(textoConfirmar),
            ),
          ],
        );
      },
    );
    return result ?? false;
  }
}
