# Especificación de diseño — Rediseño visual (modo claro / modo oscuro)

> **Nota (2026-09-19).** La dirección visual vigente es "Tinta y Neón", descrita
> en [`design-spec-tinta-y-neon.md`](design-spec-tinta-y-neon.md). Conserva la
> paleta de este documento sin cambios y modifica forma, composición y
> tipografía. Este archivo sigue siendo la referencia de la paleta y del tema
> `editorial_app_theme.dart`.

Este archivo resume, en un formato que Claude Code puede leer e implementar
directamente en tu proyecto Flutter, las decisiones tomadas en el canvas de
diseño (Opción A = modo claro, Opción C = modo oscuro). Referencia visual
completa, con los tableros y las 3 variantes de exploración, en:
https://claude.ai/artifact/MFE1EvCB4eYk4iqtRq6YkW

**Cómo usarlo con Claude Code:** copia este archivo y `app_theme.proposal.txt` a tu
proyecto (por ejemplo `docs/design-spec.md` y `lib/theme/app_theme.dart`), y
pídele a Claude Code algo como: *"Lee docs/design-spec.md e
implementa el tema en lib/theme/app_theme.dart, luego aplícalo al menú
lateral, la barra superior y la pantalla de Mis productos."*

> La propuesta original se conserva como `app_theme.proposal.txt` para que
> Flutter no la analice como código de producción. La adaptación compatible
> con este proyecto vive en `lib/config/theme/editorial_app_theme.dart`.

## Diagnóstico que motivó el rediseño

- El menú trataba todas las acciones como botones grandes de igual peso.
- El magenta se usaba en superficies muy grandes, perdiendo elegancia.
- Mezcla de rectángulos, píldoras y radios sin lógica.
- Tarjetas de producto sin contenedor, jerarquía ni proporciones consistentes.
- Barras superiores y tipografía inconsistentes entre pantallas.

La solución: magenta solo como acento, radios consistentes, jerarquía clara
en el menú (una sola acción destacada, resto como filas de navegación), y
tarjetas con proporción fija + metadatos.

## Los dos modos

- **Claro ("A — Magenta editorial")**: conserva tu magenta de marca, pero
  solo como acento sobre fondos blancos/rosados muy sutiles.
- **Oscuro ("C — Modo oscuro manga")**: paleta nueva, fondo casi negro,
  magenta eléctrico (u otro acento) con alto contraste, tarjetas con borde
  fino en vez de sombra.

> **Nota de decisión pendiente:** en el canvas, cada modo usa una pareja
> tipográfica distinta (ver abajo). Es una opción de diseño válida (cambia
> la "voz" entre modos), pero si prefieres que la tipografía se mantenga
> igual al cambiar de tema — que es lo más común — dímelo y unificamos a
> una sola pareja para ambos modos.

## Tokens de color

### Modo claro

| Token | Valor | Uso |
|---|---|---|
| `background` | `#FDF9FC` | Fondo de pantalla |
| `surface` | `#FFFFFF` | Tarjetas, drawer, barra superior |
| `onBackground` / `onSurface` | `#241626` | Texto principal |
| `onSurfaceVariant` (muted) | `#8A7A88` | Texto secundario, captions |
| `outline` (bordes/dividers) | `#ECE1EA` | Bordes, separadores |
| `primary` (acento) | `#9A1E74` | CTA, fila activa, FAB, íconos de acento |
| `onPrimary` | `#FFFFFF` | Texto/ícono sobre `primary` |
| `primaryContainer` (tinte) | `#9A1E74` a 8–12% opacidad | Fondos tintados (fila activa, chip CTA) |
| `scrim` | `rgba(36,22,38,0.45)` | Overlay del drawer |

Variantes de acento para probar (mismo chroma/lightness, distinto tono):
`#B0227F`, `#7E1861`, `#C23E93`.

### Modo oscuro

| Token | Valor | Uso |
|---|---|---|
| `background` | `#131117` | Fondo de pantalla |
| `surface` | `#1B1820` | Tarjetas |
| `surfaceContainer` (drawer) | `#17151B` | Fondo del drawer |
| `onBackground` / `onSurface` | `#F1EEF5` | Texto principal |
| `onSurfaceVariant` (muted) | `#9089A0` | Texto secundario |
| `outline` (bordes/dividers) | `#2C2833` | Bordes, separadores |
| `primary` (acento) | `#FF3FA0` | Texto/ícono de acento, borde de botones outline |
| `primaryContainer` (tinte) | `#FF3FA0` a 10–16% opacidad | Fondos tintados |
| `scrim` | `rgba(0,0,0,0.6)` | Overlay del drawer |

