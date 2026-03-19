import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';
import '../helpers/app_formatters.dart';
import '../models/cuota_pago.dart';

class TablaAmortizacion extends StatelessWidget {
  final List<CuotaPago> cuotas;

  const TablaAmortizacion({
    super.key,
    required this.cuotas,
  });

  @override
  Widget build(BuildContext context) {
    // Encontrar la próxima cuota pendiente
    final proximaCuota = cuotas
        .where((c) => !c.pagado)
        .fold<CuotaPago?>(null, (prev, c) => prev ?? c);

    final totalPagado = cuotas.where((c) => c.pagado).length;
    final total = cuotas.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Resumen de progreso
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Expanded(
                child: _resumenItem(
                  'Pagadas',
                  '$totalPagado/$total',
                  AppColors.success,
                ),
              ),
              Container(
                width: 1,
                height: 30,
                color: AppColors.divider,
              ),
              Expanded(
                child: _resumenItem(
                  'Pendientes',
                  '${total - totalPagado}',
                  total - totalPagado > 0
                      ? AppColors.warning
                      : AppColors.success,
                ),
              ),
              if (proximaCuota != null) ...[
                Container(
                  width: 1,
                  height: 30,
                  color: AppColors.divider,
                ),
                Expanded(
                  child: _resumenItem(
                    'Próxima',
                    AppFormatters.fechaCorta(proximaCuota.fechaPago),
                    AppColors.primary,
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Tabla
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            columnSpacing: 14,
            headingRowHeight: 44,
            dataRowMinHeight: 44,
            dataRowMaxHeight: 60,
            headingRowColor: WidgetStateProperty.all(
              AppColors.primary.withValues(alpha: 0.1),
            ),
            columns: const [
              DataColumn(label: Text('No.')),
              DataColumn(label: Text('Fecha')),
              DataColumn(label: Text('Capital'), numeric: true),
              DataColumn(label: Text('Interés'), numeric: true),
              DataColumn(label: Text('Cuota'), numeric: true),
              DataColumn(label: Text('Saldo'), numeric: true),
              DataColumn(label: Text('Estado')),
            ],
            rows: cuotas.map((c) {
              final esProxima = proximaCuota?.id == c.id;

              return DataRow(
                color: WidgetStateProperty.resolveWith<Color?>((states) {
                  if (c.pagado) {
                    return AppColors.successLight.withValues(alpha: 0.3);
                  }
                  if (esProxima) {
                    return AppColors.warningLight.withValues(alpha: 0.5);
                  }
                  return null;
                }),
                cells: [
                  DataCell(Text(
                    '${c.cuotaNumero}',
                    style: esProxima
                        ? AppTextStyles.labelLarge
                            .copyWith(color: AppColors.warning)
                        : null,
                  )),
                  DataCell(Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(AppFormatters.fechaCorta(c.fechaPago)),
                      if (c.pagado && c.fechaPagado != null)
                        Text(
                          'Pagado: ${AppFormatters.fechaCorta(c.fechaPagado!)}',
                          style: AppTextStyles.caption
                              .copyWith(color: AppColors.success),
                        ),
                    ],
                  )),
                  DataCell(Text(AppFormatters.moneda(c.capital))),
                  DataCell(Text(AppFormatters.moneda(c.interes))),
                  DataCell(Text(
                    AppFormatters.moneda(c.totalCuota),
                    style: AppTextStyles.labelLarge,
                  )),
                  DataCell(Text(AppFormatters.moneda(c.saldo))),
                  DataCell(_estadoChip(c, esProxima)),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _resumenItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: AppTextStyles.titleSmall.copyWith(color: color),
        ),
        const SizedBox(height: 2),
        Text(label, style: AppTextStyles.caption),
      ],
    );
  }

  Widget _estadoChip(CuotaPago cuota, bool esProxima) {
    if (cuota.pagado) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.success.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle, color: AppColors.success, size: 16),
            SizedBox(width: 4),
            Text('Pagado',
                style: TextStyle(
                    color: AppColors.success,
                    fontSize: 11,
                    fontWeight: FontWeight.w600)),
          ],
        ),
      );
    }

    if (esProxima) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.warning.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.schedule, color: AppColors.warning, size: 16),
            SizedBox(width: 4),
            Text('Próxima',
                style: TextStyle(
                    color: AppColors.warning,
                    fontSize: 11,
                    fontWeight: FontWeight.w600)),
          ],
        ),
      );
    }

    return const Icon(
      Icons.radio_button_unchecked,
      color: AppColors.disabled,
      size: 20,
    );
  }
}
