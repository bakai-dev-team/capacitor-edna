package kg.bakai.capacitor.edna;

import android.content.Context;
import android.graphics.Canvas;
import android.graphics.drawable.Drawable;
import android.util.AttributeSet;
import android.view.View;
import android.widget.ImageView;

/** SDK image-loading target. Only BankClientSideView paints the operator photo. */
public final class BankAvatarSourceView extends ImageView {
    public BankAvatarSourceView(Context context, AttributeSet attrs) {
        super(context, attrs);
        setImportantForAccessibility(IMPORTANT_FOR_ACCESSIBILITY_NO);
    }

    @Override public void draw(Canvas canvas) {
        // Suppress the background as well as the photo, even if SDK binding
        // restores visibility, alpha, tint or a circular background.
    }

    @Override public void invalidateDrawable(Drawable drawable) {
        super.invalidateDrawable(drawable);
        if (getParent() instanceof View) {
            View side = ((View) getParent()).findViewById(R.id.bank_client_side);
            if (side != null) side.invalidate();
        }
    }
}
