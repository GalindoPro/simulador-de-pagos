import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';
import '../helpers/app_formatters.dart';
import '../models/pago.dart';
import '../models/cliente.dart';

class PagoListTile extends StatelessWidget {
  final Pago pago;
  final Cliente? cliente;
  final VoidCallback? onTap;
  final VoidCallback? onEliminar;
  final VoidCallback? onCompartirPdf;

  const PagoListTile({
    super.key,
    required this.pago,
    this.cliente,
    this.onTap,
    this.onEliminar,
    this.onCompartirPdf,
  });

  IconData _iconoMetodo() {
    switch (pago.metodoPago) {
      case 'efectivo':
        return Icons.money;
      case 'transferencia':
        return Icons.account_balance;
      case 'cheque':
        return Icons.description;
      case 'tarjeta':
        return Icons.credit_card;
      default:
        return Icons.payment;
    }
  }

  Color _colorEstado() {
    switch (pago.estado) {
      case 'completado':
        return AppColors.success;
      case 'pendiente':
        return AppColors.warning;
      case 'cancelado':
        return AppColors.error;
      default:
        return AppColors.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: CircleAvatar(
        backgroundColor: _colorEstado().withValues(alpha: 0.1),
        child: Icon(_iconoMetodo(), color: _colorEstado(), size: 20),
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              cliente?.nombreCompleto ?? 'Cliente',
              style: AppTextStyles.titleSmall,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            AppFormatters.moneda(pago.monto),
            style: AppTextStyles.titleSmall.copyWith(
              color: _colorEstado(),
            ),
          ),
        ],
      ),
      subtitle: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  pago.concepto,
                  style: AppTextStyles.bodySmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Row(
                  children: [
                    Text(
                      AppFormatters.fechaCorta(pago.fecha),
                      style: AppTextStyles.caption,
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: _colorEstado().withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        pago.estado,
                        style: AppTextStyles.labelSmall.copyWith(
                          color: _colorEstado(),
                          fontSize: 9,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (pago.estaCompletado && onCompartirPdf != null)
            IconButton(
              onPressed: onCompartirPdf,
              icon: const Icon(Icons.picture_as_pdf),
              color: AppColors.primary,
              iconSize: 22,
              tooltip: 'Compartir recibo',
              constraints: const BoxConstraints(
                minWidth: 36,
                minHeight: 36,
              ),
              padding: EdgeInsets.zero,
            ),
        ],
      ),
      isThreeLine: true,
    );
  }
}
