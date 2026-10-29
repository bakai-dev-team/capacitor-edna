package kg.bakai.capacitor.edna;

import android.animation.ValueAnimator;
import android.content.Context;
import android.graphics.Canvas;
import android.graphics.Paint;
import android.os.SystemClock;
import android.util.AttributeSet;
import android.util.TypedValue;
import android.view.View;
import android.view.ViewTreeObserver;
import android.view.animation.AccelerateDecelerateInterpolator;

/** Mirrors tg-dots-bounce; follows SDK loading visibility without changing SDK state. */
public final class BankLoadingDots extends View implements ViewTreeObserver.OnPreDrawListener {
    private final Paint paint = new Paint(Paint.ANTI_ALIAS_FLAG);
    private final AccelerateDecelerateInterpolator easing = new AccelerateDecelerateInterpolator();
    private final float density;
    private boolean loading;
    private long startedAt;
    private View title;
    private View subtitle;
    private View empty;
    private View error;
    private View search;

    public BankLoadingDots(Context context, AttributeSet attrs) {
        super(context, attrs);
        density = getResources().getDisplayMetrics().density;
        TypedValue color = new TypedValue();
        context.getTheme().resolveAttribute(R.attr.bakaiEdnaText, color, true);
        paint.setColor(color.data);
    }

    @Override protected void onAttachedToWindow() {
        super.onAttachedToWindow();
        View root = getRootView();
        title = root.findViewById(edna.chatcenter.ui.R.id.consult_name);
        subtitle = root.findViewById(edna.chatcenter.ui.R.id.subtitle);
        empty = root.findViewById(edna.chatcenter.ui.R.id.fl_empty);
        error = root.findViewById(edna.chatcenter.ui.R.id.chatErrorLayout);
        search = root.findViewById(edna.chatcenter.ui.R.id.searchBar);
        getViewTreeObserver().addOnPreDrawListener(this);
    }

    @Override public boolean onPreDraw() {
        boolean next = empty != null && empty.isShown()
                && (error == null || !error.isShown()) && (search == null || !search.isShown());
        if (next != loading) {
            loading = next;
            startedAt = SystemClock.uptimeMillis();
            setVisibility(loading ? VISIBLE : INVISIBLE);
            invalidate();
        }
        if (subtitle instanceof android.widget.TextView
                && getResources().getConfiguration().getLocales().get(0).getLanguage().equals("ky")) {
            android.widget.TextView label = (android.widget.TextView) subtitle;
            String text = label.getText().toString().trim().replaceAll("\\s+", " ");
            if (text.matches("(?iu)Отдел обслуживания физ\\.\\s*лиц")) {
                label.setText("Жеке жактарды тейлөө бөлүмү");
            }
        }
        // Alpha preserves the SDK's title/subtitle visibility and live updates.
        if (title != null) title.setAlpha(loading ? 0f : 1f);
        if (subtitle != null) subtitle.setAlpha(loading ? 0f : 1f);
        return true;
    }

    @Override protected void onDraw(Canvas canvas) {
        super.onDraw(canvas);
        if (!loading) return;
        boolean animate = android.os.Build.VERSION.SDK_INT < 26 || ValueAnimator.areAnimatorsEnabled();
        long elapsed = SystemClock.uptimeMillis() - startedAt;
        for (int i = 0; i < 3; i++) {
            long delayed = elapsed - i * 150L;
            float phase = delayed < 0 ? 0f : (delayed % 1000L) / 1000f;
            float progress = phase < .4f ? phase / .4f : phase < .8f ? (.8f - phase) / .4f : 0f;
            float bounce = animate ? easing.getInterpolation(progress) : 0f;
            paint.setAlpha(animate ? (int) (255 * (.3f + .7f * bounce)) : 255);
            canvas.drawCircle((1.5f + i * 5f) * density,
                    getHeight() / 2f - 2f * density * bounce, 1.5f * density, paint);
        }
        if (animate && getWindowVisibility() == VISIBLE && isShown()) postInvalidateOnAnimation();
    }

    @Override protected void onDetachedFromWindow() {
        if (getViewTreeObserver().isAlive()) getViewTreeObserver().removeOnPreDrawListener(this);
        if (title != null) title.setAlpha(1f);
        if (subtitle != null) subtitle.setAlpha(1f);
        loading = false;
        title = subtitle = empty = error = search = null;
        super.onDetachedFromWindow();
    }
}
