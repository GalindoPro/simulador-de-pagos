import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_strings.dart';
import '../../helpers/app_formatters.dart';
import '../../providers/pago_provider.dart';
import '../../providers/cliente_provider.dart';
import '../../router/app_routes.dart';
import '../../widgets/stat_card.dart';
import '../../widgets/pago_list_tile.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/confirm_dialog.dart';
import '../../widgets/app_error_widget.dart';

class PagosScreen extends ConsumerWidget {
  const PagosScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pagosAsync = ref.watch(pagosFiltradosProvider);
    final filtro = ref.watch(pagosFiltroProvider);
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
        title: const Text(AppStrings.pagos),
      ),
      body: Column(
        children: [
          // Stats header
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
            child: ref.watch(resumenPagosProvider).when(
                  data: (r) => Row(
                    children: [
                      Expanded(
                        child: StatCard(
                          titulo: 'Cobrado mes',
                          valor: AppFormatters.moneda(r['cobrado']?.toDouble() ?? 0),
                          icono: Icons.trending_up,
                          color: AppColors.success,
                        ),
                      ),
                      Expanded(
                        child: StatCard(
                          titulo: 'Pendiente',
                          valor: AppFormatters.moneda(r['pendiente']?.toDouble() ?? 0),
                          icono: Icons.pending,
                          color: AppColors.warning,
                        ),
                      ),
                      Expanded(
                        child: StatCard(
                          titulo: 'Completados',
                          valor: '${r['completados'] ?? 0}',
                          icono: Icons.check_circle,
                          color: AppColors.info,
                        ),
                      ),
                    ],
                  ),
                  loading: () => const SizedBox(height: 80),
                  error: (_, _) => const SizedBox.shrink(),
                ),
          ),

          // Filtros
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                _filtroChip(ref, 'Todos', null, filtro.estado),
                const SizedBox(width: 8),
                _filtroChip(ref, 'Pendiente', 'pendiente', filtro.estado),
                const SizedBox(width: 8),
                _filtroChip(
                    ref, 'Completado', 'completado', filtro.estado),
              ],
            ),
          ),

          // Búsqueda
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Buscar por concepto...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: EdgeInsets.zero,
              ),
              onChanged: (v) {
                ref.read(pagosFiltroProvider.notifier).state =
                    filtro.copyWith(busqueda: v);
              },
            ),
          ),
          const SizedBox(height: 8),

          // Lista
          Expanded(
            child: pagosAsync.when(
              data: (pagos) {
                if (pagos.isEmpty) {
                  return EmptyState(
                    mensaje: AppStrings.sinPagos,
                    icono: Icons.attach_money,
                    textoAccion: AppStrings.nuevoPago,
                    onAccion: () => context.push(AppRoutes.nuevoPago),
                  );
                }

                final clientes = clientesAsync.valueOrNull ?? [];

                return RefreshIndicator(
                  onRefresh: () async {
                    ref.invalidate(pagosProvider);
                    ref.invalidate(resumenPagosProvider);
                  },
                  child: ListView.builder(
                    itemCount: pagos.length,
                    itemBuilder: (ctx, i) {
                      final p = pagos[i];
                      final cliente = clientes
                          .where((c) => c.id == p.clienteId)
                          .firstOrNull;

                      return Dismissible(
                        key: Key(p.id),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          color: AppColors.error,
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          child: const Icon(Icons.delete,
                              color: Colors.white),
                        ),
                        confirmDismiss: (_) => ConfirmDialog.show(
                          context,
                          titulo: AppStrings.eliminar,
                          mensaje: AppStrings.confirmarEliminar,
                        ),
                        onDismissed: (_) {
                          ref.read(pagosProvider.notifier).eliminar(p.id);
                        },
                        child: PagoListTile(
                          pago: p,
                          cliente: cliente,
                          onTap: () => context.push('/pagos/${p.id}'),
                        ),
                      );
                    },
                  ),
                );
              },
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) => AppErrorWidget(
                mensaje: e.toString(),
                onRetry: () => ref.invalidate(pagosProvider),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push(AppRoutes.nuevoPago),
        child: const Icon(Icons.add),
      ),
    ),
    );
  }

  Widget _filtroChip(
      WidgetRef ref, String label, String? valor, String? actual) {
    return FilterChip(
      label: Text(label),
      selected: actual == valor,
      onSelected: (_) {
        final filtro = ref.read(pagosFiltroProvider);
        ref.read(pagosFiltroProvider.notifier).state =
            filtro.copyWith(estado: valor ?? '');
      },
      selectedColor: AppColors.primaryLight,
    );
  }
}
