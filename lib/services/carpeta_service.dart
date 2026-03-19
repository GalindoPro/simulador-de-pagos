import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import '../models/models.dart';
import '../helpers/app_formatters.dart';

class CarpetaService {
  CarpetaService._();
  static final CarpetaService instance = CarpetaService._();

  Future<String> get _basePath async {
    final dir = await getApplicationDocumentsDirectory();
    final carpeta = Directory('${dir.path}/CapitalPro');
    if (!await carpeta.exists()) {
      await carpeta.create(recursive: true);
    }
    return carpeta.path;
  }

  Future<String> _carpetaCliente(String clienteId, String nombre) async {
    final base = await _basePath;
    final carpeta = Directory('$base/Clientes/${nombre}_$clienteId');
    if (!await carpeta.exists()) {
      await carpeta.create(recursive: true);
    }
    return carpeta.path;
  }

  Future<String> generarPDFPerfil(Cliente cliente) async {
    final carpeta =
        await _carpetaCliente(cliente.id, cliente.nombreCompleto);
    final path = '$carpeta/perfil_${cliente.id}.pdf';

    final pdf = pw.Document();
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.letter,
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Header(
                level: 0,
                child: pw.Text('Capital Pro - Perfil de Cliente',
                    style: pw.TextStyle(
                        fontSize: 20, fontWeight: pw.FontWeight.bold)),
              ),
              pw.SizedBox(height: 20),
              _pdfRow('Nombre', cliente.nombreCompleto),
              _pdfRow('Teléfono', AppFormatters.telefono(cliente.telefono)),
              if (cliente.dpi != null && cliente.dpi!.isNotEmpty)
                _pdfRow('DPI', AppFormatters.formatearDPI(cliente.dpi!)),
              if (cliente.email != null && cliente.email!.isNotEmpty)
                _pdfRow('Email', cliente.email!),
              if (cliente.direccion != null && cliente.direccion!.isNotEmpty)
                _pdfRow('Dirección', cliente.direccion!),
              if (cliente.telefonoReferencia != null &&
                  cliente.telefonoReferencia!.isNotEmpty)
                _pdfRow('Tel. Referencia',
                    AppFormatters.telefono(cliente.telefonoReferencia!)),
              _pdfRow('Fecha Registro',
                  AppFormatters.fechaLarga(cliente.fechaRegistro)),
              _pdfRow('Estado', cliente.estado.toUpperCase()),
            ],
          );
        },
      ),
    );

    final file = File(path);
    await file.writeAsBytes(await pdf.save());
    return path;
  }

  Future<String> generarPDFTablaPagos(
    Cliente cliente,
    Prestamo prestamo,
    List<CuotaPago> cuotas,
  ) async {
    final carpeta =
        await _carpetaCliente(cliente.id, cliente.nombreCompleto);
    final path = '$carpeta/plan_pagos_${prestamo.id}.pdf';

    final pdf = pw.Document();
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.letter,
        build: (context) {
          return [
            pw.Header(
              level: 0,
              child: pw.Text('Plan de Pagos',
                  style: pw.TextStyle(
                      fontSize: 20, fontWeight: pw.FontWeight.bold)),
            ),
            pw.SizedBox(height: 10),
            _pdfRow('Cliente', cliente.nombreCompleto),
            _pdfRow('Monto', AppFormatters.moneda(prestamo.montoOriginal)),
            _pdfRow('Tasa', AppFormatters.porcentaje(prestamo.tasaInteres)),
            _pdfRow('Plazo', '${prestamo.plazoMeses} meses'),
            _pdfRow('Cuota Mensual',
                AppFormatters.moneda(prestamo.cuotaMensual)),
            _pdfRow(
                'Total a Pagar', AppFormatters.moneda(prestamo.totalPagar)),
            pw.SizedBox(height: 20),
            pw.TableHelper.fromTextArray(
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              headerDecoration:
                  const pw.BoxDecoration(color: PdfColors.grey300),
              cellAlignments: {
                0: pw.Alignment.center,
                1: pw.Alignment.center,
                2: pw.Alignment.centerRight,
                3: pw.Alignment.centerRight,
                4: pw.Alignment.centerRight,
                5: pw.Alignment.centerRight,
              },
              headers: ['No.', 'Fecha', 'Capital', 'Interés', 'Cuota', 'Saldo'],
              data: cuotas
                  .map((c) => [
                        '${c.cuotaNumero}',
                        AppFormatters.fechaCorta(c.fechaPago),
                        AppFormatters.moneda(c.capital),
                        AppFormatters.moneda(c.interes),
                        AppFormatters.moneda(c.totalCuota),
                        AppFormatters.moneda(c.saldo),
                      ])
                  .toList(),
            ),
          ];
        },
      ),
    );

    final file = File(path);
    await file.writeAsBytes(await pdf.save());
    return path;
  }

  Future<String> generarReciboPago(
    Pago pago,
    Cliente cliente,
    CuotaPago? cuota,
    Prestamo? prestamo,
  ) async {
    final carpeta =
        await _carpetaCliente(cliente.id, cliente.nombreCompleto);
    final path = '$carpeta/recibo_${pago.id}.pdf';

    final pdf = pw.Document();
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.letter,
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Header(
                level: 0,
                child: pw.Text('Recibo de Pago',
                    style: pw.TextStyle(
                        fontSize: 20, fontWeight: pw.FontWeight.bold)),
              ),
              pw.SizedBox(height: 20),
              _pdfRow('Cliente', cliente.nombreCompleto),
              _pdfRow('Monto', AppFormatters.moneda(pago.monto)),
              _pdfRow('Fecha', AppFormatters.fechaLarga(pago.fecha)),
              _pdfRow('Método', pago.metodoPago),
              _pdfRow('Concepto', pago.concepto),
              if (cuota != null)
                _pdfRow('Cuota No.', '${cuota.cuotaNumero}'),
              if (prestamo != null) ...[
                pw.SizedBox(height: 10),
                _pdfRow('Saldo Pendiente',
                    AppFormatters.moneda(prestamo.saldoPendiente)),
              ],
              pw.SizedBox(height: 30),
              pw.Divider(),
              pw.SizedBox(height: 10),
              pw.Text('Capital Pro — Gestión Financiera',
                  style: const pw.TextStyle(fontSize: 10)),
            ],
          );
        },
      ),
    );

    final file = File(path);
    await file.writeAsBytes(await pdf.save());
    return path;
  }

  Future<String> generarFiniquito(
    Cliente cliente,
    Prestamo prestamo,
  ) async {
    final carpeta =
        await _carpetaCliente(cliente.id, cliente.nombreCompleto);
    final path = '$carpeta/finiquito_${prestamo.id}.pdf';

    final pdf = pw.Document();
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.letter,
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Center(
                child: pw.Text('FINIQUITO',
                    style: pw.TextStyle(
                        fontSize: 24, fontWeight: pw.FontWeight.bold)),
              ),
              pw.SizedBox(height: 30),
              pw.Text(
                'Por medio del presente se hace constar que el/la señor(a) '
                '${cliente.nombreCompleto} ha cumplido con la totalidad del '
                'pago del préstamo por un monto original de '
                '${AppFormatters.moneda(prestamo.montoOriginal)}, '
                'otorgado con fecha ${AppFormatters.fechaLarga(prestamo.fechaInicio)}.',
                style: const pw.TextStyle(fontSize: 12),
              ),
              pw.SizedBox(height: 20),
              _pdfRow('Monto Original',
                  AppFormatters.moneda(prestamo.montoOriginal)),
              _pdfRow(
                  'Total Pagado', AppFormatters.moneda(prestamo.totalPagar)),
              _pdfRow('Fecha Inicio',
                  AppFormatters.fechaLarga(prestamo.fechaInicio)),
              _pdfRow('Fecha Finalización',
                  AppFormatters.fechaLarga(DateTime.now())),
              pw.SizedBox(height: 40),
              pw.Text(
                'Se extiende el presente finiquito en la fecha '
                '${AppFormatters.fechaLarga(DateTime.now())}.',
                style: const pw.TextStyle(fontSize: 12),
              ),
              pw.SizedBox(height: 60),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(children: [
                    pw.Container(width: 150, child: pw.Divider()),
                    pw.Text('Prestamista'),
                  ]),
                  pw.Column(children: [
                    pw.Container(width: 150, child: pw.Divider()),
                    pw.Text('Cliente'),
                  ]),
                ],
              ),
            ],
          );
        },
      ),
    );

    final file = File(path);
    await file.writeAsBytes(await pdf.save());
    return path;
  }

  Future<void> compartirArchivo(String path) async {
    await Share.shareXFiles([XFile(path)]);
  }

  Future<void> compartirBaseDatos() async {
    final dir = await getApplicationDocumentsDirectory();
    final dbPath = '${dir.path}/../databases/capital_pro.db';
    final file = File(dbPath);
    if (await file.exists()) {
      await Share.shareXFiles([XFile(dbPath)],
          text: 'Respaldo Capital Pro');
    }
  }

  pw.Widget _pdfRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        children: [
          pw.SizedBox(
            width: 150,
            child: pw.Text('$label:',
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
          ),
          pw.Expanded(child: pw.Text(value)),
        ],
      ),
    );
  }
}
