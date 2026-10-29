package kg.bakai.capacitor.edna;

import android.content.Context;
import android.util.AttributeSet;
import android.widget.LinearLayout;

/** Caps SDK-requested bubble widths while retaining wrap-content measurement. */
public final class BankMessageBubble extends LinearLayout {
    public BankMessageBubble(Context context, AttributeSet attrs) { super(context, attrs); }

    @Override protected void onMeasure(int widthSpec, int heightSpec) {
        float dp = getResources().getDisplayMetrics().density;
        int windowWidth = getResources().getConfiguration().screenWidthDp;
        int limit = Math.round(Math.min(windowWidth * .72f, 320f) * dp);
        int mode = MeasureSpec.getMode(widthSpec);
        int width = mode == MeasureSpec.UNSPECIFIED ? limit : Math.min(limit, MeasureSpec.getSize(widthSpec));
        super.onMeasure(MeasureSpec.makeMeasureSpec(width,
                mode == MeasureSpec.EXACTLY ? MeasureSpec.EXACTLY : MeasureSpec.AT_MOST), heightSpec);
    }
}
