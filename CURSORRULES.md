# .cursorrules — Capital Pro

> Pega este contenido en un archivo `.cursorrules` en la raíz del proyecto.

## Proyecto
App Flutter para gestión financiera local de préstamos en Guatemala.

- Idioma: español
- Moneda: Q
- Sin backend externo
- Datos locales en SQLite
- Navegación con Go Router
- Estado con Riverpod

## Reglas de código

### UI y estilos
- Usar `AppColors`, `AppStrings` y `AppTextStyles` siempre que existan.
- Evitar `TextStyle(...)` directo en pantallas.
- No hardcodear textos en la UI.
- Mantener consistencia visual con Material Design.

### Lógica
- Usar `try/catch` en operaciones async.
- Antes de usar `context` después de un `await`, validar `if (mounted)`.
- Mantener validaciones centralizadas en helpers/validators.
- Eliminar imports no usados.

### Nombres y datos
- Usar nombres en español y consistentes con el dominio.
- Formatear nombres con title case cuando aplique.
- Validar teléfono y DPI según formato guatemalteco.
- La tasa por defecto de préstamos es 7%.

### Base de datos
- El acceso principal va por `DatabaseHelper` y repositorios.
- Si se toca SQLite en web, inicializar `databaseFactoryFfiWeb`.
- No romper compatibilidad entre móvil y web.

### Navegación
- Preferir `go_router`.
- Mantener rutas declaradas centralizadamente.
- No hacer navegación sin contexto válido.

## Módulos clave
- auth
- dashboard
- clientes
- prestamos
- pagos
- simulador
- reportes
- configuracion

## Flujo del negocio
- Usuario registra cuenta y capital inicial.
- Crea clientes.
- Genera préstamos y tabla de cuotas.
- Registra pagos por cuota o concepto.
- Revisa dashboard y reportes con saldo real.

## Errores comunes a evitar
- No abrir SQLite sin inicializar en web.
- No mezclar lógica de UI con acceso a base de datos.
- No duplicar validadores ni utilidades.
- No dejar textos literales en pantallas.
- No romper el flujo de autenticación ni la persistencia local.

## Comandos válidos para validar
```bash
flutter analyze
flutter test
flutter run
flutter run -d chrome --debug
```
