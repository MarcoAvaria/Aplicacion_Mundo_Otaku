# Retirar GetX y subir a Riverpod 3 — evaluación

**Fecha:** 2026-09-24 · **Estado:** evaluación; **no se ha cambiado código**.
**Tarea:** T-051. Se separa en dos, a pedido de Marco: GetX por un lado y
Riverpod 3 como tarea propia.

Todo lo que aparece aquí se midió sobre el código de `mejora/modernizacion`
(`54a2a1d` en adelante), con Flutter 3.47.5. Lo que es suposición está marcado.

---

## 1. GetX

> **Hecho el 2026-09-24**, a la espera de revisión para commitear. La lista de
> mensajes pasó a ser estado de `_ChatViewState`, cada `setState` comprueba
> `mounted`, y se retiraron `chat_controller.dart`, `Get.put`, la exportación
> del barril y la dependencia `get`. Hay una prueba de widget nueva del chat
> —`test/features/chats/chat_screen_mensajes_test.dart`, 7 casos— que hace de
> servidor despachando eventos al socket con `emitEvent`; se comprobó rompiendo
> el código de cuatro formas que cada rotura la atrapa la prueba que
> corresponde. Matriz completa en verde, Playwright 8 de 8, y en el teléfono la
> conversación real muestra sus cuatro mensajes en orden, idénticos al volver a
> entrar.

### Qué hace hoy, exactamente

GetX se usa para **una sola cosa**: guardar la lista de mensajes del chat.

| Archivo | Uso |
| --- | --- |
| `lib/main.dart` | `Get.put(ChatController())` antes de `runApp` |
| `lib/features/shared/widgets/chat/chat_controller.dart` | `ChatController extends GetxController`, con `chatMessages = <Message>[].obs` y tres métodos: agregar, reemplazar y vaciar |
| `lib/features/products/presentation/screens/chat_screen.dart` | `Get.find<ChatController>()` y un `Obx` que redibuja la lista |
| `lib/features/shared/widgets/widgets.dart` | reexporta `chat_controller.dart` |

La navegación, los diálogos y la inyección de GetX **no se usan**: la app
arranca con `MaterialApp.router`, no con `GetMaterialApp`. Ninguna otra pantalla
ni ninguna prueba toca `ChatController`.

### Qué efectos tendría retirarlo

**Los buenos:**

- **Una sola forma de manejar estado.** Hoy conviven Riverpod en toda la app y
  GetX en una lista. Quien lea el código tiene que entender dos modelos para
  seguir un mensaje.
- **El historial deja de vivir en un objeto global.** `ChatController` se crea
  una vez al arrancar y vive hasta que se cierra la app. Al salir de una
  conversación, sus mensajes **se quedan en memoria**; solo se borran al entrar
  a otra, porque `initState` llama a `clearMessages()`. Si alguna vez una
  conversación se abriera sin pasar por ese `initState` —otra pantalla, una
  prueba—, mostraría los mensajes de la anterior. Con estado propio de la
  pantalla, los mensajes nacen y mueren con ella, y ese error deja de ser
  posible.
- **Se va una dependencia que arrastra `dart:html`.** La compilación web de
  Flutter 3.47 la señala como incompatible con WebAssembly
  (`get/get_utils/src/platform/platform_web.dart`). No bloquea nada hoy, pero es
  uno de los obstáculos si algún día la web pasa a Wasm.

**Los riesgos, revisados uno por uno:**

- **Un evento del socket después de cerrar la pantalla.** Con estado local, un
  `setState` sobre una pantalla ya cerrada lanza un error. Se revisó: `dispose`
  da de baja los tres manejadores (`chat-history`, `new-message`, `chat-error`)
  con la misma referencia con que se registraron, así que no deberían llegar
  eventos tardíos. Aun así, el cambio tiene que comprobar `mounted` antes de
  cada `setState`, que es barato y cierra la puerta del todo.
- **La exportación del barril.** `widgets.dart` reexporta `chat_controller.dart`;
  hay que quitar esa línea. `message.dart` se queda.
- **El chat es la zona más delicada de la app.** Por eso importa que es
  justamente la mejor cubierta: los recorridos Playwright de dos sesiones que
  conversan **y se reconectan**, el del historial ordenado tras recargar, y el
  del aviso a quien no tiene la conversación abierta.

### Propuesta

