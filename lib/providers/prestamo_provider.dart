import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/prestamo.dart';
import '../models/cuota_pago.dart';
import '../models/resumen_financiero.dart';
import '../repositories/prestamo_repository.dart';
import '../repositories/pago_repository.dart';
import '../repositories/cliente_repository.dart';

final prestamoRepositoryProvider = Provider((ref) => PrestamoRepository());

final prestamosProvider =
    AsyncNotifierProvider<PrestamosNotifier, List<Prestamo>>(
        PrestamosNotifier.new);

class PrestamosNotifier extends AsyncNotifier<List<Prestamo>> {
  @override
  Future<List<Prestamo>> build() async {
    final repo = ref.read(prestamoRepositoryProvider);
    return repo.obtenerTodos();
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

  Future<void> registrarPago(
      String prestamoId, double monto, String cuotaId) async {
    final repo = ref.read(prestamoRepositoryProvider);
    await repo.registrarPago(prestamoId, monto);
    await repo.marcarCuotaPagada(cuotaId);
    ref.invalidateSelf();
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
  return repo.obtenerProximosAVencer(30);
});

final resumenFinancieroProvider =
    FutureProvider<ResumenFinanciero>((ref) async {
  final prestamoRepo = ref.read(prestamoRepositoryProvider);
  final pagoRepo = PagoRepository();
  final clienteRepo = ClienteRepository();

  final results = await Future.wait([
    pagoRepo.sumarCobradoMes(),
    prestamoRepo.sumarTotalPrestado(),
    prestamoRepo.sumarSaldoPendiente(),
    pagoRepo.sumarInteresesMes(),
    prestamoRepo.contarActivos(),
    prestamoRepo.contarVencidos(),
    clienteRepo.contarActivos(),
    clienteRepo.contarNuevosMes(),
    pagoRepo.pagosPorMes(6),
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
  );
});
