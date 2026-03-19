# Capital Pro — Contexto completo del proyecto v2.0

> **Compatible con:** Claude, ChatGPT, Gemini, GitHub Copilot, Cursor, Windsurf
> **Versión:** 2.0 — Parte 4 completa

---

## ¿Qué es Capital Pro?

App Flutter de gestión financiera para prestamistas en Guatemala.
Un solo dispositivo Android/iOS. SQLite local. Sin backend.

- **Moneda:** Quetzales (Q)
- **Teléfonos:** 8 dígitos, código país +502
- **DPI:** 13 dígitos, formato XXXX-XXXXX-XXXX (ej: 3274-32047-1405)
- **Idioma UI:** Español
- **Plataformas:** Android e iOS

---

## Stack técnico

```yaml
dependencies:
  flutter_riverpod: ^2.4.0
  go_router: ^12.0.0
  sqflite: ^2.3.0
  path: ^1.9.0
  path_provider: ^2.1.0
  crypto: ^3.0.3
  shared_preferences: ^2.2.0
  uuid: ^4.2.0
  intl: ^0.18.1
  google_fonts: ^6.1.0
  image_picker: ^1.0.7
  url_launcher: ^6.2.5
  share_plus: ^7.0.0
  pdf: ^3.11.3
  printing: ^5.14.2
  fl_chart: ^0.66.0
  flutter_speed_dial: ^7.0.0
  permission_handler: ^11.3.0
```

---

## Base de datos — SQL completo v2

```sql
CREATE TABLE usuarios (
  id             TEXT PRIMARY KEY,
  nombre         TEXT NOT NULL,
  telefono       TEXT UNIQUE NOT NULL,
  password_hash  TEXT NOT NULL,
  capital_inicial REAL NOT NULL DEFAULT 0,
  activo         INTEGER DEFAULT 1,
  fecha_registro TEXT NOT NULL
);

CREATE TABLE preguntas_seguridad (
  id             TEXT PRIMARY KEY,
  usuario_id     TEXT NOT NULL,
  pregunta       TEXT NOT NULL,
  respuesta_hash TEXT NOT NULL,
  FOREIGN KEY (usuario_id) REFERENCES usuarios(id)
);

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
);

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
);

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
);

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
);
```

---

## Flujo de registro (3 pasos)

```
PASO 1 — Datos de acceso
  nombre (Title Case auto) + teléfono + contraseña + confirmar

PASO 2 — Preguntas de seguridad
  Pregunta 1 (seleccionar de lista) + respuesta
  Pregunta 2 (seleccionar de lista) + respuesta

PASO 3 — Capital inicial
  "¿Cuánto capital tiene disponible para prestar?" (Q)
  Nota: "Puedes cambiarlo después en Configuración"

→ Registro exitoso → regresar al Login (NO auto-login)
```

### Preguntas de seguridad disponibles
```dart
const kPreguntasSeguridad = [
  '¿Cuál es el nombre de tu primera mascota?',
  '¿En qué ciudad naciste?',
  '¿Cuál es el nombre de tu madre?',
  '¿Cuál es tu apodo de infancia?',
  '¿Cuál fue el nombre de tu primera escuela?',
  '¿Cuál es el nombre de tu mejor amigo de infancia?',
];
```

---

## Flujo de recuperación de contraseña

```
Login → "¿Olvidaste tu contraseña?" → /recuperar-password
  1. Ingresa teléfono registrado
  2. Responde pregunta de seguridad 1
  3. Responde pregunta de seguridad 2
  4. Nueva contraseña + confirmar
  → SnackBar éxito → Login
```

---

## Dashboard — pantalla Inicio

```
HEADER (collapsible SliverAppBar):
  Saludo según hora + nombre usuario
  Capital disponible: Q XX,XXX.XX
  Fecha actual

ACCIONES RÁPIDAS (Row de 3 botones):
  [+ Nuevo Cliente]  [+ Préstamo]  [Simulador]

GRID 2x3 de StatCards:
  Interés del mes | Clientes activos
  Préstamos activos | Vencidos
  Cobrado este mes | Saldo pendiente

GRÁFICA DE BARRAS (fl_chart):
  Cobros por mes — últimos 6 meses

SECCIÓN Últimos pagos → [Ver todos]
SECCIÓN Próximos a vencer → [Ver todos]
```

---

## Simulador de préstamos (/simulador)

```
INPUTS:
  Monto (Q)
  Tasa interés mensual (% — default 7%)
  Plazo (Slider 1-60 meses)
  Fecha primer pago (DatePicker)

RESULTADO — tabla completa:
  No. | Fecha pago | Cuota | Capital | Interés | Saldo

RESUMEN debajo:
  Total a pagar | Total intereses | Cuota mensual

BOTÓN: [Crear préstamo con estos datos]
  → Navega a /prestamos/nuevo con datos precargados
```

---

## Clientes — lógica de estados

