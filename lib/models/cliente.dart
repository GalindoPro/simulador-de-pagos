import 'usuario.dart';

class Cliente {
  final String id;
  final String usuarioId;
  final String nombre;
  final String apellido;
  final String telefono;
  final String? telefonoReferencia;
  final String? email;
  final String? direccion;
  final String? dpi;
  final String? fotoPath;
  final DateTime fechaRegistro;
  final String estado;
  final bool activo;

  Cliente({
    required this.id,
    required this.usuarioId,
    required this.nombre,
    required this.apellido,
    required this.telefono,
    this.telefonoReferencia,
    this.email,
    this.direccion,
    this.dpi,
    this.fotoPath,
    required this.fechaRegistro,
    this.estado = 'activo',
    this.activo = true,
  });

  /// Factory con Title Case automático en nombre y apellido
  factory Cliente.crear({
    required String id,
    required String usuarioId,
    required String nombre,
    required String apellido,
    required String telefono,
    String? telefonoReferencia,
    String? email,
    String? direccion,
    String? dpi,
    String? fotoPath,
    DateTime? fechaRegistro,
    String estado = 'activo',
  }) {
    return Cliente(
      id: id,
      usuarioId: usuarioId,
      nombre: Usuario.toTitleCase(nombre),
      apellido: Usuario.toTitleCase(apellido),
      telefono: telefono,
      telefonoReferencia: telefonoReferencia,
      email: email,
      direccion: direccion,
      dpi: dpi,
      fotoPath: fotoPath,
      fechaRegistro: fechaRegistro ?? DateTime.now(),
      estado: estado,
    );
  }

  factory Cliente.fromMap(Map<String, dynamic> map) {
    return Cliente(
      id: map['id'] as String,
      usuarioId: map['usuario_id'] as String? ?? '',
      nombre: map['nombre'] as String,
      apellido: map['apellido'] as String,
      telefono: map['telefono'] as String,
      telefonoReferencia: map['telefono_referencia'] as String?,
      email: map['email'] as String?,
      direccion: map['direccion'] as String?,
      dpi: map['dpi'] as String?,
      fotoPath: map['foto_path'] as String?,
      fechaRegistro: DateTime.parse(map['fecha_registro'] as String),
      estado: map['estado'] as String? ?? 'activo',
      activo: (map['activo'] as int?) == 1,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'usuario_id': usuarioId,
      'nombre': nombre,
      'apellido': apellido,
      'telefono': telefono,
      'telefono_referencia': telefonoReferencia,
      'email': email,
      'direccion': direccion,
      'dpi': dpi,
      'foto_path': fotoPath,
      'fecha_registro': fechaRegistro.toIso8601String(),
      'estado': estado,
      'activo': activo ? 1 : 0,
    };
  }

  Cliente copyWith({
    String? id,
    String? usuarioId,
    String? nombre,
    String? apellido,
    String? telefono,
    String? telefonoReferencia,
    String? email,
    String? direccion,
    String? dpi,
    String? fotoPath,
    DateTime? fechaRegistro,
    String? estado,
    bool? activo,
  }) {
    return Cliente(
      id: id ?? this.id,
      usuarioId: usuarioId ?? this.usuarioId,
      nombre: nombre ?? this.nombre,
      apellido: apellido ?? this.apellido,
      telefono: telefono ?? this.telefono,
      telefonoReferencia: telefonoReferencia ?? this.telefonoReferencia,
      email: email ?? this.email,
      direccion: direccion ?? this.direccion,
      dpi: dpi ?? this.dpi,
      fotoPath: fotoPath ?? this.fotoPath,
      fechaRegistro: fechaRegistro ?? this.fechaRegistro,
      estado: estado ?? this.estado,
      activo: activo ?? this.activo,
    );
  }

  String get nombreCompleto => '$nombre $apellido';

  String get iniciales {
    final n = nombre.isNotEmpty ? nombre[0] : '';
    final a = apellido.isNotEmpty ? apellido[0] : '';
    return '$n$a'.toUpperCase();
  }
}
