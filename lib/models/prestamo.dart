class Prestamo {
  final String id;
  final String clienteId;
  final double montoOriginal;
  final double tasaInteres;
  final int plazoMeses;
  final DateTime fechaInicio;
  final DateTime fechaVencimiento;
  final double saldoPendiente;
  final String estado;
  final String? garantia;
  final String? notas;
  final String? registradoPor;
  final DateTime fechaCreacion;

  Prestamo({
    required this.id,
    required this.clienteId,
    required this.montoOriginal,
    this.tasaInteres = 7.0,
    required this.plazoMeses,
    required this.fechaInicio,
    required this.fechaVencimiento,
    required this.saldoPendiente,
    this.estado = 'activo',
    this.garantia,
    this.notas,
    this.registradoPor,
    required this.fechaCreacion,
  });

  factory Prestamo.fromMap(Map<String, dynamic> map) {
    return Prestamo(
      id: map['id'] as String,
      clienteId: map['cliente_id'] as String,
      montoOriginal: (map['monto_original'] as num).toDouble(),
      tasaInteres: (map['tasa_interes'] as num?)?.toDouble() ?? 7.0,
      plazoMeses: map['plazo_meses'] as int,
      fechaInicio: DateTime.parse(map['fecha_inicio'] as String),
      fechaVencimiento: DateTime.parse(map['fecha_vencimiento'] as String),
      saldoPendiente: (map['saldo_pendiente'] as num).toDouble(),
      estado: map['estado'] as String? ?? 'activo',
      garantia: map['garantia'] as String?,
      notas: map['notas'] as String?,
      registradoPor: map['registrado_por'] as String?,
      fechaCreacion: DateTime.parse(map['fecha_creacion'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'cliente_id': clienteId,
      'monto_original': montoOriginal,
      'tasa_interes': tasaInteres,
      'plazo_meses': plazoMeses,
      'fecha_inicio': fechaInicio.toIso8601String(),
      'fecha_vencimiento': fechaVencimiento.toIso8601String(),
      'saldo_pendiente': saldoPendiente,
      'estado': estado,
      'garantia': garantia,
      'notas': notas,
      'registrado_por': registradoPor,
      'fecha_creacion': fechaCreacion.toIso8601String(),
    };
  }

  Prestamo copyWith({
    String? id,
    String? clienteId,
    double? montoOriginal,
    double? tasaInteres,
    int? plazoMeses,
    DateTime? fechaInicio,
    DateTime? fechaVencimiento,
    double? saldoPendiente,
    String? estado,
    String? garantia,
    String? notas,
    String? registradoPor,
    DateTime? fechaCreacion,
  }) {
    return Prestamo(
      id: id ?? this.id,
      clienteId: clienteId ?? this.clienteId,
      montoOriginal: montoOriginal ?? this.montoOriginal,
      tasaInteres: tasaInteres ?? this.tasaInteres,
      plazoMeses: plazoMeses ?? this.plazoMeses,
      fechaInicio: fechaInicio ?? this.fechaInicio,
      fechaVencimiento: fechaVencimiento ?? this.fechaVencimiento,
      saldoPendiente: saldoPendiente ?? this.saldoPendiente,
      estado: estado ?? this.estado,
      garantia: garantia ?? this.garantia,
      notas: notas ?? this.notas,
      registradoPor: registradoPor ?? this.registradoPor,
      fechaCreacion: fechaCreacion ?? this.fechaCreacion,
    );
  }

  double get cuotaMensual {
    final interesMensual = tasaInteres / 100;
    final totalInteres = montoOriginal * interesMensual * plazoMeses;
    return (montoOriginal + totalInteres) / plazoMeses;
  }

  double get totalIntereses {
    final interesMensual = tasaInteres / 100;
    return montoOriginal * interesMensual * plazoMeses;
  }

  double get totalPagar => montoOriginal + totalIntereses;

  double get progreso {
    if (montoOriginal == 0) {
      return 0;
    }
    return (montoOriginal - saldoPendiente) / montoOriginal;
  }

  bool get estaVencido {
    return estado == 'activo' && DateTime.now().isAfter(fechaVencimiento);
  }

  bool get estaPagado => estado == 'pagado';
}
