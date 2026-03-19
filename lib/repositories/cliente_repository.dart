import '../models/cliente.dart';
import '../services/database_helper.dart';

class ClienteRepository {
  final _db = DatabaseHelper.instance;

  Future<void> crear(Cliente cliente) async {
    final db = await _db.database;
    await db.insert('clientes', cliente.toMap());
  }

  Future<void> actualizar(Cliente cliente) async {
    final db = await _db.database;
    await db.update(
      'clientes',
      cliente.toMap(),
      where: 'id = ?',
      whereArgs: [cliente.id],
    );
  }

  Future<void> eliminar(String id) async {
    final db = await _db.database;
    await db.update(
      'clientes',
      {'activo': 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<Cliente?> obtenerPorId(String id) async {
    final db = await _db.database;
    final result = await db.query(
      'clientes',
      where: 'id = ? AND activo = 1',
      whereArgs: [id],
    );
    if (result.isEmpty) {
      return null;
    }
    return Cliente.fromMap(result.first);
  }

  Future<List<Cliente>> obtenerActivos(String usuarioId) async {
    final db = await _db.database;
    final result = await db.query(
      'clientes',
      where: "activo = 1 AND estado = 'activo' AND usuario_id = ?",
      whereArgs: [usuarioId],
      orderBy: 'nombre ASC',
    );
    return result.map((m) => Cliente.fromMap(m)).toList();
  }

  Future<List<Cliente>> obtenerInactivos(String usuarioId) async {
    final db = await _db.database;
    final result = await db.query(
      'clientes',
      where:
          "activo = 1 AND (estado = 'inactivo' OR estado = 'finalizado') AND usuario_id = ?",
      whereArgs: [usuarioId],
      orderBy: 'nombre ASC',
    );
    return result.map((m) => Cliente.fromMap(m)).toList();
  }

  Future<List<Cliente>> obtenerTodos(String usuarioId) async {
    final db = await _db.database;
    final result = await db.query(
      'clientes',
      where: 'activo = 1 AND usuario_id = ?',
      whereArgs: [usuarioId],
      orderBy: 'nombre ASC',
    );
    return result.map((m) => Cliente.fromMap(m)).toList();
  }

  Future<List<Cliente>> buscar(String query, String usuarioId) async {
    final db = await _db.database;
    final result = await db.query(
      'clientes',
      where:
          'activo = 1 AND usuario_id = ? AND (nombre LIKE ? OR apellido LIKE ? OR telefono LIKE ? OR dpi LIKE ?)',
      whereArgs: [usuarioId, '%$query%', '%$query%', '%$query%', '%$query%'],
      orderBy: 'nombre ASC',
    );
    return result.map((m) => Cliente.fromMap(m)).toList();
  }

  Future<void> actualizarEstado(String id, String estado) async {
    final db = await _db.database;
    await db.update(
      'clientes',
      {'estado': estado},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> contarActivos(String usuarioId) async {
    final db = await _db.database;
    final result = await db.rawQuery(
      "SELECT COUNT(*) as total FROM clientes WHERE activo = 1 AND estado = 'activo' AND usuario_id = ?",
      [usuarioId],
    );
    return result.first['total'] as int;
  }

  Future<int> contarNuevosMes(String usuarioId) async {
    final db = await _db.database;
    final now = DateTime.now();
    final inicioMes = DateTime(now.year, now.month, 1).toIso8601String();
    final result = await db.rawQuery(
      'SELECT COUNT(*) as total FROM clientes WHERE activo = 1 AND usuario_id = ? AND fecha_registro >= ?',
      [usuarioId, inicioMes],
    );
    return result.first['total'] as int;
  }
}
