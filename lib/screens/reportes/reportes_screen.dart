import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_strings.dart';
import '../../constants/app_text_styles.dart';
import '../../helpers/app_formatters.dart';
import '../../providers/auth_provider.dart';
import '../../models/resumen_financiero.dart';
import '../../providers/prestamo_provider.dart';
import '../../router/app_routes.dart';
import '../../services/carpeta_service.dart';
import '../../widgets/app_snack_bar.dart';
import '../../widgets/stat_card.dart';
import '../../widgets/app_error_widget.dart';

class ReportesScreen extends ConsumerStatefulWidget {
  const ReportesScreen({super.key});

  @override
  ConsumerState<ReportesScreen> createState() => _ReportesScreenState();
}

class _ReportesScreenState extends ConsumerState<ReportesScreen> {
  DateTime _mesActual = DateTime(DateTime.now().year, DateTime.now().month);

  void _mesAnterior() {
    setState(() {
      _mesActual = DateTime(_mesActual.year, _mesActual.month - 1);
    });
  }

  void _mesSiguiente() {
    setState(() {
      _mesActual = DateTime(_mesActual.year, _mesActual.month + 1);
    });
  }

  bool _exportando = false;

  Future<void> _exportarPDF(dynamic r) async {
    if (_exportando) return;
    setState(() => _exportando = true);

    try {
      final usuario = ref.read(sesionActualProvider);
      final capitalDisp =
          ref.read(capitalDisponibleProvider).valueOrNull ?? 0;

      final path = await CarpetaService.instance.generarReporteFinanciero(
        nombreUsuario: usuario?.nombre ?? 'Usuario',
        capitalInicial: usuario?.capitalInicial ?? 0,
        capitalDisponible: capitalDisp,
        totalCobradoMes: r.totalCobradoMes,
        totalPrestado: r.totalPrestado,
        saldoPendiente: r.saldoPendiente,
        interesDelMes: r.interesDelMes,
        prestamosActivos: r.prestamosActivos,
        prestamosVencidos: r.prestamosVencidos,
        totalClientes: r.totalClientes,
        clientesNuevosMes: r.clientesNuevosMes,
        tasaMorosidad: r.tasaMorosidad,
        pagosPorMes: r.pagosPorMes,
        prestamosPorMes: r.prestamosPorMes,
      );

      await CarpetaService.instance.compartirArchivo(path);

      if (mounted) {
        AppSnackBar.exito(context, 'Reporte PDF generado y compartido');
      }
    } catch (e) {
      if (mounted) {
        AppSnackBar.error(context, 'Error al generar PDF: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _exportando = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final resumenAsync = ref.watch(resumenFinancieroProvider);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) context.go(AppRoutes.dashboard);
      },
      child: Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go(AppRoutes.dashboard),
        ),
        title: const Text(AppStrings.reportes),
      ),
      body: resumenAsync.when(
        data: (r) => SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Selector de mes
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    onPressed: _mesAnterior,
                    icon: const Icon(Icons.chevron_left),
                  ),
                  Text(
                    AppFormatters.fechaMes(_mesActual),
                    style: AppTextStyles.titleMedium,
                  ),
                  IconButton(
                    onPressed: _mesSiguiente,
                    icon: const Icon(Icons.chevron_right),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Capital section
              _buildCapitalCard(r),
              const SizedBox(height: 16),

              // KPI cards
              Row(
                children: [
                  Expanded(
                    child: StatCard(
                      titulo: AppStrings.totalCobrado,
                      valor: AppFormatters.moneda(r.totalCobradoMes),
                      icono: Icons.trending_up,
                      color: AppColors.success,
                      subtitulo: 'Este mes',
                    ),
                  ),
                  Expanded(
                    child: StatCard(
                      titulo: AppStrings.totalPrestado,
                      valor: AppFormatters.moneda(r.totalPrestado),
                      icono: Icons.account_balance,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Expanded(
                    child: StatCard(
                      titulo: 'Ganancias totales',
                      valor: AppFormatters.moneda(r.interesesTotales),
                      icono: Icons.savings,
                      color: Colors.teal,
                    ),
                  ),
                  Expanded(
                    child: StatCard(
                      titulo: AppStrings.interesDelMes,
                      valor: AppFormatters.moneda(r.interesDelMes),
                      icono: Icons.percent,
                      color: Colors.deepPurple,
                      subtitulo: 'Este mes',
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Expanded(
                    child: StatCard(
                      titulo: AppStrings.tasaMorosidad,
                      valor: AppFormatters.porcentaje(r.tasaMorosidad),
                      icono: Icons.warning,
                      color: AppColors.warning,
                    ),
                  ),
                  Expanded(
                    child: StatCard(
                      titulo: AppStrings.clientesNuevos,
                      valor: '${r.clientesNuevosMes}',
                      icono: Icons.person_add,
                      color: AppColors.info,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Gráfica circular - Distribución de capital
              _buildPieChartCard(r),
              const SizedBox(height: 24),

              // Gráfica de barras cobros
              Text(AppStrings.cobrosPorMes,
                  style: AppTextStyles.titleMedium),
              const SizedBox(height: 12),
              SizedBox(
                height: 200,
                child: _buildBarChart(r.pagosPorMes),
              ),
              const SizedBox(height: 24),

              // Botones
              ElevatedButton.icon(
                onPressed: _exportando ? null : () => _exportarPDF(r),
                icon: _exportando
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.picture_as_pdf),
                label: Text(_exportando ? 'Generando...' : AppStrings.exportarPDF),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () {
                  CarpetaService.instance.compartirBaseDatos();
                },
                icon: const Icon(Icons.share),
                label: const Text(AppStrings.compartirDB),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => AppErrorWidget(
          mensaje: e.toString(),
          onRetry: () => ref.invalidate(resumenFinancieroProvider),
        ),
      ),
    ),
    );
  }

  Widget _buildCapitalCard(ResumenFinanciero r) {
    final usuario = ref.watch(sesionActualProvider);
    final capitalInicial = usuario?.capitalInicial ?? 0;
    final capitalDisp = capitalInicial - r.saldoPendiente;
    final capitalConGanancias = capitalInicial + r.interesesTotales;
    final porcentajeInvertido =
        capitalInicial > 0 ? (r.saldoPendiente / capitalInicial * 100) : 0.0;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.account_balance_wallet,
                    color: AppColors.primary, size: 22),
                const SizedBox(width: 8),
                Text('Resumen de Capital', style: AppTextStyles.titleMedium),
              ],
            ),
            const Divider(height: 20),
            _capitalRow(
              'Capital inicial',
              AppFormatters.moneda(capitalInicial),
              Icons.flag,
              AppColors.primary,
            ),
            _capitalRow(
              AppStrings.capitalDisponible,
              AppFormatters.moneda(capitalDisp),
              Icons.account_balance,
              capitalDisp > 0 ? AppColors.success : AppColors.error,
            ),
            _capitalRow(
              'Capital invertido',
              AppFormatters.moneda(r.saldoPendiente),
              Icons.trending_up,
              Colors.orange,
            ),
            _capitalRow(
              'Capital + Ganancias',
              AppFormatters.moneda(capitalConGanancias),
              Icons.emoji_events,
              Colors.teal,
            ),
            const SizedBox(height: 8),
            // Barra de progreso de capital invertido
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Capital invertido: ${porcentajeInvertido.toStringAsFixed(1)}%',
                  style: AppTextStyles.labelSmall,
                ),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: capitalInicial > 0
                        ? (r.saldoPendiente / capitalInicial).clamp(0.0, 1.0)
                        : 0,
                    minHeight: 8,
                    backgroundColor: Colors.grey.shade200,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      porcentajeInvertido > 90
                          ? AppColors.error
                          : porcentajeInvertido > 70
                              ? Colors.orange
                              : AppColors.success,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _capitalRow(String label, String value, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(label, style: AppTextStyles.bodySmall),
          ),
          Text(
            value,
            style: AppTextStyles.titleSmall.copyWith(color: color),
          ),
        ],
      ),
    );
  }

  Widget _buildPieChartCard(ResumenFinanciero r) {
    final usuario = ref.watch(sesionActualProvider);
    final capitalInicial = usuario?.capitalInicial ?? 0;
    final capitalDisp = capitalInicial - r.saldoPendiente;
    final ganancias = r.interesesTotales;

    final labels = <String>[];
    final values = <double>[];
    final colors = <Color>[];

    if (capitalDisp > 0) {
      labels.add('Disponible');
      values.add(capitalDisp);
      colors.add(AppColors.success);
    }
    if (r.saldoPendiente > 0) {
      labels.add('Invertido');
      values.add(r.saldoPendiente);
      colors.add(AppColors.primary);
    }
    if (ganancias > 0) {
      labels.add('Ganancias');
      values.add(ganancias);
      colors.add(Colors.teal);
    }

    if (values.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: Text('Sin datos de capital', style: AppTextStyles.bodySmall),
          ),
        ),
      );
    }

    final total = values.fold<double>(0, (s, v) => s + v);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text('Distribución de Capital', style: AppTextStyles.titleMedium),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: PieChart(
                PieChartData(
                  sectionsSpace: 3,
                  centerSpaceRadius: 40,
                  sections: List.generate(values.length, (i) {
                    final pct = (values[i] / total * 100);
                    return PieChartSectionData(
                      color: colors[i],
                      value: values[i],
                      title: '${pct.toStringAsFixed(1)}%',
                      radius: 55,
                      titleStyle: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    );
                  }),
                ),
              ),
            ),
            const SizedBox(height: 16),
            ...List.generate(values.length, (i) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Row(
                    children: [
                      Container(
                        width: 14,
                        height: 14,
                        decoration: BoxDecoration(
                          color: colors[i],
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(labels[i], style: AppTextStyles.bodySmall),
                      ),
                      Text(
                        AppFormatters.moneda(values[i]),
                        style: AppTextStyles.titleSmall.copyWith(color: colors[i]),
                      ),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildBarChart(Map<String, double> datos) {
    if (datos.isEmpty) {
      return const Center(child: Text('Sin datos'));
    }

    final entries = datos.entries.toList();
    final maxY = entries.map((e) => e.value).reduce((a, b) => a > b ? a : b);

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxY > 0 ? maxY * 1.2 : 100,
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              return BarTooltipItem(
                AppFormatters.moneda(rod.toY),
                AppTextStyles.labelSmall.copyWith(color: Colors.white),
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final idx = value.toInt();
                if (idx >= 0 && idx < entries.length) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      entries[idx].key,
                      style: AppTextStyles.labelSmall,
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
          leftTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        borderData: FlBorderData(show: false),
        gridData: const FlGridData(show: false),
        barGroups: List.generate(entries.length, (i) {
          return BarChartGroupData(
            x: i,
            barRods: [
              BarChartRodData(
                toY: entries[i].value,
                color: AppColors.primary,
                width: 20,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(4)),
              ),
            ],
          );
        }),
      ),
    );
  }
}
