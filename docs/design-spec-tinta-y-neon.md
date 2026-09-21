# Especificación de diseño — "Tinta y Neón"

Segunda dirección visual del cliente, aprobada por Marco el 2026-09-19. Parte
de la paleta de `editorial_app_theme.dart` (ver [`design-spec.md`](design-spec.md),
propuesta "Magenta editorial") y **no la reemplaza**: conserva sus colores tal
cual y cambia la forma, la composición y la tipografía.

## La idea

Mundo Otaku es una aplicación de **intercambio**, no de venta. De ahí sale la
metáfora: un intercambio es una doble página de manga, dos viñetas enfrentadas.
El lenguaje visual mezcla las dos culturas que conviven en la aplicación:

- **Manga japonés:** estructura de viñetas, borde de tinta, trama de puntos
  (screentone), sombras duras de imprenta sin desenfoque, paneles apenas
  inclinados.
- **Manhwa coreano:** recorrido vertical continuo, aire y color.

Reglas de forma: nada queda perfectamente cuadrado ni alineado; las viñetas se
inclinan entre 0,3° y 1,2°; las sombras son duras, con desplazamiento (4, 4) y
desenfoque cero.

## Paleta

Se conserva sin cambios la de `editorial_app_theme.dart`. Los valores vivien en
`InkTokens` (`lib/features/shared/widgets/ink_tokens.dart`), resueltos por modo.

| Rol | Claro | Oscuro |
| --- | --- | --- |
| Fondo | `#FDF9FC` | `#131117` |
| Panel | `#FFFFFF` | `#1B1820` |
| Tinta / borde | `#241626` (2,5 px) | `#2C2833` (1,8 px) |
| Texto | `#241626` | `#F1EEF5` |
| Texto secundario | `#6E5F6C` | `#9089A0` |
| Acento | `#9A1E74` | `#38182D` con neón `#FF3FA0` |

Dos precisiones importantes:

- **El texto secundario del modo claro cambió** de `#8A7A88` a `#6E5F6C`. El
  original daba 3,4:1 de contraste sobre el fondo y no pasaba AA para texto
  pequeño; el nuevo da 5,2:1 conservando el mismo matiz.
- **El neón `#FF3FA0` solo se usa en acentos pequeños:** bordes de 1 a 1,5 px,
  iconos, cifras y etiquetas. Nunca como relleno de superficies grandes. Para
  fondos teñidos en modo oscuro se usa `#38182D`, que es el `primaryContainer`
  que el propio tema calcula. Esto además es coherente con
  `outlinedPrimaryActions: true`, que el tema ya define para el modo oscuro.

## Tipografía

Bricolage Grotesque para títulos y Work Sans para texto corrido, las mismas de
la dirección anterior, pero **empaquetadas en la aplicación** en vez de
descargarse en tiempo de ejecución con `google_fonts`. Los archivos variables
están en `assets/fonts/` con sus licencias OFL, y el acceso pasa por
`AppFonts` (`lib/config/theme/app_fonts.dart`).

El motivo no es estético: `google_fonts` descarga las tipografías por red la
primera vez, así que sin conexión no llegaban y el primer render mostraba una
fuente de reemplazo antes de cambiar.

En `pubspec.yaml` cada peso se declara apuntando al mismo archivo variable, y
el peso real se pide con `fontVariations`.

**Limitación conocida.** El diseño pide el eje de ancho `wdth` en 88, algo
condensado. En Flutter 3.16.8 el motor angosta los glifos pero sigue calculando
el avance del carácter de espacio con la instancia por omisión, así que entre
palabras queda un hueco visiblemente grande. Por eso `AppFonts.displayWidth`
quedó en 100. Al actualizar Flutter hay que volverlo a 88 y comprobar el
espaciado; está registrado en `ai-handoff/ROADMAP.md` como "R-20 en detalle".

### Caracteres japoneses y coreanos

El lomo vertical 交換 · 교환 ("intercambio" en japonés y en coreano) es el guiño
a ambas culturas. Se implementa en `VerticalCjkLabel`, que apila los caracteres
uno a uno: en CSS esto sería `writing-mode: vertical-rl`, que Flutter no tiene,
y `RotatedBox` acostaría los glifos.

`assets/fonts/NotoSansKR-Subset.ttf` pesa 6 KB porque se pidió a Google Fonts
recortada **solo a esos cuatro caracteres**. Para agregar cualquier otro
carácter japonés o coreano hay que regenerar el archivo:

```
https://fonts.googleapis.com/css2?family=Noto+Sans+KR:wght@700&text=<caracteres>
```

pidiéndolo con un `User-Agent` antiguo para que Google entregue TrueType en vez
de woff2, que Flutter no admite.

## Cómo está implementado

Cada pantalla rediseñada es **un archivo nuevo**; el original queda intacto para
poder volver atrás, según la regla de `ai-handoff/PRECAUCIONES.md`.