```
estado: 'activo'     → tiene préstamo(s) activo(s)
estado: 'inactivo'   → sin préstamos, sin deuda
estado: 'finalizado' → terminó de pagar (apto para nuevo crédito)

/clientes            → solo activos
/clientes/inactivos  → inactivos + finalizados (historial completo)
```

### Campos del formulario de cliente
```
nombre*           Title Case automático en onChanged
apellido*         Title Case automático en onChanged
telefono*         8 dígitos, solo números
telefono_referencia  número familiar/referencia (opcional, 8 dígitos)
dpi               13 dígitos → auto-formato XXXX-XXXXX-XXXX
foto              image_picker: cámara o galería (.jpg/.png)
email             opcional
direccion         opcional
```

### DPI — formatter y validator
```dart
class DpiInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(oldValue, newValue) {
    final d = newValue.text.replaceAll('-', '');
    if (d.length > 13) { return oldValue; }
    String r = '';
    for (int i = 0; i < d.length; i++) {
      if (i == 4 || i == 9) { r += '-'; }
      r += d[i];
    }
    return TextEditingValue(
      text: r,
      selection: TextSelection.collapsed(offset: r.length),
    );
  }
}

static String? dpi(String? v) {
  if (v == null || v.trim().isEmpty) { return null; }
  if (v.replaceAll('-','').length != 13) { return 'DPI debe tener 13 dígitos'; }
  return null;
}
```

---

## Préstamos — lógica

```
Tasa default: 7% mensual

Al GUARDAR un préstamo:
  1. Insertar en prestamos
  2. Generar tabla de amortización → tabla_pagos
  3. Generar PDF plan de pagos
  4. Cambiar estado cliente → 'activo'
  5. Enviar WhatsApp al cliente (préstamo aprobado)
  6. Mostrar BottomSheet resumen antes de confirmar

RESUMEN en BottomSheet:
  Cliente, Monto, Tasa, Plazo
  Cuota mensual | Total intereses | Total a pagar
  Fecha inicio | Fecha final
  [Cancelar] [Confirmar préstamo]

Método de pago:
  'efectivo'      → solo registra monto
  'transferencia' → monto + foto comprobante (image_picker)
```

---

## Pagos — lógica

```
Al REGISTRAR un pago:
  1. Insertar en pagos
  2. Marcar cuota como pagada en tabla_pagos
  3. Actualizar saldo_pendiente del préstamo
  4. Si saldo = 0:
     → estado préstamo = 'pagado'
     → estado cliente = 'finalizado'
     → generar PDF finiquito automáticamente
  5. Generar PDF recibo de pago
  6. Enviar WhatsApp confirmación al cliente
  7. Las cuotas del préstamo aparecen automáticamente en /pagos
```

---

## Reglas de código OBLIGATORIAS

```dart
// ✅ SIEMPRE
color: AppColors.error              // nunca Colors.red
Text(AppStrings.guardar)            // nunca Text('Guardar')
style: AppTextStyles.bodyMedium     // nunca TextStyle(...)
if (cond) { hacer(); }             // siempre llaves en if/else
TextFormField(initialValue: v)      // nunca value:
if (mounted) { usar(context); }    // después de cada await
try { await op(); } catch(e) {...} // siempre try/catch en async
Usuario.toTitleCase('juan')         // → "Juan" para nombres
Cliente.crear(nombre:'juan',...)    // Title Case automático
```

---

## Helpers

```dart
AppFormatters.moneda(1250.50)          // Q 1,250.50
AppFormatters.fechaCorta(fecha)        // 15/01/2024
AppFormatters.fechaLarga(fecha)        // 15 de enero de 2024
AppFormatters.telefono('55551234')     // 5555-1234
AppFormatters.porcentaje(7.0)          // 7.0%
AppFormatters.formatearDPI('327432..') // 3274-32047-1405

AppValidators.nombre(v)
AppValidators.apellido(v)
AppValidators.telefono(v)
AppValidators.dpi(v)
AppValidators.email(v)
AppValidators.password(v)
AppValidators.monto(v)

AppSnackBar.exito(context, msg)
AppSnackBar.error(context, msg)
AppSnackBar.advertencia(context, msg)
AppSnackBar.info(context, msg)
```

---

## Widgets reutilizables

```dart
AppCard(child, onTap, padding, color)
StatCard(titulo, valor, icono, color, subtitulo)
LoadingButton(texto, onPressed, isLoading, icono)
EmptyState(mensaje, icono, subtitulo, onAccion, textoAccion)
ConfirmDialog.show(context, titulo, mensaje)   // → Future<bool>
ClienteAvatar(nombre, apellido, fotoPath, radio)
PagoListTile(pago, cliente, onTap, onEliminar)
PrestamoCard(prestamo, cliente, onTap)
SeccionHeader(titulo, onVerTodos)
WhatsAppButton(telefono, mensaje, mostrarTexto)
AppErrorWidget(mensaje, onRetry)
TablaAmortizacion(cuotas)
```

---

## Rutas

