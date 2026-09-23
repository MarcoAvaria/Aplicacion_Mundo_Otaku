const path = require('node:path');
const fs = require('node:fs');
const { backendDirectory } = require('../scripts/environment');
const { randomBytes, createCipheriv } = require('node:crypto');
const { test, expect } = require('@playwright/test');

// Por omision, la API se deduce de `E2E_BACKEND_URL`, que es la misma variable
// que usan la configuracion de Playwright y el arranque del backend. Antes este
// valor tenia su propia variable y su propio puerto escrito a mano, asi que
// mover la suite a otro puerto levantaba la API en el sitio nuevo mientras las
// llamadas directas de las pruebas seguian yendo al viejo.
const backendUrl = process.env.E2E_BACKEND_URL || 'http://127.0.0.1:3001';
const apiUrl = process.env.E2E_API_URL || `${backendUrl}/api`;
const fixtureDirectory = path.resolve(__dirname, '..', '..', 'assets');

async function apiRequest(route, { token, method = 'GET', body } = {}) {
  const response = await fetch(`${apiUrl}${route}`, {
    method,
    headers: {
      ...(body ? { 'Content-Type': 'application/json' } : {}),
      ...(token ? { Authorization: `Bearer ${token}` } : {}),
    },
    body: body ? JSON.stringify(body) : undefined,
  });
  if (!response.ok) {
    throw new Error(
      `${method} ${route} respondió ${response.status}: ${await response.text()}`,
    );
  }
  return response.json();
}

// Páginas cuya semántica ya se activó: el botón solo existe la primera vez, así
// que volver a esperarlo en cada navegación costaría el tiempo de espera entero.
const semanticsEnabledPages = new WeakSet();

// Una carga real de documento (una recarga) reinicia la semántica de Flutter y
// vuelve a inyectar el botón. Un cambio de ruta por hash no, y por eso se
// escucha `load` y no `framenavigated`: si se olvidara este reinicio, tras un
// `reload()` la semántica no se activaría nunca y no se encontraría nada.
const pagesWatchedForReload = new WeakSet();

function forgetSemanticsOnReload(page) {
  if (pagesWatchedForReload.has(page)) return;
  pagesWatchedForReload.add(page);
  page.on('load', () => semanticsEnabledPages.delete(page));
}

async function enableFlutterAccessibility(page) {
  forgetSemanticsOnReload(page);
  await page.waitForFunction(() => {
    const glassPane = document.querySelector('flt-glass-pane');
    const sceneHost = glassPane?.shadowRoot?.querySelector('flt-scene-host');
    return (sceneHost?.childElementCount ?? 0) > 0;
  });

  if (semanticsEnabledPages.has(page)) return;

  // Flutter Web inyecta el botón que activa la semántica unos milisegundos
  // después de pintar la primera escena. Antes se consultaba una sola vez con
  // `count()`: si todavía no existía, la semántica no se activaba nunca y
  // cualquier `getByLabel` posterior agotaba su tiempo. De ahí que los
  // recorridos fallaran de forma intermitente en el acceso. Ahora se espera.
  const enableButton = page.getByRole('button', {
    name: 'Enable accessibility',
  });
  try {
    await enableButton.waitFor({ state: 'attached', timeout: 15_000 });
    await enableButton.evaluate((element) => element.click());
  } catch {
    // No apareció: la semántica ya venía activa en esta página.
  }
  semanticsEnabledPages.add(page);
}

async function openFlutterRoute(page, route) {
  await page.goto(`/#${route}`);
  await enableFlutterAccessibility(page);
}

async function prepareAuthenticatedContext(context, token) {
  const encryptionKey = randomBytes(32);
  const initializationVector = randomBytes(12);
  const cipher = createCipheriv(
    'aes-256-gcm',
    encryptionKey,
    initializationVector,
  );
  const encryptedToken = Buffer.concat([
    cipher.update(token, 'utf8'),
    cipher.final(),
    cipher.getAuthTag(),
  ]);

  await context.addInitScript(
    ({ key, encryptedValue }) => {
      // Sembrar una sola vez: las recargas deben recuperar el JWT real y un
      // logout no debe ser deshecho por este script de preparación.
      if (sessionStorage.getItem('e2e-auth-prepared')) return;
      sessionStorage.setItem('e2e-auth-prepared', 'true');
      localStorage.setItem('FlutterSecureStorage', key);
      localStorage.setItem(
        'FlutterSecureStorage.auth_token',
        encryptedValue,
      );
    },
    {
      key: encryptionKey.toString('base64'),
      encryptedValue: `${initializationVector.toString('base64')}.${encryptedToken.toString('base64')}`,
    },
  );
}

// Flutter Web no recibe las teclas hasta que su elemento de edicion oculto tiene
// el foco del navegador. El clic lo pide, pero el foco no llega en el mismo tick
// y en un runner headless puede tardar bastante mas que en un equipo de
// escritorio: de ahi que el recorrido del chat fallara en CI y casi nunca en
// local (T-026). Se espera la condicion en vez de un tiempo fijo.
async function waitForEditingFocus(page) {
  try {
    await page.waitForFunction(
      () => {
        const element = document.activeElement;
        if (!element) return false;
        return (
          element.tagName === 'INPUT' ||
          element.tagName === 'TEXTAREA' ||
          element.isContentEditable === true
        );
      },
      { timeout: 5_000 },
    );
  } catch {
    // Mejor esfuerzo: si no se puede confirmar, se intenta escribir igual y el
    // bucle de reintentos de quien llama sigue haciendo su trabajo.
  }
}

