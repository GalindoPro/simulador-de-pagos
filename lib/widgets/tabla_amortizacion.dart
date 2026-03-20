import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';
import '../helpers/app_formatters.dart';
import '../models/cuota_pago.dart';

class TablaAmortizacion extends StatelessWidget {
  final List<CuotaPago> cuotas;
  final double montoOriginal;
  final double tasaInteres;
  final double cuotaMensual;
  final DateTime fechaInicio;

  const TablaAmortizacion({
    super.key,
    required this.cuotas,
    required this.montoOriginal,
    required this.tasaInteres,
    required this.cuotaMensual,
    required this.fechaInicio,
  });

  @override
  Widget build(BuildContext context) {
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
              Container(
                width: 1,
                height: 30,
                color: AppColors.divider,
              ),
              Expanded(
                child: _resumenItem(
                  'Cuota',
                  AppFormatters.moneda(cuotaMensual),
                  AppColors.primary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Tabla
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            columnSpacing: 10,
            headingRowHeight: 44,
            dataRowMinHeight: 36,
            dataRowMaxHeight: 40,
            headingRowColor: WidgetStateProperty.all(
              AppColors.primary.withValues(alpha: 0.1),
            ),
            columns: [
              DataColumn(label: _headerText('#')),
              DataColumn(label: _headerText('Días'), numeric: true),
              DataColumn(label: _headerText('Fecha')),
              DataColumn(label: _headerText('Fecha\nde pago')),
              DataColumn(label: _headerText('Saldo del\npréstamo'), numeric: true),
              DataColumn(label: _headerText('Adeudado'), numeric: true),
              DataColumn(label: _headerText('Pagado'), numeric: true),
              DataColumn(label: _headerText('Por\nadelantado'), numeric: true),
              DataColumn(label: _headerText('Tarde'), numeric: true),
              DataColumn(label: _headerText('Pendiente'), numeric: true),
            ],
            rows: _buildRows(),
          ),
        ),
      ],
    );
  }

  List<DataRow> _buildRows() {
    final rows = <DataRow>[];

    // Row 0 - Desembolso (interés del primer mes)
    final interesInicial = montoOriginal * (tasaInteres / 100);
    rows.add(DataRow(
      color: WidgetStateProperty.all(
          AppColors.primary.withValues(alpha: 0.05)),
      cells: [
        const DataCell(Text('')),
        const DataCell(Text('')),
        DataCell(_cellText(AppFormatters.fechaCorta(fechaInicio))),
        const DataCell(Text('')),
        DataCell(_cellText(AppFormatters.moneda(montoOriginal))),
        DataCell(_cellText(AppFormatters.moneda(interesInicial))),
        DataCell(_cellText(AppFormatters.moneda(interesInicial))),
        const DataCell(Text('')),
        const DataCell(Text('')),
        const DataCell(Text('')),
      ],
    ));

    // Cuotas
    DateTime fechaAnterior = fechaInicio;
    for (int i = 0; i < cuotas.length; i++) {
      final c = cuotas[i];
      final dias = c.fechaPago.difference(fechaAnterior).inDays;
      fechaAnterior = c.fechaPago;

      // Saldo del préstamo ANTES de pagar esta cuota
      final saldoPrestamo = c.saldo + c.capital;

      final adeudado = cuotaMensual;

      // Clasificar pago según fecha real vs fecha programada
      double pagado = 0.0;
      double porAdelantado = 0.0;
      double tarde = 0.0;
      double pendiente = 0.0;

      if (c.pagado && c.fechaPagado != null) {
        pagado = adeudado;
        if (!c.fechaPagado!.isAfter(c.fechaPago)) {
          porAdelantado = adeudado;
        } else {
          tarde = adeudado;
        }
      } else {
        pendiente = adeudado;
      }

      rows.add(DataRow(
        color: WidgetStateProperty.resolveWith<Color?>((states) {
          if (c.pagado) {
            return AppColors.successLight.withValues(alpha: 0.3);
          }
          return null;
        }),
        cells: [
          DataCell(_cellText('${c.cuotaNumero}')),
          DataCell(_cellText('$dias')),
          DataCell(_cellText(AppFormatters.fechaCorta(c.fechaPago))),
          DataCell(_cellText(c.fechaPagado != null
              ? AppFormatters.fechaCorta(c.fechaPagado!)
              : '')),
          DataCell(_cellText(AppFormatters.moneda(saldoPrestamo))),
          DataCell(_cellText(AppFormatters.moneda(adeudado))),
          DataCell(_cellText(AppFormatters.moneda(pagado))),
          DataCell(_cellText(AppFormatters.moneda(porAdelantado))),
          DataCell(_cellText(AppFormatters.moneda(tarde))),
          DataCell(_cellText(AppFormatters.moneda(pendiente))),
        ],
      ));
    }

    return rows;
  }

  Widget _headerText(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.bold,
        color: AppColors.textPrimary,
      ),
    );
  }

  Widget _cellText(String text) {
    return Text(
      text,
      style: const TextStyle(fontSize: 11),
    );
  }

  Widget _resumenItem(String label, String value, Color color) {
    return Column(
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            value,
            style: AppTextStyles.titleSmall.copyWith(color: color),
          ),
        ),
        const SizedBox(height: 2),
        Text(label, style: AppTextStyles.caption),
      ],
    );
  }
}
