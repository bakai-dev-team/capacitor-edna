package kg.bakai.capacitor.edna;
import android.app.Activity;
import android.content.Intent;
import android.net.Uri;
import android.view.ViewGroup;
import android.webkit.WebView;
import android.webkit.WebViewClient;
import android.webkit.WebResourceRequest;
import android.widget.Toast;
import android.app.Dialog;
import android.graphics.Color;
import android.os.Build;
import android.view.View;
import android.view.Window;
import android.view.WindowManager;
import android.widget.LinearLayout;
import androidx.core.view.ViewCompat;
import androidx.core.view.WindowCompat;
import androidx.core.view.WindowInsetsCompat;
import androidx.core.graphics.Insets;
import java.nio.charset.StandardCharsets;

public final class BankContactProfile {
    public static void show(Activity activity, boolean dark) {
        boolean russian = activity.getResources().getConfiguration().getLocales().get(0).getLanguage().equals("ru");
        boolean kyrgyz = activity.getResources().getConfiguration().getLocales().get(0).getLanguage().equals("ky");
        String html;
        try (java.io.InputStream stream = activity.getAssets().open("bakai_edna_profile.html")) {
            java.io.ByteArrayOutputStream bytes = new java.io.ByteArrayOutputStream();
            byte[] buffer = new byte[4096]; int count;
            while ((count = stream.read(buffer)) != -1) bytes.write(buffer, 0, count);
            html = bytes.toString(StandardCharsets.UTF_8.name());
        } catch (java.io.IOException error) { return; }
        html = html.replace("__THEME__", dark ? "dark" : "light")
            .replace("__BANK__", russian ? "БАКАЙ БАНК" : kyrgyz ? "БАКАЙ БАНК" : "BAKAI BANK")
            .replace("__CONTACTS__", russian ? "Контакты" : kyrgyz ? "Байланыш маалыматы" : "Contacts")
            .replace("__SITE__", russian ? "Сайт" : kyrgyz ? "Сайт" : "Website")
            .replace("__PHONE__", russian ? "Номер" : kyrgyz ? "Номер" : "Phone")
            .replace("__CLOSE__", russian ? "Закрыть" : kyrgyz ? "Жабуу" : "Close");
        Dialog dialog = new Dialog(activity, android.R.style.Theme_DeviceDefault_NoActionBar);
        dialog.requestWindowFeature(Window.FEATURE_NO_TITLE);
        WebView web = new WebView(activity);
        web.setBackgroundColor(0xFF000E51);
        web.getSettings().setJavaScriptEnabled(false);
        web.getSettings().setAllowFileAccess(false);
        web.getSettings().setAllowContentAccess(false);
        web.setWebViewClient(new WebViewClient() {
            @Override public boolean shouldOverrideUrlLoading(WebView view, WebResourceRequest request) {
                return open(request.getUrl());
            }
            @Override public boolean shouldOverrideUrlLoading(WebView view, String url) { return open(Uri.parse(url)); }
            private boolean open(Uri uri) {
                if ("bankprofile".equals(uri.getScheme())) { dialog.dismiss(); return true; }
                if (!("https".equals(uri.getScheme()) || "tel".equals(uri.getScheme()))) return true;
                try { activity.startActivity(new Intent(Intent.ACTION_VIEW, uri)); }
                catch (android.content.ActivityNotFoundException error) {
                    Toast.makeText(activity, russian ? "Не удалось открыть ссылку" : kyrgyz ? "Шилтемени ачуу мүмкүн болгон жок" : "Unable to open link", Toast.LENGTH_SHORT).show();
                }
                return true;
            }
        });
        // Draw the hero itself behind the status bar so its gradient has no seam.
        final String profileHtml = html.replace("</style>",
            ".hero{height:calc(270px + var(--status-inset,0px));padding-top:var(--status-inset,0px)}"
            + ".close{top:calc(20px + var(--status-inset,0px))}"
            + ".content{min-height:calc(100vh - 248px - var(--status-inset,0px))}</style>");
        final int[] loadedTopInset = {-1};
        int pageColor = dark ? 0xFF171819 : 0xFFF5F6FA;
        LinearLayout root = new LinearLayout(activity);
        root.setOrientation(LinearLayout.VERTICAL);
        root.setBackgroundColor(pageColor);
        View navigationBackground = new View(activity);
        navigationBackground.setBackgroundColor(pageColor);
        root.addView(web, new LinearLayout.LayoutParams(-1, 0, 1));
        root.addView(navigationBackground, new LinearLayout.LayoutParams(-1, 0));
        ViewCompat.setOnApplyWindowInsetsListener(root, (view, windowInsets) -> {
            Insets bars = windowInsets.getInsets(WindowInsetsCompat.Type.systemBars()
                | WindowInsetsCompat.Type.displayCutout());
            if (loadedTopInset[0] != bars.top) {
                loadedTopInset[0] = bars.top;
                float cssTop = bars.top / activity.getResources().getDisplayMetrics().density;
                String insetHtml = profileHtml.replace("<head>", "<head><style>:root{--status-inset:"
                    + cssTop + "px}</style>");
                web.loadDataWithBaseURL("https://bakai-profile.invalid/", insetHtml, "text/html", "UTF-8", null);
            }
            navigationBackground.getLayoutParams().height = bars.bottom;
            root.setPadding(bars.left, 0, bars.right, 0);
            root.requestLayout();
            return WindowInsetsCompat.CONSUMED;
        });
        dialog.setContentView(root);
        dialog.setOnDismissListener(ignored -> { web.stopLoading(); web.destroy(); });
        Window window = dialog.getWindow();
        if (window != null) {
            window.setBackgroundDrawableResource(android.R.color.transparent);
            window.clearFlags(WindowManager.LayoutParams.FLAG_TRANSLUCENT_STATUS
                | WindowManager.LayoutParams.FLAG_TRANSLUCENT_NAVIGATION
                | WindowManager.LayoutParams.FLAG_DIM_BEHIND);
            window.addFlags(WindowManager.LayoutParams.FLAG_DRAWS_SYSTEM_BAR_BACKGROUNDS);
            WindowCompat.setDecorFitsSystemWindows(window, false);
            window.setStatusBarColor(Color.TRANSPARENT);
            window.setNavigationBarColor(Color.TRANSPARENT);
            if (Build.VERSION.SDK_INT >= 28) window.setNavigationBarDividerColor(Color.TRANSPARENT);
            if (Build.VERSION.SDK_INT >= 29) {
                window.setStatusBarContrastEnforced(false);
                window.setNavigationBarContrastEnforced(false);
            }
            WindowCompat.getInsetsController(window, root).setAppearanceLightStatusBars(false);
            WindowCompat.getInsetsController(window, root).setAppearanceLightNavigationBars(!dark);
        }
        dialog.show();
        if (window != null) window.setLayout(ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.MATCH_PARENT);
        ViewCompat.requestApplyInsets(root);
    }
}
