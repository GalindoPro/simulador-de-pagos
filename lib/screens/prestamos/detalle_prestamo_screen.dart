import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_strings.dart';
import '../../constants/app_text_styles.dart';
import '../../helpers/app_formatters.dart';
import '../../providers/prestamo_provider.dart';
import '../../providers/cliente_provider.dart';
import '../../services/carpeta_service.dart';
import '../../widgets/app_snack_bar.dart';
import '../../widgets/tabla_amortizacion.dart';
import '../../widgets/app_error_widget.dart';

class DetallePrestamoScreen extends ConsumerStatefulWidget {
  final String prestamoId;

  const DetallePrestamoScreen({super.key, required this.prestamoId});

  @override
  ConsumerState<DetallePrestamoScreen> createState() =>
      _DetallePrestamoScreenState();
}

class _DetallePrestamoScreenState
    extends ConsumerState<DetallePrestamoScreen> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refrescarDatos();
    }
  }

  void _refrescarDatos() {
    ref.invalidate(cuotasPrestamoProvider(widget.prestamoId));
    ref.invalidate(prestamosProvider);
  }

  @override
  Widget build(BuildContext context) {
    final prestamoId = widget.prestamoId;
    final prestamosAsync = ref.watch(prestamosProvider);

    return prestamosAsync.when(
      data: (prestamos) {
        final prestamo =
            prestamos.where((p) => p.id == prestamoId).firstOrNull;
        if (prestamo == null) {
          return Scaffold(
            appBar: AppBar(),
            body: const Center(child: Text('Préstamo no encontrado')),
          );
        }

        final clienteAsync =
            ref.watch(clientePorIdProvider(prestamo.clienteId));
        final cuotasAsync =
            ref.watch(cuotasPrestamoProvider(prestamoId));

        return Scaffold(
          appBar: AppBar(
            title: const Text(AppStrings.detallePrestamo),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () =>
                    context.push('/prestamos/$prestamoId/editar'),
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Banner vencido
                if (prestamo.estaVencido)
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: AppColors.errorLight,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.warning, color: AppColors.error),
                        const SizedBox(width: 8),
                        Text('Préstamo vencido',
                            style: AppTextStyles.titleSmall
                                .copyWith(color: AppColors.error)),
                      ],
                    ),
                  ),

                // Resumen
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        clienteAsync.when(
                          data: (c) => Text(
                            c?.nombreCompleto ?? 'Cliente',
                            style: AppTextStyles.headlineSmall,
                          ),
                          loading: () => const SizedBox.shrink(),
                          error: (_, _) => const SizedBox.shrink(),
                        ),
                        const SizedBox(height: 16),
                        _datoRow('Monto original',
                            AppFormatters.moneda(prestamo.montoOriginal)),
                        _datoRow('Saldo pendiente',
                            AppFormatters.moneda(prestamo.saldoPendiente)),
                        _datoRow('Tasa',
                            AppFormatters.porcentaje(prestamo.tasaInteres)),
                        _datoRow('Plazo', '${prestamo.plazoMeses} meses'),
                        _datoRow('Cuota mensual',
                            AppFormatters.moneda(prestamo.cuotaMensual)),
                        _datoRow('Total a pagar',
                            AppFormatters.moneda(prestamo.totalPagar)),
                        _datoRow('Fecha inicio',
                            AppFormatters.fechaCorta(prestamo.fechaInicio)),
                        _datoRow('Fecha vencimiento',
                            AppFormatters.fechaCorta(prestamo.fechaVencimiento)),
                        if (prestamo.garantia != null)
                          _datoRow('Garantía', prestamo.garantia!),
                        const SizedBox(height: 12),
                        LinearProgressIndicator(
                          value: prestamo.progreso,
                          backgroundColor: AppColors.divider,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            prestamo.estaVencido
                                ? AppColors.error
                                : AppColors.primary,
                          ),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${(prestamo.progreso * 100).toStringAsFixed(1)}% pagado',
                          style: AppTextStyles.caption,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Tabla de cuotas
                Text(AppStrings.tablaAmortizacion,
                    style: AppTextStyles.titleMedium),
                const SizedBox(height: 8),
                cuotasAsync.when(
                  data: (cuotas) => TablaAmortizacion(cuotas: cuotas),
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Text('Error: $e'),
                ),
                const SizedBox(height: 16),

                // Botón registrar pago
                if (prestamo.estado == 'activo')
                  ElevatedButton.icon(
                    onPressed: () async {
                      await context.push(
                        '/pagos/nuevo?prestamoId=$prestamoId&clienteId=${prestamo.clienteId}',
                      );
                      _refrescarDatos();
                    },
                    icon: const Icon(Icons.payment),
                    label: const Text('Registrar Pago'),
                  ),

                // Botón finiquito
                if (prestamo.estaPagado) ...[
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: () async {
                      final cliente = await ref.read(
                          clientePorIdProvider(prestamo.clienteId).future);
                      if (cliente != null) {
                        await CarpetaService.instance
                            .generarFiniquito(cliente, prestamo);
                        if (context.mounted) {
                          AppSnackBar.exito(
                              context, 'Finiquito generado exitosamente');
                        }
                      }
                    },
                    icon: const Icon(Icons.description),
                    label: const Text('Generar Finiquito'),
                  ),
                ],
                const SizedBox(height: 32),
              ],
            ),
          ),
        );
      },
      loading: () => Scaffold(
        appBar: AppBar(),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        appBar: AppBar(),
        body: AppErrorWidget(mensaje: e.toString()),
      ),
    );
  }

  Widget _datoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTextStyles.bodySmall),
          Text(value, style: AppTextStyles.titleSmall),
        ],
      ),
    );
  }
}
