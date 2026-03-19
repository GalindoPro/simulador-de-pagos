import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_strings.dart';
import '../../constants/app_text_styles.dart';
import '../../helpers/app_validators.dart';
import '../../providers/auth_provider.dart';
import '../../router/app_routes.dart';
import '../../services/carpeta_service.dart';
import '../../widgets/app_snack_bar.dart';
import '../../widgets/confirm_dialog.dart';
import '../../widgets/loading_button.dart';

class ConfiguracionScreen extends ConsumerWidget {
  const ConfiguracionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usuario = ref.watch(sesionActualProvider);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) context.go(AppRoutes.dashboard);
      },
      child: Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go(AppRoutes.dashboard),
        ),
        title: const Text(AppStrings.configuracion),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Mi perfil
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(AppStrings.miPerfil,
                      style: AppTextStyles.titleMedium),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: AppColors.primary,
                        child: Text(
                          usuario?.nombre.isNotEmpty == true
                              ? usuario!.nombre[0].toUpperCase()
                              : 'U',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              usuario?.nombre ?? 'Usuario',
                              style: AppTextStyles.titleSmall,
                            ),
                            Text(
                              usuario?.telefono ?? '',
                              style: AppTextStyles.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    leading: const Icon(Icons.person),
                    title: const Text(AppStrings.cambiarNombre),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _cambiarNombre(context, ref),
                  ),
                  ListTile(
                    leading: const Icon(Icons.lock),
                    title: const Text(AppStrings.cambiarPassword),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _cambiarPassword(context, ref),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Respaldo
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(AppStrings.respaldoDatos,
                      style: AppTextStyles.titleMedium),
                  const SizedBox(height: 12),
                  ListTile(
                    leading: const Icon(Icons.backup),
                    title: const Text(AppStrings.exportarDB),
                    subtitle: const Text('Compartir archivo de base de datos'),
                    trailing: const Icon(Icons.share),
                    onTap: () {
                      CarpetaService.instance.compartirBaseDatos();
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Acerca de
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(AppStrings.acercaDe,
                      style: AppTextStyles.titleMedium),
                  const SizedBox(height: 12),
                  ListTile(
                    leading: const Icon(Icons.info),
                    title: const Text(AppStrings.appName),
                    subtitle:
                        const Text('Versión ${AppStrings.version}'),
                  ),
                  const ListTile(
                    leading: Icon(Icons.business),
                    title: Text('Gestión Financiera'),
                    subtitle: Text('App para prestamistas en Guatemala'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Cerrar sesión
          LoadingButton(
            texto: AppStrings.cerrarSesion,
            onPressed: () async {
              final confirm = await ConfirmDialog.show(
                context,
                titulo: AppStrings.cerrarSesion,
                mensaje: '¿Estás seguro de que deseas cerrar sesión?',
                textoConfirmar: AppStrings.cerrarSesion,
              );
              if (confirm && context.mounted) {
                await ref.read(sesionActualProvider.notifier).logout();
                if (context.mounted) {
                  context.go(AppRoutes.login);
                }
              }
            },
            isLoading: false,
            icono: Icons.logout,
            color: AppColors.error,
          ),
          const SizedBox(height: 32),
        ],
      ),
    ),
    );
  }

  void _cambiarNombre(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController(
      text: ref.read(sesionActualProvider)?.nombre ?? '',
    );
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(AppStrings.cambiarNombre),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: controller,
            decoration: const InputDecoration(
              labelText: AppStrings.nombre,
            ),
            textCapitalization: TextCapitalization.words,
            validator: AppValidators.nombre,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(AppStrings.cancelar),
          ),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                await ref
                    .read(sesionActualProvider.notifier)
                    .actualizarNombre(controller.text.trim());
                if (ctx.mounted) {
                  Navigator.pop(ctx);
                  AppSnackBar.exito(context, AppStrings.datosGuardados);
                }
              }
            },
            child: const Text(AppStrings.guardar),
          ),
        ],
      ),
    );
  }

  void _cambiarPassword(BuildContext context, WidgetRef ref) {
    final newPassCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(AppStrings.cambiarPassword),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: newPassCtrl,
                decoration: const InputDecoration(
                  labelText: AppStrings.nuevaPassword,
                ),
                obscureText: true,
                validator: AppValidators.password,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: confirmCtrl,
                decoration: const InputDecoration(
                  labelText: AppStrings.confirmarNuevaPassword,
                ),
                obscureText: true,
                validator: (v) =>
                    AppValidators.confirmarPassword(v, newPassCtrl.text),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(AppStrings.cancelar),
          ),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                final usuario = ref.read(sesionActualProvider);
                if (usuario != null) {
                  await ref
                      .read(usuarioRepositoryProvider)
                      .actualizarPassword(usuario.id, newPassCtrl.text);
                  if (ctx.mounted) {
                    Navigator.pop(ctx);
                    AppSnackBar.exito(
                        context, AppStrings.passwordActualizada);
                  }
                }
              }
            },
            child: const Text(AppStrings.guardar),
          ),
        ],
      ),
    );
  }
}
