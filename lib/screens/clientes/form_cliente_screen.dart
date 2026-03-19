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
import '../../helpers/app_validators.dart';
import '../../helpers/dpi_input_formatter.dart';
import '../../models/cliente.dart';
import '../../models/usuario.dart';
import '../../providers/cliente_provider.dart';
import '../../services/carpeta_service.dart';
import '../../services/whatsapp_service.dart';
import '../../widgets/app_snack_bar.dart';
import '../../widgets/loading_button.dart';

class FormClienteScreen extends ConsumerStatefulWidget {
  final String? clienteId;

  const FormClienteScreen({super.key, this.clienteId});

  @override
  ConsumerState<FormClienteScreen> createState() => _FormClienteScreenState();
}

class _FormClienteScreenState extends ConsumerState<FormClienteScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombreCtrl = TextEditingController();
  final _apellidoCtrl = TextEditingController();
  final _telefonoCtrl = TextEditingController();
  final _telRefCtrl = TextEditingController();
  final _dpiCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _direccionCtrl = TextEditingController();

  String? _fotoPath;
  bool _isLoading = false;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    if (widget.clienteId != null) {
      _isEditing = true;
      _cargarCliente();
    }
  }

  Future<void> _cargarCliente() async {
    final cliente =
        await ref.read(clientePorIdProvider(widget.clienteId!).future);
    if (cliente != null && mounted) {
      setState(() {
        _nombreCtrl.text = cliente.nombre;
        _apellidoCtrl.text = cliente.apellido;
        _telefonoCtrl.text = cliente.telefono;
        _telRefCtrl.text = cliente.telefonoReferencia ?? '';
        _dpiCtrl.text = cliente.dpi ?? '';
        _emailCtrl.text = cliente.email ?? '';
        _direccionCtrl.text = cliente.direccion ?? '';
        _fotoPath = cliente.fotoPath;
      });
    }
  }

  Future<void> _seleccionarFoto() async {
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
          _fotoPath = image.path;
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

    setState(() {
      _isLoading = true;
    });

    try {
      final cliente = Cliente.crear(
        id: _isEditing ? widget.clienteId! : const Uuid().v4(),
        nombre: _nombreCtrl.text.trim(),
        apellido: _apellidoCtrl.text.trim(),
        telefono: _telefonoCtrl.text.trim(),
        telefonoReferencia: _telRefCtrl.text.trim().isNotEmpty
            ? _telRefCtrl.text.trim()
            : null,
        dpi: _dpiCtrl.text.trim().isNotEmpty ? _dpiCtrl.text.trim() : null,
        email:
            _emailCtrl.text.trim().isNotEmpty ? _emailCtrl.text.trim() : null,
        direccion: _direccionCtrl.text.trim().isNotEmpty
            ? _direccionCtrl.text.trim()
            : null,
        fotoPath: _fotoPath,
      );

      if (_isEditing) {
        await ref.read(clientesProvider.notifier).actualizar(cliente);
      } else {
        await ref.read(clientesProvider.notifier).crear(cliente);
        await CarpetaService.instance.generarPDFPerfil(cliente);

        if (mounted) {
          WhatsAppService.enviarMensaje(
            cliente.telefono,
            WhatsAppService.mensajeBienvenida(cliente.nombre),
            context,
          );
        }
      }

      if (!mounted) {
        return;
      }

      AppSnackBar.exito(context,
          _isEditing ? AppStrings.datosGuardados : 'Cliente guardado. PDF generado.');
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
    _nombreCtrl.dispose();
    _apellidoCtrl.dispose();
    _telefonoCtrl.dispose();
    _telRefCtrl.dispose();
    _dpiCtrl.dispose();
    _emailCtrl.dispose();
    _direccionCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
            _isEditing ? AppStrings.editarCliente : AppStrings.nuevoCliente),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Foto
              GestureDetector(
                onTap: _seleccionarFoto,
                child: CircleAvatar(
                  radius: 50,
                  backgroundColor: AppColors.divider,
                  backgroundImage: _fotoPath != null
                      ? FileImage(File(_fotoPath!))
                      : null,
                  child: _fotoPath == null
                      ? const Icon(Icons.camera_alt,
                          size: 32, color: AppColors.textSecondary)
                      : null,
                ),
              ),
              const SizedBox(height: 8),
              Text('Toca para agregar foto', style: AppTextStyles.caption),
              const SizedBox(height: 24),

              // Nombre
              TextFormField(
                controller: _nombreCtrl,
                decoration: const InputDecoration(
                  labelText: '${AppStrings.nombre} *',
                  prefixIcon: Icon(Icons.person),
                ),
                textCapitalization: TextCapitalization.words,
                onChanged: (v) {
                  final tc = Usuario.toTitleCase(v);
                  if (tc != v) {
                    _nombreCtrl.value = TextEditingValue(
                      text: tc,
                      selection: TextSelection.collapsed(offset: tc.length),
                    );
                  }
                },
                validator: AppValidators.nombre,
              ),
              const SizedBox(height: 16),

              // Apellido
              TextFormField(
                controller: _apellidoCtrl,
                decoration: const InputDecoration(
                  labelText: '${AppStrings.apellido} *',
                  prefixIcon: Icon(Icons.person_outline),
                ),
                textCapitalization: TextCapitalization.words,
                onChanged: (v) {
                  final tc = Usuario.toTitleCase(v);
                  if (tc != v) {
                    _apellidoCtrl.value = TextEditingValue(
                      text: tc,
                      selection: TextSelection.collapsed(offset: tc.length),
                    );
                  }
                },
                validator: AppValidators.apellido,
              ),
              const SizedBox(height: 16),

              // Teléfono
              TextFormField(
                controller: _telefonoCtrl,
                decoration: const InputDecoration(
                  labelText: '${AppStrings.telefono} *',
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

              // Tel referencia
              TextFormField(
                controller: _telRefCtrl,
                decoration: const InputDecoration(
                  labelText: AppStrings.telefonoReferencia,
                  prefixIcon: Icon(Icons.phone_forwarded),
                  hintText: 'Número familiar/referencia',
                ),
                keyboardType: TextInputType.phone,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(8),
                ],
              ),
              const SizedBox(height: 16),

              // DPI
              TextFormField(
                controller: _dpiCtrl,
                decoration: const InputDecoration(
                  labelText: AppStrings.dpi,
                  prefixIcon: Icon(Icons.badge),
                  hintText: 'XXXX-XXXXX-XXXX',
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[\d-]')),
                  DpiInputFormatter(),
                ],
                validator: AppValidators.dpi,
              ),
              const SizedBox(height: 16),

              // Email
              TextFormField(
                controller: _emailCtrl,
                decoration: const InputDecoration(
                  labelText: AppStrings.email,
                  prefixIcon: Icon(Icons.email),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: AppValidators.email,
              ),
              const SizedBox(height: 16),

              // Dirección
              TextFormField(
                controller: _direccionCtrl,
                decoration: const InputDecoration(
                  labelText: AppStrings.direccion,
                  prefixIcon: Icon(Icons.location_on),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 32),

              LoadingButton(
                texto: AppStrings.guardar,
                onPressed: _guardar,
                isLoading: _isLoading,
                icono: Icons.save,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
