# Push-уведомления edna

Плагин предоставляет native hooks и методы JS. Приложение подключает их к своему
каналу FCM/APNs, получает разрешение уведомлений и сохраняет текущий поток PIN/входа.
Без настроенного канала edna и авторизации тестового клиента по userId реальную доставку
проверить нельзя. Push-токен устройства и токен авторизации клиента — разные данные.

## Android

В существующем `FirebaseMessagingService` приложения:

```kotlin
import kg.bakai.capacitor.edna.EdnaPush

// Внутри существующего onNewToken(token):
EdnaPush.setToken(applicationContext, token)
// Затем существующая обработка токена приложения.

// Внутри существующего onMessageReceived(remoteMessage):
if (EdnaPush.handleMessage(applicationContext, remoteMessage.data)) return
// Затем существующая обработка остальных уведомлений приложения.
```

Не добавляйте второй FirebaseMessagingService для тех же событий.
Передавайте также уже полученный FCM-токен при старте приложения, не только его
обновления. Это можно сделать через `BakaiEdna.setPushToken({ token })`.

Для SDK 5.23.0 обработчик распознаёт `origin=threads` и передаёт data payload SDK.
На стенде требуется соответствующий data-only FCM канал. При `true` приложение
не должно создавать дублирующее уведомление. В холодном процессе восстанавливаются
сохранённые транспортные настройки. Токены клиента этот код не сохраняет.
Локальная обработка включается при `authorize` и отключается при `logout`.

PendingIntent запускает обычную launch Activity приложения, передавая
`origin=threads` и `google.message_id`. Нативный экран чата из пуша напрямую
не запускается. Нажатие должно попадать в существующий обработчик приложения,
например `pushNotificationActionPerformed` Capacitor PushNotifications.

## iOS

В AppDelegate импортируйте модуль в зависимости от способа подключения:

```swift
#if canImport(BakaiEdnaPlugin)
import BakaiEdnaPlugin // Swift Package Manager
#elseif canImport(BakaiCapacitorEdna)
import BakaiCapacitorEdna // CocoaPods
#endif
```

В существующий `didRegisterForRemoteNotificationsWithDeviceToken` добавьте:

```swift
EdnaPush.setDeviceToken(deviceToken)
```

Это исходный APNs `Data`, полученный от iOS. Если Firebase преобразует результат
регистрации в FCM-токен, передайте edna APNs до этого преобразования. Существующую
передачу токенов Firebase/Capacitor сохраните. Не заменяйте существующий
UNUserNotificationCenterDelegate: показ и нажатия остаются у приложения.
При передаче через JavaScript `setPushToken` принимает APNs как строку hex.

В приложении нужны capability Push Notifications, корректный provisioning и
настройки APNs в edna. Режим Background Modes / Remote notifications включайте,
если ваш сценарий использует фоновую обработку remote notification.

## Нажатие и авторизация

В обработчике нажатия классифицируйте payload:

```ts
const { matches } = await BakaiEdna.isEdnaPush({ data: notification.data ?? {} });
if (matches) {
  // Сохранить ожидающее открытие чата средствами приложения.
  // Если сессия заблокирована — сначала пройти существующий вход/PIN.
  // Затем взять ID текущего клиента из авторизованной сессии,
  // выполнить initialize (если ещё не выполнялся),
  // authorize({ userId: String(clientId) }) и openChat.
  // При кастомной авторизации дополнительно получить токен от backend.
  // После успешного открытия очистить ожидающее действие.
  return;
}
// Обычные уведомления обрабатываются как раньше.
```

Это часть обработчика приложения, не отдельная страница. Путь `/edna-chat`
не требуется от edna: приложение может хранить простой флаг ожидающего открытия.
После PIN чат открывается автоматически без второй кнопки. Не используйте
userId/token из push для авторизации; берите данные текущей банковской сессии.
Повторные события нажатия объединяйте, чтобы не открывать чат одновременно дважды.
Переход к конкретному сообщению и рекламные кампании этим плагином не реализованы.

## Выход и проверка

При PIN-блокировке вызывайте `lockChat`, при выходе из аккаунта — `logout`.
Успешный локальный вызов logout не гарантирует серверную отписку без сети или
после потери локального состояния процесса. Отзыв доступа/подписок требуется
согласовать с backend/edna; особенно это важно для APNs, доставляемых самой ОС.

Проверьте реальную доставку в foreground/background/после остановки процесса,
нажатие до и после PIN, смену пользователя, старый баннер после выхода,
обновление FCM/APNs-токена и сохранение обработки обычных банковских пушей.
В example-app каналы Firebase/APNs не настроены: он проверяет ручное открытие чата.
