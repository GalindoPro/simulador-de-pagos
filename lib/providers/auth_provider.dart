import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/usuario.dart';
import '../repositories/usuario_repository.dart';

final usuarioRepositoryProvider = Provider((ref) => UsuarioRepository());

final sesionActualProvider =
    StateNotifierProvider<SesionNotifier, Usuario?>((ref) {
  return SesionNotifier(ref.read(usuarioRepositoryProvider));
});

class SesionNotifier extends StateNotifier<Usuario?> {
  final UsuarioRepository _repo;

  SesionNotifier(this._repo) : super(null) {
    _cargarSesion();
  }

  Future<void> _cargarSesion() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('usuario_id');
    if (userId != null) {
      final usuarios = await _repo.obtenerTodos();
      state = usuarios.where((u) => u.id == userId).firstOrNull;
    }
  }

  Future<bool> login(String telefono, String password) async {
    final usuario = await _repo.login(telefono, password);
    if (usuario != null) {
      state = usuario;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('usuario_id', usuario.id);
      await prefs.setString('usuario_nombre', usuario.nombre);
      await prefs.setDouble('capital_inicial', usuario.capitalInicial);
      return true;
    }
    return false;
  }

  Future<void> logout() async {
    state = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('usuario_id');
    await prefs.remove('usuario_nombre');
    await prefs.remove('capital_inicial');
  }

  Future<void> actualizarNombre(String nombre) async {
    if (state != null) {
      await _repo.actualizarNombre(state!.id, nombre);
      state = state!.copyWith(nombre: Usuario.toTitleCase(nombre));
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('usuario_nombre', state!.nombre);
    }
  }

  Future<void> actualizarCapital(double capital) async {
    if (state != null) {
      await _repo.actualizarCapital(state!.id, capital);
      state = state!.copyWith(capitalInicial: capital);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble('capital_inicial', capital);
    }
  }
}
