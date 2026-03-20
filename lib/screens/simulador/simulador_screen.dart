import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_strings.dart';
import '../../constants/app_text_styles.dart';
import '../../helpers/app_formatters.dart';
import '../../helpers/app_validators.dart';
import '../../models/cuota_pago.dart';
import '../../router/app_routes.dart';
import '../../widgets/tabla_amortizacion.dart';

class SimuladorScreen extends StatefulWidget {
  const SimuladorScreen({super.key});

  @override
  State<SimuladorScreen> createState() => _SimuladorScreenState();
}

class _SimuladorScreenState extends State<SimuladorScreen> {
  final _formKey = GlobalKey<FormState>();
  final _montoCtrl = TextEditingController();
  final _tasaCtrl = TextEditingController(text: '7.0');
  double _plazo = 12;
  DateTime _fechaPrimerPago = DateTime(
    DateTime.now().year,
    DateTime.now().month + 1,
    1,
  );
  List<CuotaPago>? _cuotas;

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

  double get _totalIntereses {
    if (_monto <= 0) {
      return 0;
    }
    return _monto * (_tasa / 100) * _plazoInt;
  }

  double get _totalPagar => _monto + _totalIntereses;

  void _calcularTabla() {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    setState(() {
      _cuotas = CuotaPago.generarTabla(
        prestamoId: 'simulacion',
        monto: _monto,
        tasaInteres: _tasa,
        plazoMeses: _plazoInt,
        fechaInicio: _fechaPrimerPago,
      );
    });
  }

  Future<void> _seleccionarFecha() async {
    final fecha = await showDatePicker(
      context: context,
      initialDate: _fechaPrimerPago,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      locale: const Locale('es'),
    );
    if (fecha != null) {
      setState(() {
        _fechaPrimerPago = fecha;
      });
    }
  }

  @override
  void dispose() {
    _montoCtrl.dispose();
    _tasaCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.simulador)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Inputs
              TextFormField(
                controller: _montoCtrl,
                decoration: const InputDecoration(
                  labelText: AppStrings.montoOriginal,
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
              TextFormField(
                controller: _tasaCtrl,
                decoration: const InputDecoration(
                  labelText: AppStrings.tasaInteres,
                  prefixIcon: Icon(Icons.percent),
                  suffixText: '%',
                ),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 16),
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
              InkWell(
                onTap: _seleccionarFecha,
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: AppStrings.fechaPrimerPago,
                    prefixIcon: Icon(Icons.calendar_today),
                  ),
                  child: Text(
                    AppFormatters.fechaCorta(_fechaPrimerPago),
                    style: AppTextStyles.bodyMedium,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Preview en tiempo real
              Card(
                color: AppColors.infoLight,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _previewRow(AppStrings.cuotaMensual,
                          AppFormatters.moneda(_cuotaMensual)),
                      const Divider(),
                      _previewRow(AppStrings.totalIntereses,
                          AppFormatters.moneda(_totalIntereses)),
                      const Divider(),
                      _previewRow(AppStrings.totalPagar,
                          AppFormatters.moneda(_totalPagar)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              ElevatedButton.icon(
                onPressed: _calcularTabla,
                icon: const Icon(Icons.table_chart),
                label: const Text(AppStrings.calcularTabla),
              ),

              if (_cuotas != null) ...[
                const SizedBox(height: 24),
                Text(AppStrings.tablaAmortizacion,
                    style: AppTextStyles.titleMedium),
                const SizedBox(height: 8),
                TablaAmortizacion(
                  cuotas: _cuotas!,
                  montoOriginal: _monto,
                  tasaInteres: _tasa,
                  cuotaMensual: _cuotaMensual,
                  fechaInicio: _fechaPrimerPago,
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () {
                    context.push(
                      AppRoutes.nuevoPrestamo,
                      extra: {
                        'monto': _monto,
                        'tasa': _tasa,
                        'plazo': _plazoInt,
                        'fechaInicio': _fechaPrimerPago,
                      },
                    );
                  },
                  icon: const Icon(Icons.add),
                  label: const Text(AppStrings.crearPrestamoConDatos),
                ),
              ],
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }


  Widget _previewRow(String label, String valor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTextStyles.bodyMedium),
          Text(valor, style: AppTextStyles.titleMedium),
        ],
      ),
    );
  }
}
