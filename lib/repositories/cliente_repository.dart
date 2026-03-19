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

  Future<List<Cliente>> obtenerActivos() async {
    final db = await _db.database;
    final result = await db.query(
      'clientes',
      where: "activo = 1 AND estado = 'activo'",
      orderBy: 'nombre ASC',
    );
    return result.map((m) => Cliente.fromMap(m)).toList();
  }

  Future<List<Cliente>> obtenerInactivos() async {
    final db = await _db.database;
    final result = await db.query(
      'clientes',
      where: "activo = 1 AND (estado = 'inactivo' OR estado = 'finalizado')",
      orderBy: 'nombre ASC',
    );
    return result.map((m) => Cliente.fromMap(m)).toList();
  }

  Future<List<Cliente>> obtenerTodos() async {
    final db = await _db.database;
    final result = await db.query(
      'clientes',
      where: 'activo = 1',
      orderBy: 'nombre ASC',
    );
    return result.map((m) => Cliente.fromMap(m)).toList();
  }

  Future<List<Cliente>> buscar(String query) async {
    final db = await _db.database;
    final result = await db.query(
      'clientes',
      where:
          'activo = 1 AND (nombre LIKE ? OR apellido LIKE ? OR telefono LIKE ? OR dpi LIKE ?)',
      whereArgs: ['%$query%', '%$query%', '%$query%', '%$query%'],
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

  Future<int> contarActivos() async {
    final db = await _db.database;
    final result = await db.rawQuery(
      "SELECT COUNT(*) as total FROM clientes WHERE activo = 1 AND estado = 'activo'",
    );
    return result.first['total'] as int;
  }

  Future<int> contarNuevosMes() async {
    final db = await _db.database;
    final now = DateTime.now();
    final inicioMes = DateTime(now.year, now.month, 1).toIso8601String();
    final result = await db.rawQuery(
      'SELECT COUNT(*) as total FROM clientes WHERE activo = 1 AND fecha_registro >= ?',
      [inicioMes],
    );
    return result.first['total'] as int;
  }
}
