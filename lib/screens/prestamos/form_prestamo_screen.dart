import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_strings.dart';
import '../../constants/app_text_styles.dart';
import '../../helpers/app_formatters.dart';
import '../../helpers/app_validators.dart';
import '../../models/prestamo.dart';
import '../../models/cuota_pago.dart';
import '../../models/cliente.dart';
import '../../providers/cliente_provider.dart';
import '../../providers/prestamo_provider.dart';
import '../../services/carpeta_service.dart';
import '../../services/whatsapp_service.dart';
import '../../widgets/app_snack_bar.dart';
import '../../widgets/loading_button.dart';

class FormPrestamoScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic>? datosSimulador;

  const FormPrestamoScreen({super.key, this.datosSimulador});

  @override
  ConsumerState<FormPrestamoScreen> createState() =>
      _FormPrestamoScreenState();
}

class _FormPrestamoScreenState extends ConsumerState<FormPrestamoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _montoCtrl = TextEditingController();
  final _tasaCtrl = TextEditingController(text: '7.0');
  final _garantiaCtrl = TextEditingController();
  final _notasCtrl = TextEditingController();

  String? _clienteId;
  double _plazo = 12;
  DateTime _fechaInicio = DateTime.now();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.datosSimulador != null) {
      final d = widget.datosSimulador!;
      _montoCtrl.text = (d['monto'] as double?)?.toStringAsFixed(0) ?? '';
      _tasaCtrl.text = (d['tasa'] as double?)?.toString() ?? '7.0';
      _plazo = (d['plazo'] as int?)?.toDouble() ?? 12;
      _fechaInicio = d['fechaInicio'] as DateTime? ?? DateTime.now();
    }
  }

  double get _monto =>
      double.tryParse(_montoCtrl.text.replaceAll(',', '')) ?? 0;
  double get _tasa => double.tryParse(_tasaCtrl.text) ?? 7.0;
  int get _plazoInt => _plazo.round();

  double get _cuotaMensual {
    if (_monto <= 0 || _plazoInt <= 0) {
      return 0;
    }
    final interes = _monto * (_tasa / 100) * _plazoInt;
    return (_monto + interes) / _plazoInt;
  }

  double get _totalIntereses =>
      _monto > 0 ? _monto * (_tasa / 100) * _plazoInt : 0;
  double get _totalPagar => _monto + _totalIntereses;

  DateTime get _fechaVencimiento => DateTime(
        _fechaInicio.year,
        _fechaInicio.month + _plazoInt,
        _fechaInicio.day,
      );

  Future<void> _seleccionarFecha() async {
    final fecha = await showDatePicker(
      context: context,
      initialDate: _fechaInicio,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      locale: const Locale('es'),
    );
    if (fecha != null) {
      setState(() {
        _fechaInicio = fecha;
      });
    }
  }

  void _mostrarConfirmacion() {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    if (_clienteId == null) {
      AppSnackBar.advertencia(context, 'Selecciona un cliente');
      return;
    }

    final clientes = ref.read(clientesProvider).valueOrNull ?? [];
    final cliente =
        clientes.where((c) => c.id == _clienteId).firstOrNull;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Confirmar Préstamo',
                  style: AppTextStyles.headlineSmall,
                  textAlign: TextAlign.center),
              const SizedBox(height: 20),
              _resumenRow('Cliente', cliente?.nombreCompleto ?? ''),
              _resumenRow('Monto', AppFormatters.moneda(_monto)),
              _resumenRow('Tasa', AppFormatters.porcentaje(_tasa)),
              _resumenRow('Plazo', '$_plazoInt meses'),
              const Divider(),
              _resumenRow(
                  'Cuota mensual', AppFormatters.moneda(_cuotaMensual)),
              _resumenRow(
                  'Total intereses', AppFormatters.moneda(_totalIntereses)),
              _resumenRow('Total a pagar', AppFormatters.moneda(_totalPagar)),
              const Divider(),
              _resumenRow(
                  'Fecha inicio', AppFormatters.fechaCorta(_fechaInicio)),
              _resumenRow('Fecha vencimiento',
                  AppFormatters.fechaCorta(_fechaVencimiento)),
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
                    child: LoadingButton(
                      texto: AppStrings.confirmarPrestamo,
                      onPressed: () {
                        Navigator.pop(ctx);
                        _guardar(cliente);
                      },
                      isLoading: _isLoading,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Future<void> _guardar(Cliente? cliente) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final prestamoId = const Uuid().v4();

      final prestamo = Prestamo(
        id: prestamoId,
        clienteId: _clienteId!,
        montoOriginal: _monto,
        tasaInteres: _tasa,
        plazoMeses: _plazoInt,
        fechaInicio: _fechaInicio,
        fechaVencimiento: _fechaVencimiento,
        saldoPendiente: _monto,
        garantia: _garantiaCtrl.text.trim().isNotEmpty
            ? _garantiaCtrl.text.trim()
            : null,
        notas: _notasCtrl.text.trim().isNotEmpty
            ? _notasCtrl.text.trim()
            : null,
        fechaCreacion: DateTime.now(),
      );

      final cuotas = CuotaPago.generarTabla(
        prestamoId: prestamoId,
        monto: _monto,
        tasaInteres: _tasa,
        plazoMeses: _plazoInt,
        fechaInicio: _fechaInicio,
      );

      await ref.read(prestamosProvider.notifier).crear(prestamo, cuotas);

      // Cambiar estado del cliente a activo
      await ref
          .read(clientesProvider.notifier)
          .actualizarEstado(_clienteId!, 'activo');

      // Generar PDF
      if (cliente != null) {
        await CarpetaService.instance
            .generarPDFTablaPagos(cliente, prestamo, cuotas);

        // WhatsApp
        if (mounted) {
          WhatsAppService.enviarMensaje(
            cliente.telefono,
            WhatsAppService.mensajePrestamoAprobado(
              nombre: cliente.nombre,
              monto: AppFormatters.moneda(_monto),
              cuota: AppFormatters.moneda(_cuotaMensual),
              plazo: '$_plazoInt',
            ),
            context,
          );
        }
      }

      if (!mounted) {
        return;
      }

      ref.invalidate(resumenFinancieroProvider);
      AppSnackBar.exito(context, AppStrings.prestamoCreado);
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
    _tasaCtrl.dispose();
    _garantiaCtrl.dispose();
    _notasCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final clientesAsync = ref.watch(clientesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.nuevoPrestamo)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Cliente dropdown
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
                    });
                  },
                  validator: (v) => v == null ? 'Selecciona un cliente' : null,
                ),
                loading: () => const LinearProgressIndicator(),
                error: (_, _) => const Text('Error cargando clientes'),
              ),
              const SizedBox(height: 16),

              // Monto
              TextFormField(
                controller: _montoCtrl,
                decoration: const InputDecoration(
                  labelText: '${AppStrings.montoOriginal} *',
                  prefixIcon: Icon(Icons.attach_money),
                  prefixText: 'Q ',
                ),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[\d,.]')),
                ],
                validator: AppValidators.monto,
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 16),

              // Tasa
              TextFormField(
                controller: _tasaCtrl,
                decoration: const InputDecoration(
                  labelText: '${AppStrings.tasaInteres} *',
                  prefixIcon: Icon(Icons.percent),
                  suffixText: '%',
                ),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 16),

              // Plazo
              Text(
                '${AppStrings.plazoMeses}: $_plazoInt meses',
                style: AppTextStyles.labelLarge,
              ),
              Slider(
                value: _plazo,
                min: 1,
                max: 60,
                divisions: 59,
                label: '$_plazoInt meses',
                onChanged: (v) => setState(() {
                  _plazo = v;
                }),
              ),
              const SizedBox(height: 8),

              // Fecha inicio
              InkWell(
                onTap: _seleccionarFecha,
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: '${AppStrings.fechaInicio} *',
                    prefixIcon: Icon(Icons.calendar_today),
                  ),
                  child: Text(
                    AppFormatters.fechaCorta(_fechaInicio),
                    style: AppTextStyles.bodyMedium,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Garantía
              TextFormField(
                controller: _garantiaCtrl,
                decoration: const InputDecoration(
                  labelText: AppStrings.garantia,
                  prefixIcon: Icon(Icons.shield),
                ),
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
              const SizedBox(height: 24),

              // Preview
              Card(
                color: AppColors.infoLight,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _resumenRow(AppStrings.cuotaMensual,
                          AppFormatters.moneda(_cuotaMensual)),
                      const Divider(),
                      _resumenRow(AppStrings.totalIntereses,
                          AppFormatters.moneda(_totalIntereses)),
                      const Divider(),
                      _resumenRow(AppStrings.totalPagar,
                          AppFormatters.moneda(_totalPagar)),
                      const Divider(),
                      _resumenRow(AppStrings.fechaVencimiento,
                          AppFormatters.fechaCorta(_fechaVencimiento)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              LoadingButton(
                texto: 'Guardar Préstamo',
                onPressed: _mostrarConfirmacion,
                isLoading: _isLoading,
                icono: Icons.save,
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _resumenRow(String label, String valor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTextStyles.bodyMedium),
          Text(valor,
              style: AppTextStyles.titleSmall),
        ],
      ),
    );
  }
}
