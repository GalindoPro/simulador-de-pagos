import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_strings.dart';
import '../../helpers/app_formatters.dart';
import '../../providers/prestamo_provider.dart';
import '../../providers/cliente_provider.dart';
import '../../router/app_routes.dart';
import '../../widgets/stat_card.dart';
import '../../widgets/prestamo_card.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/app_error_widget.dart';

class PrestamosScreen extends ConsumerStatefulWidget {
  const PrestamosScreen({super.key});

  @override
  ConsumerState<PrestamosScreen> createState() => _PrestamosScreenState();
}

class _PrestamosScreenState extends ConsumerState<PrestamosScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => _refrescar());
  }

  void _refrescar() {
    ref.invalidate(prestamosProvider);
    ref.invalidate(resumenFinancieroProvider);
  }

  @override
  Widget build(BuildContext context) {
    final prestamosAsync = ref.watch(prestamosFiltradosProvider);
    final filtroActual = ref.watch(prestamosFiltroProvider);
    final clientesAsync = ref.watch(clientesProvider);

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
        title: const Text(AppStrings.prestamos),
      ),
      body: SafeArea(
        top: false,
        child: Column(
        children: [
          // Header stats
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
            child: ref.watch(resumenFinancieroProvider).when(
                  data: (r) => Row(
                    children: [
                      Expanded(
                        child: StatCard(
                          titulo: 'Total prestado',
                          valor: AppFormatters.moneda(r.totalPrestado),
                          icono: Icons.account_balance,
                          color: AppColors.primary,
                        ),
                      ),
                      Expanded(
                        child: StatCard(
                          titulo: 'Activos',
                          valor: '${r.prestamosActivos}',
                          icono: Icons.trending_up,
                          color: AppColors.info,
                        ),
                      ),
                      Expanded(
                        child: StatCard(
                          titulo: 'Vencidos',
                          valor: '${r.prestamosVencidos}',
                          icono: Icons.warning,
                          color: AppColors.error,
                        ),
                      ),
                    ],
                  ),
                  loading: () => const SizedBox(height: 80),
                  error: (_, _) => const SizedBox.shrink(),
                ),
          ),

          // Filter chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                _filtroChip('Todos', 'todos', filtroActual),
                const SizedBox(width: 8),
                _filtroChip('Activos', 'activos', filtroActual),
                const SizedBox(width: 8),
                _filtroChip('Vencidos', 'vencidos', filtroActual),
                const SizedBox(width: 8),
                _filtroChip('Pagados', 'pagados', filtroActual),
              ],
            ),
          ),

          // Lista
          Expanded(
            child: prestamosAsync.when(
              data: (prestamos) {
                if (prestamos.isEmpty) {
                  return EmptyState(
                    mensaje: AppStrings.sinPrestamos,
                    icono: Icons.payments_outlined,
                    textoAccion: AppStrings.nuevoPrestamo,
                    onAccion: () async {
                      await context.push(AppRoutes.nuevoPrestamo);
                      _refrescar();
                    },
                  );
                }

                final clientes = clientesAsync.valueOrNull ?? [];

                return RefreshIndicator(
                  onRefresh: () async {
                    ref.invalidate(prestamosProvider);
                  },
                  child: ListView.builder(
                    itemCount: prestamos.length,
                    itemBuilder: (ctx, i) {
                      final p = prestamos[i];
                      final cliente = clientes
                          .where((c) => c.id == p.clienteId)
                          .firstOrNull;
                      return PrestamoCard(
                        prestamo: p,
                        cliente: cliente,
                        onTap: () async {
                          await context.push('/prestamos/${p.id}');
                          _refrescar();
                        },
                      );
                    },
                  ),
                );
              },
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) => AppErrorWidget(
                mensaje: e.toString(),
                onRetry: () => ref.invalidate(prestamosProvider),
              ),
            ),
          ),
        ],
      ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await context.push(AppRoutes.nuevoPrestamo);
          _refrescar();
        },
        child: const Icon(Icons.add),
      ),
    ),
    );
  }

  Widget _filtroChip(String label, String valor, String actual) {
    final isSelected = actual == valor;
    return FilterChip(
      label: Text(
        label,
        style: TextStyle(
          color: AppColors.textPrimary,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
      selected: isSelected,
      onSelected: (_) {
        ref.read(prestamosFiltroProvider.notifier).state = valor;
      },
      selectedColor: AppColors.primaryLight,
    );
  }
}
