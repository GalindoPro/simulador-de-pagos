import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/pago.dart';
import '../repositories/pago_repository.dart';
import 'auth_provider.dart';

final pagoRepositoryProvider = Provider((ref) => PagoRepository());

class PagoFiltro {
  final String? estado;
  final String? metodoPago;
  final DateTime? fechaDesde;
  final DateTime? fechaHasta;
  final String busqueda;

  const PagoFiltro({
    this.estado,
    this.metodoPago,
    this.fechaDesde,
    this.fechaHasta,
    this.busqueda = '',
  });

  PagoFiltro copyWith({
    String? estado,
    String? metodoPago,
    DateTime? fechaDesde,
    DateTime? fechaHasta,
    String? busqueda,
  }) {
    return PagoFiltro(
      estado: estado ?? this.estado,
      metodoPago: metodoPago ?? this.metodoPago,
      fechaDesde: fechaDesde ?? this.fechaDesde,
      fechaHasta: fechaHasta ?? this.fechaHasta,
      busqueda: busqueda ?? this.busqueda,
    );
  }
}

final pagosProvider =
    AsyncNotifierProvider<PagosNotifier, List<Pago>>(PagosNotifier.new);

class PagosNotifier extends AsyncNotifier<List<Pago>> {
  @override
  Future<List<Pago>> build() async {
    final repo = ref.read(pagoRepositoryProvider);
    final usuarioId = ref.watch(usuarioIdProvider);
    return repo.obtenerTodos(usuarioId);
  }

  Future<void> crear(Pago pago) async {
    final repo = ref.read(pagoRepositoryProvider);
    await repo.crear(pago);
    ref.invalidateSelf();
  }

  Future<void> actualizar(Pago pago) async {
    final repo = ref.read(pagoRepositoryProvider);
    await repo.actualizar(pago);
    ref.invalidateSelf();
  }

  Future<void> eliminar(String id) async {
    final repo = ref.read(pagoRepositoryProvider);
    await repo.eliminar(id);
    ref.invalidateSelf();
  }
}

final pagosFiltroProvider =
    StateProvider<PagoFiltro>((ref) => const PagoFiltro());

final pagosFiltradosProvider =
    Provider<AsyncValue<List<Pago>>>((ref) {
  final pagosAsync = ref.watch(pagosProvider);
  final filtro = ref.watch(pagosFiltroProvider);

  return pagosAsync.whenData((pagos) {
    var resultado = pagos.toList();

    if (filtro.estado != null && filtro.estado!.isNotEmpty) {
      resultado = resultado.where((p) => p.estado == filtro.estado).toList();
    }

    if (filtro.metodoPago != null && filtro.metodoPago!.isNotEmpty) {
      resultado =
          resultado.where((p) => p.metodoPago == filtro.metodoPago).toList();
    }

    if (filtro.fechaDesde != null) {
      resultado = resultado
          .where((p) => p.fecha.isAfter(filtro.fechaDesde!))
          .toList();
    }

    if (filtro.fechaHasta != null) {
      resultado = resultado
          .where((p) => p.fecha.isBefore(filtro.fechaHasta!))
          .toList();
    }

    if (filtro.busqueda.isNotEmpty) {
      final query = filtro.busqueda.toLowerCase();
      resultado = resultado
          .where((p) => p.concepto.toLowerCase().contains(query))
          .toList();
    }

    return resultado;
  });
});

final pagosRecientesProvider =
    FutureProvider.family<List<Pago>, int>((ref, limite) async {
  final repo = ref.read(pagoRepositoryProvider);
  final usuarioId = ref.watch(usuarioIdProvider);
  return repo.obtenerRecientes(limite, usuarioId);
});

final pagosPorClienteProvider =
    FutureProvider.family<List<Pago>, String>((ref, clienteId) async {
  final repo = ref.read(pagoRepositoryProvider);
  return repo.obtenerPorCliente(clienteId);
});

final resumenPagosProvider = FutureProvider((ref) async {
  final repo = ref.read(pagoRepositoryProvider);
  final usuarioId = ref.watch(usuarioIdProvider);
  final cobrado = await repo.sumarCobradoMes(usuarioId);
  final pendiente = await repo.sumarPendiente(usuarioId);
  final completados = await repo.contarCompletadosMes(usuarioId);

  return {
    'cobrado': cobrado,
    'pendiente': pendiente,
    'completados': completados,
  };
});
