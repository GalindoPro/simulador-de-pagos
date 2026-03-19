# .cursorrules — Capital Pro v2.0
# Pega en archivo .cursorrules en la raíz del proyecto
# Compatible: Cursor, Windsurf, Zed

## Proyecto
App Flutter "Capital Pro" — gestión de préstamos para Guatemala.
Moneda Q. Teléfonos 8 dígitos (+502). DPI 13 dígitos (XXXX-XXXXX-XXXX).
Un solo dispositivo Android/iOS. SQLite local. Sin backend.

## Plataformas
Android (minSdk 21, targetSdk 34) e iOS.

## Reglas absolutas de código

### Colores — SIEMPRE AppColors
primary, primaryLight, primaryDark, secondary
success, error, warning, info
background, surface, divider
textPrimary, textSecondary, textHint, textOnPrimary
efectivo, transferencia, pendiente, completado, cancelado, vencido, activo

### Strings — SIEMPRE AppStrings, nunca hardcodeados en UI
### Estilos — SIEMPRE AppTextStyles, nunca TextStyle(...)
### if/else/for/while — SIEMPRE con llaves {}
### TextFormField — SIEMPRE initialValue:, nunca value:
### async — SIEMPRE con try/catch
### context después de await — SIEMPRE if (mounted)
### Imports sin usar — ELIMINAR

### Title Case OBLIGATORIO para nombres
Usuario.toTitleCase(input)    // usuarios
Cliente.crear(...)            // clientes — aplica automáticamente

### DPI guatemalteco
DpiInputFormatter()           // auto-formato XXXX-XXXXX-XXXX
AppValidators.dpi(v)          // valida 13 dígitos
AppFormatters.formatearDPI(s) // display formateado

## Flujo de registro (3 pasos)
Paso 1: nombre + teléfono + contraseña
Paso 2: 2 preguntas de seguridad + respuestas (SHA-256)
Paso 3: capital inicial en Q
→ Siempre regresa al Login (NO auto-login)

## Nuevas rutas
/simulador              → SimuladorScreen
/recuperar-password     → RecuperarPasswordScreen
/clientes/inactivos     → ClientesInactivosScreen

## Módulo pagos
Métodos: 'efectivo' | 'transferencia'
Transferencia → pide foto comprobante (image_picker)
Al pagar → WhatsApp automático al cliente
Al finalizar préstamo → PDF finiquito automático

## Tasa interés default: 7% mensual

## Errores comunes a evitar
- Siempre await DatabaseHelper en main() antes de runApp()
- multiDexEnabled true en build.gradle
- Todos los permisos en AndroidManifest.xml y Info.plist
- FileProvider configurado para image_picker en Android
- minSdkVersion 21
