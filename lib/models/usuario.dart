import 'dart:convert';
import 'package:crypto/crypto.dart';

class Usuario {
  final String id;
  final String nombre;
  final String telefono;
  final String passwordHash;
  final double capitalInicial;
  final bool activo;
  final DateTime fechaRegistro;

  Usuario({
    required this.id,
    required this.nombre,
    required this.telefono,
    required this.passwordHash,
    this.capitalInicial = 0,
    this.activo = true,
    required this.fechaRegistro,
  });

  factory Usuario.fromMap(Map<String, dynamic> map) {
    return Usuario(
      id: map['id'] as String,
      nombre: map['nombre'] as String,
      telefono: map['telefono'] as String,
      passwordHash: map['password_hash'] as String,
      capitalInicial: (map['capital_inicial'] as num?)?.toDouble() ?? 0,
      activo: (map['activo'] as int?) == 1,
      fechaRegistro: DateTime.parse(map['fecha_registro'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nombre': nombre,
      'telefono': telefono,
      'password_hash': passwordHash,
      'capital_inicial': capitalInicial,
      'activo': activo ? 1 : 0,
      'fecha_registro': fechaRegistro.toIso8601String(),
    };
  }

  Usuario copyWith({
    String? id,
    String? nombre,
    String? telefono,
    String? passwordHash,
    double? capitalInicial,
    bool? activo,
    DateTime? fechaRegistro,
  }) {
    return Usuario(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      telefono: telefono ?? this.telefono,
      passwordHash: passwordHash ?? this.passwordHash,
      capitalInicial: capitalInicial ?? this.capitalInicial,
      activo: activo ?? this.activo,
      fechaRegistro: fechaRegistro ?? this.fechaRegistro,
    );
  }

  static String hashPassword(String password) {
    final bytes = utf8.encode(password);
    return sha256.convert(bytes).toString();
  }

  static String toTitleCase(String text) {
    if (text.isEmpty) {
      return text;
    }
    return text
        .split(' ')
        .map((word) {
          if (word.isEmpty) {
            return word;
          }
          return word[0].toUpperCase() + word.substring(1).toLowerCase();
        })
        .join(' ');
  }
}

class PreguntaSeguridad {
  final String id;
  final String usuarioId;
  final String pregunta;
  final String respuestaHash;

  PreguntaSeguridad({
    required this.id,
    required this.usuarioId,
    required this.pregunta,
    required this.respuestaHash,
  });

  factory PreguntaSeguridad.fromMap(Map<String, dynamic> map) {
    return PreguntaSeguridad(
      id: map['id'] as String,
      usuarioId: map['usuario_id'] as String,
      pregunta: map['pregunta'] as String,
      respuestaHash: map['respuesta_hash'] as String,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'usuario_id': usuarioId,
      'pregunta': pregunta,
      'respuesta_hash': respuestaHash,
    };
  }

  static String hashRespuesta(String respuesta) {
    final bytes = utf8.encode(respuesta.toLowerCase().trim());
    return sha256.convert(bytes).toString();
  }
}
