class Pago {
  final String id;
  final String clienteId;
  final String? prestamoId;
  final int? cuotaNumero;
  final double monto;
  final DateTime fecha;
  final String metodoPago;
  final String? comprobantePath;
  final String concepto;
  final String estado;
  final String? notas;
  final String? pdfPath;
  final String? registradoPor;
  final DateTime fechaCreacion;

  Pago({
    required this.id,
    required this.clienteId,
    this.prestamoId,
    this.cuotaNumero,
    required this.monto,
    required this.fecha,
    required this.metodoPago,
    this.comprobantePath,
    required this.concepto,
    this.estado = 'completado',
    this.notas,
    this.pdfPath,
    this.registradoPor,
    required this.fechaCreacion,
  });

  factory Pago.fromMap(Map<String, dynamic> map) {
    return Pago(
      id: map['id'] as String,
      clienteId: map['cliente_id'] as String,
      prestamoId: map['prestamo_id'] as String?,
      cuotaNumero: map['cuota_numero'] as int?,
      monto: (map['monto'] as num).toDouble(),
      fecha: DateTime.parse(map['fecha'] as String),
      metodoPago: map['metodo_pago'] as String,
      comprobantePath: map['comprobante_path'] as String?,
      concepto: map['concepto'] as String,
      estado: map['estado'] as String? ?? 'completado',
      notas: map['notas'] as String?,
      pdfPath: map['pdf_path'] as String?,
      registradoPor: map['registrado_por'] as String?,
      fechaCreacion: DateTime.parse(map['fecha_creacion'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'cliente_id': clienteId,
      'prestamo_id': prestamoId,
      'cuota_numero': cuotaNumero,
      'monto': monto,
      'fecha': fecha.toIso8601String(),
      'metodo_pago': metodoPago,
      'comprobante_path': comprobantePath,
      'concepto': concepto,
      'estado': estado,
      'notas': notas,
      'pdf_path': pdfPath,
      'registrado_por': registradoPor,
      'fecha_creacion': fechaCreacion.toIso8601String(),
    };
  }

  Pago copyWith({
    String? id,
    String? clienteId,
    String? prestamoId,
    int? cuotaNumero,
    double? monto,
    DateTime? fecha,
    String? metodoPago,
    String? comprobantePath,
    String? concepto,
    String? estado,
    String? notas,
    String? pdfPath,
    String? registradoPor,
    DateTime? fechaCreacion,
  }) {
    return Pago(
      id: id ?? this.id,
      clienteId: clienteId ?? this.clienteId,
      prestamoId: prestamoId ?? this.prestamoId,
      cuotaNumero: cuotaNumero ?? this.cuotaNumero,
      monto: monto ?? this.monto,
      fecha: fecha ?? this.fecha,
      metodoPago: metodoPago ?? this.metodoPago,
      comprobantePath: comprobantePath ?? this.comprobantePath,
      concepto: concepto ?? this.concepto,
      estado: estado ?? this.estado,
      notas: notas ?? this.notas,
      pdfPath: pdfPath ?? this.pdfPath,
      registradoPor: registradoPor ?? this.registradoPor,
      fechaCreacion: fechaCreacion ?? this.fechaCreacion,
    );
  }

  bool get esEfectivo => metodoPago == 'efectivo';
  bool get esTransferencia => metodoPago == 'transferencia';
  bool get estaCompletado => estado == 'completado';
  bool get estaPendiente => estado == 'pendiente';
}
