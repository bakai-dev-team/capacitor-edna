package kg.bakai.capacitor.edna

import android.content.Intent
import android.net.Uri
import android.os.Handler
import android.os.Looper
import android.util.Log
import com.getcapacitor.Plugin
import com.getcapacitor.JSObject
import org.json.JSONObject
import com.getcapacitor.PluginCall
import com.getcapacitor.PluginMethod
import com.getcapacitor.annotation.CapacitorPlugin
import edna.chatcenter.core.config.ChatAuth
import edna.chatcenter.core.config.ChatUser
import edna.chatcenter.core.config.transport.ChatNetworkConfig
import edna.chatcenter.core.config.transport.ChatTransportConfig
import edna.chatcenter.ui.visual.ChatConfig
import edna.chatcenter.ui.visual.core.ChatCenterUI
import edna.chatcenter.core.main.ChatCenterUIListener
import edna.chatcenter.core.main.Error as EdnaError
import edna.chatcenter.core.serviceLocator.core.LocatorContext
import edna.chatcenter.core.utils.history.HistoryRepository
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext

/** Shared by the bridge and the dedicated native Activity; accessed on the main thread. */
internal object EdnaSession {
    var language: String? = null
    var sdk: ChatCenterUI? = null
    var userId: String? = null
    var opening = false
    var unlocked = false
    var configKey: String? = null
    var revision = 0L
    var lastMessageDateChanged: ((Long) -> Unit)? = null
    var chatPresented: (() -> Unit)? = null
    var refreshingLastMessageDate = false
    private val main = Handler(Looper.getMainLooper())

    fun refreshUnreadAfterClosing(expectedRevision: Long) {
        val instance = sdk ?: return
        val id = userId ?: return
        // Allow read receipts to reach the server before the follow-up requests.
        for (delay in longArrayOf(0, 1000, 3000)) {
            main.postDelayed({
                if (revision != expectedRevision || userId != id || !unlocked ||
                    opening || EdnaChatActivity.current.get() != null) return@postDelayed
                runCatching { instance.updateUnreadCountMessagesIfNeed() }
                    .onFailure { Log.w("BakaiEdna", "Could not refresh unread after closing chat") }
            }, delay)
        }
    }
}

@CapacitorPlugin(name = "BakaiEdna")
class BakaiEdnaPlugin : Plugin() {
    private val main = Handler(Looper.getMainLooper())

    override fun load() {
        super.load()
        EdnaSession.lastMessageDateChanged = { timestamp ->
            notifyListeners("lastMessageDateChanged", JSObject().put("timestamp", timestamp))
        }
        EdnaSession.chatPresented = { notifyListeners("chatPresented", JSObject()) }
    }

    private fun execute(call: PluginCall, block: () -> Unit) {
        main.post {
            try { block() }
            catch (error: IllegalArgumentException) { call.reject(error.message ?: "Invalid argument", "INVALID_ARGUMENT") }
            catch (error: Exception) { call.reject("edna operation failed", "EDNA_ERROR") }
        }
    }

    private fun required(call: PluginCall, key: String): String =
        call.getString(key)?.takeIf { it.isNotBlank() }
            ?: throw IllegalArgumentException("$key is required")

    private fun endpoint(call: PluginCall, key: String, scheme: String): String {
        val value = required(call, key)
        val uri = Uri.parse(value)
        require(uri.scheme == scheme && !uri.host.isNullOrBlank() && uri.userInfo == null) {
            "$key must be an absolute $scheme URL without credentials"
        }
        return value
    }

    private fun sdk(call: PluginCall): ChatCenterUI? {
        val sdk = EdnaSession.sdk
        if (sdk == null) call.reject("Call initialize first", "NOT_INITIALIZED")
        return sdk
    }

    @PluginMethod
    fun initialize(call: PluginCall) = execute(call) {

        val providerUid = required(call, "providerUid")
        val appMarker = call.getString("appMarker") ?: ""

        val restUrl = endpoint(
            call,
            "restUrl",
            "https"
        )

        val webSocketUrl = endpoint(
            call,
            "webSocketUrl",
            "wss"
        )

        val dataStoreUrl = endpoint(
            call,
            "dataStoreUrl",
            "https"
        )
        val options = JSONObject().apply {
            put("providerUid", providerUid)
            put("appMarker", appMarker)
            put("restUrl", restUrl)
            put("webSocketUrl", webSocketUrl)
            put("dataStoreUrl", dataStoreUrl)
        }

        EdnaPush.initialize(
            context,
            options
        )

        call.resolve()
    }

