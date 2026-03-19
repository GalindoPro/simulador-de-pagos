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
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columnSpacing: 16,
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
          return DataRow(
            color: c.pagado
                ? WidgetStateProperty.all(
                    AppColors.successLight.withValues(alpha: 0.3))
                : null,
            cells: [
              DataCell(Text('${c.cuotaNumero}')),
              DataCell(Text(AppFormatters.fechaCorta(c.fechaPago))),
              DataCell(Text(AppFormatters.moneda(c.capital))),
              DataCell(Text(AppFormatters.moneda(c.interes))),
              DataCell(Text(
                AppFormatters.moneda(c.totalCuota),
                style: AppTextStyles.labelLarge,
              )),
              DataCell(Text(AppFormatters.moneda(c.saldo))),
              DataCell(
                Icon(
                  c.pagado ? Icons.check_circle : Icons.radio_button_unchecked,
                  color: c.pagado ? AppColors.success : AppColors.disabled,
                  size: 20,
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }
}
