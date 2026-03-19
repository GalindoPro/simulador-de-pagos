import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../constants/app_strings.dart';
import '../../constants/app_text_styles.dart';
import '../../helpers/app_formatters.dart';
import '../../providers/pago_provider.dart';
import '../../providers/cliente_provider.dart';
import '../../providers/prestamo_provider.dart';
import '../../services/carpeta_service.dart';
import '../../services/whatsapp_service.dart';
import '../../widgets/app_error_widget.dart';
import '../../widgets/whatsapp_button.dart';

class DetallePagoScreen extends ConsumerWidget {
  final String pagoId;

  const DetallePagoScreen({super.key, required this.pagoId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pagosAsync = ref.watch(pagosProvider);

    return pagosAsync.when(
      data: (pagos) {
        final pago = pagos.where((p) => p.id == pagoId).firstOrNull;
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
                        _datoRow('Estado', pago.estado),
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

                const SizedBox(height: 24),

                // Botones
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          if (pago.pdfPath != null) {
                            CarpetaService.instance
                                .compartirArchivo(pago.pdfPath!);
                          }
                        },
                        icon: const Icon(Icons.picture_as_pdf),
                        label: const Text('Ver Recibo'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: clienteAsync.when(
                        data: (cliente) {
                          if (cliente == null) {
                            return const SizedBox.shrink();
                          }
                          return WhatsAppButton(
                            telefono: cliente.telefono,
                            mensaje:
                                WhatsAppService.mensajeConfirmacionPago(
                              nombre: cliente.nombre,
                              monto: AppFormatters.moneda(pago.monto),
                              concepto: pago.concepto,
                            ),
                            mostrarTexto: true,
                          );
                        },
                        loading: () => const SizedBox.shrink(),
                        error: (_, _) => const SizedBox.shrink(),
                      ),
                    ),
                  ],
                ),
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
