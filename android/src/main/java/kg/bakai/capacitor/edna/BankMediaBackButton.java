package kg.bakai.capacitor.edna;

import android.content.Context;
import android.graphics.drawable.Drawable;
import android.util.AttributeSet;
import android.widget.ImageButton;
import edna.chatcenter.ui.visual.uiStyle.DesignSystemExtensionsKt;

/** ImagesActivity incorrectly applies chatFlow.backButton to the gallery button. */
public final class BankMediaBackButton extends ImageButton {
    private boolean mediaStyleReady;
    public BankMediaBackButton(Context context, AttributeSet attrs) { super(context, attrs); }

    @Override protected void onAttachedToWindow() {
        super.onAttachedToWindow();
        var style = DesignSystemExtensionsKt.getFlows(getContext()).getGalleryFlow()
            .getNavigationBarStyle().getBackButton().getStyle();
        Integer background = style.getBackground();
        super.setBackgroundDrawable(background == null ? null : getContext().getDrawable(background));
        super.setImageDrawable(getContext().getDrawable(R.drawable.bakai_edna_media_back));
        Integer tint = style.getIconTintColor();
        if (tint != null) setImageTintList(android.content.res.ColorStateList.valueOf(getContext().getColor(tint)));
        setBackgroundTintList(null);
        setElevation(0); setTranslationZ(0); setStateListAnimator(null); setOutlineProvider(null);
        mediaStyleReady = true;
    }
    @Override public void setBackgroundDrawable(Drawable drawable) {
        if (!mediaStyleReady) super.setBackgroundDrawable(drawable);
    }
    @Override public void setImageDrawable(Drawable drawable) {
        if (!mediaStyleReady) super.setImageDrawable(drawable);
    }
}
