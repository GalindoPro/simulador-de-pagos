import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_strings.dart';
import '../../constants/app_text_styles.dart';
import '../../helpers/app_formatters.dart';
import '../../providers/auth_provider.dart';
import '../../providers/prestamo_provider.dart';
import '../../providers/pago_provider.dart';
import '../../providers/cliente_provider.dart';
import '../../router/app_routes.dart';
import '../../widgets/stat_card.dart';
import '../../widgets/seccion_header.dart';
import '../../widgets/pago_list_tile.dart';
import '../../widgets/prestamo_card.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  int _currentIndex = 0;
  DateTime? _lastBackPress;

  void _refrescarDashboard() {
    ref.invalidate(resumenFinancieroProvider);
    ref.invalidate(pagosRecientesProvider(5));
    ref.invalidate(proximosAVencerProvider);
    ref.invalidate(clientesProvider);
  }

  @override
  Widget build(BuildContext context) {
    final usuario = ref.watch(sesionActualProvider);
    final resumenAsync = ref.watch(resumenFinancieroProvider);
    final pagosRecientes = ref.watch(pagosRecientesProvider(5));
    final proximosVencer = ref.watch(proximosAVencerProvider);
    final clientesAsync = ref.watch(clientesProvider);

    final nombreUsuario = usuario?.nombre ?? 'Usuario';
    final capital = usuario?.capitalInicial ?? 0;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        final now = DateTime.now();
        if (_lastBackPress != null &&
            now.difference(_lastBackPress!) < const Duration(seconds: 2)) {
          Navigator.of(context).pop();
          return;
        }
        _lastBackPress = now;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Presiona atrás de nuevo para salir'),
            duration: Duration(seconds: 2),
          ),
        );
      },
      child: Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(resumenFinancieroProvider);
            ref.invalidate(pagosRecientesProvider(5));
            ref.invalidate(proximosAVencerProvider);
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${AppFormatters.saludo()}, $nombreUsuario',
                            style: AppTextStyles.headlineSmall,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            AppFormatters.fechaActual(),
                            style: AppTextStyles.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    CircleAvatar(
                      backgroundColor: AppColors.primary,
                      child: Text(
                        nombreUsuario.isNotEmpty
                            ? nombreUsuario[0].toUpperCase()
                            : 'U',
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '${AppStrings.capitalDisponible}: ${AppFormatters.moneda(capital)}',
                  style: AppTextStyles.moneda,
                ),
                const SizedBox(height: 24),

                // Acciones rápidas
                Row(
                  children: [
                    _accionRapida(
                      Icons.person_add,
                      'Nuevo\nCliente',
                      () async {
                        await context.push(AppRoutes.nuevoCliente);
                        _refrescarDashboard();
                      },
                    ),
                    const SizedBox(width: 12),
                    _accionRapida(
                      Icons.description,
                      'Nuevo\nPréstamo',
                      () async {
                        await context.push(AppRoutes.nuevoPrestamo);
                        _refrescarDashboard();
                      },
                    ),
                    const SizedBox(width: 12),
                    _accionRapida(
                      Icons.calculate,
                      'Simulador',
                      () => context.push(AppRoutes.simulador),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Grid de stats
                resumenAsync.when(
                  data: (r) => Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: StatCard(
                              titulo: AppStrings.interesDelMes,
                              valor: AppFormatters.moneda(r.interesDelMes),
                              icono: Icons.trending_up,
                              color: AppColors.success,
                            ),
                          ),
                          Expanded(
                            child: StatCard(
                              titulo: AppStrings.clientesActivos,
                              valor: '${r.totalClientes}',
                              icono: Icons.people,
                              color: AppColors.info,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: StatCard(
                              titulo: AppStrings.prestamosActivos,
                              valor: '${r.prestamosActivos}',
                              icono: Icons.payments,
                              color: AppColors.primary,
                            ),
                          ),
                          Expanded(
                            child: StatCard(
                              titulo: AppStrings.prestamosVencidos,
                              valor: '${r.prestamosVencidos}',
                              icono: Icons.warning,
                              color: AppColors.error,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: StatCard(
                              titulo: AppStrings.cobradoEsteMes,
                              valor:
                                  AppFormatters.moneda(r.totalCobradoMes),
                              icono: Icons.attach_money,
                              color: AppColors.success,
                            ),
                          ),
                          Expanded(
                            child: StatCard(
                              titulo: AppStrings.saldoPendiente,
                              valor:
                                  AppFormatters.moneda(r.saldoPendiente),
                              icono: Icons.account_balance_wallet,
                              color: AppColors.warning,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Gráfica
                      if (r.pagosPorMes.isNotEmpty) ...[
                        Text(AppStrings.cobrosPorMes,
                            style: AppTextStyles.titleMedium),
                        const SizedBox(height: 12),
                        SizedBox(
                          height: 200,
                          child: _buildBarChart(r.pagosPorMes),
                        ),
                      ],
                    ],
                  ),
                  loading: () => const Center(
                      child: Padding(
                    padding: EdgeInsets.all(32),
                    child: CircularProgressIndicator(),
                  )),
                  error: (_, _) => const SizedBox.shrink(),
                ),
                const SizedBox(height: 16),

                // Últimos pagos
                SeccionHeader(
                  titulo: AppStrings.ultimosPagos,
                  onVerTodos: () {
                    context.go(AppRoutes.pagos);
                  },
                ),
                pagosRecientes.when(
                  data: (pagos) {
                    if (pagos.isEmpty) {
                      return Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text('Sin pagos recientes',
                            style: AppTextStyles.bodySmall),
                      );
                    }
                    final clientes =
                        clientesAsync.valueOrNull ?? [];
                    return Column(
                      children: pagos.map((p) {
                        final cliente = clientes
                            .where((c) => c.id == p.clienteId)
                            .firstOrNull;
                        return PagoListTile(
                          pago: p,
                          cliente: cliente,
                          onTap: () async {
                            await context.push('/pagos/${p.id}');
                            _refrescarDashboard();
                          },
                        );
                      }).toList(),
                    );
                  },
                  loading: () => const SizedBox.shrink(),
                  error: (_, _) => const SizedBox.shrink(),
                ),
                const SizedBox(height: 16),

                // Próximos a vencer
                SeccionHeader(
                  titulo: AppStrings.proximosVencer,
                  onVerTodos: () => context.go(AppRoutes.prestamos),
                ),
                proximosVencer.when(
                  data: (prestamos) {
                    if (prestamos.isEmpty) {
                      return Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text('Sin préstamos próximos a vencer',
                            style: AppTextStyles.bodySmall),
                      );
                    }
                    final clientes =
                        clientesAsync.valueOrNull ?? [];
                    return Column(
                      children: prestamos.map((p) {
                        final cliente = clientes
                            .where((c) => c.id == p.clienteId)
                            .firstOrNull;
                        return PrestamoCard(
                          prestamo: p,
                          cliente: cliente,
                          onTap: () async {
                            await context.push('/prestamos/${p.id}');
                            _refrescarDashboard();
                          },
                        );
                      }).toList(),
                    );
                  },
                  loading: () => const SizedBox.shrink(),
                  error: (_, _) => const SizedBox.shrink(),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (i) {
          setState(() {
            _currentIndex = i;
          });
          switch (i) {
            case 0:
              _refrescarDashboard();
              context.go(AppRoutes.dashboard);
              break;
            case 1:
              context.go(AppRoutes.clientes);
              break;
            case 2:
              context.go(AppRoutes.prestamos);
              break;
            case 3:
              context.go(AppRoutes.pagos);
              break;
            case 4:
              context.go(AppRoutes.reportes);
              break;
            case 5:
              context.go(AppRoutes.configuracion);
              break;
          }
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: AppStrings.inicio,
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people),
            label: AppStrings.clientes,
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.payments),
            label: AppStrings.prestamos,
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.attach_money),
            label: AppStrings.pagos,
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart),
            label: AppStrings.reportes,
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: AppStrings.configuracion,
          ),
        ],
      ),
    ),
    );
  }

  Widget _accionRapida(IconData icon, String label, VoidCallback onTap) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              Icon(icon, color: AppColors.primary, size: 28),
              const SizedBox(height: 8),
              Text(
                label,
                style: AppTextStyles.labelMedium,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBarChart(Map<String, double> datos) {
    final entries = datos.entries.toList();
    final maxY =
        entries.map((e) => e.value).reduce((a, b) => a > b ? a : b);

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
