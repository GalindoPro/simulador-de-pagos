import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_strings.dart';
import '../../constants/app_text_styles.dart';
import '../../helpers/app_formatters.dart';
import '../../providers/cliente_provider.dart';
import '../../providers/prestamo_provider.dart';
import '../../providers/pago_provider.dart';
import '../../widgets/cliente_avatar.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/prestamo_card.dart';
import '../../widgets/pago_list_tile.dart';
import '../../widgets/whatsapp_button.dart';
import '../../widgets/app_error_widget.dart';

class DetalleClienteScreen extends ConsumerWidget {
  final String clienteId;

  const DetalleClienteScreen({super.key, required this.clienteId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final clienteAsync = ref.watch(clientePorIdProvider(clienteId));

    return clienteAsync.when(
      data: (cliente) {
        if (cliente == null) {
          return Scaffold(
            appBar: AppBar(),
            body: const Center(child: Text('Cliente no encontrado')),
          );
        }

        return DefaultTabController(
          length: 3,
          child: Scaffold(
            appBar: AppBar(
              title: Text(cliente.nombreCompleto),
              actions: [
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () =>
                      context.push('/clientes/${cliente.id}/editar'),
                ),
              ],
              bottom: const TabBar(
                indicatorColor: Colors.white,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white70,
                tabs: [
                  Tab(text: 'Info', icon: Icon(Icons.person)),
                  Tab(text: 'Préstamos', icon: Icon(Icons.payments)),
                  Tab(text: 'Pagos', icon: Icon(Icons.attach_money)),
                ],
              ),
            ),
            body: Column(
              children: [
                // Banner de estado
                if (cliente.estado == 'finalizado')
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    color: AppColors.successLight,
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle,
                            color: AppColors.success),
                        const SizedBox(width: 8),
                        Text(
                          'Préstamo finalizado — Apto para nuevo crédito',
                          style: AppTextStyles.bodySmall
                              .copyWith(color: AppColors.success),
                        ),
                      ],
                    ),
                  ),
                if (cliente.estado == 'inactivo')
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    color: AppColors.background,
                    child: Row(
                      children: [
                        const Icon(Icons.person_off,
                            color: AppColors.textSecondary),
                        const SizedBox(width: 8),
                        Text(
                          'Sin préstamos activos',
                          style: AppTextStyles.bodySmall,
                        ),
                      ],
                    ),
                  ),
                Expanded(
                  child: TabBarView(
                    children: [
                      // Tab Info
                      SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            ClienteAvatar(
                              nombre: cliente.nombre,
                              apellido: cliente.apellido,
                              fotoPath: cliente.fotoPath,
                              radio: 48,
                            ),
                            const SizedBox(height: 16),
                            Text(cliente.nombreCompleto,
                                style: AppTextStyles.headlineSmall),
                            const SizedBox(height: 24),
                            _infoTile(Icons.phone, 'Teléfono',
                                AppFormatters.telefono(cliente.telefono)),
                            if (cliente.telefonoReferencia != null)
                              _infoTile(
                                  Icons.phone_forwarded,
                                  'Tel. Referencia',
                                  AppFormatters.telefono(
                                      cliente.telefonoReferencia!)),
                            if (cliente.dpi != null && cliente.dpi!.isNotEmpty)
                              _infoTile(Icons.badge, 'DPI',
                                  AppFormatters.formatearDPI(cliente.dpi!)),
                            if (cliente.email != null &&
                                cliente.email!.isNotEmpty)
                              _infoTile(
                                  Icons.email, 'Email', cliente.email!),
                            if (cliente.direccion != null &&
                                cliente.direccion!.isNotEmpty)
                              _infoTile(Icons.location_on, 'Dirección',
                                  cliente.direccion!),
                            _infoTile(Icons.calendar_today, 'Registrado',
                                AppFormatters.fechaLarga(cliente.fechaRegistro)),
                            const SizedBox(height: 16),
                            WhatsAppButton(
                              telefono: cliente.telefono,
                              mensaje: '¡Hola ${cliente.nombre}!',
                              mostrarTexto: true,
                            ),
                          ],
                        ),
                      ),

                      // Tab Préstamos
                      _TabPrestamos(clienteId: clienteId, cliente: cliente),

                      // Tab Pagos
                      _TabPagos(clienteId: clienteId, cliente: cliente),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
      loading: () => Scaffold(
        appBar: AppBar(),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        appBar: AppBar(),
        body: AppErrorWidget(mensaje: e.toString()),
      ),
    );
  }

  Widget _infoTile(IconData icon, String label, String value) {
    return ListTile(
      leading: Icon(icon, color: AppColors.primary),
      title: Text(label, style: AppTextStyles.labelMedium),
      subtitle: Text(value, style: AppTextStyles.bodyMedium),
    );
  }
}

class _TabPrestamos extends ConsumerWidget {
  final String clienteId;
  final dynamic cliente;

  const _TabPrestamos({required this.clienteId, required this.cliente});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prestamosAsync =
        ref.watch(prestamosPorClienteProvider(clienteId));

    return prestamosAsync.when(
      data: (prestamos) {
        if (prestamos.isEmpty) {
          return const EmptyState(
            mensaje: AppStrings.sinPrestamos,
            icono: Icons.payments_outlined,
          );
        }
        return ListView.builder(
          itemCount: prestamos.length,
          itemBuilder: (ctx, i) {
            return PrestamoCard(
              prestamo: prestamos[i],
              cliente: cliente,
              onTap: () =>
                  context.push('/prestamos/${prestamos[i].id}'),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => AppErrorWidget(mensaje: e.toString()),
    );
  }
}

class _TabPagos extends ConsumerWidget {
  final String clienteId;
  final dynamic cliente;

  const _TabPagos({required this.clienteId, required this.cliente});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pagosAsync = ref.watch(pagosPorClienteProvider(clienteId));

    return pagosAsync.when(
      data: (pagos) {
        if (pagos.isEmpty) {
          return const EmptyState(
            mensaje: AppStrings.sinPagos,
            icono: Icons.attach_money,
          );
        }
        return ListView.builder(
          itemCount: pagos.length,
          itemBuilder: (ctx, i) {
            return PagoListTile(
              pago: pagos[i],
              cliente: cliente,
              onTap: () => context.push('/pagos/${pagos[i].id}'),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => AppErrorWidget(mensaje: e.toString()),
    );
  }
}
