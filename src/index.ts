import { registerPlugin } from '@capacitor/core';
import type { BakaiEdnaPlugin } from './definitions.js';

export const BakaiEdna = registerPlugin<BakaiEdnaPlugin>('BakaiEdna', {
  web: () => import('./web.js').then(({ BakaiEdnaWeb }) => new BakaiEdnaWeb()),
});

export type * from './definitions.js';
