import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  DatabaseHelper._();

  static final DatabaseHelper instance = DatabaseHelper._();
  static Database? _database;

  Future<Database> get database async {
    if (_database != null) {
      return _database!;
    }
    _database = await _initDB();
    return _database!;
  }

  Future<Database> _initDB() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'capital_pro.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE usuarios (
        id             TEXT PRIMARY KEY,
        nombre         TEXT NOT NULL,
        telefono       TEXT UNIQUE NOT NULL,
        password_hash  TEXT NOT NULL,
        capital_inicial REAL NOT NULL DEFAULT 0,
        activo         INTEGER DEFAULT 1,
        fecha_registro TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE preguntas_seguridad (
        id             TEXT PRIMARY KEY,
        usuario_id     TEXT NOT NULL,
        pregunta       TEXT NOT NULL,
        respuesta_hash TEXT NOT NULL,
        FOREIGN KEY (usuario_id) REFERENCES usuarios(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE clientes (
        id                  TEXT PRIMARY KEY,
        nombre              TEXT NOT NULL,
        apellido            TEXT NOT NULL,
        telefono            TEXT NOT NULL,
        telefono_referencia TEXT,
        email               TEXT,
        direccion           TEXT,
        dpi                 TEXT,
        foto_path           TEXT,
        fecha_registro      TEXT NOT NULL,
        estado              TEXT DEFAULT 'activo',
        activo              INTEGER DEFAULT 1
      )
    ''');

    await db.execute('''
      CREATE TABLE prestamos (
        id                TEXT PRIMARY KEY,
        cliente_id        TEXT NOT NULL,
        monto_original    REAL NOT NULL,
        tasa_interes      REAL NOT NULL DEFAULT 7.0,
        plazo_meses       INTEGER NOT NULL,
        fecha_inicio      TEXT NOT NULL,
        fecha_vencimiento TEXT NOT NULL,
        saldo_pendiente   REAL NOT NULL,
        estado            TEXT DEFAULT 'activo',
        garantia          TEXT,
        notas             TEXT,
        registrado_por    TEXT,
        fecha_creacion    TEXT NOT NULL,
        FOREIGN KEY (cliente_id) REFERENCES clientes(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE pagos (
        id               TEXT PRIMARY KEY,
        cliente_id       TEXT NOT NULL,
        prestamo_id      TEXT,
        cuota_numero     INTEGER,
        monto            REAL NOT NULL,
        fecha            TEXT NOT NULL,
        metodo_pago      TEXT NOT NULL,
        comprobante_path TEXT,
        concepto         TEXT NOT NULL,
        estado           TEXT DEFAULT 'completado',
        notas            TEXT,
        pdf_path         TEXT,
        registrado_por   TEXT,
        fecha_creacion   TEXT NOT NULL,
        FOREIGN KEY (cliente_id) REFERENCES clientes(id),
        FOREIGN KEY (prestamo_id) REFERENCES prestamos(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE tabla_pagos (
        id           TEXT PRIMARY KEY,
        prestamo_id  TEXT NOT NULL,
        cuota_numero INTEGER NOT NULL,
        fecha_pago   TEXT NOT NULL,
        capital      REAL NOT NULL,
        interes      REAL NOT NULL,
        total_cuota  REAL NOT NULL,
        saldo        REAL NOT NULL,
        pagado       INTEGER DEFAULT 0,
        fecha_pagado TEXT,
        FOREIGN KEY (prestamo_id) REFERENCES prestamos(id)
      )
    ''');
  }

  Future<void> close() async {
    final db = await database;
    db.close();
    _database = null;
  }
}