// Vuelca los marcos del WebSocket a la salida, para depurar el chat.
//
// Se activa con `E2E_TRACE_SOCKETS=1` y esta apagado el resto del tiempo.
// Reenvia tambien los mensajes de consola que empiecen por `[t026]`, para que
// una traza temporal puesta en el cliente aparezca intercalada con los marcos
// y se pueda leer el orden de los hechos. Fue lo que permitio cerrar T-026.
//
// Se activa con E2E_TRACE_SOCKETS=1 y no hace nada sin esa variable, asi que no
// afecta a las corridas normales ni a CI. Es la forma mas directa de ver que
// emite y que recibe cada sesion sin tocar el cliente Flutter, que se sirve ya
// compilado. Util sobre todo para T-026, la intermitencia de la reconexion.
function traceWebSockets(page, tag) {
  if (!process.env.E2E_TRACE_SOCKETS) return;
  const at = () => new Date().toISOString().slice(11, 23);
  page.on('console', (mensaje) => {
    const texto = mensaje.text();
    if (texto.includes('[t026]')) console.log(`${at()} [${tag}] ${texto}`);
  });
  page.on('websocket', (ws) => {
    console.log(`${at()} [${tag}] socket abierto`);
    ws.on('framesent', (frame) =>
      console.log(`${at()} [${tag}] >> ${String(frame.payload).slice(0, 200)}`));
    ws.on('framereceived', (frame) =>
      console.log(`${at()} [${tag}] << ${String(frame.payload).slice(0, 200)}`));
    ws.on('socketerror', (error) =>
      console.log(`${at()} [${tag}] error de socket: ${error}`));
    ws.on('close', () => console.log(`${at()} [${tag}] socket cerrado`));
  });
}

async function enterFlutterText(page, locator, value) {
  for (let entryAttempt = 0; entryAttempt < 5; entryAttempt += 1) {
    let field;
    for (let scrollAttempt = 0; scrollAttempt < 12; scrollAttempt += 1) {
      field = await locator.boundingBox();
      if (field && field.y < 900 && field.y + field.height > 56) break;

      await page.mouse.move(640, 450);
      await page.mouse.wheel(0, !field || field.y >= 900 ? 500 : -500);
      await page.waitForTimeout(100);
    }
    if (!field || field.y >= 900 || field.y + field.height <= 56) {
      throw new Error('El campo de texto no está visible.');
    }

    await page.mouse.click(
      field.x + field.width / 2,
      Math.min(895, Math.max(60, field.y + field.height / 2)),
    );
    await waitForEditingFocus(page);
    // Se teclea en vez de usar `fill`. `fill` asigna el valor del elemento del
    // DOM por programa y Flutter Web no siempre lo ingiere: el `input` del
    // navegador queda con el texto nuevo mientras el `TextEditingController`
    // del widget conserva el viejo, así que el formulario guardaba el valor
    // anterior sin avisar. Teclear recorre la ruta real de entrada, que es
    // además lo que hace una persona.
    await page.keyboard.press('Control+A');
    await page.keyboard.type(value, { delay: 5 });
    await page.waitForTimeout(150);

    if ((await locator.inputValue()) !== value) continue;
    await locator.press('Tab');
    await page.waitForTimeout(150);
    if ((await locator.inputValue()) === value) return;
  }

  throw new Error(`No fue posible ingresar el texto en ${await locator.getAttribute('aria-label')}.`);
}

// Hace clic releyendo la posicion del control y reintentando.
//
// Hace falta en Flutter Web: Playwright pulsa sobre la capa de accesibilidad
// que Flutter superpone al lienzo, y tras un redibujado esa capa puede moverse
// o reemplazarse entre que se resuelve el elemento y se pulsa. El clic se
// pierde sin error: no se ejecuta el manejador y no aparece ningun aviso.
//
// Fue la causa de T-026. Tras reconectar el chat, el boton de enviar se
// redibuja y un `.click()` pelado se perdia en cerca de la mitad de las
// corridas: el mensaje se quedaba escrito en el campo y nunca se emitia. Una
// persona en un dispositivo real no pasa por esto, porque su toque lo resuelve
// Flutter en el lienzo y no la capa del DOM.
async function clickFlutterControl(page, locator, { direction = 1 } = {}) {
  for (let attempt = 0; attempt < 15; attempt += 1) {
    if ((await locator.count()) > 0) {
      const control = await locator.boundingBox();
      if (
        control &&
        control.y + control.height > 60 &&
        control.y < 900
      ) {
        await page.mouse.click(
          control.x + control.width / 2,
          Math.max(65, Math.min(895, control.y + control.height / 2)),
        );
        return;
      }
    }

    await page.mouse.move(640, 700);
    await page.mouse.wheel(0, direction * 600);
    await page.waitForTimeout(150);
  }

  throw new Error('No fue posible encontrar el control en la pantalla.');
}

async function enterChatMessage(page, value) {
  const field = page.getByRole('textbox');
  for (let attempt = 0; attempt < 5; attempt += 1) {
    const box = await field.boundingBox();
    if (!box) throw new Error('El campo de chat no está disponible.');

    await page.mouse.click(
      box.x + box.width / 2,
      Math.min(895, Math.max(60, box.y + box.height / 2)),
    );
    await waitForEditingFocus(page);
    await page.keyboard.press('Control+A');
    await page.keyboard.type(value, { delay: 5 });
    await page.waitForTimeout(150);
    if ((await field.inputValue()) === value) return;
  }

  throw new Error('No fue posible ingresar el mensaje en el chat.');
}

