import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';

class EmptyState extends StatelessWidget {
  final String mensaje;
  final IconData icono;
  final String? subtitulo;
  final VoidCallback? onAccion;
  final String? textoAccion;

  const EmptyState({
    super.key,
    required this.mensaje,
    this.icono = Icons.inbox_outlined,
    this.subtitulo,
    this.onAccion,
    this.textoAccion,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icono, size: 64, color: AppColors.disabled),
            const SizedBox(height: 16),
            Text(
              mensaje,
              style: AppTextStyles.titleMedium.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            if (subtitulo != null) ...[
              const SizedBox(height: 8),
              Text(
                subtitulo!,
                style: AppTextStyles.bodySmall,
                textAlign: TextAlign.center,
              ),
            ],
            if (onAccion != null && textoAccion != null) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: onAccion,
                icon: const Icon(Icons.add),
                label: Text(textoAccion!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
