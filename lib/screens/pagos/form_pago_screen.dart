import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_strings.dart';
import '../../constants/app_text_styles.dart';
import '../../helpers/app_formatters.dart';
import '../../helpers/app_validators.dart';
import '../../models/pago.dart';
import '../../providers/auth_provider.dart';
import '../../providers/cliente_provider.dart';
import '../../providers/prestamo_provider.dart';
import '../../providers/pago_provider.dart';
import '../../services/carpeta_service.dart';
import '../../services/whatsapp_service.dart';
import '../../widgets/app_snack_bar.dart';
import '../../widgets/loading_button.dart';

class FormPagoScreen extends ConsumerStatefulWidget {
  final String? clienteId;
  final String? prestamoId;

  const FormPagoScreen({super.key, this.clienteId, this.prestamoId});

  @override
  ConsumerState<FormPagoScreen> createState() => _FormPagoScreenState();
}

class _FormPagoScreenState extends ConsumerState<FormPagoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _montoCtrl = TextEditingController();
  final _conceptoCtrl = TextEditingController();
  final _notasCtrl = TextEditingController();

  String? _clienteId;
  String? _prestamoId;
  DateTime _fecha = DateTime.now();
  String _metodoPago = 'efectivo';
  String? _comprobantePath;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _clienteId = widget.clienteId;
    _prestamoId = widget.prestamoId;

    if (_prestamoId != null) {
      _cargarDatosPrestamo();
    }
  }

  Future<void> _cargarDatosPrestamo() async {
    final cuota = await ref
        .read(prestamoRepositoryProvider)
        .obtenerCuotaActual(_prestamoId!);
    final prestamo = await ref
        .read(prestamoRepositoryProvider)
        .obtenerPorId(_prestamoId!);

    if (cuota != null && mounted) {
      setState(() {
        _montoCtrl.text = cuota.totalCuota.toStringAsFixed(2);
        _conceptoCtrl.text = 'Cuota No. ${cuota.cuotaNumero}';
      });
    } else if (prestamo != null && mounted) {
      setState(() {
        _montoCtrl.text = prestamo.cuotaMensual.toStringAsFixed(2);
      });
    }
  }

  Future<void> _seleccionarFecha() async {
    final fecha = await showDatePicker(
      context: context,
      initialDate: _fecha,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 30)),
      locale: const Locale('es'),
    );
    if (fecha != null) {
      setState(() {
        _fecha = fecha;
      });
    }
  }

  Future<void> _seleccionarComprobante() async {
    final picker = ImagePicker();
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Cámara'),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Galería'),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );

    if (source == null) {
      return;
    }

    try {
      final image = await picker.pickImage(
        source: source,
        maxWidth: 800,
        imageQuality: 80,
      );
      if (image != null && mounted) {
        setState(() {
          _comprobantePath = image.path;
        });
      }
    } catch (e) {
      if (mounted) {
        AppSnackBar.error(context, 'Error al seleccionar imagen');
      }
    }
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    if (_clienteId == null) {
      AppSnackBar.advertencia(context, 'Selecciona un cliente');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final pagoId = const Uuid().v4();
      final monto =
          double.parse(_montoCtrl.text.replaceAll(',', ''));

      // Obtener cuota actual si hay préstamo
      int? cuotaNumero;
      String? cuotaId;
      if (_prestamoId != null) {
        final cuota = await ref
            .read(prestamoRepositoryProvider)
            .obtenerCuotaActual(_prestamoId!);
        if (cuota != null) {
          cuotaNumero = cuota.cuotaNumero;
          cuotaId = cuota.id;
        }
      }

      final usuarioId = ref.read(usuarioIdProvider);
      final pago = Pago(
        id: pagoId,
        clienteId: _clienteId!,
        prestamoId: _prestamoId,
        cuotaNumero: cuotaNumero,
        monto: monto,
        fecha: _fecha,
        metodoPago: _metodoPago,
        comprobantePath: _comprobantePath,
        concepto: _conceptoCtrl.text.trim(),
        notas: _notasCtrl.text.trim().isNotEmpty
            ? _notasCtrl.text.trim()
            : null,
        registradoPor: usuarioId,
        fechaCreacion: DateTime.now(),
      );

      await ref.read(pagosProvider.notifier).crear(pago);

      // Registrar pago en préstamo
      if (_prestamoId != null && cuotaId != null) {
        await ref
            .read(prestamosProvider.notifier)
            .registrarPago(_prestamoId!, monto, cuotaId);

        // Verificar si el préstamo quedó pagado
        final prestamo = await ref
            .read(prestamoRepositoryProvider)
            .obtenerPorId(_prestamoId!);

        if (prestamo != null && prestamo.estaPagado) {
          // Cambiar estado del cliente
          await ref
              .read(clientesProvider.notifier)
              .actualizarEstado(_clienteId!, 'finalizado');

          // Generar finiquito
          final cliente = await ref
              .read(clientePorIdProvider(_clienteId!).future);
          if (cliente != null) {
            await CarpetaService.instance
                .generarFiniquito(cliente, prestamo);
          }
        }
      }

      // Generar recibo PDF
      final cliente =
          await ref.read(clientePorIdProvider(_clienteId!).future);
      if (cliente != null) {
        final cuota = _prestamoId != null
            ? await ref
                .read(prestamoRepositoryProvider)
                .obtenerCuotaActual(_prestamoId!)
            : null;
        final prestamo = _prestamoId != null
            ? await ref
                .read(prestamoRepositoryProvider)
                .obtenerPorId(_prestamoId!)
            : null;

        final cuotasPendientes = _prestamoId != null
            ? await ref
                .read(prestamoRepositoryProvider)
                .contarCuotasPendientes(_prestamoId!)
            : 0;

        final reciboPdfPath = await CarpetaService.instance
            .generarReciboPago(pago, cliente, cuota, prestamo,
                cuotasPendientes: cuotasPendientes);

        // Guardar ruta del PDF en el pago
        final pagoConPdf = pago.copyWith(pdfPath: reciboPdfPath);
        await ref.read(pagosProvider.notifier).actualizar(pagoConPdf);

        // WhatsApp
        if (mounted) {
          WhatsAppService.enviarMensaje(
            cliente.telefono,
            WhatsAppService.mensajeConfirmacionPago(
              nombre: cliente.nombre,
              monto: AppFormatters.moneda(monto),
              concepto: pago.concepto,
              saldoPendiente: prestamo != null
                  ? AppFormatters.moneda(prestamo.saldoPendiente)
                  : null,
            ),
            context,
          );
        }
      }

      if (!mounted) {
        return;
      }

      ref.invalidate(prestamosProvider);
      ref.invalidate(resumenPagosProvider);
      ref.invalidate(pagosRecientesProvider);
      if (_prestamoId != null) {
        ref.invalidate(cuotasPrestamoProvider(_prestamoId!));
      }
      AppSnackBar.exito(context, AppStrings.pagoRegistrado);
      context.pop();
    } catch (e) {
      if (mounted) {
        AppSnackBar.error(context, AppStrings.errorGenerico);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _montoCtrl.dispose();
    _conceptoCtrl.dispose();
    _notasCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final clientesAsync = ref.watch(clientesProvider);
    final prestamosAsync = _clienteId != null
        ? ref.watch(prestamosPorClienteProvider(_clienteId!))
        : null;

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.nuevoPago)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Cliente
              clientesAsync.when(
                data: (clientes) => DropdownButtonFormField<String>(
                  initialValue: _clienteId,
                  decoration: const InputDecoration(
                    labelText: 'Cliente *',
                    prefixIcon: Icon(Icons.person),
                  ),
                  isExpanded: true,
                  items: clientes.map((c) {
                    return DropdownMenuItem(
                      value: c.id,
                      child: Text(c.nombreCompleto),
                    );
                  }).toList(),
                  onChanged: (v) {
                    setState(() {
                      _clienteId = v;
                      _prestamoId = null;
                    });
                  },
                  validator: (v) => v == null ? 'Selecciona un cliente' : null,
                ),
                loading: () => const LinearProgressIndicator(),
                error: (_, _) => const Text('Error cargando clientes'),
              ),
              const SizedBox(height: 16),

              // Préstamo (opcional)
              if (prestamosAsync != null)
                prestamosAsync.when(
                  data: (prestamos) {
                    final activos = prestamos
                        .where((p) => p.estado == 'activo')
                        .toList();
                    if (activos.isEmpty) {
                      return const SizedBox.shrink();
                    }
                    return Column(
                      children: [
                        DropdownButtonFormField<String>(
                          initialValue: _prestamoId,
                          decoration: const InputDecoration(
                            labelText: 'Préstamo (opcional)',
                            prefixIcon: Icon(Icons.payments),
                          ),
                          isExpanded: true,
                          items: activos.map((p) {
                            return DropdownMenuItem(
                              value: p.id,
                              child: Text(
                                '${AppFormatters.moneda(p.montoOriginal)} - Saldo: ${AppFormatters.moneda(p.saldoPendiente)}',
                              ),
                            );
                          }).toList(),
                          onChanged: (v) {
                            setState(() {
                              _prestamoId = v;
                            });
                            if (v != null) {
                              _cargarDatosPrestamo();
                            }
                          },
                        ),
                        const SizedBox(height: 16),
                      ],
                    );
                  },
                  loading: () => const LinearProgressIndicator(),
                  error: (_, _) => const SizedBox.shrink(),
                ),

              // Monto
              TextFormField(
                controller: _montoCtrl,
                decoration: const InputDecoration(
                  labelText: '${AppStrings.monto} *',
                  prefixIcon: Icon(Icons.attach_money),
                  prefixText: 'Q ',
                ),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[\d,.]')),
                ],
                validator: AppValidators.monto,
              ),
              const SizedBox(height: 16),

              // Fecha
              InkWell(
                onTap: _seleccionarFecha,
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: '${AppStrings.fecha} *',
                    prefixIcon: Icon(Icons.calendar_today),
                  ),
                  child: Text(
                    AppFormatters.fechaCorta(_fecha),
                    style: AppTextStyles.bodyMedium,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Método de pago
              Text(AppStrings.metodoPago, style: AppTextStyles.labelLarge),
              const SizedBox(height: 8),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(
                    value: 'efectivo',
                    label: Text('Efectivo'),
                    icon: Icon(Icons.money),
                  ),
                  ButtonSegment(
                    value: 'transferencia',
                    label: Text('Transferencia'),
                    icon: Icon(Icons.account_balance),
                  ),
                ],
                selected: {_metodoPago},
                onSelectionChanged: (v) {
                  setState(() {
                    _metodoPago = v.first;
                  });
                },
              ),
              const SizedBox(height: 16),

              // Comprobante (si transferencia)
              if (_metodoPago == 'transferencia') ...[
                Text(AppStrings.comprobante,
                    style: AppTextStyles.labelLarge),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: _seleccionarComprobante,
                  child: Container(
                    height: 120,
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.divider),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: _comprobantePath != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.file(
                              File(_comprobantePath!),
                              fit: BoxFit.cover,
                              width: double.infinity,
                            ),
                          )
                        : const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.add_a_photo,
                                    color: AppColors.textSecondary),
                                SizedBox(height: 4),
                                Text('Agregar comprobante'),
                              ],
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Concepto
              TextFormField(
                controller: _conceptoCtrl,
                decoration: const InputDecoration(
                  labelText: '${AppStrings.concepto} *',
                  prefixIcon: Icon(Icons.description),
                ),
                validator: AppValidators.requerido,
              ),
              const SizedBox(height: 16),

              // Notas
              TextFormField(
                controller: _notasCtrl,
                decoration: const InputDecoration(
                  labelText: AppStrings.notas,
                  prefixIcon: Icon(Icons.note),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 32),

              LoadingButton(
                texto: 'Registrar Pago',
                onPressed: _guardar,
                isLoading: _isLoading,
                icono: Icons.payment,
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
