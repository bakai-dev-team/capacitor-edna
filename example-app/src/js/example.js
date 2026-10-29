import { Capacitor } from '@capacitor/core';
import { BakaiEdna } from 'bakai-capacitor-edna';

const form = document.getElementById('chat-form');
const status = document.getElementById('status');
let initializedConfig;
let busy = false;
const value = (id) => document.getElementById(id).value.trim();

async function run(operation) {
  if (busy) return;
  if (!Capacitor.isNativePlatform()) {
    status.textContent = 'Чат работает только в нативном приложении Android или iOS.';
    return;
  }
  busy = true;
  form.querySelectorAll('button').forEach((button) => { button.disabled = true; });
  try {
    await operation();
  } catch (error) {
    // Do not print credentials or arbitrary SDK/server error text.
    const codes = ['INVALID_ARGUMENT', 'NOT_INITIALIZED', 'NOT_AUTHORIZED', 'ALREADY_INITIALIZED',
      'CHAT_BUSY', 'CHAT_ALREADY_OPEN', 'NO_ACTIVITY', 'LOGOUT_REQUIRED', 'EDNA_ERROR'];
    const code = codes.includes(error?.code) ? error.code : 'UNKNOWN';
    status.textContent = `Не удалось выполнить действие (${code}). Проверьте настройки и состояние сессии.`;
  } finally {
    busy = false;
    form.querySelectorAll('button').forEach((button) => { button.disabled = false; });
  }
}

form.addEventListener('submit', (event) => {
  event.preventDefault();
  void run(async () => {
    const config = {
      providerUid: value('providerUid'), appMarker: value('appMarker'),
      restUrl: value('restUrl'), webSocketUrl: value('webSocketUrl'), dataStoreUrl: value('dataStoreUrl'),
    };
    const configKey = JSON.stringify(config);
    if (initializedConfig && initializedConfig !== configKey) {
      status.textContent = 'Чтобы сменить стенд, полностью перезапустите приложение.';
      return;
    }
    if (!initializedConfig) {
      await BakaiEdna.initialize(config);
      initializedConfig = configKey;
    }
    await BakaiEdna.authorize({ userId: value('userId'), token: value('token') || undefined, scheme: value('scheme') || undefined });
    await BakaiEdna.openChat({ prefilledMessage: value('prefilledMessage') || undefined });
    status.textContent = 'Команда открытия передана SDK. Проверьте отправку и получение сообщения в чате.';
  });
});

document.getElementById('lock').addEventListener('click', () => {
  void run(async () => {
    await BakaiEdna.lockChat();
    status.textContent = 'Экран заблокирован. Кнопка открытия повторно авторизует клиента.';
  });
});

document.getElementById('logout').addEventListener('click', () => {
  void run(async () => {
    await BakaiEdna.logout();
    document.getElementById('token').value = '';
    status.textContent = 'Команда выхода выполнена. Можно авторизовать другого клиента.';
  });
});
