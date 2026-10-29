package kg.bakai.capacitor.edna;

import android.graphics.*;
import android.graphics.drawable.*;
import android.view.View;
import android.view.ViewTreeObserver;
import android.util.TypedValue;

/** A sampled backdrop, blurred separately from the sharp send icon. */
public final class BankSendButtonStyle {
    public static void install(View root) {
        View button = root.findViewById(edna.chatcenter.ui.R.id.send_message);
        if (button == null) return;
        button.getViewTreeObserver().addOnPreDrawListener(new ViewTreeObserver.OnPreDrawListener() {
            public boolean onPreDraw() {
                if (button.getWidth() == 0 || button.getHeight() == 0) return true;
                button.getViewTreeObserver().removeOnPreDrawListener(this);
                TypedValue color = new TypedValue();
                button.getContext().getTheme().resolveAttribute(R.attr.bakaiEdnaText, color, true);
                float dp = button.getResources().getDisplayMetrics().density;
                // Composer is a solid surface; capture on layout/theme creation, not each frame.
                int w = Math.max(1, Math.round(button.getWidth() / dp));
                int h = Math.max(1, Math.round(button.getHeight() / dp));
                Bitmap bitmap = Bitmap.createBitmap(w, h, Bitmap.Config.ARGB_8888);
                Canvas canvas = new Canvas(bitmap);
                int[] a = new int[2], b = new int[2];
                root.getLocationInWindow(a); button.getLocationInWindow(b);
                canvas.scale(1 / dp, 1 / dp);
                canvas.translate(a[0] - b[0], a[1] - b[1]);
                float alpha = button.getAlpha();
                button.setAlpha(0);
                root.draw(canvas);
                button.setAlpha(alpha);
                bitmap = blur(bitmap, 14);
                StateListDrawable states = new StateListDrawable();
                states.addState(new int[]{android.R.attr.state_pressed}, surface(button, bitmap, color.data, .14f, dp));
                states.addState(new int[]{android.R.attr.state_hovered}, surface(button, bitmap, color.data, .10f, dp));
                states.addState(new int[]{}, surface(button, bitmap, color.data, .06f, dp));
                button.setBackground(states);
                button.setClipToOutline(true);
                button.setOutlineProvider(new android.view.ViewOutlineProvider() {
                    public void getOutline(View view, Outline outline) { outline.setOval(0, 0, view.getWidth(), view.getHeight()); }
                });
                return true;
            }
        });
    }
    private static Drawable surface(View view, Bitmap image, int text, float alpha, float dp) {
        BitmapDrawable backdrop = new BitmapDrawable(view.getResources(), image);
        ColorMatrix saturation = new ColorMatrix(); saturation.setSaturation(1.8f);
        backdrop.setColorFilter(new ColorMatrixColorFilter(saturation));
        GradientDrawable overlay = new GradientDrawable(); overlay.setShape(GradientDrawable.OVAL);
        overlay.setColor((Math.round(Color.alpha(text) * alpha) << 24) | (text & 0xFFFFFF));
        overlay.setStroke(Math.max(1, Math.round(.5f * dp)), (Math.round(Color.alpha(text) * .08f) << 24) | (text & 0xFFFFFF));
        return new LayerDrawable(new Drawable[]{backdrop, overlay});
    }
    private static Bitmap blur(Bitmap bitmap, int radius) {
        int w = bitmap.getWidth(), h = bitmap.getHeight();
        int[] pixels = new int[w*h], output = new int[w*h];
        bitmap.getPixels(pixels, 0, w, 0, 0, w, h);
        for (int y=0; y<h; y++) for (int x=0; x<w; x++) {
            long a=0,r=0,g=0,b=0; int count=0;
            for(int yy=Math.max(0,y-radius); yy<=Math.min(h-1,y+radius); yy++)
                for(int xx=Math.max(0,x-radius); xx<=Math.min(w-1,x+radius); xx++) {
                    int c=pixels[yy*w+xx]; a+=Color.alpha(c); r+=Color.red(c); g+=Color.green(c); b+=Color.blue(c); count++;
                }
            output[y*w+x]=Color.argb((int)(a/count),(int)(r/count),(int)(g/count),(int)(b/count));
        }
        bitmap.setPixels(output,0,w,0,0,w,h); return bitmap;
    }
}
