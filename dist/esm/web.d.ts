import { WebPlugin } from '@capacitor/core';
import type { AuthorizeOptions, BakaiEdnaPlugin, InitializeOptions, OpenChatOptions } from './definitions.js';
export declare class BakaiEdnaWeb extends WebPlugin implements BakaiEdnaPlugin {
    getLastMessageDate(): Promise<{
        timestamp?: number;
    }>;
    refreshUnreadCount(): Promise<void>;
    initialize(_options: InitializeOptions): Promise<void>;
    authorize(_options: AuthorizeOptions): Promise<void>;
    openChat(_options?: OpenChatOptions): Promise<void>;
    closeChat(): Promise<void>;
    lockChat(): Promise<void>;
    setPushToken(_options: {
        token: string;
    }): Promise<void>;
    isEdnaPush(_options: {
        data: Record<string, unknown>;
    }): Promise<{
        matches: boolean;
    }>;
    logout(): Promise<void>;
}
