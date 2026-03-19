import '../models/prestamo.dart';
import '../models/cuota_pago.dart';
import '../services/database_helper.dart';

class PrestamoRepository {
  final _db = DatabaseHelper.instance;

  Future<void> crear(Prestamo prestamo, List<CuotaPago> cuotas) async {
    final db = await _db.database;
    await db.transaction((txn) async {
      await txn.insert('prestamos', prestamo.toMap());
      for (final cuota in cuotas) {
        await txn.insert('tabla_pagos', cuota.toMap());
      }
    });
  }

  Future<void> actualizar(Prestamo prestamo) async {
    final db = await _db.database;
    await db.update(
      'prestamos',
      prestamo.toMap(),
      where: 'id = ?',
      whereArgs: [prestamo.id],
    );
  }

  Future<Prestamo?> obtenerPorId(String id) async {
    final db = await _db.database;
    final result = await db.query(
      'prestamos',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (result.isEmpty) {
      return null;
    }
    return Prestamo.fromMap(result.first);
  }

  Future<List<Prestamo>> obtenerTodos() async {
    final db = await _db.database;
    final result = await db.query(
      'prestamos',
      orderBy: 'fecha_creacion DESC',
    );
    return result.map((m) => Prestamo.fromMap(m)).toList();
  }

  Future<List<Prestamo>> obtenerPorCliente(String clienteId) async {
    final db = await _db.database;
    final result = await db.query(
      'prestamos',
      where: 'cliente_id = ?',
      whereArgs: [clienteId],
      orderBy: 'fecha_creacion DESC',
    );
    return result.map((m) => Prestamo.fromMap(m)).toList();
  }

  Future<List<Prestamo>> obtenerActivos() async {
    final db = await _db.database;
    final result = await db.query(
      'prestamos',
      where: "estado = 'activo'",
      orderBy: 'fecha_vencimiento ASC',
    );
    return result.map((m) => Prestamo.fromMap(m)).toList();
  }

  Future<List<Prestamo>> obtenerVencidos() async {
    final db = await _db.database;
    final now = DateTime.now().toIso8601String();
    final result = await db.query(
      'prestamos',
      where: "estado = 'activo' AND fecha_vencimiento < ?",
      whereArgs: [now],
    );
    return result.map((m) => Prestamo.fromMap(m)).toList();
  }

  Future<List<Prestamo>> obtenerProximosAVencer(int dias) async {
    final db = await _db.database;
    final now = DateTime.now();
    final limite = now.add(Duration(days: dias)).toIso8601String();
    final result = await db.query(
      'prestamos',
      where:
          "estado = 'activo' AND fecha_vencimiento >= ? AND fecha_vencimiento <= ?",
      whereArgs: [now.toIso8601String(), limite],
      orderBy: 'fecha_vencimiento ASC',
    );
    return result.map((m) => Prestamo.fromMap(m)).toList();
  }

  Future<List<CuotaPago>> obtenerCuotas(String prestamoId) async {
    final db = await _db.database;
    final result = await db.query(
      'tabla_pagos',
      where: 'prestamo_id = ?',
      whereArgs: [prestamoId],
      orderBy: 'cuota_numero ASC',
    );
    return result.map((m) => CuotaPago.fromMap(m)).toList();
  }

  Future<CuotaPago?> obtenerCuotaActual(String prestamoId) async {
    final db = await _db.database;
    final result = await db.query(
      'tabla_pagos',
      where: 'prestamo_id = ? AND pagado = 0',
      whereArgs: [prestamoId],
      orderBy: 'cuota_numero ASC',
      limit: 1,
    );
    if (result.isEmpty) {
      return null;
    }
    return CuotaPago.fromMap(result.first);
  }

  Future<void> registrarPago(String prestamoId, double monto) async {
    final db = await _db.database;
    await db.rawUpdate(
      'UPDATE prestamos SET saldo_pendiente = saldo_pendiente - ? WHERE id = ?',
      [monto, prestamoId],
    );

    // Verificar si se terminó de pagar
    final prestamo = await obtenerPorId(prestamoId);
    if (prestamo != null && prestamo.saldoPendiente <= 0.01) {
      await db.update(
        'prestamos',
        {'estado': 'pagado', 'saldo_pendiente': 0},
        where: 'id = ?',
        whereArgs: [prestamoId],
      );
    }
  }

  Future<void> marcarCuotaPagada(String cuotaId) async {
    final db = await _db.database;
    await db.update(
      'tabla_pagos',
      {
        'pagado': 1,
        'fecha_pagado': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [cuotaId],
    );
  }

  Future<int> contarActivos() async {
    final db = await _db.database;
    final result = await db.rawQuery(
      "SELECT COUNT(*) as total FROM prestamos WHERE estado = 'activo'",
    );
    return result.first['total'] as int;
  }

  Future<int> contarVencidos() async {
    final db = await _db.database;
    final now = DateTime.now().toIso8601String();
    final result = await db.rawQuery(
      "SELECT COUNT(*) as total FROM prestamos WHERE estado = 'activo' AND fecha_vencimiento < ?",
      [now],
    );
    return result.first['total'] as int;
  }

  Future<double> sumarSaldoPendiente() async {
    final db = await _db.database;
    final result = await db.rawQuery(
      "SELECT COALESCE(SUM(saldo_pendiente), 0) as total FROM prestamos WHERE estado = 'activo'",
    );
    return (result.first['total'] as num).toDouble();
  }

  Future<double> sumarTotalPrestado() async {
    final db = await _db.database;
    final result = await db.rawQuery(
      'SELECT COALESCE(SUM(monto_original), 0) as total FROM prestamos',
    );
    return (result.first['total'] as num).toDouble();
  }

  Future<Map<String, double>> prestamosPorMes(int meses) async {
    final db = await _db.database;
    final resultado = <String, double>{};
    final now = DateTime.now();

    for (int i = meses - 1; i >= 0; i--) {
      final mes = DateTime(now.year, now.month - i, 1);
      final finMes = DateTime(now.year, now.month - i + 1, 1);
      final result = await db.rawQuery(
        "SELECT COALESCE(SUM(monto_original), 0) as total FROM prestamos WHERE fecha_inicio >= ? AND fecha_inicio < ?",
        [mes.toIso8601String(), finMes.toIso8601String()],
      );
      final label =
          '${mes.month.toString().padLeft(2, '0')}/${mes.year.toString().substring(2)}';
      resultado[label] = (result.first['total'] as num).toDouble();
    }

    return resultado;
  }
}
