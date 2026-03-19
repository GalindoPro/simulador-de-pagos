import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';
import '../helpers/app_formatters.dart';
import '../models/prestamo.dart';
import '../models/cliente.dart';

class PrestamoCard extends StatelessWidget {
  final Prestamo prestamo;
  final Cliente? cliente;
  final VoidCallback? onTap;

  const PrestamoCard({
    super.key,
    required this.prestamo,
    this.cliente,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorEstado = _colorEstado();

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      cliente?.nombreCompleto ?? 'Cliente',
                      style: AppTextStyles.titleSmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: colorEstado.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      prestamo.estado.toUpperCase(),
                      style: TextStyle(
                        color: colorEstado,
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            AppFormatters.moneda(prestamo.montoOriginal),
                            style: AppTextStyles.titleMedium,
                          ),
                        ),
                        Text(
                          'Saldo: ${AppFormatters.moneda(prestamo.saldoPendiente)}',
                          style: AppTextStyles.bodySmall,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${prestamo.plazoMeses} meses',
                        style: AppTextStyles.bodySmall,
                      ),
                      Text(
                        AppFormatters.fechaCorta(prestamo.fechaVencimiento),
                        style: AppTextStyles.caption,
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: prestamo.progreso,
                backgroundColor: AppColors.divider,
                valueColor: AlwaysStoppedAnimation<Color>(colorEstado),
                borderRadius: BorderRadius.circular(4),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _colorEstado() {
    if (prestamo.estaVencido) {
      return AppColors.error;
    }
    switch (prestamo.estado) {
      case 'activo':
        return AppColors.primary;
      case 'pagado':
        return AppColors.success;
      default:
        return AppColors.textSecondary;
    }
  }
}
