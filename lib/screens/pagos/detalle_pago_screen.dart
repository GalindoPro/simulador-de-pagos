import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_strings.dart';
import '../../constants/app_text_styles.dart';
import '../../helpers/app_formatters.dart';
import '../../providers/pago_provider.dart';
import '../../providers/cliente_provider.dart';
import '../../providers/prestamo_provider.dart';
import '../../services/carpeta_service.dart';
import '../../services/whatsapp_service.dart';
import '../../widgets/app_error_widget.dart';
import '../../widgets/app_snack_bar.dart';

class DetallePagoScreen extends ConsumerStatefulWidget {
  final String pagoId;

  const DetallePagoScreen({super.key, required this.pagoId});

  @override
  ConsumerState<DetallePagoScreen> createState() => _DetallePagoScreenState();
}

class _DetallePagoScreenState extends ConsumerState<DetallePagoScreen> {
  bool _generandoPdf = false;
  bool _enviandoWhatsApp = false;

  Future<void> _compartirRecibo(dynamic pago, dynamic cliente) async {
    setState(() => _generandoPdf = true);

    try {
      String? path = pago.pdfPath;

      if (path == null && cliente != null) {
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

        final cuotasPendientes = pago.prestamoId != null
            ? await ref
                .read(prestamoRepositoryProvider)
                .contarCuotasPendientes(pago.prestamoId!)
            : 0;

        path = await CarpetaService.instance
            .generarReciboPago(pago, cliente, cuota, prestamo,
                cuotasPendientes: cuotasPendientes);

        await ref
            .read(pagosProvider.notifier)
            .actualizar(pago.copyWith(pdfPath: path));
      }

      if (path != null) {
        await CarpetaService.instance.compartirArchivo(path);
      }
    } finally {
      if (mounted) {
        setState(() => _generandoPdf = false);
      }
    }
  }

