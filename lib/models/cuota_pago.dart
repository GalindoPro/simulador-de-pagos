class CuotaPago {
  final String id;
  final String prestamoId;
  final int cuotaNumero;
  final DateTime fechaPago;
  final double capital;
  final double interes;
  final double totalCuota;
  final double saldo;
  final bool pagado;
  final DateTime? fechaPagado;

  CuotaPago({
    required this.id,
    required this.prestamoId,
    required this.cuotaNumero,
    required this.fechaPago,
    required this.capital,
    required this.interes,
    required this.totalCuota,
    required this.saldo,
    this.pagado = false,
    this.fechaPagado,
  });

  factory CuotaPago.fromMap(Map<String, dynamic> map) {
    return CuotaPago(
      id: map['id'] as String,
      prestamoId: map['prestamo_id'] as String,
      cuotaNumero: map['cuota_numero'] as int,
      fechaPago: DateTime.parse(map['fecha_pago'] as String),
      capital: (map['capital'] as num).toDouble(),
      interes: (map['interes'] as num).toDouble(),
      totalCuota: (map['total_cuota'] as num).toDouble(),
      saldo: (map['saldo'] as num).toDouble(),
      pagado: (map['pagado'] as int?) == 1,
      fechaPagado: map['fecha_pagado'] != null
          ? DateTime.parse(map['fecha_pagado'] as String)
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'prestamo_id': prestamoId,
      'cuota_numero': cuotaNumero,
      'fecha_pago': fechaPago.toIso8601String(),
      'capital': capital,
      'interes': interes,
      'total_cuota': totalCuota,
      'saldo': saldo,
      'pagado': pagado ? 1 : 0,
      'fecha_pagado': fechaPagado?.toIso8601String(),
    };
  }

  CuotaPago copyWith({
    String? id,
    String? prestamoId,
    int? cuotaNumero,
    DateTime? fechaPago,
    double? capital,
    double? interes,
    double? totalCuota,
    double? saldo,
    bool? pagado,
    DateTime? fechaPagado,
  }) {
    return CuotaPago(
      id: id ?? this.id,
      prestamoId: prestamoId ?? this.prestamoId,
      cuotaNumero: cuotaNumero ?? this.cuotaNumero,
      fechaPago: fechaPago ?? this.fechaPago,
      capital: capital ?? this.capital,
      interes: interes ?? this.interes,
      totalCuota: totalCuota ?? this.totalCuota,
      saldo: saldo ?? this.saldo,
      pagado: pagado ?? this.pagado,
      fechaPagado: fechaPagado ?? this.fechaPagado,
    );
  }

  /// Genera tabla de amortización completa
  static List<CuotaPago> generarTabla({
    required String prestamoId,
    required double monto,
    required double tasaInteres,
    required int plazoMeses,
    required DateTime fechaInicio,
  }) {
    final cuotas = <CuotaPago>[];
    final interesMensual = tasaInteres / 100;
    final capitalMensual = monto / plazoMeses;
    double saldoRestante = monto;

    for (int i = 1; i <= plazoMeses; i++) {
      final interes = saldoRestante * interesMensual;
      final totalCuota = capitalMensual + interes;
      saldoRestante -= capitalMensual;

      if (saldoRestante < 0.01) {
        saldoRestante = 0;
      }

      final fechaPago = DateTime(
        fechaInicio.year,
        fechaInicio.month + i,
        fechaInicio.day,
      );

      cuotas.add(CuotaPago(
        id: '${prestamoId}_cuota_$i',
        prestamoId: prestamoId,
        cuotaNumero: i,
        fechaPago: fechaPago,
        capital: double.parse(capitalMensual.toStringAsFixed(2)),
        interes: double.parse(interes.toStringAsFixed(2)),
        totalCuota: double.parse(totalCuota.toStringAsFixed(2)),
        saldo: double.parse(saldoRestante.toStringAsFixed(2)),
      ));
    }

    return cuotas;
  }
}
