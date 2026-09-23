# Cuánto cuesta abrir el tiempo real (T-036)

**Estado:** evaluación hecha y **frente A implementado**. Sin commit · **Fecha:** 2026-09-23 · **Rama:** `feature/tiempo-real`

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

> **Hecho el 2026-09-23.** La estimación de abajo se cumplió: el trabajo en sí
> fue corto y **lo caro resultó ser exactamente lo que se había anticipado, la
> prueba**. Detalle al final de esta sección.

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

### Cómo quedó, y qué costó de verdad

En el servidor, un `RealtimeNotifierService` en su propio módulo. Esa parte no es
capricho: el *gateway* ya dependía del servicio de intercambios, así que el
servicio no podía depender del *gateway* para avisar. Un módulo que no importa a
ninguno de los dos, y que los dos importan, rompe el ciclo.

Cada persona entra a su sala al autenticar el socket, y el servicio avisa
**después de confirmar la transacción**: si el aviso saliera antes y la escritura
fallara, la otra persona vería un cambio que nunca ocurrió. Por esa sala viaja
solo el identificador del intercambio.

En el cliente, el socket expone los avisos como flujo y se enganchan en el mixin
que Chats, Enviadas y Recibidas ya compartían, así que un solo punto cubre las
tres pantallas.

**La prueba costó más que el código, y conviene decir por qué.** El primer
intento fue colgar la comprobación del recorrido largo de dos sesiones, y ahí se
tropezó con dos problemas ajenos: la lista de chats cargada en frío aparece vacía
(quedó como T-041) y la navegación por el menú no resultó fiable desde esa
pantalla. Se cambió por una **prueba propia y corta**, que prepara el intercambio
por la API y mide el marco del WebSocket en vez de la interfaz. Medir el marco es
deliberado: el aviso es lo que esta pieza introduce, y así la prueba no depende de
cómo cada pantalla decida refrescarse. De paso fija la garantía que importa, que
por la sala personal **no** viaje el contenido del mensaje.

La lección, que ya había aparecido con T-026: **una comprobación nueva colgada de
un recorrido largo hereda toda su fragilidad**. Sale más barato un recorrido
propio y corto.

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

## La entidad "Cambio" ya existe

Marco preguntó si había un objeto "Cambio" con un atributo de estado, o si había
que crearlo. **Ya está**: es `ChatExchange`, la tabla `chat_exchanges`, y su
atributo `status` es exactamente eso.

```ts
@Column({
  type: 'enum',
  enum: ['pending', 'abort', 'rejected', 'inProgress', 'done', 'cancelled'],
  default: 'pending',
})
status: string;
```

Cada intercambio guarda además los dos productos, los dos dueños y quién lo
propuso. Las transiciones que usa la aplicación hoy:

| Desde | Acción | Hacia |
| --- | --- | --- |
| `pending` | quien propuso se arrepiente | `abort` |
| `pending` | quien recibe rechaza | `rejected` |
| `pending` | quien recibe acepta | `inProgress` |
| `inProgress` | el intercambio se concreta | `done` |
| `inProgress` | alguno lo deja sin efecto | `cancelled` |

Esto confirma el punto de Marco sobre la confirmación al aceptar: **no hay
ninguna transición que devuelva a `pending`**. Arrepentirse de aceptar no es
retroceder, es avanzar a `cancelled`, y ese movimiento la otra persona también
lo ve. Por eso aceptar ahora pregunta, igual que rechazar y cancelar.

### Lo que sí falta, y es lo que conviene planificar

El objeto existe, pero **no guarda nada sobre su propia historia**:

- **No hay fechas.** La tabla no tiene `createdAt` ni `updatedAt`, así que no se
  puede saber cuándo se propuso un intercambio ni cuándo se aceptó. Ordenar las
  bandejas por antigüedad hoy no es posible.
- **No hay registro de quién cambió el estado.** Con dos participantes y
  transiciones que ambos pueden disparar (`cancelled` la puede provocar
  cualquiera), no queda rastro de quién hizo qué.
- **Solo se conserva el estado actual.** Al pasar a `cancelled` se pierde que
  antes estuvo `inProgress`; no hay historial.
- Dos estados se parecen lo suficiente como para confundir a quien lea el código
  más adelante: `abort` (quien propuso retiró la propuesta) y `cancelled` (el
  intercambio ya aceptado se deja sin efecto). Los nombres no lo dicen solos.

Lo mínimo razonable sería agregar `createdAt` y `updatedAt` —barato, sin migrar
contenido, solo columnas nuevas con valor por omisión— y dejar el historial de
transiciones para el frente B, que ya va a tocar el esquema de todos modos. Ese
historial encaja naturalmente con la tabla de mensajes: ambos son "cosas que
pasaron en este intercambio, en orden".

## Qué cuesta esto en planes gratuitos

Marco preguntó, con razón, cuánto cuesta esto cuando todo corre en planes
gratuitos: la API en Render y PostgreSQL en Neon. La respuesta es mejor de lo que
parece, y conviene entender por qué.

**Empujar no es lo mismo que preguntar.** La alternativa intuitiva a "avisar" es
"preguntar cada cierto rato", y esa sí sale cara: con un sondeo cada diez
segundos, una sola persona con la aplicación abierta genera unas 360 consultas
por hora, y cada una despierta la base. El frente A **no consulta nada**: el
servidor ya tiene el dato en la mano porque acaba de guardarlo, y emitir el aviso
no toca la base de datos. Cuesta un mensaje por WebSocket, y solo cuando algo
pasa de verdad.

Comparado con lo que hay hoy, el frente A **ahorra** trabajo: cada vez que
alguien tira para refrescar sin que haya nada nuevo, eso sí es una consulta.

**Lo que sí consume es la conexión abierta.** El plan gratuito de Render suspende
el servicio tras un rato sin tráfico, y un WebSocket abierto cuenta como tráfico:
mientras alguien tenga la sesión iniciada, el servicio no se suspende. Para una
demostración eso juega a favor —desaparece el arranque en frío de casi un
minuto—, pero consume horas de instancia del plan gratuito. Con las dos cuentas
de demostración no es un problema; conviene tenerlo presente si algún día hay
muchas sesiones simultáneas.

**El frente B también abarata el funcionamiento**, aunque no lo parezca. Hoy cada
mensaje reescribe el arreglo `jsonb` completo: mientras más larga la conversación,
más bytes se escriben por mensaje. Una tabla de mensajes escribe una fila y
siempre cuesta lo mismo. O sea que B no es solo "más ordenado": en un plan con
cómputo limitado, es **menos** trabajo por mensaje. Su costo está en la migración,
no en el día a día.

**Una observación aparte que conviene no perder de vista:** las imágenes de los
productos se guardan dentro de PostgreSQL (`IMAGE_STORAGE_DRIVER=postgres`). Eso
simplificó el despliegue, pero el almacenamiento de la base gratuita es el recurso
más fácil de agotar, y las imágenes pesan mucho más que el texto. Si en algún
momento aprieta el límite, ese es el primer lugar donde mirar, antes que los
mensajes.

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
