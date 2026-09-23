# Cuánto cuesta abrir el tiempo real (T-036)

**Estado:** evaluación para decidir. Sin commit · **Fecha:** 2026-09-23 · **Rama:** `feature/tiempo-real`

Marco pidió estimar el costo de T-036 antes de comprometerse, y mencionó además
que "habría que almacenar las conversaciones y algunos metadatos asociados". Al
mirarlo de cerca resultó que **son dos frentes distintos**, con costos y riesgos
muy diferentes, y conviene no tratarlos como uno solo.

## Qué falta hoy, exactamente

El *gateway* emite `new-message` **solo a la sala de la conversación abierta**
(`chat_<id>`), y el cliente se une a una sola sala a la vez. Consecuencia: si no
tienes esa conversación abierta, nada te avisa. Lo mismo con los cambios de
estado de un intercambio.

T-035 tapó el hueco por el lado del usuario —refresco manual, recarga al volver a
la pantalla y al reanudar la app, y el contador de no leídos— pero nada de eso es
tiempo real: hay que provocarlo.

## Frente A: avisar fuera de la conversación abierta

**Costo: bajo.** Más bajo de lo que parecía, por un detalle que conviene tener
presente: **el socket se conecta al iniciar sesión**, no al entrar al chat
(`auth_provider.dart`, donde se llama a `SocketService.instance.initialize`). Ya
existe una conexión viva por usuario durante toda la sesión, así que no hay que
inventar un ciclo de vida nuevo, que suele ser la parte cara de estas cosas.

Lo que hay que tocar:

| Dónde | Cambio |
| --- | --- |
| `messages-ws.gateway.ts`, `handleConnection` | `client.join('user_<id>')`. El id ya está resuelto ahí para autenticar. |
| `messages-ws.gateway.ts`, `handleSendMessage` | Avisar además a la sala del **otro** participante, con un evento liviano (identificador del intercambio y marca de tiempo), no con el mensaje entero. |
| `chat-exchange.controller.ts`, los tres `@Patch` | Avisar a ambos participantes cuando el intercambio se aprueba, se rechaza o cambia de estado. |
| `socket_service.dart` | Escuchar ese evento. **No** hace falta unirse a otra sala: el servidor empuja a la sala del usuario por su cuenta. |
| Providers de intercambios | Al recibirlo, refrescar. `refreshExchangeData` y la marca de lectura ya existen desde T-035, así que es enchufar, no construir. |

Riesgo principal, y hay que nombrarlo: **no mandar el contenido del mensaje por
la sala del usuario**. La sala de la conversación ya valida pertenencia
(`isUserInRoom`); la del usuario no valida nada por sí misma, así que el evento
debe llevar lo mínimo y el cliente debe pedir el detalle por los caminos que ya
comprueban permisos.

Lo que de verdad cuesta aquí no es el código sino **la prueba**: un recorrido
Playwright de dos sesiones donde la segunda recibe el aviso *sin* abrir la
conversación. Es factible —ya hay recorridos de dos sesiones— pero alarga CI.

## Frente B: normalizar las conversaciones

Esto es lo que Marco intuía, y es un trabajo bastante mayor.

Hoy los mensajes viven en **una columna `jsonb` sobre `chat_exchanges`**:

```ts
@Column('jsonb', { nullable: true, default: '[]' })
messages: { content: string; timestamp: Date; sendBy: string }[] = [];
```

Funciona para una demostración, pero tiene límites concretos, no teóricos:

- **Cada mensaje reescribe el arreglo completo** dentro de una transacción
  (`appendMessage` lee, agrega y vuelve a guardar). El costo de escribir crece
  con el largo de la conversación, y dos mensajes a la vez compiten por la misma
  fila.
- **Los mensajes no tienen identificador**, así que no se puede marcar uno como
  leído, ni editar, ni borrar, ni paginar. Una conversación larga viaja entera en
  cada `chat-history`.
- **No hay estado de lectura en el servidor.** Por eso T-035 tuvo que resolverlo
  con una marca local por dispositivo: hoy, si entras desde otro teléfono, tus
  no leídos no te siguen. Es una limitación conocida y aceptada, no un olvido.
- No se puede indexar ni buscar dentro de las conversaciones.

Lo que implicaría hacerlo bien: una tabla `chat_messages` (id, intercambio,
autor, contenido, fecha), otra de participación con `last_read_at` por persona, y
una **migración de los datos que ya existen en `jsonb`**, incluida la base de la
demostración publicada. Después habría que reescribir `appendMessage`, el
historial del *gateway*, el mapeador del cliente y el cálculo de no leídos, que
pasaría del dispositivo al servidor.

**Costo: medio-alto, y con el único riesgo real de perder datos** de todo lo que
hemos hecho hasta ahora, porque toca migrar contenido en una base que está
publicada.

## Recomendación

**Hacer A primero y B aparte, en ese orden.** Tres razones:

1. A se nota de inmediato en la demostración y no toca la base de datos, así que
   si sale mal se revierte sin consecuencias.
2. B es el único trabajo de esta pareja que puede perder datos. Merece su propia
   sesión, con respaldo previo y su migración probada en local antes de tocar la
   base publicada.
3. A **no depende** de B. El contador de no leídos seguirá funcionando con la
   marca local mientras tanto; lo que B mejora es que esa marca deje de ser por
   dispositivo.

Lo que conviene **no** hacer: meter los dos en la misma rama. Son dos cosas que
fallan por motivos distintos y conviene poder revertir una sin la otra.

## Alternativa honesta, si el tiempo aprieta

Si el objetivo inmediato es la presentación del proyecto, el refresco manual de
T-035 ya cubre el caso de uso: la persona ve el contador y tira para actualizar.
A agrega pulido; B agrega correción de fondo. Ninguno de los dos es un requisito
para que la demostración se sostenga, y decirlo así evita empezar por obligación
algo que se empieza mejor por decisión.
