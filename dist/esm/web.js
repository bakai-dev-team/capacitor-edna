import { WebPlugin } from '@capacitor/core';
export class BakaiEdnaWeb extends WebPlugin {
    async getLastMessageDate() {
        return {};
    }
    async refreshUnreadCount() {
        throw this.unimplemented('edna requires iOS or Android.');
    }
    async initialize(_options) {
        throw this.unimplemented('edna requires iOS or Android.');
    }
    async authorize(_options) {
        throw this.unimplemented('edna requires iOS or Android.');
    }
    async openChat(_options) {
        throw this.unimplemented('edna requires iOS or Android.');
    }
    async closeChat() {
        throw this.unimplemented('edna requires iOS or Android.');
    }
    async lockChat() {
        throw this.unimplemented('edna requires iOS or Android.');
    }
    async setPushToken(_options) {
        throw this.unimplemented('edna requires iOS or Android.');
    }
    async isEdnaPush(_options) {
        return { matches: false };
    }
    async logout() {
        throw this.unimplemented('edna requires iOS or Android.');
    }
}
//# sourceMappingURL=web.js.map