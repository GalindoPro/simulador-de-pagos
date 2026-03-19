import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_strings.dart';
import '../../models/prestamo.dart';
import '../../models/cuota_pago.dart';
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

  void _editarPrestamo(Prestamo prestamo) async {
    // Obtener cuotas pagadas para saber el estado actual
    final cuotas = await ref.read(
        cuotasPrestamoProvider(prestamo.id).future);
    final cuotasPagadas = cuotas.where((c) => c.pagado).length;
    final capitalPagado = cuotas
        .where((c) => c.pagado)
        .fold<double>(0, (sum, c) => sum + c.capital);
    final saldoActual = prestamo.montoOriginal - capitalPagado;

    final tasaCtrl = TextEditingController(
        text: prestamo.tasaInteres.toString());
    final garantiaCtrl = TextEditingController(text: prestamo.garantia ?? '');
    final notasCtrl = TextEditingController(text: prestamo.notas ?? '');
    int nuevoPlazo = prestamo.plazoMeses;

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          final nuevaTasa = double.tryParse(tasaCtrl.text) ?? prestamo.tasaInteres;
          final cuotasRestantes = nuevoPlazo - cuotasPagadas;
          final interesRestante = saldoActual * (nuevaTasa / 100) * cuotasRestantes;
          final nuevaCuota = cuotasRestantes > 0
              ? (saldoActual + interesRestante) / cuotasRestantes
              : 0.0;
          final nuevoTotal = capitalPagado +
              cuotas.where((c) => c.pagado).fold<double>(0, (s, c) => s + c.interes) +
              saldoActual + interesRestante;

          return Padding(
            padding: EdgeInsets.fromLTRB(
                24, 24, 24, MediaQuery.of(ctx).viewInsets.bottom + 24),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Editar Préstamo',
                      style: AppTextStyles.headlineSmall,
                      textAlign: TextAlign.center),
                  const SizedBox(height: 8),
                  Text(
                    '$cuotasPagadas de ${prestamo.plazoMeses} cuotas pagadas · Saldo: ${AppFormatters.moneda(saldoActual)}',
                    style: AppTextStyles.bodySmall,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),

                  // Tasa
                  TextField(
                    controller: tasaCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Tasa de interés (%)',
                      prefixIcon: Icon(Icons.percent),
                      suffixText: '%',
                    ),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    onChanged: (_) => setModalState(() {}),
                  ),
                  const SizedBox(height: 16),

                  // Plazo
                  Text(
                    'Nuevo plazo: $nuevoPlazo meses ($cuotasRestantes restantes)',
                    style: AppTextStyles.labelLarge,
                  ),
                  Slider(
                    value: nuevoPlazo.toDouble(),
                    min: (cuotasPagadas + 1).toDouble(),
                    max: 60,
                    divisions: 60 - cuotasPagadas - 1 > 0
                        ? 60 - cuotasPagadas - 1
                        : 1,
                    label: '$nuevoPlazo meses',
                    onChanged: (v) {
                      setModalState(() {
                        nuevoPlazo = v.round();
                      });
                    },
                  ),
                  const SizedBox(height: 8),

                  // Preview
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.infoLight,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        _previewRow('Nueva cuota', AppFormatters.moneda(nuevaCuota)),
                        _previewRow('Cuotas restantes', '$cuotasRestantes'),
                        _previewRow('Total a pagar', AppFormatters.moneda(nuevoTotal)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Garantía y notas
                  TextField(
                    controller: garantiaCtrl,
                    decoration: const InputDecoration(
                      labelText: AppStrings.garantia,
                      prefixIcon: Icon(Icons.shield),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: notasCtrl,
                    decoration: const InputDecoration(
                      labelText: AppStrings.notas,
                      prefixIcon: Icon(Icons.note),
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text(AppStrings.cancelar),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () async {
                            await _guardarEdicion(
                              ctx,
                              prestamo,
                              cuotas,
                              nuevaTasa,
                              nuevoPlazo,
                              garantiaCtrl.text.trim(),
                              notasCtrl.text.trim(),
                            );
                          },
                          child: const Text(AppStrings.guardar),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _guardarEdicion(
    BuildContext ctx,
    Prestamo prestamo,
    List<CuotaPago> cuotasActuales,
    double nuevaTasa,
    int nuevoPlazo,
    String garantia,
    String notas,
  ) async {
    final cuotasPagadas = cuotasActuales.where((c) => c.pagado).toList();
    final capitalPagado =
        cuotasPagadas.fold<double>(0, (sum, c) => sum + c.capital);
    final saldoActual = prestamo.montoOriginal - capitalPagado;
    final cuotasRestantes = nuevoPlazo - cuotasPagadas.length;

    if (cuotasRestantes <= 0) {
      if (mounted) {
        AppSnackBar.advertencia(
            context, 'El plazo debe ser mayor a las cuotas ya pagadas');
      }
      return;
    }

    // Calcular nueva fecha vencimiento
    final nuevaFechaVencimiento = DateTime(
      prestamo.fechaInicio.year,
      prestamo.fechaInicio.month + nuevoPlazo,
      prestamo.fechaInicio.day,
    );

    // Generar nuevas cuotas solo para las pendientes
    final nuevasCuotas = <CuotaPago>[];
    final capitalMensual = saldoActual / cuotasRestantes;
    double saldoRestante = saldoActual;

    for (int i = 0; i < cuotasRestantes; i++) {
      final numCuota = cuotasPagadas.length + i + 1;
      final interes = saldoRestante * (nuevaTasa / 100);
      final totalCuota = capitalMensual + interes;
      saldoRestante -= capitalMensual;
      if (saldoRestante < 0.01) saldoRestante = 0;

      final fechaPago = DateTime(
        prestamo.fechaInicio.year,
        prestamo.fechaInicio.month + numCuota,
        prestamo.fechaInicio.day,
      );

      nuevasCuotas.add(CuotaPago(
        id: '${prestamo.id}_cuota_$numCuota',
        prestamoId: prestamo.id,
        cuotaNumero: numCuota,
        fechaPago: fechaPago,
        capital: double.parse(capitalMensual.toStringAsFixed(2)),
        interes: double.parse(interes.toStringAsFixed(2)),
        totalCuota: double.parse(totalCuota.toStringAsFixed(2)),
        saldo: double.parse(saldoRestante.toStringAsFixed(2)),
      ));
    }

    // Actualizar préstamo
    final updated = prestamo.copyWith(
      tasaInteres: nuevaTasa,
      plazoMeses: nuevoPlazo,
      saldoPendiente: saldoActual,
      fechaVencimiento: nuevaFechaVencimiento,
      garantia: garantia.isNotEmpty ? garantia : null,
      notas: notas.isNotEmpty ? notas : null,
    );

    await ref.read(prestamosProvider.notifier).regenerarCuotas(
          updated, nuevasCuotas);

    if (ctx.mounted) Navigator.pop(ctx);
    _refrescarDatos();
    ref.invalidate(capitalDisponibleProvider);
    if (mounted) {
      AppSnackBar.exito(context, 'Préstamo actualizado con nuevas cuotas');
    }
  }

  Widget _previewRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTextStyles.bodySmall),
          Text(value, style: AppTextStyles.titleSmall),
        ],
      ),
    );
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
              if (prestamo.estado == 'activo')
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () => _editarPrestamo(prestamo),
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
