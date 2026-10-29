package kg.bakai.capacitor.edna;

import android.content.Context;
import android.util.AttributeSet;
import android.util.TypedValue;
import android.graphics.Color;
import android.graphics.Typeface;
import android.graphics.drawable.GradientDrawable;
import android.view.ViewTreeObserver;
import android.widget.LinearLayout;
import android.widget.TextView;

/** Styles the server's resolve request, retaining Edna's original button handlers. */
public final class BankResolveRequestLayout extends LinearLayout implements ViewTreeObserver.OnPreDrawListener {
    public BankResolveRequestLayout(Context context, AttributeSet attrs) { super(context, attrs); }
    @Override protected void onAttachedToWindow() {
        super.onAttachedToWindow();
        getViewTreeObserver().addOnPreDrawListener(this);
        TypedValue value = new TypedValue();
        getContext().getTheme().resolveAttribute(R.attr.bakaiEdnaText, value, true);
        boolean dark = Color.red(value.data) > 128;
        GradientDrawable card = new GradientDrawable(GradientDrawable.Orientation.TL_BR,
            dark ? new int[] { 0xFF1B1D23, 0xFF202228 } : new int[] { 0xFFFFFFFF, 0xFFF5F6FA });
        card.setCornerRadius(dp(24));
        setBackground(card);
        style(edna.chatcenter.ui.R.id.request_to_resolve_thread, 18, dark ? Color.WHITE : 0xFF07203A, true);
        style(R.id.bakai_resolve_subtitle, 14, dark ? 0xFFB8B8BA : 0xFF626970, false);
        style(edna.chatcenter.ui.R.id.deny_request, 16, 0xFF007AFF, true);
        style(edna.chatcenter.ui.R.id.approve_request, 16, Color.WHITE, true);
        findViewById(edna.chatcenter.ui.R.id.deny_request).setBackground(pill(dark ? 0xFF192B3C : 0xFFE7F1FF));
        findViewById(edna.chatcenter.ui.R.id.approve_request).setBackground(pill(0xFF007AFF));
    }
    @Override protected void onDetachedFromWindow() {
        getViewTreeObserver().removeOnPreDrawListener(this);
        super.onDetachedFromWindow();
    }
    @Override public boolean onPreDraw() {
        boolean russian = getResources().getConfiguration().getLocales().get(0).getLanguage().equals("ru");
        boolean kyrgyz = getResources().getConfiguration().getLocales().get(0).getLanguage().equals("ky");
        label(R.id.bakai_resolve_subtitle, russian ? "Продолжить консультацию?" : kyrgyz ? "Кеңешүүнү улантасызбы?" : "Continue the consultation?");
        // Edna resets its labels when RecyclerView rebinds this request.
        label(edna.chatcenter.ui.R.id.request_to_resolve_thread, russian ? "Специалист ответил\nна все вопросы" : kyrgyz ? "Адис бардык суроолоруңузга\nжооп берди" : "The specialist has answered\nall your questions");
        label(edna.chatcenter.ui.R.id.deny_request, russian ? "Продолжить" : kyrgyz ? "Улантуу" : "Continue");
        label(edna.chatcenter.ui.R.id.approve_request, russian ? "Завершить" : kyrgyz ? "Аяктоо" : "Finish");
        return true;
    }
    private void label(int id, String value) {
        TextView text = findViewById(id);
        if (!value.contentEquals(text.getText())) text.setText(value);
    }
    private void style(int id, int size, int color, boolean bold) {
        TextView text = findViewById(id);
        text.setTextSize(TypedValue.COMPLEX_UNIT_SP, size); text.setTextColor(color);
        text.setTypeface(text.getTypeface(), bold ? Typeface.BOLD : Typeface.NORMAL);
    }
    private GradientDrawable pill(int color) {
        GradientDrawable shape = new GradientDrawable(); shape.setColor(color); shape.setCornerRadius(dp(24)); return shape;
    }
    private int dp(int value) { return Math.round(value * getResources().getDisplayMetrics().density); }
}
