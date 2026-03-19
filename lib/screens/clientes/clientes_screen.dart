import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_strings.dart';
import '../../constants/app_text_styles.dart';
import '../../helpers/app_formatters.dart';
import '../../providers/cliente_provider.dart';
import '../../router/app_routes.dart';
import '../../services/whatsapp_service.dart';
import '../../widgets/cliente_avatar.dart';
import '../../widgets/confirm_dialog.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/app_error_widget.dart';

class ClientesScreen extends ConsumerWidget {
  const ClientesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final clientesAsync = ref.watch(clientesFiltradosProvider);
    final busquedaCtrl = TextEditingController(
      text: ref.read(clientesBusquedaProvider),
    );

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
        title: const Text(AppStrings.clientesActivos),
        actions: [
          TextButton.icon(
            onPressed: () => context.push(AppRoutes.clientesInactivos),
            icon: const Icon(Icons.history, color: Colors.white),
            label: const Text('Historial',
                style: TextStyle(color: Colors.white)),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: TextField(
              controller: busquedaCtrl,
              decoration: InputDecoration(
                hintText: '${AppStrings.buscar} cliente...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (v) {
                ref.read(clientesBusquedaProvider.notifier).state = v;
              },
            ),
          ),
        ),
      ),
      body: clientesAsync.when(
        data: (clientes) {
          if (clientes.isEmpty) {
            return EmptyState(
              mensaje: AppStrings.sinClientes,
              icono: Icons.people_outline,
              subtitulo: 'Agrega tu primer cliente',
              textoAccion: AppStrings.nuevoCliente,
              onAccion: () => context.push(AppRoutes.nuevoCliente),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(clientesProvider);
            },
            child: ListView.builder(
              itemCount: clientes.length,
              itemBuilder: (ctx, i) {
                final c = clientes[i];
                return Dismissible(
                  key: Key(c.id),
                  direction: DismissDirection.horizontal,
                  confirmDismiss: (direction) async {
                    if (direction == DismissDirection.startToEnd) {
                      WhatsAppService.enviarMensaje(
                        c.telefono,
                        WhatsAppService.mensajeBienvenida(c.nombre),
                        context,
                      );
                      return false;
                    } else {
                      return ConfirmDialog.show(
                        context,
                        titulo: 'Marcar inactivo',
                        mensaje:
                            '¿Deseas marcar a ${c.nombreCompleto} como inactivo?',
                      );
                    }
                  },
                  onDismissed: (direction) {
                    if (direction == DismissDirection.endToStart) {
                      ref
                          .read(clientesProvider.notifier)
                          .actualizarEstado(c.id, 'inactivo');
                    }
                  },
                  background: Container(
                    color: AppColors.whatsapp,
                    alignment: Alignment.centerLeft,
                    padding: const EdgeInsets.only(left: 20),
                    child:
                        const Icon(Icons.chat, color: Colors.white),
                  ),
                  secondaryBackground: Container(
                    color: AppColors.error,
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    child: const Icon(Icons.person_off,
                        color: Colors.white),
                  ),
                  child: ListTile(
                    leading: ClienteAvatar(
                      nombre: c.nombre,
                      apellido: c.apellido,
                      fotoPath: c.fotoPath,
                    ),
                    title: Text(c.nombreCompleto,
                        style: AppTextStyles.titleSmall),
                    subtitle: Text(
                      AppFormatters.telefono(c.telefono),
                      style: AppTextStyles.bodySmall,
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.push('/clientes/${c.id}'),
                  ),
                );
              },
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => AppErrorWidget(
          mensaje: e.toString(),
          onRetry: () => ref.invalidate(clientesProvider),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push(AppRoutes.nuevoCliente),
        child: const Icon(Icons.person_add),
      ),
    ),
    );
  }
}
