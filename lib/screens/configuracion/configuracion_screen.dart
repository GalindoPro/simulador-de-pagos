import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_strings.dart';
import '../../constants/app_text_styles.dart';
import '../../helpers/app_formatters.dart';
import '../../helpers/app_validators.dart';
import '../../providers/auth_provider.dart';
import '../../providers/cliente_provider.dart';
import '../../providers/prestamo_provider.dart';
import '../../providers/pago_provider.dart';
import '../../router/app_routes.dart';
import 'package:file_picker/file_picker.dart';
import '../../services/carpeta_service.dart';
import '../../services/database_helper.dart';
import '../../widgets/app_snack_bar.dart';
import '../../widgets/cliente_avatar.dart';
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
      body: SafeArea(
        top: false,
        child: ListView(
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
                    leading: const Icon(Icons.attach_money),
                    title: const Text('Editar Capital'),
                    subtitle: Text(
                      AppFormatters.moneda(usuario?.capitalInicial ?? 0),
                      style: AppTextStyles.bodySmall,
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _editarCapital(context, ref),
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

          // Administración de clientes
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Administración',
                      style: AppTextStyles.titleMedium),
                  const SizedBox(height: 12),
                  ListTile(
                    leading: const Icon(Icons.people, color: AppColors.error),
                    title: const Text('Eliminar Clientes'),
                    subtitle: const Text('Gestionar y eliminar clientes'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _mostrarEliminarClientes(context, ref),
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
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.download, color: AppColors.primary),
                    title: const Text('Importar Base de Datos'),
                    subtitle: const Text(
                        'Restaurar datos desde otro dispositivo'),
                    trailing: const Icon(Icons.folder_open),
                    onTap: () => _importarBaseDatos(context, ref),
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
          const SizedBox(height: 16),

          // Ayuda
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Ayuda', style: AppTextStyles.titleMedium),
                  const SizedBox(height: 12),
                  ListTile(
                    leading: const Icon(Icons.help_outline, color: AppColors.primary),
                    title: const Text('Guía de uso'),
                    subtitle: const Text('Instrucciones paso a paso'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _mostrarAyuda(context),
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
                ref.invalidate(clientesProvider);
                ref.invalidate(prestamosProvider);
                ref.invalidate(pagosProvider);
                ref.invalidate(resumenFinancieroProvider);
                ref.invalidate(resumenPagosProvider);
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

  void _editarCapital(BuildContext context, WidgetRef ref) {
    final usuario = ref.read(sesionActualProvider);
    final controller = TextEditingController(
      text: usuario?.capitalInicial.toStringAsFixed(0) ?? '0',
    );
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Editar Capital'),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: controller,
            decoration: const InputDecoration(
              labelText: 'Capital disponible',
              prefixText: 'Q ',
              prefixIcon: Icon(Icons.attach_money),
            ),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Ingresa un monto';
              final monto = double.tryParse(v.replaceAll(',', ''));
              if (monto == null || monto < 0) return 'Monto inválido';
              return null;
            },
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
                final monto = double.parse(
                    controller.text.trim().replaceAll(',', ''));
                await ref
                    .read(sesionActualProvider.notifier)
                    .actualizarCapital(monto);
                if (ctx.mounted) {
                  Navigator.pop(ctx);
                  AppSnackBar.exito(context, 'Capital actualizado');
                }
              }
            },
            child: const Text(AppStrings.guardar),
          ),
        ],
      ),
    );
  }

  void _mostrarEliminarClientes(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        expand: false,
        builder: (_, scrollController) {
          final clientesAsync = ref.watch(clientesProvider);

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Icon(Icons.people, color: AppColors.error),
                    const SizedBox(width: 8),
                    Text('Eliminar Clientes',
                        style: AppTextStyles.titleMedium),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: clientesAsync.when(
                  data: (clientes) {
                    if (clientes.isEmpty) {
                      return const Center(
                        child: Text('No hay clientes registrados'),
                      );
                    }
                    return ListView.builder(
                      controller: scrollController,
                      itemCount: clientes.length,
                      itemBuilder: (_, i) {
                        final c = clientes[i];
                        return ListTile(
                          leading: ClienteAvatar(
                            nombre: c.nombre,
                            apellido: c.apellido,
                            fotoPath: c.fotoPath,
                          ),
                          title: Text(c.nombreCompleto),
                          subtitle: Text(c.telefono,
                              style: AppTextStyles.bodySmall),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete,
                                color: AppColors.error),
                            onPressed: () async {
                              final confirm = await ConfirmDialog.show(
                                context,
                                titulo: 'Eliminar Cliente',
                                mensaje:
                                    '¿Eliminar a ${c.nombreCompleto}? Esta acción no se puede deshacer.',
                                textoConfirmar: AppStrings.eliminar,
                              );
                              if (confirm) {
                                await ref
                                    .read(clientesProvider.notifier)
                                    .eliminar(c.id);
                                if (context.mounted) {
                                  AppSnackBar.exito(context,
                                      '${c.nombreCompleto} eliminado');
                                }
                              }
                            },
                          ),
                        );
                      },
                    );
                  },
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(child: Text(e.toString())),
                ),
              ),
            ],
          );
        },
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

  void _importarBaseDatos(BuildContext context, WidgetRef ref) async {
    final confirm = await ConfirmDialog.show(
      context,
      titulo: 'Importar Base de Datos',
      mensaje:
          '¿Estás seguro? Esto reemplazará todos los datos actuales con los del archivo importado. '
          'Se recomienda exportar un respaldo antes de continuar.',
      textoConfirmar: 'Importar',
    );
    if (!confirm || !context.mounted) return;

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        allowMultiple: false,
      );

      if (result == null || result.files.single.path == null) return;

      final filePath = result.files.single.path!;
      if (!filePath.endsWith('.db')) {
        if (context.mounted) {
          AppSnackBar.error(
              context, 'Archivo inválido. Selecciona un archivo .db');
        }
        return;
      }

      await DatabaseHelper.instance.importarBaseDatos(filePath);

      // Reload session and invalidate all providers
      await ref.read(sesionActualProvider.notifier).cargarSesion();
      ref.invalidate(clientesProvider);
      ref.invalidate(prestamosProvider);
      ref.invalidate(pagosProvider);
      ref.invalidate(resumenFinancieroProvider);
      ref.invalidate(resumenPagosProvider);
      ref.invalidate(capitalDisponibleProvider);

      if (context.mounted) {
        AppSnackBar.exito(context, 'Base de datos importada correctamente');
        context.go(AppRoutes.login);
      }
    } catch (e) {
      if (context.mounted) {
        AppSnackBar.error(context, 'Error al importar: $e');
      }
    }
  }

  void _mostrarAyuda(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (_, scrollController) => Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(Icons.help_outline, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text('Guía de uso — Capital Pro',
                        style: AppTextStyles.titleMedium,
                        overflow: TextOverflow.ellipsis),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.all(16),
                children: const [
                  _PasoAyuda(
                    numero: 1,
                    titulo: 'Registro e inicio de sesión',
                    icono: Icons.login,
                    color: AppColors.primary,
                    instrucciones: [
                      'Al abrir la app por primera vez, presiona "Crear cuenta".',
                      'Ingresa tu nombre, teléfono y una contraseña.',
                      'Define tu capital inicial (el dinero disponible para prestar).',
                      'Para ingresar después, usa tu teléfono y contraseña.',
                    ],
                  ),
                  _PasoAyuda(
                    numero: 2,
                    titulo: 'Registrar un cliente',
                    icono: Icons.person_add,
                    color: AppColors.info,
                    instrucciones: [
                      'Desde el inicio, presiona "Nuevo Cliente" o ve a Clientes > botón (+).',
                      'Llena nombre, apellido y teléfono (obligatorios).',
                      'Opcionalmente agrega DPI, dirección y foto.',
                      'Al guardar, se genera un PDF de perfil y se envía un mensaje de bienvenida por WhatsApp.',
                    ],
                  ),
                  _PasoAyuda(
                    numero: 3,
                    titulo: 'Crear un préstamo',
                    icono: Icons.description,
                    color: AppColors.success,
                    instrucciones: [
                      'Ve a Préstamos > botón (+) o desde el inicio "Nuevo Préstamo".',
                      'Selecciona el cliente, ingresa el monto, tasa de interés y plazo en meses.',
                      'Revisa la cuota mensual calculada y el resumen.',
                      'Al confirmar, se genera la tabla de amortización y se notifica al cliente por WhatsApp.',
                      'El capital disponible se descuenta automáticamente.',
                    ],
                  ),
                  _PasoAyuda(
                    numero: 4,
                    titulo: 'Simulador de préstamos',
                    icono: Icons.calculate,
                    color: AppColors.warning,
                    instrucciones: [
                      'Desde el inicio, presiona "Simulador".',
                      'Ingresa monto, tasa y plazo para ver la cuota mensual.',
                      'Revisa la tabla de amortización completa.',
                      'Si te convence, presiona "Crear préstamo" para usar esos datos directamente.',
                    ],
                  ),
                  _PasoAyuda(
                    numero: 5,
                    titulo: 'Registrar un pago',
                    icono: Icons.payment,
                    color: AppColors.primary,
                    instrucciones: [
                      'Ve a Pagos > botón (+) o desde el detalle del préstamo "Registrar Pago".',
                      'Selecciona el cliente y el préstamo activo.',
                      'El monto de la cuota se carga automáticamente según la tabla de amortización.',
                      'Elige el método de pago: Efectivo o Transferencia/Depósito.',
                      'Si es transferencia, puedes agregar foto del comprobante.',
                      'Al guardar, se genera el recibo PDF y se envía confirmación por WhatsApp.',
                    ],
                  ),
                  _PasoAyuda(
                    numero: 6,
                    titulo: 'Tabla de amortización',
                    icono: Icons.table_chart,
                    color: AppColors.info,
                    instrucciones: [
                      'Cada préstamo tiene su tabla con 10 columnas.',
                      'Muestra: número de cuota, días, fecha programada, fecha de pago real, saldo, adeudado, pagado, por adelantado, tarde y pendiente.',
                      'Las cuotas pagadas aparecen en verde.',
                      'Si el pago se hizo antes o en la fecha: aparece en "Por adelantado".',
                      'Si el pago se hizo después de la fecha: aparece en "Tarde".',
                    ],
                  ),
                  _PasoAyuda(
                    numero: 7,
                    titulo: 'Editar préstamo y cancelar deuda',
                    icono: Icons.edit,
                    color: AppColors.warning,
                    instrucciones: [
                      'En el detalle del préstamo, presiona el ícono de editar.',
                      'Puedes cambiar el plazo o la tasa de interés.',
                      'Activa "Cancelar deuda completa" si el cliente quiere liquidar todo de una vez.',
                      'Se calcula el saldo de capital más un mes de interés.',
                      'Al confirmar, se genera el finiquito automáticamente.',
                    ],
                  ),
                  _PasoAyuda(
                    numero: 8,
                    titulo: 'Gestión de clientes',
                    icono: Icons.people,
                    color: AppColors.success,
                    instrucciones: [
                      'En Clientes, desliza a la derecha para enviar WhatsApp.',
                      'Desliza a la izquierda para marcar como inactivo.',
                      'En Historial, los clientes finalizados pueden recibir un nuevo préstamo deslizando a la izquierda.',
                      'Los clientes inactivos se pueden reactivar de la misma manera.',
                    ],
                  ),
                  _PasoAyuda(
                    numero: 9,
                    titulo: 'Reportes y estadísticas',
                    icono: Icons.bar_chart,
                    color: AppColors.primary,
                    instrucciones: [
                      'Ve a Reportes para ver el resumen financiero.',
                      'Consulta el capital prestado, ganancias, intereses del mes.',
                      'La gráfica circular muestra la distribución del capital.',
                      'Revisa los cobros por mes en la gráfica de barras.',
                    ],
                  ),
                  _PasoAyuda(
                    numero: 10,
                    titulo: 'Respaldo y migración',
                    icono: Icons.backup,
                    color: AppColors.info,
                    instrucciones: [
                      'En Configuración > Respaldo, presiona "Exportar" para compartir tu base de datos.',
                      'Guarda el archivo .db en un lugar seguro (Google Drive, WhatsApp, etc.).',
                      'Para migrar a otro teléfono: instala la app, ve a Configuración > "Importar Base de Datos".',
                      'Selecciona el archivo .db y se restaurarán todos tus datos.',
                    ],
                  ),
                  SizedBox(height: 32),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PasoAyuda extends StatelessWidget {
  final int numero;
  final String titulo;
  final IconData icono;
  final Color color;
  final List<String> instrucciones;

  const _PasoAyuda({
    required this.numero,
    required this.titulo,
    required this.icono,
    required this.color,
    required this.instrucciones,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Card(
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: color.withValues(alpha: 0.3)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: color.withValues(alpha: 0.15),
                    child: Text(
                      '$numero',
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Icon(icono, color: color, size: 22),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      titulo,
                      style: AppTextStyles.titleSmall,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ...instrucciones.map((inst) => Padding(
                    padding: const EdgeInsets.only(bottom: 6, left: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Icon(Icons.circle, size: 6, color: color),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            inst,
                            style: AppTextStyles.bodySmall,
                          ),
                        ),
                      ],
                    ),
                  )),
            ],
          ),
        ),
      ),
    );
  }
}