    @PluginMethod
    fun authorize(call: PluginCall) = execute(call) {
        val instance = sdk(call) ?: return@execute
        val userId = required(call, "userId")
        val token = call.getString("token")
        val scheme = call.getString("scheme")
        require(token == null || token.isNotBlank()) {
            "token must not be blank when provided"
        }
        require(
            scheme == null ||
                    (scheme.isNotBlank() && token != null)
        ) {
            "scheme requires a token"
        }
        if (
            EdnaSession.opening ||
            EdnaChatActivity.current.get()?.isFinishing == true
        ) {
            call.reject(
                "Chat is transitioning",
                "CHAT_BUSY"
            )
            return@execute
        }
        if (
            EdnaSession.userId != null &&
            EdnaSession.userId != userId
        ) {
            call.reject(
                "Call logout before changing user",
                "LOGOUT_REQUIRED"
            )
            return@execute
        }
        val auth = token?.let {
            ChatAuth(
                it,
                scheme,
                signature = null
            )
        }
        val fullName = call.getString("fullName")?.trim()
        val deviceId = call.getString("deviceId")?.trim()
        require(fullName == null || fullName.isNotEmpty()) { "fullName must not be blank" }
        require(deviceId == null || deviceId.isNotEmpty()) { "deviceId must not be blank" }
        if (EdnaSession.userId != userId) EdnaSession.revision++
        val revision = EdnaSession.revision
        // SDK authorization can emit unread immediately.
        EdnaSession.userId = userId
        instance.setChatCenterUIListener(
            object : ChatCenterUIListener {
                override fun networkErrorReceived(error: EdnaError) {
                    Log.e("EdnaSDK", "Network error: $error")
                }
                override fun exceptionReceived(trace: String) {
                    Log.e("EdnaSDK", "SDK exception: $trace")
                }
                override fun unreadMessageCountChanged(count: UInt) {
                    main.post {
                        if (EdnaSession.revision != revision || EdnaSession.userId != userId) return@post
                        notifyListeners("unreadCountChanged", JSObject().put("count", count.toLong()).put("userId", userId))
                    }
                }
                override fun urlClicked(url: String) {
                }
            }
        )
        instance.authorize(
            ChatUser(userId, fullName, deviceId?.let { mapOf("deviceId" to it) }),
            auth
        )
        EdnaSession.unlocked = true
        EdnaPush.setEnabled(
            context,
            true
        )
        call.resolve()
    }

    @PluginMethod
    fun getLastMessageDate(call: PluginCall) = execute(call) {
        val timestamp = context.getSharedPreferences("bakai_edna_chat", android.content.Context.MODE_PRIVATE)
            .getLong("last_message_timestamp", 0L)
        val result = JSObject()
        if (timestamp > 0L) result.put("timestamp", timestamp)
        call.resolve(result)
    }

    @PluginMethod
    fun refreshLastMessageDate(call: PluginCall) = execute(call) {
        val userId = EdnaSession.userId
        if (userId == null) {
            call.reject("Call authorize first", "NOT_AUTHORIZED")
            return@execute
        }
        if (EdnaChatActivity.current.get() != null) {
            call.resolve()
            return@execute
        }
        if (EdnaSession.refreshingLastMessageDate) {
            call.resolve()
            return@execute
        }
        val history = runCatching {
            LocatorContext.getLocator()
                .resolveInstanceOrNull(HistoryRepository::class)
                ?.instance as? HistoryRepository
        }.getOrNull()
        if (history == null) {
            call.reject("Edna message history is not ready", "EDNA_NOT_READY")
            return@execute
        }
        EdnaSession.refreshingLastMessageDate = true
        val revision = EdnaSession.revision
        val appContext = context.applicationContext
        CoroutineScope(SupervisorJob() + Dispatchers.IO).launch {
            val timestamp = runCatching {
                history.loadPage(
                    null,
                    null,
                    mutableMapOf<String, edna.chatcenter.core.models.enums.AttachmentStateEnum>(),
                    true,
                ).items
                    .asSequence()
                    .map { it.timeStamp }
                    .filter { it > 0L }
                    .maxOrNull()
            }.getOrNull()
            withContext(Dispatchers.Main) {
                EdnaSession.refreshingLastMessageDate = false
                if (EdnaSession.revision != revision || EdnaSession.userId != userId) {
                    call.reject("Session changed", "SESSION_CHANGED")
                    return@withContext
                }
                if (timestamp != null) {
                    val prefs = appContext.getSharedPreferences("bakai_edna_chat", android.content.Context.MODE_PRIVATE)
                    val previous = prefs.getLong("last_message_timestamp", 0L)
                    if (timestamp > previous) {
                        prefs.edit().putLong("last_message_timestamp", timestamp).apply()
                        EdnaSession.lastMessageDateChanged?.invoke(timestamp)
                    }
                }
                call.resolve()
            }
        }
    }

