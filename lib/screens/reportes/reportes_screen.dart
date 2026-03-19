import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_strings.dart';
import '../../constants/app_text_styles.dart';
import '../../helpers/app_formatters.dart';
import '../../providers/prestamo_provider.dart';
import '../../router/app_routes.dart';
import '../../services/carpeta_service.dart';
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

              // KPI cards
              Row(
                children: [
                  Expanded(
                    child: StatCard(
                      titulo: AppStrings.totalCobrado,
                      valor: AppFormatters.moneda(r.totalCobradoMes),
                      icono: Icons.trending_up,
                      color: AppColors.success,
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

              // Gráfica de barras
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
                onPressed: () {
                  // TODO: Generar reporte PDF completo
                },
                icon: const Icon(Icons.picture_as_pdf),
                label: const Text(AppStrings.exportarPDF),
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