// Si el elemento de edicion del navegador tiene ahora mismo el foco.
//
// Flutter Web escribe el texto en un elemento oculto del DOM. Si ese elemento
// pierde el foco, las teclas se van a la pagina y la aplicacion no se entera.
async function hasEditingFocus(page) {
  return page.evaluate(() => {
    const element = document.activeElement;
    if (!element) return false;
    return (
      element.tagName === 'INPUT' ||
      element.tagName === 'TEXTAREA' ||
      element.isContentEditable === true
    );
  });
}

// Escribe un mensaje y lo envia con Enter, comprobando antes que el campo
// conserve el foco.
//
// El campo del chat declara `onSubmitted`, asi que Enter envia igual que pulsar
// el boton, y ademas es lo que hace una persona en un teclado.
//
// La comprobacion del foco es lo que arregla T-026. Al reconectar el chat, el
// arbol se reconstruye y Flutter Web **le quita el foco** al elemento de
// edicion oculto. El texto ya escrito se queda en el, asi que todas las señales
// enganan: el elemento existe, esta visible y `inputValue()` devuelve el texto
// correcto. Pero como no esta enfocado, la tecla Enter se va a la pagina y la
// aplicacion no llega a ejecutar su manejador: no se emite nada y no hay ningun
// error. Se midio con un censo del DOM en el momento del fallo, que mostro un
// unico campo, conectado y visible, con el texto dentro y `activeElement`
// apuntando a otra parte.
//
// Por eso no basta con reintentar el envio: hay que rehacer el ciclo completo,
// porque el clic de `enterChatMessage` es lo que devuelve el foco al elemento.
//
// Una persona no pasa por esto: vuelve a tocar el campo antes de escribir.
async function sendChatMessage(page, value) {
  for (let attempt = 0; attempt < 5; attempt += 1) {
    await enterChatMessage(page, value);
    if (await hasEditingFocus(page)) {
      await page.keyboard.press('Enter');
      return;
    }
  }

  throw new Error('El campo del chat perdio el foco antes de poder enviar.');
}

async function swipeProductPhotos(page) {
  const first = page.getByRole('img', { name: 'Foto 1 de 2', exact: true });
  const second = page.getByRole('img', { name: 'Foto 2 de 2', exact: true });
  await expect(first).toBeVisible();
  const initial = await first.boundingBox();
  const center = initial.x + initial.width / 2;
  const y = initial.y + initial.height / 2;
  const grab = initial.width * 0.3;
  await page.mouse.move(center + grab, y);
  await page.mouse.down();
  await page.mouse.move(center - grab, y, { steps: 30 });
  await page.mouse.up();
  await expect.poll(async () => {
    const box = await second.boundingBox();
    return box ? Math.abs(box.x + box.width / 2 - center) : Infinity;
  }).toBeLessThan(2);
  await page.mouse.move(center - grab, y);
  await page.mouse.down();
  await page.mouse.move(center + grab, y, { steps: 30 });
  await page.mouse.up();
  await expect.poll(async () => {
    const box = await first.boundingBox();
    return box ? Math.abs(box.x + box.width / 2 - center) : Infinity;
  }).toBeLessThan(2);
}

async function login(page, email, password) {
  await openFlutterRoute(page, '/login');
  await enterFlutterText(page, page.getByLabel('El correo de tu cuenta'), email);
  await enterFlutterText(page, page.getByLabel('Contraseña'), password);
  await page.getByRole('button', { name: 'Iniciar sesión' }).click();
  await expect(
    page.getByRole('heading', { name: 'Cambia y descubre' }),
  ).toBeVisible();
  // El snackbar de bienvenida desplaza el botón flotante mientras se anima.
  await expect(page.getByLabel(
    '¡Revisa lo que la comunidad tiene para ofrecer! :)',
  )).toBeHidden();
}

async function controlTestApi(action) {
  const id = `${action}-${Date.now()}`;
  const directory = path.join(backendDirectory, '.e2e-artifacts');
  fs.writeFileSync(path.join(directory, 'api-command.json'), JSON.stringify({ id, action }));
  let state;
  await expect.poll(() => {
    try { state = JSON.parse(fs.readFileSync(path.join(directory, 'api-state.json'), 'utf8')); }
    catch { return undefined; }
    return state.id;
  }).toBe(id);
  expect(state.error).toBeUndefined();
  return state;
}

async function expectOrderedMessages(page, messages) {
  let previousY = -Infinity;
  for (const message of messages) {
    // Flutter combina el texto y la hora en la etiqueta de la burbuja.
    const locator = page.getByLabel(message);
    await expect(locator).toHaveCount(1);
    await expect(locator).toBeVisible();
    const box = await locator.boundingBox();
    expect(box.y).toBeGreaterThan(previousY);
    previousY = box.y;
  }
}