```dart
AppRoutes.splash             = '/'
AppRoutes.login              = '/login'
AppRoutes.registro           = '/registro'
AppRoutes.recuperarPassword  = '/recuperar-password'
AppRoutes.dashboard          = '/dashboard'
AppRoutes.simulador          = '/simulador'
AppRoutes.clientes           = '/clientes'
AppRoutes.clientesInactivos  = '/clientes/inactivos'
AppRoutes.nuevoCliente       = '/clientes/nuevo'
AppRoutes.detalleCliente     = '/clientes/:id'
AppRoutes.editarCliente      = '/clientes/:id/editar'
AppRoutes.pagos              = '/pagos'
AppRoutes.nuevoPago          = '/pagos/nuevo'
AppRoutes.detallePago        = '/pagos/:id'
AppRoutes.prestamos          = '/prestamos'
AppRoutes.nuevoPrestamo      = '/prestamos/nuevo'
AppRoutes.detallePrestamo    = '/prestamos/:id'
AppRoutes.editarPrestamo     = '/prestamos/:id/editar'
AppRoutes.reportes           = '/reportes'
AppRoutes.configuracion      = '/configuracion'
```

---

## Guía anti-errores Android/iOS

### Errores comunes y soluciones

```
MissingPluginException (image_picker/url_launcher)
→ flutter clean && flutter pub get && flutter run

PlatformException (permission_handler)
→ Verificar permisos en AndroidManifest.xml e Info.plist

App se congela en splash
→ Asegurarse que DatabaseHelper.instance.database
  esté awaited ANTES de runApp() en main()

setState() called after dispose()
→ Siempre verificar: if (mounted) { setState(...); }

type 'Null' is not subtype of 'String'
→ Revisar fromMap() — campos nullable deben usar 'as String?'

Build failed — Gradle
→ cd android && ./gradlew clean && cd .. && flutter run

CocoaPods error (iOS)
→ cd ios && pod install --repo-update && cd .. && flutter run

RenderFlex overflowed
→ Envolver Column en SingleChildScrollView o usar Expanded
```

### AndroidManifest.xml — permisos requeridos

```xml
<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="android.permission.CAMERA"/>
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE"
    android:maxSdkVersion="32"/>
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE"
    android:maxSdkVersion="28"/>
<uses-permission android:name="android.permission.READ_MEDIA_IMAGES"/>

<queries>
  <intent>
    <action android:name="android.intent.action.VIEW"/>
    <data android:scheme="https"/>
  </intent>
  <package android:name="com.whatsapp"/>
  <package android:name="com.whatsapp.w4b"/>
</queries>

<!-- Dentro de <application> para image_picker -->
<provider
    android:name="androidx.core.content.FileProvider"
    android:authorities="${applicationId}.fileprovider"
    android:exported="false"
    android:grantUriPermissions="true">
  <meta-data
      android:name="android.support.FILE_PROVIDER_PATHS"
      android:resource="@xml/file_paths"/>
</provider>
```

### android/app/src/main/res/xml/file_paths.xml
```xml
<?xml version="1.0" encoding="utf-8"?>
<paths>
  <external-path name="external_files" path="."/>
  <cache-path name="cache" path="."/>
</paths>
```

### Info.plist (iOS)
```xml
<key>NSCameraUsageDescription</key>
<string>Para tomar fotos de clientes y comprobantes</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>Para adjuntar fotos de clientes y comprobantes</string>
<key>NSPhotoLibraryAddUsageDescription</key>
<string>Para guardar imágenes</string>
```

### android/app/build.gradle
```gradle
android {
    compileSdkVersion 34
    defaultConfig {
        minSdkVersion 21
        targetSdkVersion 34
        multiDexEnabled true
    }
}
dependencies {
    implementation 'androidx.multidex:multidex:2.0.1'
}
```

---

## Flujos de negocio completos

### Flujo A: Nuevo cliente + préstamo
```
1. /clientes/nuevo → formulario → guardar
   → PDF perfil en carpeta del cliente
   → WhatsApp bienvenida

2. Detalle cliente → "Nuevo préstamo"
   → formulario (tasa 7% default)
   → BottomSheet resumen → confirmar
   → genera tabla de amortización
   → genera PDF plan de pagos
   → WhatsApp "préstamo aprobado"
   → cuotas aparecen en /pagos
```

### Flujo B: Registrar pago
```
1. /pagos → cuota pendiente → "Registrar pago"
2. Efectivo: solo monto
   Transferencia: monto + foto comprobante
3. Al guardar:
   → marca cuota pagada
   → actualiza saldo del préstamo
   → genera PDF recibo
   → WhatsApp confirmación al cliente
   → si préstamo terminado → PDF finiquito
   → si préstamo terminado → cliente pasa a inactivos
```

### Flujo C: Recuperar contraseña
```
Login → "¿Olvidaste tu contraseña?"
→ teléfono → pregunta 1 → pregunta 2
→ nueva contraseña → Login
```

### Flujo D: Simulador
```
/simulador → monto + tasa + plazo
→ tabla de amortización completa
→ resumen (total, intereses, cuota)
→ [Crear préstamo] → /prestamos/nuevo precargado
```
