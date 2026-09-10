# Propuestas de diseño para Mundo Otaku

Estas propuestas parten del flujo real del producto: descubrir publicaciones, revisar su estado, ofrecer un producto propio, aceptar o rechazar la solicitud y conversar durante el intercambio. La prioridad es que la demo de portafolio se entienda sin explicación del autor.

La línea base anterior al rediseño está protegida en la rama y etiqueta `respaldo-recuperado-2026-09-10`. Esta exploración vive en `diseno/renovacion-portafolio`.

## A. Yoru Exchange — recomendada

Una dirección nocturna y editorial que combina índigo profundo, violeta apagado, coral cálido y pequeños acentos menta. Tiene una identidad ligada al mundo otaku sin copiar la estética de una franquicia.

- **Personalidad:** urbana, comunitaria, cinematográfica y adulta.
- **Ventaja:** genera la portada más memorable para un caso de estudio y hace destacar las fotografías de productos.
- **Riesgo:** necesita controlar contraste, densidad y fondos para no oscurecer formularios.
- **Tipografía propuesta:** `Space Grotesk` para títulos y `Inter` para interfaz.
- **Tokens principales:** `#111426`, `#202442`, `#F4EEE8`, `#FF7A6E`, `#80D8C7`, `#A99BEF`.

La portada usaría la ilustración únicamente en acceso y comunicación. El catálogo mantendría superficies sólidas, tarjetas claras y fotografías reales.

## B. Manga Press

Una dirección gráfica inspirada en impresión risográfica, tramas y revistas culturales. Usa papel crema, negro carbón, bermellón, ciruela y un pequeño acento cobalto.

- **Personalidad:** autoral, gráfica, coleccionable y enérgica.
- **Ventaja:** es la propuesta más distintiva y funciona muy bien en capturas de portafolio.
- **Riesgo:** puede competir con las portadas de manga si las tramas se usan dentro del catálogo.
- **Tipografía propuesta:** `Archivo Black` para titulares y `IBM Plex Sans` para interfaz.
- **Tokens principales:** `#F3E9D3`, `#181513`, `#E84A2A`, `#64374D`, `#2855D9`, `#FFFFFF`.

Las tramas quedarían limitadas a cabeceras, estados vacíos y elementos promocionales. Formularios y tarjetas conservarían fondos limpios.

## C. Club Coleccionista

Una propuesta luminosa y acogedora con crema, verde azulado, coral arcilla, lavanda y madera. Presenta el intercambio como una actividad segura entre personas de una comunidad.

- **Personalidad:** cercana, confiable, ordenada y tranquila.
- **Ventaja:** ofrece la mejor legibilidad inicial y encaja con un catálogo amplio.
- **Riesgo:** requiere un símbolo y una voz propios para no parecer una tienda genérica.
- **Tipografía propuesta:** `Manrope` para títulos y texto de interfaz.
- **Tokens principales:** `#FFF9F1`, `#173A3B`, `#4C8E8B`, `#D97862`, `#B8A9D9`, `#E8D8C5`.

## Comparación

| Criterio | Yoru Exchange | Manga Press | Club Coleccionista |
| --- | ---: | ---: | ---: |
| Identidad para portafolio | 5/5 | 5/5 | 3/5 |
| Legibilidad de producto | 4/5 | 3/5 | 5/5 |
| Adaptación móvil/escritorio | 4/5 | 4/5 | 5/5 |
| Uso de las fotos existentes | 5/5 | 3/5 | 5/5 |
| Complejidad de implementación | Media | Media/alta | Baja/media |

Recomiendo **Yoru Exchange**, usando la disciplina de superficies de Club Coleccionista. Esa combinación entrega una portada con personalidad y un área autenticada clara.

## Sistema de interfaz común

Las tres propuestas comparten la misma arquitectura para que la elección estética no obligue a rehacer el producto:

- ancho máximo de contenido de 1200 px en escritorio;
- navegación inferior de cuatro destinos en móvil y barra lateral compacta en escritorio;
- tarjetas con proporción consistente para evitar saltos entre fotografías;
- estados de intercambio visibles: pendiente, aceptado, completado, rechazado y cancelado;
- acción principal única por pantalla;
- flujo de propuesta en tres pasos: producto deseado, producto ofrecido y confirmación;
- chat con encabezado del intercambio, resumen plegable y fecha real;
- estados vacíos con una instrucción útil y una acción concreta;
- área táctil mínima de 44 px y contraste WCAG AA para texto normal.

## Pantallas prioritarias

1. Acceso con identidad de marca y entrada directa a las cuentas demo.
2. Descubrir con búsqueda, filtros simples y tarjetas adaptables.
3. Detalle con dueño, condición, etiquetas y acción `Proponer intercambio`.
4. Selector de producto propio y confirmación de solicitud.
5. Bandeja de intercambios separada por acción requerida y actividad reciente.
6. Chat persistente con contexto visible del intercambio.
7. Publicar/editar con selección de imágenes compatible con web.

Abre `index.html` para revisar las tres direcciones en una presentación adaptable. Las imágenes fueron generadas con la herramienta integrada `image_gen`; sus prompts se conservan en `PROMPTS.md`.

