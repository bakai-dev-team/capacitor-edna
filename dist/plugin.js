var capacitorBakaiEdna = (function (exports, core) {
    'use strict';

    const BakaiEdna = core.registerPlugin('BakaiEdna', {
        web: () => Promise.resolve().then(function () { return web; }).then(({ BakaiEdnaWeb }) => new BakaiEdnaWeb()),
    });

    class BakaiEdnaWeb extends core.WebPlugin {
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

    var web = /*#__PURE__*/Object.freeze({
        __proto__: null,
        BakaiEdnaWeb: BakaiEdnaWeb
    });

    exports.BakaiEdna = BakaiEdna;

    return exports;

})({}, capacitorExports);
//# sourceMappingURL=plugin.js.map
