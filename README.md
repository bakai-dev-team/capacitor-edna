# bakai-capacitor-edna

Нативный чат edna для Capacitor 8. JavaScript-экспорт: `BakaiEdna`.
Android написан на Kotlin, iOS — на Swift. Angular/Ionic не требуются самому плагину.

## Зависимости

- Node.js 22+, Capacitor 8.
- Android: JDK 21, Android SDK 36, Gradle 8.14.3; SDK edna 5.23.0.
- iOS: deployment target 15.0, Xcode с поддержкой приложенного Swift framework.
  В `ios/Frameworks/ChatCenterUI.xcframework` находится SDK 5.9.0.
  Он подключён через CocoaPods (`.podspec`) и Swift Package Manager (`Package.swift`).

Версии SDK должны соответствовать вашему серверному стенду edna.
Сборка этого нового пакета и реальные сообщения/пуши ещё не проверены.

## Сборка пакета вручную

Из папки `capacitor-edna`:

```sh
npm install
npm run check
npm run build
```

`check` проверяет TypeScript без генерации файлов. `build` обновляет `dist` и
раздел API README, но не собирает Android/iOS.
Нативные проверки запускаются отдельно:

```sh
npm run verify:android
npm run verify:ios
```

Для проверки состава пакета после сборки: `npm pack --dry-run`.
Для создания архива: `npm pack`. Framework включён в список `files` npm-пакета.
`dist` генерируется локально и не хранится в Git. После изменения TypeScript
обязательно пересоберите пакет до подключения к приложению.

## Подключение в банкинг

После сборки пакета, из корня `mobile-banking`:

```sh
npm install ../capacitor-edna
npx cap sync
```

Это заменит прежнюю файловую зависимость `../bakai-capacitor-edna`.
Само имя npm-пакета остаётся `bakai-capacitor-edna`, поэтому JS-импорт не меняется.

Android Maven edna регистрируется плагином для всех проектов сборки с фильтром
`exclusiveContent` для групп `edna.*`. В обычном проекте Capacitor отдельный
Maven-блок в приложении не нужен. При использовании `PREFER_SETTINGS`/
`FAIL_ON_PROJECT_REPOS` потребуется перенести настройку репозиториев в
`settings.gradle` и согласовать её с регистрацией репозиториев в плагине.

На iOS Swift-модуль при CocoaPods называется `BakaiCapacitorEdna`,
при SPM — `BakaiEdnaPlugin`. Учитывайте это для нативного импорта `EdnaPush`.

## Использование

```ts
import { BakaiEdna } from 'bakai-capacitor-edna';

// Один раз за время жизни нативного экземпляра плагина.
await BakaiEdna.initialize({
  providerUid: ednaConfig.providerUid,
  appMarker: ednaConfig.appMarker,
  restUrl: ednaConfig.restUrl,
  webSocketUrl: ednaConfig.webSocketUrl,
  dataStoreUrl: ednaConfig.dataStoreUrl,
});

// Для авторизации без кастомного токена достаточно ID клиента.
await BakaiEdna.authorize({
  userId: String(clientId),
  fullName: clientFullName,
  deviceId: deviceId,
});
await BakaiEdna.openChat();
```

`clientId` — стабильный идентификатор текущего клиента, согласованный для вашего
стенда. В банкинге используется `credentials.customer_id`; сам плагин не зависит
от банковской модели и принимает строковый `userId`.

Если на стенде включена кастомная авторизация, можно передать токен:

```ts
await BakaiEdna.authorize({
  userId: String(clientId),
  token: chatToken,
  scheme: authScheme, // необязательно
});
```

`token` необязателен. Не передавайте пустую строку; опустите поле, если токен
не нужен. `scheme` имеет смысл только с `token`. На iOS без токена используется
`authorize(user:)`, на Android — `authorize(ChatUser(userId), null)`.

`fullName` передаётся в имя клиента SDK, `deviceId` — в `ChatUser.data["deviceId"]`. Оба значения берутся из приложения и необязательны для совместимости. Для отображения deviceId в рабочем месте оператора поле может потребовать настройки на стороне edna.
Способ авторизации должен соответствовать настройкам сервера; плагин не
переходит на авторизацию без токена автоматически при ошибке сервера.
В режиме только userId отдельный endpoint токена не нужен. Плагин не генерирует
токены и не передаёт банковский access token в SDK.

`initialize`/`authorize` завершаются после передачи данных SDK; это не подтверждение
успешного подключения или серверной проверки токена. На Android `openChat`
завершается после запуска Activity, на iOS — после показа контроллера.

Последовательность операций контролирует приложение. При `CHAT_BUSY` дождитесь
окончания перехода и повторите действие. Перед сменой пользователя нужен успешный
`logout`. Для смены стенда полностью перезапустите приложение.

## Сессия и пуши

