package kg.bakai.capacitor.edna;

import android.content.Context;
import android.util.AttributeSet;
import android.widget.FrameLayout;

/** Bounds both loading placeholders and SDK-computed image sizes. */
public final class BankImagePreview extends FrameLayout {
    public BankImagePreview(Context context, AttributeSet attrs) { super(context, attrs); }

    @Override protected void onMeasure(int widthSpec, int heightSpec) {
        int limit = getResources().getDimensionPixelSize(R.dimen.bakai_edna_image_preview_max);
        int width = MeasureSpec.getMode(widthSpec) == MeasureSpec.UNSPECIFIED ? limit : MeasureSpec.getSize(widthSpec);
        int height = MeasureSpec.getMode(heightSpec) == MeasureSpec.UNSPECIFIED ? limit : MeasureSpec.getSize(heightSpec);
        float scale = Math.min(1f, (float) limit / Math.max(1, Math.max(width, height)));
        super.onMeasure(MeasureSpec.makeMeasureSpec(Math.max(1, Math.round(width * scale)), MeasureSpec.EXACTLY),
                MeasureSpec.makeMeasureSpec(Math.max(1, Math.round(height * scale)), MeasureSpec.EXACTLY));
    }
}
