package kg.bakai.capacitor.edna;

import android.content.Context;
import android.util.AttributeSet;
import android.graphics.drawable.ColorDrawable;
import android.graphics.drawable.GradientDrawable;
import android.graphics.drawable.Drawable;
import android.view.View;
import android.widget.Button;
import android.widget.LinearLayout;

/** Geometry for Edna's existing attachment buttons; SDK keeps their listeners. */
public final class BankAttachmentMenuLayout extends LinearLayout {
    public BankAttachmentMenuLayout(Context context, AttributeSet attrs) { super(context, attrs); }

    @Override protected void onAttachedToWindow() {
        super.onAttachedToWindow();
        float density = getResources().getDisplayMetrics().density;
        int[] ids = { edna.chatcenter.ui.R.id.camera, edna.chatcenter.ui.R.id.gallery, edna.chatcenter.ui.R.id.file };
        boolean russian = getResources().getConfiguration().getLocales().get(0).getLanguage().equals("ru");
        boolean kyrgyz = getResources().getConfiguration().getLocales().get(0).getLanguage().equals("ky");
        String[] titles = kyrgyz ? new String[] { "Камера", "Галерея", "Файл" } : russian ? new String[] { "Камера", "Галерея", "Файл" } : new String[] { "Camera", "Gallery", "File" };
        for (int i = 0; i < ids.length; i++) {
            Button button = findViewById(ids[i]);
            button.setAllCaps(false);
            button.setText(titles[i]);
            button.setMinHeight(0);
            button.setMinimumHeight(0);
            button.setCompoundDrawablePadding(Math.round(6 * density));
            Drawable background = button.getBackground();
            if (background instanceof ColorDrawable) {
                GradientDrawable pill = new GradientDrawable();
                pill.setColor(((ColorDrawable) background).getColor());
                pill.setCornerRadius(33 * density);
                button.setBackground(pill);
            }
            Drawable[] icons = button.getCompoundDrawables();
            for (Drawable icon : icons) {
                if (icon != null) icon.setBounds(0, 0, Math.round(22 * density), Math.round(22 * density));
            }
            button.setCompoundDrawables(icons[0], icons[1], icons[2], icons[3]);
        }
        // Read the selected Edna palette instead of copying the SDK container's
        // default white drawable. The app's theme can differ from system night mode.
        int surfaceResource = edna.chatcenter.ui.visual.uiStyle.DesignSystemExtensionsKt
                .getFlows(getContext()).getBottomMenuChatFlow().getBackgroundColor();
        int surfaceColor = androidx.core.content.ContextCompat.getColor(getContext(), surfaceResource);
        setBackgroundColor(surfaceColor);
        if (getParent() instanceof View) {
            View sheet = (View) getParent();
            applySurface(sheet, surfaceColor, density);
            if (sheet.getParent() instanceof View) {
                View container = (View) sheet.getParent();
                applySurface(container, surfaceColor, density);
                // Material owns the rounded outer surface of the modal sheet.
                android.view.ViewParent ancestor = container.getParent();
                while (ancestor instanceof View) {
                    View candidate = (View) ancestor;
                    if (candidate.getId() == com.google.android.material.R.id.design_bottom_sheet) {
                        applySurface(candidate, surfaceColor, density);
                        break;
                    }
                    ancestor = candidate.getParent();
                }
            }
        }
    }

    private void applySurface(View view, int color, float density) {
        GradientDrawable surface = new GradientDrawable();
        surface.setColor(color);
        surface.setCornerRadius(0);
        view.setBackground(surface);
        view.setClipToOutline(false);
    }
}