- `closeChat()` закрывает экран.
- `lockChat()` закрывает и блокирует экран до следующего `authorize`, сохраняя
  сетевую сессию SDK и push-подписку. Вызывайте при блокировке банковского приложения.
- `logout()` закрывает чат и вызывает SDK logout для известного локального пользователя.
  Вызывайте при выходе из банковского аккаунта, а не при каждом закрытии чата.
- `setPushToken({ token })`: Android — FCM; iOS — настоящий APNs-токен в hex.
- `isEdnaPush({ data })` классифицирует уведомление, не открывая чат.

Полная инструкция интеграции с приложением: [docs/push.md](docs/push.md).
Обработчики в плагине не заменяют регистрацию уведомлений, Firebase/APNs,
проверку PIN и передачу событий из приложения.

## Интерфейс и вложения

`openChat` показывает стандартный нативный интерфейс edna. HTML/CSS Ionic не
меняют этот экран. Android-тема Activity находится в
`android/src/main/res/values/styles.xml`; конфигурация SDK — в `EdnaPush.kt`.
iOS-конфигурация создаётся в `BakaiEdnaPlugin.swift` при `initialize`.
Конкретные цвета, шрифты и компоненты edna нужно настраивать через дизайн-систему
SDK на каждой платформе, после получения макета. JS-метода для темы пока нет.

Для использования камеры, фото и микрофона добавьте соответствующие описания
доступа в Info.plist приложения: `NSCameraUsageDescription`,
`NSMicrophoneUsageDescription`, `NSPhotoLibraryUsageDescription`,
`NSPhotoLibraryAddUsageDescription`. В example-app они уже добавлены.
Android manifest SDK объединяется с manifest приложения: конфликты существующих
разрешений разрешайте в приложении согласно его текущим требованиям.

## Тестовое приложение

См. [example-app/README.md](example-app/README.md). Форма принимает настройки
стенда и тестовые credentials в памяти, без localStorage и логирования токена.
На браузере нативный чат недоступен; `isEdnaPush` возвращает false,
остальные web-методы возвращают `UNIMPLEMENTED`.

Ручная проверка на обеих платформах: переписка с оператором, история,
ошибочные/истёкшие credentials, смена клиента, блокировка/выход, потеря сети,
повторное открытие, клавиатура, вложения, светлая/тёмная тема, поворот Android,
пуш в фоне и после завершения процесса. Наличие unit-тестов не заменяет эту проверку.

## API

Полные типы и комментарии находятся в `src/definitions.ts`.
Следующий раздел обновляется командой `npm run build`.

<docgen-index>