    @PluginMethod
    fun refreshUnreadCount(call: PluginCall) = execute(call) {
        val instance = sdk(call) ?: return@execute
        if (EdnaSession.userId == null) {
            call.reject("Call authorize first", "NOT_AUTHORIZED")
            return@execute
        }
        // While the chat is visible, use live SDK read events instead of polling.
        if (EdnaChatActivity.current.get() == null && !EdnaSession.opening) {
            instance.updateUnreadCountMessagesIfNeed()
        }
        call.resolve()
    }

    @PluginMethod
    fun openChat(call: PluginCall) = execute(call) {
        val instance = sdk(call) ?: return@execute
        if (EdnaSession.userId == null || !EdnaSession.unlocked) {
            call.reject("Call authorize first", "NOT_AUTHORIZED")
            return@execute
        }
        val host = activity
        if (host == null || host.isFinishing || host.isDestroyed) {
            call.reject("No active host Activity", "NO_ACTIVITY")
            return@execute
        }
        if (EdnaSession.opening || EdnaChatActivity.current.get() != null) {
            call.reject("Chat is already open", "CHAT_ALREADY_OPEN")
            return@execute
        }
        val themeName = call.getString("theme") ?: "light"
        val language = call.getString("language")?.takeIf { it.isNotBlank() }
            ?: call.getString("systemLanguage")?.takeIf { it.isNotBlank() }
            ?: android.content.res.Resources.getSystem().configuration.locales[0].toLanguageTag()
        EdnaSession.language = language
        val languageConfiguration = android.content.res.Configuration(context.resources.configuration).apply {
            setLocale(java.util.Locale.forLanguageTag(language))
        }
        val theme = BakaiEdnaTheme.create(context.createConfigurationContext(languageConfiguration), themeName)
        instance.theme = theme
        instance.darkTheme = theme
        call.getString("prefilledMessage")?.let { instance.prefill(it) }
        EdnaSession.opening = true
        try { host.startActivity(Intent(host, EdnaChatActivity::class.java).putExtra("bakaiTheme", themeName).putExtra("bakaiLanguage", language).putExtra("clientAvatarDataUrl", call.getString("clientAvatarDataUrl")?.takeIf { it.length <= 131072 })) }
        catch (error: Exception) { EdnaSession.opening = false; throw error }
        call.resolve()
    }

    @PluginMethod
    fun closeChat(call: PluginCall) = execute(call) {
        if (EdnaSession.opening) {
            call.reject("Chat is opening; retry once presented", "CHAT_BUSY")
            return@execute
        }
        EdnaChatActivity.current.get()?.finish()
        call.resolve()
    }

    @PluginMethod
    fun lockChat(call: PluginCall) = execute(call) {
        EdnaSession.unlocked = false
        EdnaChatActivity.current.get()?.finish()
        call.resolve()
    }

    @PluginMethod
    fun setPushToken(call: PluginCall) = execute(call) {
        EdnaPush.setToken(context, required(call, "token"))
        call.resolve()
    }

    @PluginMethod
    fun isEdnaPush(call: PluginCall) = execute(call) {
        val origin = call.getObject("data")?.optString("origin")
        call.resolve(JSObject().put("matches", origin.equals("threads", ignoreCase = true)))
    }

    @PluginMethod
    fun logout(call: PluginCall) = execute(call) {
        EdnaSession.revision++
        EdnaSession.unlocked = false
        EdnaPush.setEnabled(context, false)
        context.getSharedPreferences("bakai_edna_chat", android.content.Context.MODE_PRIVATE)
            .edit().remove("last_message_timestamp").apply()
        val instance = EdnaSession.sdk
        if (instance == null || EdnaSession.userId == null) {
            call.resolve()
            return@execute
        }
        if (EdnaSession.opening) {
            call.reject("Chat is opening; retry once presented", "CHAT_BUSY")
            return@execute
        }
        EdnaChatActivity.current.get()?.finish()
        instance.logout()
        EdnaSession.userId = null
        call.resolve()
    }
}
