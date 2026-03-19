import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_strings.dart';
import '../../helpers/app_formatters.dart';
import '../../providers/pago_provider.dart';
import '../../providers/cliente_provider.dart';
import '../../providers/prestamo_provider.dart';
import '../../router/app_routes.dart';
import '../../services/carpeta_service.dart';
import '../../widgets/stat_card.dart';
import '../../widgets/pago_list_tile.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/confirm_dialog.dart';
import '../../widgets/app_error_widget.dart';
import '../../widgets/app_snack_bar.dart';
import '../../models/pago.dart';
import '../../models/cliente.dart';

class PagosScreen extends ConsumerStatefulWidget {
  const PagosScreen({super.key});

  @override
  ConsumerState<PagosScreen> createState() => _PagosScreenState();
}

class _PagosScreenState extends ConsumerState<PagosScreen> {
  void _refrescarTodo() {
    ref.invalidate(pagosProvider);
    ref.invalidate(resumenPagosProvider);
  }

  @override
  Widget build(BuildContext context) {
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
                _filtroChip('Todos', null, filtro.estado),
                const SizedBox(width: 8),
                _filtroChip('Pendiente', 'pendiente', filtro.estado),
                const SizedBox(width: 8),
                _filtroChip(
                    'Completado', 'completado', filtro.estado),
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
                    onAccion: () async {
                      await context.push(AppRoutes.nuevoPago);
                      _refrescarTodo();
                    },
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
                          onTap: () async {
                            await context.push('/pagos/${p.id}');
                            _refrescarTodo();
                          },
                          onCompartirPdf: p.estaCompletado
                              ? () => _compartirRecibo(p, cliente)
                              : null,
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
        onPressed: () async {
          await context.push(AppRoutes.nuevoPago);
          _refrescarTodo();
        },
        child: const Icon(Icons.add),
      ),
    ),
    );
  }

  Future<void> _compartirRecibo(
      Pago pago, Cliente? cliente) async {
    if (pago.pdfPath != null) {
      await CarpetaService.instance.compartirArchivo(pago.pdfPath!);
    } else if (cliente != null) {
      // Regenerar recibo si no tiene ruta
      final prestamo = pago.prestamoId != null
          ? await ref
              .read(prestamoRepositoryProvider)
              .obtenerPorId(pago.prestamoId!)
          : null;
      final cuota = pago.prestamoId != null
          ? await ref
              .read(prestamoRepositoryProvider)
              .obtenerCuotaActual(pago.prestamoId!)
          : null;

      final path = await CarpetaService.instance
          .generarReciboPago(pago, cliente, cuota, prestamo);

      // Guardar ruta del PDF
      await ref
          .read(pagosProvider.notifier)
          .actualizar(pago.copyWith(pdfPath: path));

      await CarpetaService.instance.compartirArchivo(path);

      if (mounted) {
        AppSnackBar.exito(context, 'Recibo generado y compartido');
      }
    }
  }

  Widget _filtroChip(String label, String? valor, String? actual) {
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
