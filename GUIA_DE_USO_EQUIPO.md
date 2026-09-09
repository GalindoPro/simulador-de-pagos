# Guía de uso del equipo — Capital Pro

## 1. Objetivo

Esta guía sirve para que cualquier miembro del equipo pueda entender, ejecutar, probar y mantener la aplicación Capital Pro sin depender de conocimiento informal previo.

---

## 2. Descripción del proyecto

Capital Pro es una aplicación Flutter para gestionar:

- usuarios
- clientes
- préstamos
- cuotas y pagos
- reportes financieros
- configuración local de la app

La app trabaja completamente localmente con SQLite y no depende de un backend externo.

---

## 3. Requisitos del entorno

### Software necesario

- Flutter SDK
- Android Studio o Xcode según la plataforma
- VS Code o editor compatible
- Git
- Chrome para pruebas web

### Verificación rápida

```bash
flutter --version
flutter doctor
```

Si aparece algún problema de entorno, corregirlo antes de avanzar con desarrollo o pruebas.

---

## 4. Clonar y abrir el proyecto

```bash
git clone <url-del-repositorio>
cd "simulador de pagos"
```

Luego abrir la carpeta en VS Code.

---

## 5. Instalar dependencias

```bash
dart pub get
# o
flutter pub get
```

---

## 6. Ejecutar la aplicación

### Móvil / emulador

```bash
flutter run
```

### Web

```bash
flutter run -d chrome --debug
```

### Verificar análisis del proyecto

```bash
flutter analyze
```

---

## 7. Estructura del proyecto

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

### Cuándo tocar cada carpeta

- `lib/screens/`: pantallas y flujos de usuario
- `lib/providers/`: estado global
- `lib/repositories/`: acceso a datos y lógica de persistencia
- `lib/services/`: utilidades, SQLite, archivos, WhatsApp, PDF, etc.
- `lib/models/`: entidades del dominio
- `lib/helpers/`: validadores, formatters y utilidades
- `lib/router/`: navegación
- `lib/constants/`: colores, strings, temas

---

## 8. Base de datos

La app usa SQLite local con la base `capital_pro.db`.

### Tablas principales

- usuarios
- preguntas_seguridad
- clientes
- prestamos
- pagos
- tabla_pagos

### Recomendación importante

Si se trabaja en web, la base debe inicializarse correctamente con `databaseFactoryFfiWeb`.

```dart
if (kIsWeb) {
  databaseFactory = databaseFactoryFfiWeb;
}
```

Y es necesario asegurar la presencia de:

- `web/sqflite_sw.js`
- `web/sqlite3.wasm`

Si faltan, ejecutar:

```bash
dart run sqflite_common_ffi_web:setup
```

---

## 9. Flujo principal de la funcionalidad

### Registro y login

- crear usuario
- validar teléfono y contraseña
- guardar respuestas de seguridad
- configurar capital inicial

### Clientes

- registrar cliente
- ver historial
- separar activos e inactivos
- asociar clientes a préstamos

### Préstamos

- crear préstamo con monto, tasa, plazo y vencimiento
- calcular cuota mensual
- generar tabla de amortización

### Pagos

- registrar pago de cuota
- guardar comprobantes si aplica
- actualizar saldo del préstamo
- mantener registro local

### Dashboard y reportes

- visualizar resumen financiero
- revisar métricas por mes
- analizar clientes, préstamos y pagos

---

## 10. Estándares de trabajo del equipo

### Código

- Mantener nombres consistentes en español
- No hardcodear textos en pantallas
- Reutilizar `AppColors`, `AppStrings`, `AppTextStyles`
- Usar validaciones centralizadas
- Manejar errores con `try/catch`
- Usar `if (mounted)` después de `await` cuando se use `context`

### Git y ramas

Usar ramas por tarea o módulo:

```bash
git checkout -b feature/clientes
git checkout -b fix/sqlite-web
git checkout -b chore/documentacion
```

### Confirmación de cambios

```bash
git status
git add .
git commit -m "feat: mejora del módulo de clientes"
```

---

## 11. Validación antes de entregar

Antes de cerrar una tarea, validar lo siguiente:

```bash
flutter analyze
flutter test
flutter run -d chrome --debug
```

Checklist mínimo:

- proyecto compila
- no hay errores de análisis
- flujo principal funciona
- cambios no rompen otros módulos
- base de datos sigue operando correctamente

---

## 12. Problemas comunes y soluciones rápidas

### Error de SQLite en web

Síntoma:

- `databaseFactory not initialized`
- `Cannot find context with specified id`
- app no inicia en Chrome

Solución:

```dart
if (kIsWeb) {
  databaseFactory = databaseFactoryFfiWeb;
}
```

y asegurarse de tener los archivos del worker web generados.

### Error de dependencias

```bash
flutter pub get
```

### Error de análisis

```bash
flutter analyze
```

---

## 13. Plantilla para nuevas tareas

### Título

- Tarea: [nombre corto]
- Módulo: [clientes / préstamos / pagos / dashboard / auth]
- Responsable: [nombre]

### Requisitos

- objetivo
- pantalla o flujo afectado
- validación esperada
- riesgo detectado

### Entrega

- evidencia de prueba
- enlace a commit o PR
- notas de funcionamiento

---

## 14. Buenas prácticas de equipo

- documentar cambios relevantes
- mantener README y contextos actualizados
- probar antes de cerrar tareas
- revisar compatibilidad con la base local
- priorizar cambios pequeños y verificables

---

## 15. Resumen

Este proyecto es una aplicación local de gestión financiera, orientada a flujo real de préstamos y pagos. Para trabajar con ella eficientemente, basta con:

1. clonar el proyecto
2. instalar dependencias
3. ejecutar en móvil o web
4. seguir el flujo de negocio real
5. validar con `flutter analyze` y pruebas funcionales

La clave está en mantener la lógica del negocio, la base local y la experiencia de usuario alineadas.