Variantes de acento para probar: `#B14EFF` (violeta), `#FF6B4A` (naranja),
`#3FD6FF` (cian).

**Importante — contraste en modo oscuro:** el acento `#FF3FA0` es muy
brillante; usarlo como fondo sólido con texto blanco no cumple 4.5:1 de
contraste. Por eso el FAB y los botones primarios en modo oscuro usan estilo
**outline** (fondo `surface`, borde y texto/ícono en `primary`) en vez de
relleno sólido. No lo rellenes sólido sin oscurecerlo antes.

## Tipografía

| | Modo claro | Modo oscuro |
|---|---|---|
| Display / títulos | Bricolage Grotesque (600–700) | Space Grotesk (600–700) |
| Cuerpo / captions | Work Sans (400–500) | IBM Plex Sans (400–500) |

Ambas están en Google Fonts — usa el paquete `google_fonts` en Flutter (ver
`app_theme.dart`). Evita Inter, Roboto y Arial como fuentes de marca (se ven
genéricas); estas dos parejas ya fueron elegidas para evitar ese efecto.

## Espaciado y radios

- Escala de espaciado: múltiplos de 8px → 4, 8, 12, 16, 20, 24, 32, 40, 48.
- Radios — **modo claro**: tarjetas 14px, controles/chips 12–14px, FAB 16px.
- Radios — **modo oscuro**: tarjetas 18px, controles/chips 14px, FAB 18px
  (un poco más redondeado, coherente con la estética más "panel de cómic").
- Objetivo táctil mínimo: 44×44px en cualquier botón o fila interactiva.

## Iconografía

Íconos de trazo (outline), grosor de línea ~1.75px, grilla de 24px — nunca
emoji como ícono de interfaz. En el canvas usé SVG inline estilo Lucide. En
Flutter, la forma más simple de igualar esa estética es el paquete
`lucide_icons` (o `flutter_lucide`), que tiene trazo consistente en todos los
íconos. Si prefieres quedarte con Material, usa las variantes `_outlined`
(`Icons.home_outlined`, `Icons.chat_bubble_outline`, etc.) en vez de las
rellenas, para mantener la misma sensación de trazo fino.

Set de íconos usado: inicio/descubrir (home), mis productos (box), descubre
(compass), chats (message), enviadas (send), recibidas (inbox), cerrar
sesión (log-out), flecha (chevron-right), menú hamburguesa, más (plus).

## Patrones de componentes

### Barra superior
Altura fija 64px, borde inferior 1px `outline`, sin elevación/sombra. Título
con la fuente display, peso 700, 20px. Ícono de menú a la izquierda.

### Menú lateral (drawer)
- Encabezado: avatar circular 44px (fondo `primary` a ~12% opacidad,
  inicial en `primary`) + saludo pequeño muted + nombre en negrita.
- **Una sola acción destacada**: fila con fondo tintado (`primary` ~8%),
  radio 14–18px, ícono y texto en `primary`, negrita.
- Separador, luego etiqueta pequeña en mayúsculas "OTRAS OPCIONES".
- Filas de navegación: ícono + texto + chevron, 12px de padding vertical,
  todas con el mismo peso visual. La fila activa ("Mis productos") lleva
  fondo tintado y color `primary`; el resto usa `onSurface`/`onSurfaceVariant`.
- "Cerrar sesión" va separado abajo (con su propio divisor), en color muted,
  nunca como botón grande y lleno — es una acción de salida, no la principal.

### Cuadrícula de productos ("Mis productos")
GridView de 2 columnas, gap 16–18px. Cada tarjeta: imagen con proporción fija
3:4, radio del tema; título con máximo 2 líneas (elipsis); metadato debajo en
texto muted, una sola línea (ej. "Shonen · Vol. 01"). Botón flotante extendido
"Nuevo producto" abajo a la derecha (relleno en claro, outline en oscuro).

### Variantes exploradas (opcionales, para más adelante)
Si más adelante quieres probar otra dirección sobre esta misma base, en el
canvas quedaron 3 variantes ya construidas sobre los tokens de arriba:

1. **V1 — tipografía editorial**: mismo layout, pero con Playfair Display +
   Manrope (más "librería/colección").
2. **V2 — lista horizontal**: en vez de cuadrícula, filas con portada chica a
   la izquierda y texto a la derecha (más denso, más rápido de escanear).
3. **V3 — portada a sangre**: la portada ocupa toda la tarjeta, con título y
   metadato superpuestos abajo sobre un degradado (estilo app de streaming).

## Siguientes pantallas pendientes de rediseñar

Formulario de producto, chats de intercambio, accesos y solicitudes — quedan
para una siguiente ronda una vez que confirmes esta base de tema.
