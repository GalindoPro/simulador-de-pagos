import '../models/pago.dart';
import '../services/database_helper.dart';

class PagoRepository {
  final _db = DatabaseHelper.instance;

  Future<void> crear(Pago pago) async {
    final db = await _db.database;
    await db.insert('pagos', pago.toMap());
  }

  Future<void> actualizar(Pago pago) async {
    final db = await _db.database;
    await db.update(
      'pagos',
      pago.toMap(),
      where: 'id = ?',
      whereArgs: [pago.id],
    );
  }

  Future<void> eliminar(String id) async {
    final db = await _db.database;
    await db.delete(
      'pagos',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<Pago?> obtenerPorId(String id) async {
    final db = await _db.database;
    final result = await db.query(
      'pagos',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (result.isEmpty) {
      return null;
    }
    return Pago.fromMap(result.first);
  }

  Future<List<Pago>> obtenerTodos(String usuarioId) async {
    final db = await _db.database;
    final result = await db.query(
      'pagos',
      where: 'registrado_por = ?',
      whereArgs: [usuarioId],
      orderBy: 'fecha_creacion DESC',
    );
    return result.map((m) => Pago.fromMap(m)).toList();
  }

  Future<List<Pago>> obtenerPorCliente(String clienteId) async {
    final db = await _db.database;
    final result = await db.query(
      'pagos',
      where: 'cliente_id = ?',
      whereArgs: [clienteId],
      orderBy: 'fecha DESC',
    );
    return result.map((m) => Pago.fromMap(m)).toList();
  }

  Future<List<Pago>> obtenerPorPrestamo(String prestamoId) async {
    final db = await _db.database;
    final result = await db.query(
      'pagos',
      where: 'prestamo_id = ?',
      whereArgs: [prestamoId],
      orderBy: 'fecha DESC',
    );
    return result.map((m) => Pago.fromMap(m)).toList();
  }

  Future<List<Pago>> obtenerRecientes(int limite, String usuarioId) async {
    final db = await _db.database;
    final result = await db.query(
      'pagos',
      where: 'registrado_por = ?',
      whereArgs: [usuarioId],
      orderBy: 'fecha_creacion DESC',
      limit: limite,
    );
    return result.map((m) => Pago.fromMap(m)).toList();
  }

  Future<double> sumarCobradoMes(String usuarioId) async {
    final db = await _db.database;
    final now = DateTime.now();
    final inicioMes = DateTime(now.year, now.month, 1).toIso8601String();
    final result = await db.rawQuery(
      "SELECT COALESCE(SUM(monto), 0) as total FROM pagos WHERE estado = 'completado' AND registrado_por = ? AND fecha >= ?",
      [usuarioId, inicioMes],
    );
    return (result.first['total'] as num).toDouble();
  }

  Future<double> sumarInteresesMes(String usuarioId) async {
    final db = await _db.database;
    final now = DateTime.now();
    final inicioMes = DateTime(now.year, now.month, 1).toIso8601String();
    final result = await db.rawQuery(
      '''
      SELECT COALESCE(SUM(tp.interes), 0) as total
      FROM pagos p
      INNER JOIN tabla_pagos tp ON p.prestamo_id = tp.prestamo_id AND p.cuota_numero = tp.cuota_numero
      WHERE p.estado = 'completado' AND p.registrado_por = ? AND p.fecha >= ?
      ''',
      [usuarioId, inicioMes],
    );
    return (result.first['total'] as num).toDouble();
  }

  Future<int> contarCompletadosMes(String usuarioId) async {
    final db = await _db.database;
    final now = DateTime.now();
    final inicioMes = DateTime(now.year, now.month, 1).toIso8601String();
    final result = await db.rawQuery(
      "SELECT COUNT(*) as total FROM pagos WHERE estado = 'completado' AND registrado_por = ? AND fecha >= ?",
      [usuarioId, inicioMes],
    );
    return result.first['total'] as int;
  }

  Future<double> sumarPendiente(String usuarioId) async {
    final db = await _db.database;
    final result = await db.rawQuery(
      "SELECT COALESCE(SUM(monto), 0) as total FROM pagos WHERE estado = 'pendiente' AND registrado_por = ?",
      [usuarioId],
    );
    return (result.first['total'] as num).toDouble();
  }

  Future<Map<String, double>> pagosPorMes(int meses, String usuarioId) async {
    final db = await _db.database;
    final resultado = <String, double>{};
    final now = DateTime.now();

    for (int i = meses - 1; i >= 0; i--) {
      final mes = DateTime(now.year, now.month - i, 1);
      final finMes = DateTime(now.year, now.month - i + 1, 1);
      final result = await db.rawQuery(
        "SELECT COALESCE(SUM(monto), 0) as total FROM pagos WHERE estado = 'completado' AND registrado_por = ? AND fecha >= ? AND fecha < ?",
        [usuarioId, mes.toIso8601String(), finMes.toIso8601String()],
      );
      final label =
          '${mes.month.toString().padLeft(2, '0')}/${mes.year.toString().substring(2)}';
      resultado[label] = (result.first['total'] as num).toDouble();
    }

    return resultado;
  }
}
