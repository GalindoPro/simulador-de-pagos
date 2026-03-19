# Capital Pro — Guía de archivos de IA

## Archivos generados

| Archivo | Para qué sirve | Cómo usarlo |
|---------|---------------|-------------|
| `CAPITAL_PRO_CONTEXT.md` | Contexto completo del proyecto | Pega al inicio de cada sesión |
| `PROMPTS_POR_MODULO.md` | 8 prompts listos por módulo | Copia el prompt del módulo que necesitas |
| `MCP_CONFIG.json` | Conecta Claude Desktop al proyecto | Sigue las instrucciones dentro del archivo |
| `CURSORRULES.md` | Reglas para Cursor / Windsurf | Renombra a `.cursorrules` en raíz del proyecto |

---

## Flujo recomendado de trabajo

### Con Claude (claude.ai o VS Code)
```
1. Abre una nueva sesión
2. Adjunta o pega CAPITAL_PRO_CONTEXT.md
3. Pega el prompt del módulo que necesitas (de PROMPTS_POR_MODULO.md)
4. Claude genera el código siguiendo la arquitectura del proyecto
```

### Con ChatGPT
```
1. Pega el contenido completo de CAPITAL_PRO_CONTEXT.md
2. Escribe "---" para separar
3. Pega el prompt del módulo
```

### Con Gemini
```
1. Crea un proyecto en Gemini (menú izquierdo)
2. Adjunta CAPITAL_PRO_CONTEXT.md como documento del proyecto
3. Gemini lo tendrá como contexto permanente
4. Solo pega el prompt del módulo en cada mensaje
```

### Con Cursor o Windsurf
```
1. Copia el contenido de CURSORRULES.md
2. Crea un archivo .cursorrules en la raíz de capital_pro/
3. Pega el contenido
4. La IA del editor ya tiene el contexto automáticamente
```

### Con Claude Desktop + MCP (más poderoso)
```
1. Sigue las instrucciones en MCP_CONFIG.json
2. Claude podrá leer y escribir archivos directamente
3. Pídele: "Lee CAPITAL_PRO_CONTEXT.md y genera el módulo de Clientes
   directamente en lib/screens/clientes/"
```

---

## Orden sugerido de generación

```
Parte 1 ✅ → Estructura base (ya generada)
Parte 2 ✅ → Modelos + repositorios + Auth screens
Parte 3 ✅ → Auth mejorada + CarpetaService + Router 6 secciones
Parte 4   → Widgets reutilizables + Dashboard
Parte 5   → Módulo Clientes completo
Parte 6   → Módulo Préstamos + tabla de amortización
Parte 7   → Módulo Pagos + PDF automático + WhatsApp
Parte 8   → Reportes + Configuración + respaldo DB
```