* [`addListener('unreadCountChanged', ...)`](#addlistenerunreadcountchanged-)
* [`addListener('chatPresented', ...)`](#addlistenerchatpresented-)
* [`addListener('lastMessageDateChanged', ...)`](#addlistenerlastmessagedatechanged-)
* [`refreshUnreadCount()`](#refreshunreadcount)
* [`initialize(...)`](#initialize)
* [`authorize(...)`](#authorize)
* [`openChat(...)`](#openchat)
* [`closeChat()`](#closechat)
* [`lockChat()`](#lockchat)
* [`setPushToken(...)`](#setpushtoken)
* [`isEdnaPush(...)`](#isednapush)
* [`logout()`](#logout)
* [Interfaces](#interfaces)
* [Type Aliases](#type-aliases)

</docgen-index>

<docgen-api>
<!--Update the source file JSDoc comments and rerun docgen to update the docs below-->

### addListener('unreadCountChanged', ...)

```typescript
addListener(eventName: 'unreadCountChanged', listener: (event: { count: number; userId: string; }) => void) => Promise<PluginListenerHandle>
```

| Param           | Type                                                                |
| --------------- | ------------------------------------------------------------------- |
| **`eventName`** | <code>'unreadCountChanged'</code>                                   |
| **`listener`**  | <code>(event: { count: number; userId: string; }) =&gt; void</code> |

**Returns:** <code>Promise&lt;<a href="#pluginlistenerhandle">PluginListenerHandle</a>&gt;</code>

--------------------


### addListener('chatPresented', ...)

```typescript
addListener(eventName: 'chatPresented', listener: () => void) => Promise<PluginListenerHandle>
```

| Param           | Type                         |
| --------------- | ---------------------------- |
| **`eventName`** | <code>'chatPresented'</code> |
| **`listener`**  | <code>() =&gt; void</code>   |

**Returns:** <code>Promise&lt;<a href="#pluginlistenerhandle">PluginListenerHandle</a>&gt;</code>

--------------------


### addListener('lastMessageDateChanged', ...)

```typescript
addListener(eventName: 'lastMessageDateChanged', listener: (event: { timestamp: number; }) => void) => Promise<PluginListenerHandle>
```

| Param           | Type                                                    |
| --------------- | ------------------------------------------------------- |
| **`eventName`** | <code>'lastMessageDateChanged'</code>                   |
| **`listener`**  | <code>(event: { timestamp: number; }) =&gt; void</code> |

**Returns:** <code>Promise&lt;<a href="#pluginlistenerhandle">PluginListenerHandle</a>&gt;</code>

--------------------


### refreshUnreadCount()

```typescript
refreshUnreadCount() => Promise<void>
```

Requests the current SDK count, delivered through unreadCountChanged.

--------------------


### initialize(...)

```typescript
initialize(options: InitializeOptions) => Promise<void>
```

Once per native plugin instance. Does not confirm server availability.

| Param         | Type                                                            |
| ------------- | --------------------------------------------------------------- |
| **`options`** | <code><a href="#initializeoptions">InitializeOptions</a></code> |

--------------------


### authorize(...)

```typescript
authorize(options: AuthorizeOptions) => Promise<void>
```

Sets SDK credentials; resolution does not confirm server authentication.

| Param         | Type                                                          |
| ------------- | ------------------------------------------------------------- |
| **`options`** | <code><a href="#authorizeoptions">AuthorizeOptions</a></code> |

--------------------


### openChat(...)

```typescript
openChat(options?: OpenChatOptions | undefined) => Promise<void>
```

Opens native UI after authorize(). Unsupported in the browser.

| Param         | Type                                                        |
| ------------- | ----------------------------------------------------------- |
| **`options`** | <code><a href="#openchatoptions">OpenChatOptions</a></code> |

--------------------


### closeChat()

```typescript
closeChat() => Promise<void>
```

--------------------


### lockChat()

```typescript
lockChat() => Promise<void>
```

Closes and locks the native screen while preserving the SDK session/push subscription.

--------------------


### setPushToken(...)

```typescript
setPushToken(options: { token: string; }) => Promise<void>
```

Android: FCM token. iOS: raw APNs token encoded as hexadecimal, NOT an FCM token.

| Param         | Type                            |
| ------------- | ------------------------------- |
| **`options`** | <code>{ token: string; }</code> |

--------------------


### isEdnaPush(...)

```typescript
isEdnaPush(options: { data: Record<string, unknown>; }) => Promise<{ matches: boolean; }>
```

Classifies a platform notification payload; does not authorize a user or open UI.

| Param         | Type                                                                        |
| ------------- | --------------------------------------------------------------------------- |
| **`options`** | <code>{ data: <a href="#record">Record</a>&lt;string, unknown&gt;; }</code> |

**Returns:** <code>Promise&lt;{ matches: boolean; }&gt;</code>

--------------------


### logout()

```typescript
logout() => Promise<void>
```

Closes chat and calls the SDK logout. Call on bank-account logout.

--------------------


### Interfaces


#### PluginListenerHandle

| Prop         | Type                                      |
| ------------ | ----------------------------------------- |
| **`remove`** | <code>() =&gt; Promise&lt;void&gt;</code> |


#### InitializeOptions

All URLs and the provider UID must come from your edna deployment.

| Prop               | Type                |
| ------------------ | ------------------- |
| **`providerUid`**  | <code>string</code> |
| **`appMarker`**    | <code>string</code> |
| **`restUrl`**      | <code>string</code> |
| **`webSocketUrl`** | <code>string</code> |
| **`dataStoreUrl`** | <code>string</code> |


#### AuthorizeOptions

The user ID is required. Custom authentication is optional.

| Prop           | Type                | Description                                                                         |
| -------------- | ------------------- | ----------------------------------------------------------------------------------- |
| **`userId`**   | <code>string</code> | Stable client identifier agreed for the edna deployment.                            |
| **`fullName`** | <code>string</code> | Client full name displayed to support.                                              |
| **`deviceId`** | <code>string</code> | Application device identifier, sent as ChatUser.data.deviceId.                      |
| **`token`**    | <code>string</code> | Only for deployments using custom authentication. Omit for user-only authorization. |
| **`scheme`**   | <code>string</code> | Custom authentication scheme; requires token.                                       |


#### OpenChatOptions

| Prop                      | Type                                                      | Description                                                                     |
| ------------------------- | --------------------------------------------------------- | ------------------------------------------------------------------------------- |
| **`language`**            | <code>string</code>                                       | Language selected in the host app; takes priority over systemLanguage.          |
| **`systemLanguage`**      | <code>string</code>                                       | Device language, used if no app language is selected.                           |
| **`clientAvatarDataUrl`** | <code>string</code>                                       | Current client avatar, resized PNG data URL (maximum 128 KB).                   |
| **`theme`**               | <code>'light' \| 'dark' \| 'ifcLight' \| 'ifcDark'</code> | Current BakAi palette. Applied on every open without resetting the SDK session. |
| **`prefilledMessage`**    | <code>string</code>                                       | Prefills the input field; does not send a message.                              |


### Type Aliases


#### Record

Construct a type with a set of properties K of type T

<code>{ [P in K]: T; }</code>

</docgen-api>