| Pantalla | Archivo nuevo | Original conservado |
| --- | --- | --- |
| Menú lateral | `ink_navigation_drawer.dart`, `webtoon_navigation_drawer.dart`, `styled_navigation_drawer.dart` | `app_navigation_drawer.dart` |
| Descubrir | `screens/ink_discover_screen.dart`, `widgets/ink_discover_card.dart` | `discover_screen.dart` |
| Mi estante | `screens/ink_products_screen.dart`, `widgets/ink_product_row.dart` | `products_screen.dart` |
| Producto de otra persona | `screens/ink_other_product_screen.dart` | `other_product_screen.dart` |
| Solicitudes recibidas y enviadas | `chats/…/screens/ink_exchange_list_screen.dart` | `received_chat_list.dart`, `requested_chat_list.dart` |
| Propuesta de intercambio | `chats/…/screens/ink_exchange_preview_screen.dart` | `preview_received_screen.dart`, `preview_requested_screen.dart` |
| Chats (lista) | `chats/…/screens/ink_chat_list_screen.dart` | `chat_list_screen.dart` |
| Editar / publicar producto (T-037) | `screens/ink_product_screen.dart` | `product_screen.dart` (la nueva ya no usa `custom_product_field.dart`) |
| Chat | restilizado dentro de `chat_screen.dart` | — (ver nota) |

La bandeja de solicitudes y la lista de chats muestran lo mismo en distintos
momentos del flujo, así que comparten `InkExchangeCard`
(`chats/presentation/widgets/ink_exchange_card.dart`).

Piezas compartidas: `ink_tokens.dart` (colores, botón de menú y botón de sombra
dura), `halftone_painter.dart` (trama de puntos), `vertical_cjk_label.dart` y
`product_option_labels.dart`.

Las dos bandejas de solicitudes comparten una sola pantalla, parametrizada con
`ExchangeInbox`: recorren los mismos intercambios pendientes y solo cambian de
lado, así que duplicarlas habría significado mantener dos copias casi idénticas.
Cada fila se dibuja como una doble página: lo que entregas y lo que recibes, con
la flecha de intercambio entre medio.

El menú tiene **dos estilos elegibles por la persona usuaria**, "Capítulos" y
"Hilo webtoon", con el selector dentro del propio menú y la preferencia
persistida en `drawer_style_provider.dart`, con el mismo patrón del selector de
tema.

### El chat es la excepción

El chat **no** se rehízo en un archivo nuevo. Su pantalla mezcla la vista con
la conexión por socket y con GetX, así que duplicarla para cambiarle el aspecto
habría significado duplicar esa lógica. En su lugar se restilizaron solo el
globo de mensaje (`MessageItem`) y el campo de entrada, dentro de
`chat_screen.dart`.

Esa pantalla está cubierta por un recorrido Playwright, así que hay anclas que
**no se pueden cambiar** al tocarla:

- un único `textbox` en la pantalla: agregar otro campo de texto vuelve
  ambiguo el selector `getByRole('textbox')`;
- el botón de enviar debe seguir llamándose `Enviar mensaje`;
- el texto del mensaje debe seguir siendo su etiqueta de accesibilidad, porque
  la prueba busca el mensaje recién enviado con `getByLabel`;
- las etiquetas `Chat conectado` y `Chat sin conexión` del `Semantics` que
  envuelve la vista.

Conviene recordar que ese recorrido ya falla de forma intermitente en CI
(T-026 en el tablero), así que cualquier cambio ahí se revisa con cuidado.

## Trampas encontradas al implementar

Las tres aparecieron solo al ejecutar, no las detectó el análisis estático:

1. **La sombra dura se dibuja encima del relleno** si el color está en un
   `Material` padre y la sombra en un `BoxDecoration` sin color propio. La
   sombra va en un contenedor externo; así lo resuelve `InkHardButton`.
2. **Los iconos de Material pueden salir como glifo faltante** en algunos
   contextos de la build web.
3. **Las etiquetas de producto deben pasar por `productOptionLabel`** en todas
   las pantallas, o el formulario muestra "Acción / peleas" mientras la tarjeta
   muestra el valor crudo "Accion peleas".

Sobre esto último: los valores `Komodo`, `Accion peleas`, `Gore Terror` y
`Magical Girls Maho Shojo` **siguen guardados así en la base de datos**. Son el
`value` del `DropdownButton` y la columna es texto libre, así que cambiarlos
rompería los productos existentes. Solo se corrigió el texto visible;
corregir los datos sería una migración aparte.

## Banco de pruebas visual

`tool/vista_menu.dart` y `tool/vista_pantallas.dart` montan el menú y las
pantallas sin API ni sesión iniciada, con un repositorio de productos falso.
No forman parte de la aplicación.

```
flutter run -d chrome -t tool/vista_pantallas.dart
```
