package kg.bakai.capacitor.edna

import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.Handler
import android.os.Looper
import android.util.Log
import edna.chatcenter.core.config.transport.ChatNetworkConfig
import edna.chatcenter.core.config.transport.ChatTransportConfig
import edna.chatcenter.ui.visual.ChatConfig
import edna.chatcenter.ui.visual.core.ChatCenterUI
import edna.chatcenter.ui.visual.core.PendingIntentCreator
import org.json.JSONObject
import org.json.JSONArray

/** Host FirebaseMessagingService hooks. Never stores bank/chat credentials. */
object EdnaPush {
    private const val STORE = "bakai_edna_push"
    private val main by lazy { Handler(Looper.getMainLooper()) }

    @JvmStatic
    fun setToken(context: Context, token: String) {
        if (token.isNotBlank()) ChatCenterUI.setFCMToken(token, context.applicationContext)
    }

    @JvmStatic
    fun isEdnaPush(data: Map<String, String>): Boolean =
        data["origin"].equals("threads", ignoreCase = true)

    internal fun setEnabled(context: Context, enabled: Boolean) {
        context.getSharedPreferences(STORE, Context.MODE_PRIVATE).edit().putBoolean("enabled", enabled).apply()
    }

    internal fun initialize(context: Context, options: JSONObject): ChatCenterUI {
        val key = JSONArray(
            listOf("providerUid", "appMarker", "restUrl", "webSocketUrl", "dataStoreUrl")
                .map { options.optString(it) }).toString()
        EdnaSession.sdk?.let {
            require(EdnaSession.configKey == key) { "Restart the app to change edna deployment" }
            return it
        }
        val app = context.applicationContext
        val restUrl = options.getString("restUrl")
        val webSocketUrl = options.getString("webSocketUrl")
        val dataStoreUrl = options.getString("dataStoreUrl")

        val transport = ChatTransportConfig(
            restUrl,
            webSocketUrl,
            dataStoreUrl,
            hashMapOf()
        )
        val config = ChatConfig(transport, ChatNetworkConfig()).apply {
            voiceRecordingEnabled = false
        }
        // Always enter the bank's launch/PIN flow; never launch the SDK's ChatActivity directly.
        config.pendingIntentCreator = object : PendingIntentCreator {
            override fun create(context: Context, appMarker: String?): PendingIntent {
                val intent = requireNotNull(context.packageManager.getLaunchIntentForPackage(context.packageName))
                    .addFlags(Intent.FLAG_ACTIVITY_CLEAR_TOP or Intent.FLAG_ACTIVITY_SINGLE_TOP)
                    .putExtra("origin", "threads")
                    .putExtra("google.message_id", "edna-chat")
                return PendingIntent.getActivity(
                    context, 7301, intent,
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                )
            }
        }
        val sdk = ChatCenterUI(app)
        sdk.init(options.getString("providerUid"), options.optString("appMarker"), config)
        // Pushes may arrive before openChat, including after process death.
        sdk.theme = BakaiEdnaTheme.create(app, "light")
        sdk.darkTheme = BakaiEdnaTheme.create(app, "dark")
        EdnaSession.sdk = sdk
        EdnaSession.configKey = key
        app.getSharedPreferences(STORE, Context.MODE_PRIVATE).edit().putString("config", options.toString()).apply()
        return sdk
    }

    /** True means this is an edna message; the host must not display a second notification. */
    @JvmStatic
    fun handleMessage(context: Context, data: Map<String, String>): Boolean {
        if (!isEdnaPush(data)) return false
        val app = context.applicationContext
        val payload = HashMap(data)
        main.post {
            val preferences = app.getSharedPreferences(STORE, Context.MODE_PRIVATE)
            if (!preferences.getBoolean("enabled", false)) return@post
            val config = preferences.getString("config", null) ?: return@post
            try {
                // Restore transport only after process death. Authorization still requires the bank.
                initialize(app, JSONObject(config)).handleFCMMessage(payload)
            } catch (_: Exception) {
                Log.w("BakaiEdna", "Could not process edna notification")
            }
        }
        return true
    }
}
