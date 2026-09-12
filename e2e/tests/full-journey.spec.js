const path = require('node:path');
const { randomBytes, createCipheriv } = require('node:crypto');
const { test, expect } = require('@playwright/test');

const apiUrl = process.env.E2E_API_URL || 'http://127.0.0.1:3001/api';
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

async function enableFlutterAccessibility(page) {
  await page.waitForFunction(() => {
    const glassPane = document.querySelector('flt-glass-pane');
    const sceneHost = glassPane?.shadowRoot?.querySelector('flt-scene-host');
    return (sceneHost?.childElementCount ?? 0) > 0;
  });
  const enableButton = page.getByRole('button', {
    name: 'Enable accessibility',
  });
  if ((await enableButton.count()) > 0) {
    await enableButton.evaluate((element) => element.click());
  }
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
    await page.waitForTimeout(100);
    await locator.fill(value);
    await page.waitForTimeout(150);

    if ((await locator.inputValue()) !== value) continue;
    await locator.press('Tab');
    await page.waitForTimeout(150);
    if ((await locator.inputValue()) === value) return;
  }

  throw new Error(`No fue posible ingresar el texto en ${await locator.getAttribute('aria-label')}.`);
}

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
    await page.keyboard.press('Control+A');
    await page.keyboard.type(value, { delay: 5 });
    await page.waitForTimeout(150);
    if ((await field.inputValue()) === value) return;
  }

  throw new Error('No fue posible ingresar el mensaje en el chat.');
}

async function login(page, email, password) {
  await openFlutterRoute(page, '/login');
  await enterFlutterText(page, page.getByLabel('El correo de tu cuenta'), email);
  await enterFlutterText(page, page.getByLabel('Contraseña'), password);
  await page.getByRole('button', { name: 'Iniciar sesión' }).click();
  await expect(
    page.getByRole('heading', { name: '¡Cambia y descubre!' }),
  ).toBeVisible();
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

  try {
    await Promise.all([
      openFlutterRoute(firstPage, '/discover'),
      openFlutterRoute(secondPage, '/discover'),
    ]);
    await Promise.all([
      expect(
        firstPage.getByRole('heading', { name: '¡Cambia y descubre!' }),
      ).toBeVisible(),
      expect(
        secondPage.getByRole('heading', { name: '¡Cambia y descubre!' }),
      ).toBeVisible(),
    ]);

    await firstPage.getByRole('button', { name: 'Nuevo producto' }).click();
    await expect(firstPage.getByLabel('Editar producto')).toBeVisible();
    await enterFlutterText(
      firstPage,
      firstPage.getByLabel('Nombre'),
      publishedTitle,
    );
    await enterFlutterText(firstPage, firstPage.getByLabel('Volumen | Tomo'), '7');
    await enterFlutterText(
      firstPage,
      firstPage.getByLabel('Descripción'),
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

    await openFlutterRoute(secondPage, `/otherproduct/${publishedProduct.id}`);
    await expect(secondPage.getByLabel(publishedTitle)).toBeVisible();
    await clickFlutterControl(
      secondPage,
      secondPage.getByRole('button', { name: '¡Propone un cambio :)!' }),
    );
    await clickFlutterControl(
      secondPage,
      secondPage.getByLabel(offeredTitle, { exact: true }),
    );
    await expect(secondPage.getByLabel('Confirmación')).toBeVisible();

    const exchangeResponsePromise = secondPage.waitForResponse(
      (response) =>
        response.url() === `${apiUrl}/chat-exchanges` &&
        response.request().method() === 'POST',
      { timeout: 30_000 },
    );
    await clickFlutterControl(
      secondPage,
      secondPage.getByRole('button', { name: '¡Sí! Quiero cambiar :D' }),
    );
    const exchangeResponse = await exchangeResponsePromise;
    expect(exchangeResponse.status()).toBe(201);
    const exchange = await exchangeResponse.json();
    await expect(
      secondPage.getByLabel('Se ha enviado solicitud de conversación :D !'),
    ).toBeVisible();

    await openFlutterRoute(firstPage, `/previewreceived/${exchange.id}`);
    await expect(
      firstPage.getByLabel(`Te ofrecen: ${offeredTitle}`),
    ).toBeVisible();
    const acceptResponsePromise = firstPage.waitForResponse(
      (response) =>
        response.url() === `${apiUrl}/chat-exchanges/${exchange.id}/status` &&
        response.request().method() === 'PATCH',
      { timeout: 30_000 },
    );
    await clickFlutterControl(
      firstPage,
      firstPage.getByRole('button', { name: 'Aceptar' }),
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

    await enterChatMessage(secondPage, firstMessage);
    await secondPage.getByRole('button', { name: 'Enviar mensaje' }).click();
    await expect(firstPage.getByLabel(firstMessage)).toBeVisible();

    await secondContext.setOffline(true);
    await expect(secondPage.getByLabel('Chat sin conexión')).toBeVisible();
    await enterChatMessage(secondPage, reconnectedMessage);
    await secondPage.getByRole('button', { name: 'Enviar mensaje' }).click();
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
    await secondPage.getByRole('button', { name: 'Enviar mensaje' }).click();
    await expect(firstPage.getByLabel(reconnectedMessage)).toBeVisible();

    await firstPage.reload();
    await enableFlutterAccessibility(firstPage);
    await expect(firstPage.getByLabel('Chat conectado')).toBeVisible({
      timeout: 30_000,
    });
    await expect(firstPage.getByLabel(firstMessage)).toBeVisible();
    await expect(firstPage.getByLabel(reconnectedMessage)).toBeVisible();

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
      token: user1.token,
    });
    expect(completedExchange.status).toBe('done');
    expect(completedExchange.messages).toHaveLength(2);
  } finally {
    await Promise.allSettled([firstContext.close(), secondContext.close()]);
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
