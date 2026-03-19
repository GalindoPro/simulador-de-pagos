import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/prestamo.dart';
import '../models/cuota_pago.dart';
import '../models/resumen_financiero.dart';
import '../repositories/prestamo_repository.dart';
import '../repositories/pago_repository.dart';
import '../repositories/cliente_repository.dart';
import 'auth_provider.dart';

final prestamoRepositoryProvider = Provider((ref) => PrestamoRepository());

final prestamosProvider =
    AsyncNotifierProvider<PrestamosNotifier, List<Prestamo>>(
        PrestamosNotifier.new);

class PrestamosNotifier extends AsyncNotifier<List<Prestamo>> {
  @override
  Future<List<Prestamo>> build() async {
    final repo = ref.read(prestamoRepositoryProvider);
    final usuarioId = ref.watch(usuarioIdProvider);
    return repo.obtenerTodos(usuarioId);
  }

  Future<void> crear(Prestamo prestamo, List<CuotaPago> cuotas) async {
    final repo = ref.read(prestamoRepositoryProvider);
    await repo.crear(prestamo, cuotas);
    ref.invalidateSelf();
  }

  Future<void> actualizar(Prestamo prestamo) async {
    final repo = ref.read(prestamoRepositoryProvider);
    await repo.actualizar(prestamo);
    ref.invalidateSelf();
  }

  Future<void> regenerarCuotas(
      Prestamo prestamo, List<CuotaPago> nuevasCuotas) async {
    final repo = ref.read(prestamoRepositoryProvider);
    await repo.regenerarCuotas(prestamo, nuevasCuotas);
    ref.invalidateSelf();
    ref.invalidate(cuotasPrestamoProvider(prestamo.id));
  }

  Future<void> registrarPago(
      String prestamoId, double monto, String cuotaId) async {
    final repo = ref.read(prestamoRepositoryProvider);
    await repo.registrarPago(prestamoId, monto);
    await repo.marcarCuotaPagada(cuotaId);
    ref.invalidateSelf();
    ref.invalidate(cuotasPrestamoProvider(prestamoId));
  }
}

final prestamosFiltroProvider = StateProvider<String>((ref) => 'todos');

final prestamosFiltradosProvider =
    Provider<AsyncValue<List<Prestamo>>>((ref) {
  final prestamosAsync = ref.watch(prestamosProvider);
  final filtro = ref.watch(prestamosFiltroProvider);

  return prestamosAsync.whenData((prestamos) {
    switch (filtro) {
      case 'activos':
        return prestamos.where((p) => p.estado == 'activo').toList();
      case 'vencidos':
        return prestamos.where((p) => p.estaVencido).toList();
      case 'pagados':
        return prestamos.where((p) => p.estado == 'pagado').toList();
      default:
        return prestamos;
    }
  });
});

final prestamosPorClienteProvider =
    FutureProvider.family<List<Prestamo>, String>((ref, clienteId) async {
  final repo = ref.read(prestamoRepositoryProvider);
  return repo.obtenerPorCliente(clienteId);
});

final cuotasPrestamoProvider =
    FutureProvider.family<List<CuotaPago>, String>((ref, prestamoId) async {
  final repo = ref.read(prestamoRepositoryProvider);
  return repo.obtenerCuotas(prestamoId);
});

final proximosAVencerProvider =
    FutureProvider<List<Prestamo>>((ref) async {
  final repo = ref.read(prestamoRepositoryProvider);
  final usuarioId = ref.watch(usuarioIdProvider);
  return repo.obtenerProximosAVencer(30, usuarioId);
});

/// Capital disponible = capitalInicial - saldoPendiente de préstamos activos
final capitalDisponibleProvider = FutureProvider<double>((ref) async {
  final usuario = ref.watch(sesionActualProvider);
  if (usuario == null) return 0;
  final usuarioId = usuario.id;
  final repo = ref.read(prestamoRepositoryProvider);
  final saldoPendiente = await repo.sumarSaldoPendiente(usuarioId);
  return usuario.capitalInicial - saldoPendiente;
});

final resumenFinancieroProvider =
    FutureProvider<ResumenFinanciero>((ref) async {
  final prestamoRepo = ref.read(prestamoRepositoryProvider);
  final pagoRepo = PagoRepository();
  final clienteRepo = ClienteRepository();
  final usuarioId = ref.watch(usuarioIdProvider);

  final results = await Future.wait([
    pagoRepo.sumarCobradoMes(usuarioId),
    prestamoRepo.sumarTotalPrestado(usuarioId),
    prestamoRepo.sumarSaldoPendiente(usuarioId),
    pagoRepo.sumarInteresesMes(usuarioId),
    prestamoRepo.contarActivos(usuarioId),
    prestamoRepo.contarVencidos(usuarioId),
    clienteRepo.contarActivos(usuarioId),
    clienteRepo.contarNuevosMes(usuarioId),
    pagoRepo.pagosPorMes(6, usuarioId),
    prestamoRepo.prestamosPorMes(6, usuarioId),
  ]);

  final prestamosActivos = results[4] as int;
  final prestamosVencidos = results[5] as int;
  final tasaMorosidad = prestamosActivos > 0
      ? (prestamosVencidos / prestamosActivos * 100)
      : 0.0;

  return ResumenFinanciero(
    totalCobradoMes: results[0] as double,
    totalPrestado: results[1] as double,
    saldoPendiente: results[2] as double,
    interesDelMes: results[3] as double,
    prestamosActivos: prestamosActivos,
    prestamosVencidos: prestamosVencidos,
    totalClientes: results[6] as int,
    clientesNuevosMes: results[7] as int,
    tasaMorosidad: tasaMorosidad,
    pagosPorMes: results[8] as Map<String, double>,
    prestamosPorMes: results[9] as Map<String, double>,
  );
});
