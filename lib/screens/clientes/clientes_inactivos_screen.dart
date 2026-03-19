import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_strings.dart';
import '../../constants/app_text_styles.dart';
import '../../helpers/app_formatters.dart';
import '../../providers/cliente_provider.dart';
import '../../widgets/cliente_avatar.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/app_error_widget.dart';

class ClientesInactivosScreen extends ConsumerWidget {
  const ClientesInactivosScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final clientesAsync = ref.watch(clientesInactivosProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.historialClientes),
      ),
      body: clientesAsync.when(
        data: (clientes) {
          if (clientes.isEmpty) {
            return const EmptyState(
              mensaje: 'No hay historial de clientes',
              icono: Icons.history,
            );
          }

          return ListView.builder(
            itemCount: clientes.length,
            itemBuilder: (ctx, i) {
              final c = clientes[i];
              final esFinalizado = c.estado == 'finalizado';

              return ListTile(
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
                trailing: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 130),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: esFinalizado
                                ? AppColors.successLight
                                : AppColors.background,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            esFinalizado ? 'Finalizado' : 'Inactivo',
                            style: AppTextStyles.labelSmall.copyWith(
                              color: esFinalizado
                                  ? AppColors.success
                                  : AppColors.textSecondary,
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.chevron_right, size: 20),
                    ],
                  ),
                ),
                onTap: () => context.push('/clientes/${c.id}'),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => AppErrorWidget(
          mensaje: e.toString(),
          onRetry: () => ref.invalidate(clientesProvider),
        ),
      ),
    );
  }
}
