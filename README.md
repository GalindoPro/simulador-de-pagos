# Capital Pro

App Flutter para gestión de préstamos y pagos en Guatemala, diseñada para funcionar con SQLite local y flujo financiero de préstamos personales y comerciales.

## Objetivo del proyecto

- Gestionar usuarios, clientes, préstamos y pagos.
- Mantener datos en almacenamiento local.
- Cubrir flujo completo de crédito: registro, simulador, préstamo, cobro y reportes.
- Soportar uso en Android/iOS y, con ajustes especiales, en la web.

---

## Stack principal

- Flutter
- Dart
- Riverpod para estado
- Go Router para navegación
- SQLite con sqflite
- Material Design 3
- PDF / impresión / WhatsApp / image picker / permisos

## Estructura general

```text
lib/
  constants/
  helpers/
  models/
  providers/
  repositories/
  router/
  screens/
  services/
  widgets/
  main.dart
web/
  index.html
  sqflite_sw.js
  sqlite3.wasm
```

## Módulos clave

- Auth: login, registro, recuperación de contraseña
- Dashboard: resumen financiero, métricas y alertas
- Clientes: alta, detalle, historial e inactivos
- Préstamos: formulario, detalle, cuotas y vencimientos
- Pagos: registro de cuotas y comprobantes
- Simulador: cálculo de amortización y cuotas
- Reportes: indicadores y exportación
- Configuración: ajustes del usuario y exportación/importación de datos

---

## Requisitos

- Flutter SDK instalado
- Android Studio / Xcode según plataforma
- Chrome para validación web
- Dependencias de pub actualizadas

## Inicio rápido

```bash
flutter pub get
flutter run
```

Para navegador:

```bash
flutter run -d chrome --debug
```

## Configuración web para SQLite

La app usa SQLite y en web requiere la inicialización correcta del factory web.

### Requisitos

```yaml
dependencies:
  sqflite: ^2.3.0
  sqflite_common_ffi_web: ^1.0.0
```

### Setup recomendado

```bash
dart run sqflite_common_ffi_web:setup
```

Esto genera los archivos necesarios en la carpeta web:

- `web/sqflite_sw.js`
- `web/sqlite3.wasm`

Y en la app se inicializa así:

```dart
if (kIsWeb) {
  databaseFactory = databaseFactoryFfiWeb;
}
```

---

## Flujo recomendado para trabajar con IA

### 1) Contexto base
Adjunta o pega el contenido de `CAPITAL_PRO_CONTEXT.md` al inicio de la sesión.

### 2) Prompts por módulo
Usa los prompts de `PROMPTS_POR_MODULO.md` para pedir cambios específicos por área.

### 3) Reglas de editor
Si usas Cursor/Windsurf, copia el contenido de `CURSORRULES.md` a un archivo `.cursorrules` en la raíz del proyecto.

### 4) Ejemplo de uso

```text
Lee CAPITAL_PRO_CONTEXT.md, luego genera el módulo de clientes con:
- pantalla de listado
- detalle del cliente
- formulario
- filtros por estado
```

---

## Comandos útiles

```bash
flutter analyze
flutter test
flutter run -d chrome --debug
```

## Archivos importantes

| Archivo | Uso |
|---|---|
| `CAPITAL_PRO_CONTEXT.md` | Contexto general del proyecto |
| `PROMPTS_POR_MODULO.md` | Prompts listos por módulo |
| `CURSORRULES.md` | Reglas para asistentes y editores |
| `MCP_CONFIG.json` | Integración con Claude Desktop y MCP |

---

## Recomendación de mantenimiento

- Mantener documentación actualizada al cambiar pantallas o rutas.
- Actualizar el contexto de IA cuando agregues módulos nuevos.
- Revisar el README y el contexto una vez al mes para mantener coherencia.