test('dos sesiones publican, intercambian, conversan y se reconectan', async ({
  browser,
}) => {
  const runId = `${Date.now()}-${process.pid}`;
  const password = 'BrowserJourney1!';
  const user1Email = `browser-user1-${runId}@mundo-otaku.test`;
  const user2Email = `browser-user2-${runId}@mundo-otaku.test`;
  const publishedTitle = `Manga navegador ${runId}`;
  const offeredTitle = `Figura ofrecida ${runId}`;
  const firstMessage = `Mensaje en vivo ${runId}`;
  const reconnectedMessage = `Mensaje tras reconexión ${runId}`;

  const user1 = await apiRequest('/auth/register', {
    method: 'POST',
    body: {
      email: user1Email,
      fullName: 'Usuario Navegador 1',
      password,
    },
  });
  const user2 = await apiRequest('/auth/register', {
    method: 'POST',
    body: {
      email: user2Email,
      fullName: 'Usuario Navegador 2',
      password,
    },
  });
  const offeredProduct = await apiRequest('/products', {
    token: user2.token,
    method: 'POST',
    body: {
      title: offeredTitle,
      typeOf: 'Otros',
      description: 'Producto preparado para el recorrido de intercambio',
      tomo: 1,
      sizeOf: 'Ninguno',
      gender: 'Ninguno',
      demographic: 'Shonen',
      tags: ['navegador'],
      images: [],
    },
  });

  const firstContext = await browser.newContext();
  const secondContext = await browser.newContext();
  await prepareAuthenticatedContext(firstContext, user1.token);
  await prepareAuthenticatedContext(secondContext, user2.token);
  const firstPage = await firstContext.newPage();
  const secondPage = await secondContext.newPage();
  traceWebSockets(firstPage, 'sesion-1');
  traceWebSockets(secondPage, 'sesion-2');

  try {
    await Promise.all([
      openFlutterRoute(firstPage, '/discover'),
      openFlutterRoute(secondPage, '/discover'),
    ]);
    await Promise.all([
      expect(
        firstPage.getByRole('heading', { name: 'Cambia y descubre' }),
      ).toBeVisible(),
      expect(
        secondPage.getByRole('heading', { name: 'Cambia y descubre' }),
      ).toBeVisible(),
    ]);

    await firstPage.getByRole('button', { name: 'Publicar' }).click();
    await expect(firstPage.getByLabel('Editar producto')).toBeVisible();
    await enterFlutterText(
      firstPage,
      firstPage.getByLabel('Nombre'),
      publishedTitle,
    );
    await enterFlutterText(firstPage, firstPage.getByLabel('Volumen | Tomo'), '7');
    await enterFlutterText(
      firstPage,
      firstPage.getByLabel('Descripción', { exact: true }),
      'Publicación creada completamente desde Chromium',
    );
    await enterFlutterText(
      firstPage,
      firstPage.getByLabel('Tags (Separados por coma)'),
      'e2e, navegador',
    );

    const firstChooserPromise = firstPage.waitForEvent('filechooser', {
      timeout: 20_000,
    });
    await firstPage
      .getByRole('button', { name: 'Agregar imagen desde galería' })
      .click();
    const firstChooser = await firstChooserPromise;
    await firstChooser.setFiles(path.join(fixtureDirectory, 'Ao_no_Hako_Vol_01.png'));
    await expect(
      firstPage.getByLabel('Imágenes del producto: 1'),
    ).toBeVisible();

    const secondChooserPromise = firstPage.waitForEvent('filechooser', {
      timeout: 20_000,
    });
    await firstPage
      .getByRole('button', { name: 'Agregar imagen desde galería' })
      .click();
    const secondChooser = await secondChooserPromise;
    await secondChooser.setFiles(path.join(fixtureDirectory, 'Bleach_Vol_01.jpg'));
    await expect(
      firstPage.getByLabel('Imágenes del producto: 2'),
    ).toBeVisible();

    const createResponsePromise = firstPage.waitForResponse(
      (response) =>
        response.url() === `${apiUrl}/products` &&
        response.request().method() === 'POST',
      { timeout: 30_000 },
    );
    await firstPage.getByRole('button', { name: 'Guardar producto' }).click();
    const createResponse = await createResponsePromise;
    expect(createResponse.status()).toBe(201);
    const publishedProduct = await createResponse.json();
    expect(publishedProduct.images).toHaveLength(2);
    await expect(firstPage.getByLabel('Producto actualizado')).toBeVisible();

    const storedProduct = (
      await apiRequest(`/products?term=${encodeURIComponent(publishedTitle)}`)
    )[0];
    expect(storedProduct.id).toBe(publishedProduct.id);
    expect(storedProduct.images).toHaveLength(2);
    for (const image of storedProduct.images) {
      const imageResponse = await fetch(`${apiUrl}/files/product/${image}`);
      expect(imageResponse.status).toBe(200);
    }

    let blockProductDetail = true;
    await openFlutterRoute(firstPage, `/product/${publishedProduct.id}`);
    await swipeProductPhotos(firstPage);
    await secondPage.route(
      `**/api/products/${publishedProduct.id}`,
      (route) => {
        if (blockProductDetail && route.request().method() === 'GET') {
          return route.abort('internetdisconnected');
        }
        return route.continue();
      },
    );
    await openFlutterRoute(secondPage, `/otherproduct/${publishedProduct.id}`);
    await expect(
      secondPage.getByLabel('No fue posible cargar el producto.'),
    ).toBeVisible();
    blockProductDetail = false;
    await secondPage.getByRole('button', { name: 'Reintentar' }).click();
    await expect(secondPage.getByLabel(publishedTitle)).toBeVisible();
    await swipeProductPhotos(secondPage);
    await expect(
      secondPage.getByRole('button', { name: 'Guardar producto' }),
    ).toHaveCount(0);
    await expect(
      secondPage.getByRole('button', {
        name: 'Agregar imagen desde galería',
      }),
    ).toHaveCount(0);
    await clickFlutterControl(
      secondPage,
      secondPage.getByRole('button', { name: 'Proponer intercambio' }),
    );
    await clickFlutterControl(
      secondPage,
      secondPage.getByRole('button', { name: offeredTitle }),
    );
    await expect(
      secondPage.getByRole('button', { name: 'Sí, enviar' }),
    ).toBeVisible();

    const exchangeResponsePromise = secondPage.waitForResponse(
      (response) =>
        response.url() === `${apiUrl}/chat-exchanges` &&
        response.request().method() === 'POST',
      { timeout: 30_000 },
    );
    await clickFlutterControl(
      secondPage,
      secondPage.getByRole('button', { name: 'Sí, enviar' }),
    );
    const exchangeResponse = await exchangeResponsePromise;
    expect(exchangeResponse.status()).toBe(201);
    const exchange = await exchangeResponse.json();
    await expect(
      secondPage.getByLabel('Propuesta enviada. Te avisaremos cuando respondan.'),
    ).toBeVisible();

    await openFlutterRoute(firstPage, `/previewreceived/${exchange.id}`);
    await expect(
      firstPage.getByRole('img', {
        name: new RegExp(`TÚ RECIBES.*${offeredTitle}`),
      }),
    ).toBeVisible();
    const acceptResponsePromise = firstPage.waitForResponse(
      (response) =>
        response.url() === `${apiUrl}/chat-exchanges/${exchange.id}/status` &&
        response.request().method() === 'PATCH',
      { timeout: 30_000 },
    );
    await clickFlutterControl(
      firstPage,
      firstPage.getByRole('button', { name: 'Aceptar el cambio', exact: true }),
    );
    // Aceptar tambien pregunta: mueve el estado del intercambio y ese cambio le
    // llega a la otra persona, asi que deshacerlo no es retroceder.
    await clickFlutterControl(
      firstPage,
      firstPage.getByRole('button', { name: 'Sí, aceptar', exact: true }),
    );
    expect((await acceptResponsePromise).status()).toBe(200);
    await expect(
      firstPage.getByLabel('¡Acción completada con éxito!'),
    ).toBeVisible();

    await Promise.all([
      openFlutterRoute(
        firstPage,
        `/chatscreen/${exchange.id}/${publishedProduct.id}/${offeredProduct.id}`,
      ),
      openFlutterRoute(
        secondPage,
        `/chatscreen/${exchange.id}/${offeredProduct.id}/${publishedProduct.id}`,
      ),
    ]);
    await Promise.all([
      expect(firstPage.getByLabel('Chat conectado')).toBeVisible(),
      expect(secondPage.getByLabel('Chat conectado')).toBeVisible(),
    ]);

    await sendChatMessage(secondPage, firstMessage);
    await expect(firstPage.getByLabel(firstMessage)).toBeVisible();

    await secondContext.setOffline(true);
    await expect(secondPage.getByLabel('Chat sin conexión')).toBeVisible();
    // Este envio TIENE que fallar y conservar el texto.
    await sendChatMessage(secondPage, reconnectedMessage);
    await expect(
      secondPage.getByLabel('Sin conexión. El mensaje no se envió.'),
    ).toBeVisible();
    await expect(secondPage.getByRole('textbox')).toHaveValue(
      reconnectedMessage,
    );

    await secondContext.setOffline(false);
    await expect(secondPage.getByLabel('Chat conectado')).toBeVisible({
      timeout: 30_000,
    });
    await sendChatMessage(secondPage, reconnectedMessage);
    await expect(firstPage.getByLabel(reconnectedMessage)).toBeVisible();

    expect(firstPage.url()).toContain(
      `#/chatscreen/${exchange.id}/${publishedProduct.id}/${offeredProduct.id}`,
    );
    await firstPage.reload();
    await enableFlutterAccessibility(firstPage);
    await expect(firstPage.getByLabel('Chat conectado')).toBeVisible({
      timeout: 30_000,
    });
    await expect(firstPage.getByLabel(firstMessage)).toBeVisible();
    await expect(firstPage.getByLabel(reconnectedMessage)).toBeVisible();

    await firstPage.reload();
    await enableFlutterAccessibility(firstPage);
    await expect(firstPage.getByLabel('Chat conectado')).toBeVisible({
      timeout: 30_000,
    });
    await expect(firstPage.getByLabel(firstMessage)).toHaveCount(1);
    await expect(firstPage.getByLabel(reconnectedMessage)).toHaveCount(1);

    const expectedMessages = [firstMessage, reconnectedMessage];
    await expectOrderedMessages(firstPage, expectedMessages);
    const beforeRestart = (await apiRequest(`/chat-exchanges/${exchange.id}`, {
      token: user2.token,
    })).messages;
    expect(beforeRestart.map((message) => message.content)).toEqual(expectedMessages);

    // Cierre real desde Flutter y acceso nuevo, sin inyectar el JWT antiguo.
    await openFlutterRoute(firstPage, '/discover');
    await firstPage.getByRole('button', { name: 'Abrir menú' }).click();
    const logoutResponse = firstPage.waitForResponse((response) =>
      response.url() === `${apiUrl}/auth/logout` && response.request().method() === 'POST');
    await firstPage.getByRole('button', { name: 'Cerrar sesión', exact: true }).click();
    // Cerrar la sesion ahora pregunta antes: la fila queda debajo del resto del
    // menu y era facil salirse sin querer.
    await clickFlutterControl(
      firstPage,
      firstPage.getByRole('button', { name: 'Sí, cerrar', exact: true }),
    );
    expect((await logoutResponse).status()).toBe(201);
    await expect(firstPage).toHaveURL(/#\/login$/);
    await expect.poll(() => firstPage.evaluate(() =>
      localStorage.getItem('FlutterSecureStorage.auth_token'))).toBeNull();
    await login(firstPage, user1Email, password);
    await openFlutterRoute(firstPage,
      `/chatscreen/${exchange.id}/${publishedProduct.id}/${offeredProduct.id}`);
    await expect(firstPage.getByLabel('Chat conectado')).toBeVisible();
    await expectOrderedMessages(firstPage, expectedMessages);

    const oldState = JSON.parse(fs.readFileSync(
      path.join(backendDirectory, '.e2e-artifacts', 'api-state.json'), 'utf8'));
    try {
      expect((await controlTestApi('stop')).pid).toBeNull();
      await expect(firstPage.getByLabel('Chat sin conexión')).toBeVisible();
      await expect(secondPage.getByLabel('Chat sin conexión')).toBeVisible();
    } finally {
      const newState = await controlTestApi('start');
      expect(newState.pid).not.toBe(oldState.pid);
    }
    await expect.poll(async () => {
      try { return (await fetch(`${apiUrl}/health`)).status; }
      catch { return 0; }
    }, { timeout: 60_000 }).toBe(200);
    await expect(firstPage.getByLabel('Chat conectado')).toBeVisible({ timeout: 60_000 });
    await expect(secondPage.getByLabel('Chat conectado')).toBeVisible({ timeout: 60_000 });
    await expectOrderedMessages(firstPage, expectedMessages);
    await expectOrderedMessages(secondPage, expectedMessages);
    expect((await apiRequest(`/chat-exchanges/${exchange.id}`, {
      token: user2.token,
    })).messages).toEqual(beforeRestart);

    const afterWakeMessage = `Mensaje después de despertar ${runId}`;
    await sendChatMessage(firstPage, afterWakeMessage);
    expectedMessages.push(afterWakeMessage);
    await expectOrderedMessages(secondPage, expectedMessages);
    await firstPage.reload();
    await enableFlutterAccessibility(firstPage);
    await expect(firstPage.getByLabel('Chat conectado')).toBeVisible();
    await expectOrderedMessages(firstPage, expectedMessages);

    const completedResponsePromise = firstPage.waitForResponse(
      (response) =>
        response.url() === `${apiUrl}/chat-exchanges/${exchange.id}/status` &&
        response.request().method() === 'PATCH',
      { timeout: 30_000 },
    );
    await firstPage
      .getByRole('button', { name: 'Opciones del intercambio' })
      .click();
    await firstPage.getByLabel('Marcar como completado').click();
    await firstPage.getByRole('button', { name: 'Completar' }).click();
    expect((await completedResponsePromise).status()).toBe(200);

    const completedExchange = await apiRequest(`/chat-exchanges/${exchange.id}`, {
      token: user2.token,
    });
    expect(completedExchange.status).toBe('done');
    expect(completedExchange.messages.map((message) => message.content)).toEqual(expectedMessages);
  } finally {
    await Promise.allSettled([firstContext.close(), secondContext.close()]);
  }
});

test('el propietario edita, rechaza una imagen inválida y elimina su producto', async ({
  browser,
}) => {
  const runId = `${Date.now()}-${process.pid}`;
  const password = 'BrowserOwnership1!';
  const originalTitle = `Producto editable ${runId}`;
  const editedTitle = `Producto editado ${runId}`;
  const user = await apiRequest('/auth/register', {
    method: 'POST',
    body: {
      email: `browser-owner-${runId}@mundo-otaku.test`,
      fullName: 'Propietario Navegador',
      password,
    },
  });
  const product = await apiRequest('/products', {
    token: user.token,
    method: 'POST',
    body: {
      title: originalTitle,
      typeOf: 'Otros',
      description: 'Producto para comprobar edición y eliminación',
      tomo: 1,
      sizeOf: 'Ninguno',
      gender: 'Ninguno',
      demographic: 'Shonen',
      tags: ['propiedad'],
      images: [],
    },
  });

  const context = await browser.newContext();
  await prepareAuthenticatedContext(context, user.token);
  const page = await context.newPage();

  try {
    await openFlutterRoute(page, `/product/${product.id}`);
    await expect(page.getByLabel('Editar producto')).toBeVisible();
    await enterFlutterText(page, page.getByLabel('Nombre'), editedTitle);

    const editResponsePromise = page.waitForResponse(
      (response) =>
        response.url() === `${apiUrl}/products/${product.id}` &&
        response.request().method() === 'PATCH',
      { timeout: 30_000 },
    );
    await page.getByRole('button', { name: 'Guardar producto' }).click();
    expect((await editResponsePromise).status()).toBe(200);
    await expect(page.getByLabel('Producto actualizado')).toBeVisible();

    const storedProduct = await apiRequest(`/products/${product.id}`);
    expect(storedProduct.title).toBe(editedTitle);

    const chooserPromise = page.waitForEvent('filechooser', {
      timeout: 20_000,
    });
    await page
      .getByRole('button', { name: 'Agregar imagen desde galería' })
      .click();
    const chooser = await chooserPromise;
    await chooser.setFiles({
      name: 'contenido-invalido.png',
      mimeType: 'image/png',
      buffer: Buffer.from('esto no es una imagen'),
    });
    await expect(
      page.getByLabel('El archivo seleccionado no es una imagen válida.'),
    ).toBeVisible();
    await expect(page.getByLabel('Imágenes del producto: 0')).toBeVisible();

    await page.getByRole('button', { name: 'Eliminar producto' }).click();
    await expect(
      page.getByRole('button', { name: 'Eliminar', exact: true }),
    ).toBeVisible();
    const deleteResponsePromise = page.waitForResponse(
      (response) =>
        response.url() === `${apiUrl}/products/${product.id}` &&
        response.request().method() === 'DELETE',
      { timeout: 30_000 },
    );
    await page.getByRole('button', { name: 'Eliminar', exact: true }).click();
    expect((await deleteResponsePromise).status()).toBe(200);
    await expect(page).toHaveURL(/#\/productos$/);

    const deletedResponse = await fetch(`${apiUrl}/products/${product.id}`);
    expect(deletedResponse.status).toBe(404);
  } finally {
    await context.close();
  }
});

test('informa un error de red sin abandonar la pantalla de acceso', async ({
  page,
}) => {
  await openFlutterRoute(page, '/login');
  await page.route('**/api/auth/login', (route) => route.abort('internetdisconnected'));
  await enterFlutterText(
    page,
    page.getByLabel('El correo de tu cuenta'),
    'red-caida@mundo-otaku.test',
  );
  await enterFlutterText(page, page.getByLabel('Contraseña'), 'NetworkError1!');
  await page.getByRole('button', { name: 'Iniciar sesión' }).click();

  await expect(
    page.getByLabel(
      'No fue posible conectar con el servidor. Revisa tu conexión.',
    ),
  ).toBeVisible();
  await expect(page).toHaveURL(/#\/login$/);
});

test('informa fallos de listas, permite reintentar y explica estados vacíos', async ({
  browser,
}) => {
  const runId = `${Date.now()}-${process.pid}`;
  const user = await apiRequest('/auth/register', {
    method: 'POST',
    body: {
      email: `browser-empty-${runId}@mundo-otaku.test`,
      fullName: 'Usuario Listas Vacías',
      password: 'BrowserEmpty1!',
    },
  });
  const context = await browser.newContext();
  await prepareAuthenticatedContext(context, user.token);
  const page = await context.newPage();

  try {
    let blockProducts = true;
    await page.route('**/api/products*', (route) => {
      if (blockProducts && route.request().method() === 'GET') {
        return route.abort('internetdisconnected');
      }
      return route.continue();
    });

    await openFlutterRoute(page, '/productos');
    await expect(
      page.getByLabel('No fue posible cargar los productos.'),
    ).toBeVisible();
    blockProducts = false;
    await clickFlutterControl(page, page.getByRole('button', { name: 'Reintentar' }));
    await expect(
      page.getByLabel(/Tu estante está vacío/),
    ).toBeVisible();

    let blockExchanges = true;
    await page.route('**/api/chat-exchanges/user/**', (route) => {
      if (blockExchanges) {
        return route.abort('internetdisconnected');
      }
      return route.continue();
    });

    await openFlutterRoute(page, '/requestedList');
    await expect(
      page.getByLabel('No fue posible cargar los intercambios.'),
    ).toBeVisible();
    blockExchanges = false;
    await clickFlutterControl(page, page.getByRole('button', { name: 'Reintentar' }));
    await expect(
      page.getByLabel('No tienes solicitudes enviadas pendientes.'),
    ).toBeVisible();

    await openFlutterRoute(page, '/receivedList');
    await expect(
      page.getByLabel('No tienes solicitudes recibidas pendientes.'),
    ).toBeVisible();

    await openFlutterRoute(page, '/chatList');
    await expect(
      page.getByLabel(/[Nn]o tienes intercambios aceptados/),
    ).toBeVisible();
  } finally {
    await context.close();
  }
});

test('cierra la sesión cuando el token se revoca durante una edición', async ({
  browser,
}) => {
  const runId = `${Date.now()}-${process.pid}`;
  const password = 'BrowserExpired1!';
  const user = await apiRequest('/auth/register', {
    method: 'POST',
    body: {
      email: `browser-expired-${runId}@mundo-otaku.test`,
      fullName: 'Sesión Revocada',
      password,
    },
  });
  const product = await apiRequest('/products', {
    token: user.token,
    method: 'POST',
    body: {
      title: `Producto sesión ${runId}`,
      typeOf: 'Otros',
      description: 'Producto para revocar la sesión activa',
      tomo: 1,
      sizeOf: 'Ninguno',
      gender: 'Ninguno',
      demographic: 'Shonen',
      tags: ['sesión'],
      images: [],
    },
  });

  const context = await browser.newContext();
  await prepareAuthenticatedContext(context, user.token);
  const page = await context.newPage();

  try {
    await openFlutterRoute(page, `/product/${product.id}`);
    await expect(page.getByLabel('Editar producto')).toBeVisible();
    await apiRequest('/auth/logout', {
      token: user.token,
      method: 'POST',
    });

    const unauthorizedResponse = page.waitForResponse(
      (response) =>
        response.url() === `${apiUrl}/products/${product.id}` &&
        response.request().method() === 'PATCH' &&
        response.status() === 401,
      { timeout: 30_000 },
    );
    await page.getByRole('button', { name: 'Guardar producto' }).click();
    await unauthorizedResponse;

    await expect(page).toHaveURL(/#\/login$/);
    await expect(page.getByLabel('El correo de tu cuenta')).toBeVisible();
    await expect(
      page.getByLabel('Tu sesión expiró. Inicia sesión nuevamente.'),
    ).toBeVisible();
  } finally {
    await context.close();
  }
});

test('el remitente cancela y el receptor rechaza solicitudes pendientes', async ({
  browser,
}) => {
  const runId = `${Date.now()}-${process.pid}`;
  const password = 'BrowserAlternatives1!';
  const receiver = await apiRequest('/auth/register', {
    method: 'POST',
    body: {
      email: `browser-receiver-${runId}@mundo-otaku.test`,
      fullName: 'Receptor Alternativas',
      password,
    },
  });
  const sender = await apiRequest('/auth/register', {
    method: 'POST',
    body: {
      email: `browser-sender-${runId}@mundo-otaku.test`,
      fullName: 'Remitente Alternativas',
      password,
    },
  });
  const requestedProduct = await apiRequest('/products', {
    token: receiver.token,
    method: 'POST',
    body: {
      title: `Producto solicitado ${runId}`,
      typeOf: 'Otros',
      description: 'Producto del receptor',
      tomo: 1,
      sizeOf: 'Ninguno',
      gender: 'Ninguno',
      demographic: 'Shonen',
      tags: ['alternativas'],
      images: [],
    },
  });
  const offeredProduct = await apiRequest('/products', {
    token: sender.token,
    method: 'POST',
    body: {
      title: `Producto ofrecido ${runId}`,
      typeOf: 'Otros',
      description: 'Producto del remitente',
      tomo: 1,
      sizeOf: 'Ninguno',
      gender: 'Ninguno',
      demographic: 'Shonen',
      tags: ['alternativas'],
      images: [],
    },
  });
  const createExchange = () =>
    apiRequest('/chat-exchanges', {
      token: sender.token,
      method: 'POST',
      body: {
        product1: requestedProduct.id,
        product2: offeredProduct.id,
        requester1: offeredProduct.id,
      },
    });

  const senderContext = await browser.newContext();
  const receiverContext = await browser.newContext();
  const senderPage = await senderContext.newPage();
  const receiverPage = await receiverContext.newPage();

  try {
    await Promise.all([
      login(senderPage, sender.email, password),
      login(receiverPage, receiver.email, password),
    ]);
    const cancelledExchange = await createExchange();
    let blockRequestDetail = true;
    await senderPage.route(
      `**/api/chat-exchanges/${cancelledExchange.id}`,
      (route) => {
        if (blockRequestDetail && route.request().method() === 'GET') {
          return route.abort('internetdisconnected');
        }
        return route.continue();
      },
    );
    await openFlutterRoute(
      senderPage,
      `/previewrequested/${cancelledExchange.id}`,
    );
    await expect(
      senderPage.getByLabel('No fue posible cargar la solicitud.'),
    ).toBeVisible();
    blockRequestDetail = false;
    await senderPage.getByRole('button', { name: 'Reintentar' }).click();
    await expect(
      senderPage.getByRole('img', {
        name: new RegExp(`TÚ ENTREGAS.*${offeredProduct.title}`),
      }),
    ).toBeVisible();
    const cancelResponse = senderPage.waitForResponse(
      (response) =>
        response.url() ===
          `${apiUrl}/chat-exchanges/${cancelledExchange.id}/status` &&
        response.request().method() === 'PATCH',
      { timeout: 30_000 },
    );
    await clickFlutterControl(
      senderPage,
      senderPage.getByRole('button', { name: 'Cancelar la propuesta', exact: true }),
    );
    await clickFlutterControl(
      senderPage,
      senderPage.getByRole('button', { name: 'Sí, cancelar', exact: true }),
    );
    expect((await cancelResponse).status()).toBe(200);
    await expect(
      senderPage.getByLabel('Se ha cancelado la solicitud'),
    ).toBeVisible();
    expect(
      (await apiRequest(`/chat-exchanges/${cancelledExchange.id}`, {
        token: sender.token,
      })).status,
    ).toBe('abort');

    const rejectedExchange = await createExchange();
    await openFlutterRoute(
      receiverPage,
      `/previewreceived/${rejectedExchange.id}`,
    );
    await expect(
      receiverPage.getByRole('img', {
        name: new RegExp(`TÚ RECIBES.*${offeredProduct.title}`),
      }),
    ).toBeVisible();
    const rejectResponse = receiverPage.waitForResponse(
      (response) =>
        response.url() ===
          `${apiUrl}/chat-exchanges/${rejectedExchange.id}/status` &&
        response.request().method() === 'PATCH',
      { timeout: 30_000 },
    );
    await clickFlutterControl(
      receiverPage,
      receiverPage.getByRole('button', { name: 'Rechazar', exact: true }),
    );
    await clickFlutterControl(
      receiverPage,
      receiverPage.getByRole('button', { name: 'Sí, rechazar', exact: true }),
    );
    expect((await rejectResponse).status()).toBe(200);
    await expect(
      receiverPage.getByLabel('Se ha rechazado la solicitud'),
    ).toBeVisible();
    expect(
      (await apiRequest(`/chat-exchanges/${rejectedExchange.id}`, {
        token: receiver.token,
      })).status,
    ).toBe('rejected');
  } finally {
    await Promise.allSettled([
      senderContext.close(),
      receiverContext.close(),
    ]);
  }
});
