# Historial de chat R-34 — 17 de septiembre de 2026

Se reprodujo un fallo real al cerrar sesión y volver a entrar sin cerrar la pestaña: la API REST permitía acceder al intercambio, pero el chat quedaba vacío y sin conexión. Los mensajes seguían en PostgreSQL.

## Causa y corrección

`socket_io_client` 2.0.3+1 conserva un manager por origen. Para una URL sin ruta, su caché puede devolver el socket anterior, con la autenticación revocada, incluso después de `dispose()`. La prueba `socket_session_test.dart` falló al comprobar que una sesión nueva recibía exactamente el mismo objeto de socket.

`SocketService.initialize` ahora usa `enableForceNew()` cuando crea una conexión para un token diferente. Inicializar otra vez el mismo token conserva la conexión ya existente. Se mantiene el protocolo, almacenamiento y contenido de los mensajes.

## Comprobación reproducible

El recorrido `dos sesiones publican, intercambian, conversan y se reconectan` usa Chrome, Flutter Web y NestJS compilados y una base PostgreSQL efímera `mundo_otaku_e2e_test`:

1. Envía dos mensajes, incluyendo desconexión de red y reconexión.
2. Recarga dos veces y exige una sola aparición de cada mensaje, en orden vertical.
3. Cierra sesión desde el menú de Flutter, comprueba el POST de logout (201), la eliminación del token local y el nuevo acceso.
4. Vuelve al chat y comprueba el mismo historial, sin inyectar nuevamente el JWT inicial.
5. Termina el proceso NestJS de pruebas y espera que ambas sesiones indiquen desconexión.
6. Arranca otro proceso (PID distinto) sobre la misma base, espera salud HTTP 200 y reconexión de ambas sesiones.
7. Compara todo el JSON del historial, incluidos remitentes y timestamps, contra el anterior al reinicio; comprueba orden visual y ausencia de duplicados.
8. Envía un tercer mensaje tras despertar, recarga y comprueba los tres mensajes ordenados, también al completar el intercambio.

El runner controla exclusivamente su proceso hijo mediante archivos locales en `.e2e-artifacts`, sin endpoints nuevos en la API. La limpieza retira la base y los archivos temporales. El JWT de preparación se instala una sola vez por pestaña, de modo que las recargas comprueban realmente el almacenamiento de sesión.

Ejecución focalizada aprobada: 1/1 recorrido, 40,8 segundos. Prueba unitaria de regresión roja antes del arreglo y verde después; suite Flutter 23/23, análisis sin hallazgos y builds web release/Android debug aprobados con JDK 17.

Regresión final: `npm test` con los builds ya comprobados y Chrome local → 8/8 controles Node y 6/6 recorridos Playwright (1,0 min), incluido el reinicio. Los clics de reintento usan el helper de coordenadas de Flutter para evitar un segundo clic sobre un nodo semántico que desaparece al recuperarse la pantalla.

## Alcance

El reinicio es real y local; reproduce la pérdida del proceso de la API mientras PostgreSQL persiste. No se suspendió ni redeployó Render, no se modificaron los usuarios demo y no se midió el tiempo de arranque del proveedor. Estos resultados no implican un nuevo despliegue público: el cambio se entrega en un commit local.
