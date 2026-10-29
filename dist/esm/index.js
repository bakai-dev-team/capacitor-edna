import { registerPlugin } from '@capacitor/core';
export const BakaiEdna = registerPlugin('BakaiEdna', {
    web: () => import('./web.js').then(({ BakaiEdnaWeb }) => new BakaiEdnaWeb()),
});
//# sourceMappingURL=index.js.map