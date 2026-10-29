import { WebPlugin } from '@capacitor/core';
import type { AuthorizeOptions, BakaiEdnaPlugin, InitializeOptions, OpenChatOptions } from './definitions.js';

export class BakaiEdnaWeb extends WebPlugin implements BakaiEdnaPlugin {
  async refreshUnreadCount(): Promise<void> {
    throw this.unimplemented('edna requires iOS or Android.');
  }
  async initialize(_options: InitializeOptions): Promise<void> {
    throw this.unimplemented('edna requires iOS or Android.');
  }
  async authorize(_options: AuthorizeOptions): Promise<void> {
    throw this.unimplemented('edna requires iOS or Android.');
  }
  async openChat(_options?: OpenChatOptions): Promise<void> {
    throw this.unimplemented('edna requires iOS or Android.');
  }
  async closeChat(): Promise<void> {
    throw this.unimplemented('edna requires iOS or Android.');
  }
  async lockChat(): Promise<void> {
    throw this.unimplemented('edna requires iOS or Android.');
  }
  async setPushToken(_options: { token: string }): Promise<void> {
    throw this.unimplemented('edna requires iOS or Android.');
  }
  async isEdnaPush(_options: { data: Record<string, unknown> }): Promise<{ matches: boolean }> {
    return { matches: false };
  }
  async logout(): Promise<void> {
    throw this.unimplemented('edna requires iOS or Android.');
  }
}
