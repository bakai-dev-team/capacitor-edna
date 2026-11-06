import type { PluginListenerHandle } from '@capacitor/core';

/** All URLs and the provider UID must come from your edna deployment. */
export interface InitializeOptions {
  providerUid: string;
  appMarker?: string;
  restUrl: string;
  webSocketUrl: string;
  dataStoreUrl: string;
}

/** The user ID is required. Custom authentication is optional. */
export interface AuthorizeOptions {
  /** Stable client identifier agreed for the edna deployment. */
  userId: string;
  /** Client full name displayed to support. */
  fullName?: string;
  /** Application device identifier, sent as ChatUser.data.deviceId. */
  deviceId?: string;
  /** Only for deployments using custom authentication. Omit for user-only authorization. */
  token?: string;
  /** Custom authentication scheme; requires token. */
  scheme?: string;
}

export interface OpenChatOptions {
  /** Language selected in the host app; takes priority over systemLanguage. */
  language?: string;
  /** Device language, used if no app language is selected. */
  systemLanguage?: string;
  /** Current client avatar, resized PNG data URL (maximum 128 KB). */
  clientAvatarDataUrl?: string;
  /** Current BakAi palette. Applied on every open without resetting the SDK session. */
  theme?: 'light' | 'dark' | 'ifcLight' | 'ifcDark';
  /** Prefills the input field; does not send a message. */
  prefilledMessage?: string;
}

export interface BakaiEdnaPlugin {
  addListener(eventName: 'lastMessageDateChanged', listener: (event: { timestamp: number }) => void): Promise<PluginListenerHandle>;
  addListener(eventName: 'unreadCountChanged', listener: (event: { count: number; userId: string }) => void): Promise<PluginListenerHandle>;
  /** Requests the current SDK count, delivered through unreadCountChanged. */
  refreshUnreadCount(): Promise<void>;
  /** Returns the cached latest message timestamp in Unix milliseconds, if available. */
  getLastMessageDate(): Promise<{ timestamp?: number }>;
  /** Once per native plugin instance. Does not confirm server availability. */
  initialize(options: InitializeOptions): Promise<void>;
  /** Sets SDK credentials; resolution does not confirm server authentication. */
  authorize(options: AuthorizeOptions): Promise<void>;
  /** Opens native UI after authorize(). Unsupported in the browser. */
  openChat(options?: OpenChatOptions): Promise<void>;
  closeChat(): Promise<void>;
  /** Closes and locks the native screen while preserving the SDK session/push subscription. */
  lockChat(): Promise<void>;
  /** Android: FCM token. iOS: raw APNs token encoded as hexadecimal, NOT an FCM token. */
  setPushToken(options: { token: string }): Promise<void>;
  /** Classifies a platform notification payload; does not authorize a user or open UI. */
  isEdnaPush(options: { data: Record<string, unknown> }): Promise<{ matches: boolean }>;
  /** Closes chat and calls the SDK logout. Call on bank-account logout. */
  logout(): Promise<void>;
}
