import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/cliente.dart';
import '../repositories/cliente_repository.dart';
import 'auth_provider.dart';

final clienteRepositoryProvider = Provider((ref) => ClienteRepository());

final clientesProvider =
    AsyncNotifierProvider<ClientesNotifier, List<Cliente>>(
        ClientesNotifier.new);

class ClientesNotifier extends AsyncNotifier<List<Cliente>> {
  @override
  Future<List<Cliente>> build() async {
    final repo = ref.read(clienteRepositoryProvider);
    final usuarioId = ref.watch(usuarioIdProvider);
    return repo.obtenerTodos(usuarioId);
  }

  Future<void> crear(Cliente cliente) async {
    final repo = ref.read(clienteRepositoryProvider);
    await repo.crear(cliente);
    ref.invalidateSelf();
  }

  Future<void> actualizar(Cliente cliente) async {
    final repo = ref.read(clienteRepositoryProvider);
    await repo.actualizar(cliente);
    ref.invalidateSelf();
  }

  Future<void> eliminar(String id) async {
    final repo = ref.read(clienteRepositoryProvider);
    await repo.eliminar(id);
    ref.invalidateSelf();
  }

  Future<void> actualizarEstado(String id, String estado) async {
    final repo = ref.read(clienteRepositoryProvider);
    await repo.actualizarEstado(id, estado);
    ref.invalidateSelf();
  }
}

final clientesBusquedaProvider = StateProvider<String>((ref) => '');

final clientesFiltradosProvider = Provider<AsyncValue<List<Cliente>>>((ref) {
  final clientesAsync = ref.watch(clientesProvider);
  final busqueda = ref.watch(clientesBusquedaProvider).toLowerCase();

  return clientesAsync.whenData((clientes) {
    if (busqueda.isEmpty) {
      return clientes.where((c) => c.estado == 'activo').toList();
    }
    return clientes.where((c) {
      if (c.estado != 'activo') {
        return false;
      }
      final texto =
          '${c.nombre} ${c.apellido} ${c.telefono} ${c.dpi ?? ''}'
              .toLowerCase();
      return texto.contains(busqueda);
    }).toList();
  });
});

final clientesInactivosProvider =
    Provider<AsyncValue<List<Cliente>>>((ref) {
  final clientesAsync = ref.watch(clientesProvider);
  return clientesAsync.whenData((clientes) {
    return clientes
        .where((c) => c.estado == 'inactivo' || c.estado == 'finalizado')
        .toList();
  });
});

final clientePorIdProvider =
    FutureProvider.family<Cliente?, String>((ref, id) async {
  final repo = ref.read(clienteRepositoryProvider);
  return repo.obtenerPorId(id);
});
