import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_strings.dart';
import '../../constants/app_text_styles.dart';
import '../../helpers/app_validators.dart';
import '../../models/usuario.dart';
import '../../repositories/usuario_repository.dart';
import '../../router/app_routes.dart';
import '../../widgets/app_snack_bar.dart';
import '../../widgets/loading_button.dart';

class RegistroScreen extends StatefulWidget {
  const RegistroScreen({super.key});

  @override
  State<RegistroScreen> createState() => _RegistroScreenState();
}

class _RegistroScreenState extends State<RegistroScreen> {
  final _pageController = PageController();
  final _formKeys = [
    GlobalKey<FormState>(),
    GlobalKey<FormState>(),
    GlobalKey<FormState>(),
  ];

  // Paso 1
  final _nombreCtrl = TextEditingController();
  final _telefonoCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  // Paso 2
  String? _pregunta1;
  String? _pregunta2;
  final _respuesta1Ctrl = TextEditingController();
  final _respuesta2Ctrl = TextEditingController();

  // Paso 3
  final _capitalCtrl = TextEditingController();

  final _repo = UsuarioRepository();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    _nombreCtrl.dispose();
    _telefonoCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    _respuesta1Ctrl.dispose();
    _respuesta2Ctrl.dispose();
    _capitalCtrl.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_formKeys[_currentPage].currentState!.validate()) {
      if (_currentPage == 1) {
        if (_pregunta1 == null || _pregunta2 == null) {
          AppSnackBar.advertencia(context, 'Selecciona ambas preguntas');
          return;
        }
        if (_pregunta1 == _pregunta2) {
          AppSnackBar.advertencia(
              context, 'Las preguntas deben ser diferentes');
          return;
        }
      }
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _prevPage() {
    _pageController.previousPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  Future<void> _registrar() async {
    if (!_formKeys[2].currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final existe = await _repo.existeTelefono(_telefonoCtrl.text.trim());
      if (!mounted) {
        return;
      }

      if (existe) {
        AppSnackBar.error(context, AppStrings.telefonoYaRegistrado);
        setState(() {
          _isLoading = false;
        });
        return;
      }

      final uuid = const Uuid();
      final userId = uuid.v4();

      final usuario = Usuario(
        id: userId,
        nombre: Usuario.toTitleCase(_nombreCtrl.text.trim()),
        telefono: _telefonoCtrl.text.trim(),
        passwordHash: Usuario.hashPassword(_passwordCtrl.text),
        capitalInicial:
            double.parse(_capitalCtrl.text.replaceAll(',', '')),
        fechaRegistro: DateTime.now(),
      );

      await _repo.crear(usuario);

      // Guardar preguntas de seguridad
      final p1 = PreguntaSeguridad(
        id: uuid.v4(),
        usuarioId: userId,
        pregunta: _pregunta1!,
        respuestaHash:
            PreguntaSeguridad.hashRespuesta(_respuesta1Ctrl.text),
      );
      final p2 = PreguntaSeguridad(
        id: uuid.v4(),
        usuarioId: userId,
        pregunta: _pregunta2!,
        respuestaHash:
            PreguntaSeguridad.hashRespuesta(_respuesta2Ctrl.text),
      );

      await _repo.crearPregunta(p1);
      await _repo.crearPregunta(p2);

      if (!mounted) {
        return;
      }

      AppSnackBar.exito(context, AppStrings.registroExitoso);
      context.go(AppRoutes.login);
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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.registro),
      ),
      body: Column(
        children: [
          // Indicador de pasos
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: List.generate(3, (i) {
                return Expanded(
                  child: Container(
                    height: 4,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      color: i <= _currentPage
                          ? AppColors.primary
                          : AppColors.divider,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                );
              }),
            ),
          ),
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              onPageChanged: (page) {
                setState(() {
                  _currentPage = page;
                });
              },
              children: [
                _paso1(),
                _paso2(),
                _paso3(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _paso1() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKeys[0],
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(AppStrings.paso1Titulo, style: AppTextStyles.headlineSmall),
            const SizedBox(height: 24),
            TextFormField(
              controller: _nombreCtrl,
              decoration: const InputDecoration(
                labelText: AppStrings.nombre,
                prefixIcon: Icon(Icons.person),
              ),
              textCapitalization: TextCapitalization.words,
              onChanged: (v) {
                final tc = Usuario.toTitleCase(v);
                if (tc != v) {
                  _nombreCtrl.value = TextEditingValue(
                    text: tc,
                    selection:
                        TextSelection.collapsed(offset: tc.length),
                  );
                }
              },
              validator: AppValidators.nombre,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _telefonoCtrl,
              decoration: const InputDecoration(
                labelText: AppStrings.telefono,
                prefixIcon: Icon(Icons.phone),
                prefixText: '+502 ',
              ),
              keyboardType: TextInputType.phone,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(8),
              ],
              validator: AppValidators.telefono,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _passwordCtrl,
              decoration: InputDecoration(
                labelText: AppStrings.password,
                prefixIcon: const Icon(Icons.lock),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility
                        : Icons.visibility_off,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscurePassword = !_obscurePassword;
                    });
                  },
                ),
              ),
              obscureText: _obscurePassword,
              validator: AppValidators.password,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _confirmCtrl,
              decoration: InputDecoration(
                labelText: AppStrings.confirmarPassword,
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureConfirm
                        ? Icons.visibility
                        : Icons.visibility_off,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscureConfirm = !_obscureConfirm;
                    });
                  },
                ),
              ),
              obscureText: _obscureConfirm,
              validator: (v) =>
                  AppValidators.confirmarPassword(v, _passwordCtrl.text),
            ),
            const SizedBox(height: 32),
            LoadingButton(
              texto: AppStrings.siguiente,
              onPressed: _nextPage,
              isLoading: false,
              icono: Icons.arrow_forward,
            ),
          ],
        ),
      ),
    );
  }

  Widget _paso2() {
    final preguntasDisponibles1 = kPreguntasSeguridad
        .where((p) => p != _pregunta2)
        .toList();
    final preguntasDisponibles2 = kPreguntasSeguridad
        .where((p) => p != _pregunta1)
        .toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKeys[1],
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(AppStrings.paso2Titulo, style: AppTextStyles.headlineSmall),
            const SizedBox(height: 24),
            DropdownButtonFormField<String>(
              initialValue: _pregunta1,
              decoration: const InputDecoration(
                labelText: AppStrings.pregunta1,
                prefixIcon: Icon(Icons.help_outline),
              ),
              isExpanded: true,
              items: preguntasDisponibles1.map((p) {
                return DropdownMenuItem(value: p, child: Text(p));
              }).toList(),
              onChanged: (v) {
                setState(() {
                  _pregunta1 = v;
                });
              },
              validator: (v) =>
                  v == null ? AppStrings.seleccionaPregunta : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _respuesta1Ctrl,
              decoration: const InputDecoration(
                labelText: AppStrings.respuesta,
                prefixIcon: Icon(Icons.edit),
              ),
              validator: AppValidators.requerido,
            ),
            const SizedBox(height: 24),
            DropdownButtonFormField<String>(
              initialValue: _pregunta2,
              decoration: const InputDecoration(
                labelText: AppStrings.pregunta2,
                prefixIcon: Icon(Icons.help_outline),
              ),
              isExpanded: true,
              items: preguntasDisponibles2.map((p) {
                return DropdownMenuItem(value: p, child: Text(p));
              }).toList(),
              onChanged: (v) {
                setState(() {
                  _pregunta2 = v;
                });
              },
              validator: (v) =>
                  v == null ? AppStrings.seleccionaPregunta : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _respuesta2Ctrl,
              decoration: const InputDecoration(
                labelText: AppStrings.respuesta,
                prefixIcon: Icon(Icons.edit),
              ),
              validator: AppValidators.requerido,
            ),
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _prevPage,
                    icon: const Icon(Icons.arrow_back),
                    label: const Text(AppStrings.anterior),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: LoadingButton(
                    texto: AppStrings.siguiente,
                    onPressed: _nextPage,
                    isLoading: false,
                    icono: Icons.arrow_forward,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _paso3() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKeys[2],
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(AppStrings.paso3Titulo, style: AppTextStyles.headlineSmall),
            const SizedBox(height: 24),
            const Icon(
              Icons.account_balance_wallet,
              size: 64,
              color: AppColors.primary,
            ),
            const SizedBox(height: 16),
            Text(
              AppStrings.capitalInicial,
              style: AppTextStyles.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _capitalCtrl,
              decoration: const InputDecoration(
                labelText: 'Capital (Q)',
                prefixIcon: Icon(Icons.attach_money),
                prefixText: 'Q ',
              ),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(
                    RegExp(r'[\d,.]')),
              ],
              validator: AppValidators.monto,
            ),
            const SizedBox(height: 8),
            Text(
              AppStrings.capitalNota,
              style: AppTextStyles.caption,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _prevPage,
                    icon: const Icon(Icons.arrow_back),
                    label: const Text(AppStrings.anterior),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: LoadingButton(
                    texto: AppStrings.finalizar,
                    onPressed: _registrar,
                    isLoading: _isLoading,
                    icono: Icons.check,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