  Future<void> _enviarWhatsApp(dynamic pago, dynamic cliente) async {
    if (cliente == null) return;
    setState(() => _enviandoWhatsApp = true);

    try {
      // Generar PDF si no existe
      String? path = pago.pdfPath;
      if (path == null) {
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
        final cuotasPendientes = pago.prestamoId != null
            ? await ref
                .read(prestamoRepositoryProvider)
                .contarCuotasPendientes(pago.prestamoId!)
            : 0;

        path = await CarpetaService.instance
            .generarReciboPago(pago, cliente, cuota, prestamo,
                cuotasPendientes: cuotasPendientes);

        await ref
            .read(pagosProvider.notifier)
            .actualizar(pago.copyWith(pdfPath: path));
      }

      // Abrir WhatsApp directo con el número del cliente
      if (mounted) {
        await WhatsAppService.enviarMensaje(
          cliente.telefono,
          WhatsAppService.mensajeConfirmacionPago(
            nombre: cliente.nombre,
            monto: AppFormatters.moneda(pago.monto),
            concepto: pago.concepto,
          ),
          context,
        );
      }
    } catch (e) {
      if (mounted) {
        AppSnackBar.error(context, 'Error al enviar: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _enviandoWhatsApp = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final pagosAsync = ref.watch(pagosProvider);

    return pagosAsync.when(
      data: (pagos) {
        final pago =
            pagos.where((p) => p.id == widget.pagoId).firstOrNull;
        if (pago == null) {
          return Scaffold(
            appBar: AppBar(),
            body: const Center(child: Text('Pago no encontrado')),
          );
        }

        final clienteAsync =
            ref.watch(clientePorIdProvider(pago.clienteId));

        return Scaffold(
          appBar: AppBar(title: const Text(AppStrings.detallePago)),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Banner de estado
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: pago.estaCompletado
                        ? AppColors.successLight
                        : AppColors.warningLight,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        pago.estaCompletado
                            ? Icons.check_circle
                            : Icons.pending,
                        color: pago.estaCompletado
                            ? AppColors.success
                            : AppColors.warning,
                        size: 32,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              pago.estaCompletado
                                  ? 'Pago completado'
                                  : 'Pago pendiente',
                              style: AppTextStyles.titleSmall.copyWith(
                                color: pago.estaCompletado
                                    ? AppColors.success
                                    : AppColors.warning,
                              ),
                            ),
                            Text(
                              AppFormatters.moneda(pago.monto),
                              style: AppTextStyles.headlineMedium.copyWith(
                                color: pago.estaCompletado
                                    ? AppColors.success
                                    : AppColors.warning,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Acciones rápidas para compartir
                if (pago.estaCompletado)
                  Card(
                    color: AppColors.primary.withValues(alpha: 0.05),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(AppStrings.compartirRecibo,
                              style: AppTextStyles.titleSmall),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: _generandoPdf
                                      ? null
                                      : () {
                                          final cliente = ref
                                              .read(clientePorIdProvider(
                                                  pago.clienteId))
                                              .valueOrNull;
                                          _compartirRecibo(pago, cliente);
                                        },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primary,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 12),
                                  ),
                                  icon: _generandoPdf
                                      ? const SizedBox(
                                          width: 18,
                                          height: 18,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white,
                                          ),
                                        )
                                      : const Icon(Icons.picture_as_pdf),
                                  label: Text(_generandoPdf
                                      ? 'Generando...'
                                      : 'PDF Recibo'),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: clienteAsync.when(
                                  data: (cliente) {
                                    if (cliente == null) {
                                      return const SizedBox.shrink();
                                    }
                                    return ElevatedButton.icon(
                                      onPressed: _enviandoWhatsApp
                                          ? null
                                          : () => _enviarWhatsApp(pago, cliente),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.whatsapp,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 12),
                                      ),
                                      icon: _enviandoWhatsApp
                                          ? const SizedBox(
                                              width: 18,
                                              height: 18,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                color: Colors.white,
                                              ),
                                            )
                                          : const Icon(Icons.chat, size: 18),
                                      label: Text(_enviandoWhatsApp
                                          ? 'Enviando...'
                                          : 'WhatsApp'),
                                    );
                                  },
                                  loading: () => const SizedBox.shrink(),
                                  error: (_, _) => const SizedBox.shrink(),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                const SizedBox(height: 16),

                // Datos del pago
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Información del Pago',
                            style: AppTextStyles.titleMedium),
                        const SizedBox(height: 12),
                        _datoRow('Monto',
                            AppFormatters.moneda(pago.monto)),
                        _datoRow(
                            'Fecha', AppFormatters.fechaLarga(pago.fecha)),
                        _datoRow('Método', pago.metodoPago),
                        _datoRow('Concepto', pago.concepto),
                        if (pago.cuotaNumero != null)
                          _datoRow(
                              'Cuota No.', '${pago.cuotaNumero}'),
                        if (pago.notas != null && pago.notas!.isNotEmpty)
                          _datoRow('Notas', pago.notas!),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Comprobante
                if (pago.comprobantePath != null &&
                    pago.comprobantePath!.isNotEmpty)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Comprobante',
                              style: AppTextStyles.titleMedium),
                          const SizedBox(height: 12),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.file(
                              File(pago.comprobantePath!),
                              fit: BoxFit.cover,
                              width: double.infinity,
                              height: 200,
                              errorBuilder: (_, _, _) => const Center(
                                child: Text('Imagen no disponible'),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                // Datos del cliente
                clienteAsync.when(
                  data: (cliente) {
                    if (cliente == null) {
                      return const SizedBox.shrink();
                    }
                    return Column(
                      children: [
                        const SizedBox(height: 16),
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Text('Cliente',
                                    style: AppTextStyles.titleMedium),
                                const SizedBox(height: 12),
                                _datoRow('Nombre',
                                    cliente.nombreCompleto),
                                _datoRow('Teléfono',
                                    AppFormatters.telefono(cliente.telefono)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                  loading: () => const SizedBox.shrink(),
                  error: (_, _) => const SizedBox.shrink(),
                ),

                // Datos del préstamo
                if (pago.prestamoId != null)
                  ref
                      .watch(prestamosProvider)
                      .whenData((prestamos) {
                        final prestamo = prestamos
                            .where((p) => p.id == pago.prestamoId)
                            .firstOrNull;
                        if (prestamo == null) {
                          return const SizedBox.shrink();
                        }
                        return Column(
                          children: [
                            const SizedBox(height: 16),
                            Card(
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text('Préstamo',
                                        style:
                                            AppTextStyles.titleMedium),
                                    const SizedBox(height: 12),
                                    _datoRow(
                                        'Monto original',
                                        AppFormatters.moneda(
                                            prestamo.montoOriginal)),
                                    _datoRow(
                                        'Saldo pendiente',
                                        AppFormatters.moneda(
                                            prestamo.saldoPendiente)),
                                    _datoRow('Estado',
                                        prestamo.estado),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        );
                      })
                      .valueOrNull ??
                  const SizedBox.shrink(),

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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(label, style: AppTextStyles.bodySmall),
          ),
          Expanded(
            child: Text(value, style: AppTextStyles.titleSmall),
          ),
        ],
      ),
    );
  }
}