Reemplazar `ChatController` por una `List<Message>` dentro de `_ChatViewState`
—que ya es un `ConsumerStatefulWidget`—, actualizada con `setState` protegido
por `mounted`. Borrar `chat_controller.dart`, la línea de `Get.put` y la
dependencia `get` del `pubspec.yaml`.

**Costo estimado:** cuatro archivos y una sesión corta. **Verificación:**
matriz completa, los recorridos del chat y una conversación real en el teléfono.

### Algo que apareció de paso, sin comprobar

`dispose` del chat llama a `socketService.socket.off(...)`. Ese *getter* lanza
`StateError` si el socket ya no existe, y el socket se destruye al cerrar
sesión. Si la sesión se cerrara **con el chat abierto** —por ejemplo, porque el
token se revocó— y la pantalla se desmontara después, `dispose` podría fallar.
**No está comprobado**: hace falta una prueba que lo reproduzca antes de
arreglarlo. No depende de GetX, pero conviene resolverlo en el mismo cambio,
porque toca el mismo `dispose`.

---

## 2. Riverpod 3, como tarea propia

### La sonda: se probó de verdad, en un árbol aparte

En vez de estimar, se subió `flutter_riverpod` de 2.6.1 a **3.4.3** en una copia
desechable del repositorio y se midió:

| Paso | Resultado |
| --- | --- |
| Resolver dependencias | **sin conflictos** (`riverpod` y `flutter_riverpod` 3.4.3) |
| Análisis tras subir la versión | **306 errores** |
| Causa | casi todos en cascada de **una sola**: `StateNotifier` y `StateNotifierProvider` se mudaron a `package:flutter_riverpod/legacy.dart` |
| Análisis tras agregar ese import en **11 archivos** | **0 errores**, 11 avisos, todos de imports que quedaron sobrando |
| `flutter test` | **163 de 163** |

O sea: **el cambio de código obligatorio es un import en 11 archivos**. La copia
se descartó; en el repositorio no hay nada de esto.

### Los cambios de comportamiento, contrastados con nuestro código

Que compile no basta: Riverpod 3 cambia cómo se comportan algunas cosas, y eso
no lo detecta el analizador. Se revisó cada uno contra la documentación oficial
(riverpod.dev, guía de migración 3.0) y contra el código:

| Cambio de Riverpod 3 | ¿Nos afecta? | Por qué |
| --- | --- | --- |
| **Reintento automático**, con espera creciente, de los proveedores que fallan | **No se espera** | Aplica a proveedores que lanzan al construirse. No tenemos **ningún** `FutureProvider`, `StreamProvider` ni `AsyncNotifier`, y los `StateNotifier` hacen su trabajo asíncrono en métodos, no al construirse. |
| **Todas las notificaciones filtran con `==`** en vez de `identical` | **No** | **Ninguna** clase de estado sobrescribe `operator ==`, así que para nosotros `==` sigue siendo identidad. |
| **Se pausan los oyentes de widgets que no están a la vista** | **No se espera** | Hay 5 `ref.listen`: el del router, que vive en un proveedor y no se pausa, y los de las pantallas de acceso y registro, que solo importan mientras se ven. Y los avisos del socket que refrescan las listas llegan por una suscripción directa al `Stream` desde el widget (`exchange_list_support.dart`), no a través de Riverpod. |
| **`ProviderException`** envuelve los errores al leer un proveedor fallido | **No** | No hay ningún `AsyncValue` ni `.when(...)` en la app. |

### Qué **no** incluye esta tarea

Pasar los 11 `StateNotifier` a la API nueva (`Notifier`) es otra cosa: es
reescribir cada uno, y `legacy.dart` sigue soportado en Riverpod 3. Conviene
dejarlo para cuando haya una razón, no hacerlo por completar.

### Propuesta

Un solo commit: la versión en `pubspec.yaml`, el import de `legacy.dart` en los
11 archivos y quitar los 11 imports que sobran. **Costo: bajo.** Verificación:
matriz completa, Playwright y los tres flujos en el teléfono, porque el cambio
de comportamiento que más importaría —la pausa de oyentes— solo se ve
navegando.

---

## 3. Orden recomendado

1. **GetX primero.** Es el que toca el chat, y conviene que ese cambio viaje
   solo: si algo falla en la conversación, la causa no puede ser otra.
2. **Riverpod 3 después**, en otro commit. Es mecánico, pero si se mezcla con
   el de GetX y algo cambia de comportamiento, no se sabría cuál fue.

Las dos cosas caben en una sesión.
