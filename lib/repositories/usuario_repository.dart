import '../models/usuario.dart';
import '../services/database_helper.dart';

class UsuarioRepository {
  final _db = DatabaseHelper.instance;

  Future<void> crear(Usuario usuario) async {
    final db = await _db.database;
    await db.insert('usuarios', usuario.toMap());
  }

  Future<void> crearPregunta(PreguntaSeguridad pregunta) async {
    final db = await _db.database;
    await db.insert('preguntas_seguridad', pregunta.toMap());
  }

  Future<Usuario?> buscarPorTelefono(String telefono) async {
    final db = await _db.database;
    final result = await db.query(
      'usuarios',
      where: 'telefono = ? AND activo = 1',
      whereArgs: [telefono],
    );
    if (result.isEmpty) {
      return null;
    }
    return Usuario.fromMap(result.first);
  }

  Future<Usuario?> login(String telefono, String password) async {
    final db = await _db.database;
    final hash = Usuario.hashPassword(password);
    final result = await db.query(
      'usuarios',
      where: 'telefono = ? AND password_hash = ? AND activo = 1',
      whereArgs: [telefono, hash],
    );
    if (result.isEmpty) {
      return null;
    }
    return Usuario.fromMap(result.first);
  }

  Future<List<PreguntaSeguridad>> obtenerPreguntas(String usuarioId) async {
    final db = await _db.database;
    final result = await db.query(
      'preguntas_seguridad',
      where: 'usuario_id = ?',
      whereArgs: [usuarioId],
    );
    return result.map((m) => PreguntaSeguridad.fromMap(m)).toList();
  }

  Future<void> actualizarPassword(String usuarioId, String newPassword) async {
    final db = await _db.database;
    await db.update(
      'usuarios',
      {'password_hash': Usuario.hashPassword(newPassword)},
      where: 'id = ?',
      whereArgs: [usuarioId],
    );
  }

  Future<void> actualizarNombre(String usuarioId, String nombre) async {
    final db = await _db.database;
    await db.update(
      'usuarios',
      {'nombre': Usuario.toTitleCase(nombre)},
      where: 'id = ?',
      whereArgs: [usuarioId],
    );
  }

  Future<void> actualizarCapital(String usuarioId, double capital) async {
    final db = await _db.database;
    await db.update(
      'usuarios',
      {'capital_inicial': capital},
      where: 'id = ?',
      whereArgs: [usuarioId],
    );
  }

  Future<List<Usuario>> obtenerTodos() async {
    final db = await _db.database;
    final result = await db.query(
      'usuarios',
      where: 'activo = 1',
      orderBy: 'nombre ASC',
    );
    return result.map((m) => Usuario.fromMap(m)).toList();
  }

  Future<void> desactivar(String usuarioId) async {
    final db = await _db.database;
    await db.update(
      'usuarios',
      {'activo': 0},
      where: 'id = ?',
      whereArgs: [usuarioId],
    );
  }

  Future<bool> existeTelefono(String telefono) async {
    final db = await _db.database;
    final result = await db.query(
      'usuarios',
      where: 'telefono = ?',
      whereArgs: [telefono],
    );
    return result.isNotEmpty;
  }
}
