import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_strings.dart';
import '../../constants/app_text_styles.dart';
import '../../helpers/app_validators.dart';
import '../../models/usuario.dart';
import '../../repositories/usuario_repository.dart';
import '../../router/app_routes.dart';
import '../../widgets/app_snack_bar.dart';
import '../../widgets/loading_button.dart';

class RecuperarPasswordScreen extends StatefulWidget {
  const RecuperarPasswordScreen({super.key});

  @override
  State<RecuperarPasswordScreen> createState() =>
      _RecuperarPasswordScreenState();
}

class _RecuperarPasswordScreenState extends State<RecuperarPasswordScreen> {
  final _pageController = PageController();
  final _formKeys = [
    GlobalKey<FormState>(),
    GlobalKey<FormState>(),
    GlobalKey<FormState>(),
    GlobalKey<FormState>(),
  ];

  final _telefonoCtrl = TextEditingController();
  final _respuesta1Ctrl = TextEditingController();
  final _respuesta2Ctrl = TextEditingController();
  final _newPasswordCtrl = TextEditingController();
  final _confirmNewCtrl = TextEditingController();

  final _repo = UsuarioRepository();

  Usuario? _usuario;
  List<PreguntaSeguridad> _preguntas = [];
  bool _isLoading = false;
  bool _obscure1 = true;
  bool _obscure2 = true;
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    _telefonoCtrl.dispose();
    _respuesta1Ctrl.dispose();
    _respuesta2Ctrl.dispose();
    _newPasswordCtrl.dispose();
    _confirmNewCtrl.dispose();
    super.dispose();
  }

  Future<void> _buscarUsuario() async {
    if (!_formKeys[0].currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final usuario =
          await _repo.buscarPorTelefono(_telefonoCtrl.text.trim());

      if (!mounted) {
        return;
      }

      if (usuario == null) {
        AppSnackBar.error(context, AppStrings.telefonoNoRegistrado);
      } else {
        _usuario = usuario;
        _preguntas = await _repo.obtenerPreguntas(usuario.id);
        if (!mounted) {
          return;
        }
        _pageController.nextPage(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
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

  Future<void> _validarPregunta1() async {
    if (!_formKeys[1].currentState!.validate()) {
      return;
    }

    final hash =
        PreguntaSeguridad.hashRespuesta(_respuesta1Ctrl.text);
    if (hash != _preguntas[0].respuestaHash) {
      if (mounted) {
        AppSnackBar.error(context, AppStrings.respuestaIncorrecta);
      }
      return;
    }

    _pageController.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  Future<void> _validarPregunta2() async {
    if (!_formKeys[2].currentState!.validate()) {
      return;
    }

    final hash =
        PreguntaSeguridad.hashRespuesta(_respuesta2Ctrl.text);
    if (hash != _preguntas[1].respuestaHash) {
      if (mounted) {
        AppSnackBar.error(context, AppStrings.respuestaIncorrecta);
      }
      return;
    }

    _pageController.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  Future<void> _cambiarPassword() async {
    if (!_formKeys[3].currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await _repo.actualizarPassword(
          _usuario!.id, _newPasswordCtrl.text);

      if (!mounted) {
        return;
      }

      AppSnackBar.exito(context, AppStrings.passwordActualizada);
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
        title: const Text(AppStrings.recuperarPassword),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: List.generate(4, (i) {
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
                _pasoTelefono(),
                _pasoPregunta(0),
                _pasoPregunta(1),
                _pasoNuevaPassword(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _pasoTelefono() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKeys[0],
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.phone_android,
                size: 64, color: AppColors.primary),
            const SizedBox(height: 16),
            Text(
              'Ingresa tu teléfono registrado',
              style: AppTextStyles.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
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
            const SizedBox(height: 32),
            LoadingButton(
              texto: AppStrings.siguiente,
              onPressed: _buscarUsuario,
              isLoading: _isLoading,
              icono: Icons.arrow_forward,
            ),
          ],
        ),
      ),
    );
  }

  Widget _pasoPregunta(int index) {
    final ctrl = index == 0 ? _respuesta1Ctrl : _respuesta2Ctrl;
    final validar = index == 0 ? _validarPregunta1 : _validarPregunta2;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKeys[index + 1],
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.security,
                size: 64, color: AppColors.primary),
            const SizedBox(height: 16),
            Text(
              'Pregunta ${index + 1}',
              style: AppTextStyles.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            if (_preguntas.length > index)
              Text(
                _preguntas[index].pregunta,
                style: AppTextStyles.bodyLarge,
                textAlign: TextAlign.center,
              ),
            const SizedBox(height: 24),
            TextFormField(
              controller: ctrl,
              decoration: const InputDecoration(
                labelText: AppStrings.respuesta,
                prefixIcon: Icon(Icons.edit),
              ),
              validator: AppValidators.requerido,
            ),
            const SizedBox(height: 32),
            LoadingButton(
              texto: AppStrings.siguiente,
              onPressed: validar,
              isLoading: false,
              icono: Icons.arrow_forward,
            ),
          ],
        ),
      ),
    );
  }

  Widget _pasoNuevaPassword() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKeys[3],
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.lock_reset,
                size: 64, color: AppColors.primary),
            const SizedBox(height: 16),
            Text(
              'Ingresa tu nueva contraseña',
              style: AppTextStyles.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _newPasswordCtrl,
              decoration: InputDecoration(
                labelText: AppStrings.nuevaPassword,
                prefixIcon: const Icon(Icons.lock),
                suffixIcon: IconButton(
                  icon: Icon(_obscure1
                      ? Icons.visibility
                      : Icons.visibility_off),
                  onPressed: () {
                    setState(() {
                      _obscure1 = !_obscure1;
                    });
                  },
                ),
              ),
              obscureText: _obscure1,
              validator: AppValidators.password,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _confirmNewCtrl,
              decoration: InputDecoration(
                labelText: AppStrings.confirmarNuevaPassword,
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  icon: Icon(_obscure2
                      ? Icons.visibility
                      : Icons.visibility_off),
                  onPressed: () {
                    setState(() {
                      _obscure2 = !_obscure2;
                    });
                  },
                ),
              ),
              obscureText: _obscure2,
              validator: (v) => AppValidators.confirmarPassword(
                  v, _newPasswordCtrl.text),
            ),
            const SizedBox(height: 32),
            LoadingButton(
              texto: 'Cambiar Contraseña',
              onPressed: _cambiarPassword,
              isLoading: _isLoading,
              icono: Icons.check,
            ),
          ],
        ),
      ),
    );
  }
}
