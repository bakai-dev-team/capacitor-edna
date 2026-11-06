package kg.bakai.capacitor.edna

import android.os.Bundle
import android.view.View
import android.widget.EditText
import androidx.fragment.app.Fragment
import androidx.fragment.app.FragmentManager
import android.widget.FrameLayout
import androidx.activity.OnBackPressedCallback
import androidx.appcompat.app.AppCompatActivity
import androidx.core.view.ViewCompat
import androidx.core.view.WindowInsetsCompat
import edna.chatcenter.core.annotation.OpenWay
import edna.chatcenter.ui.visual.fragments.ChatFragment
import java.lang.ref.WeakReference

class EdnaChatActivity : AppCompatActivity() {
    companion object {
        internal var current = WeakReference<EdnaChatActivity>(null)
    }

    private val historyTap by lazy {
        android.view.GestureDetector(this, object : android.view.GestureDetector.SimpleOnGestureListener() {
            override fun onDown(event: android.view.MotionEvent) = true

            override fun onSingleTapUp(event: android.view.MotionEvent): Boolean {
                val input = currentFocus as? EditText ?: return false
                val chat = supportFragmentManager.findFragmentByTag("edna-chat") as? ChatFragment ?: return false
                val content = chat.view?.findViewById<View>(edna.chatcenter.ui.R.id.chat_content) ?: return false
                val bounds = android.graphics.Rect()
                if (!content.getGlobalVisibleRect(bounds) || !bounds.contains(event.rawX.toInt(), event.rawY.toInt())) return false
                // Let the SDK finish handling links, attachments and message taps
                // before hiding the keyboard changes the history's layout.
                content.post {
                    if (currentFocus === input) {
                        input.clearFocus()
                        androidx.core.view.WindowCompat.getInsetsController(window, window.decorView)
                            .hide(WindowInsetsCompat.Type.ime())
                    }
                }
                return false
            }
        })
    }

    override fun dispatchTouchEvent(event: android.view.MotionEvent): Boolean {
        historyTap.onTouchEvent(event)
        return super.dispatchTouchEvent(event)
    }

    private var darkChat = false
    private var sessionRevision = -1L

    var clientAvatar: android.graphics.Bitmap? = null
        private set

    override fun attachBaseContext(newBase: android.content.Context) {
        val configuration = android.content.res.Configuration(newBase.resources.configuration)
        val language = EdnaSession.language
            ?: android.content.res.Resources.getSystem().configuration.locales[0].toLanguageTag()
        configuration.setLocale(java.util.Locale.forLanguageTag(language))
        super.attachBaseContext(newBase.createConfigurationContext(configuration))
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        savedInstanceState?.getIntArray("bankFileRequests")?.forEach { fileRequests.add(it) }
        val avatar = intent.getStringExtra("clientAvatarDataUrl")
        clientAvatar = runCatching {
            val bytes = android.util.Base64.decode(avatar?.substringAfter(",") ?: "", android.util.Base64.DEFAULT)
            android.graphics.BitmapFactory.decodeByteArray(bytes, 0, bytes.size)
        }.getOrNull() ?: android.graphics.BitmapFactory.decodeResource(resources, R.drawable.bakai_edna_client_avatar)
        val themeName = intent.getStringExtra("bakaiTheme") ?: "light"
        darkChat = themeName == "dark" || themeName == "ifcDark"
        setTheme(when (themeName) {
            "dark" -> R.style.BakaiEdnaChatTheme_Dark
            "ifcLight" -> R.style.BakaiEdnaChatTheme_IfcLight
            "ifcDark" -> R.style.BakaiEdnaChatTheme_IfcDark
            else -> R.style.BakaiEdnaChatTheme
        })
        delegate.localNightMode = if (themeName == "dark" || themeName == "ifcDark")
            androidx.appcompat.app.AppCompatDelegate.MODE_NIGHT_YES
        else androidx.appcompat.app.AppCompatDelegate.MODE_NIGHT_NO
        supportFragmentManager.registerFragmentLifecycleCallbacks(object : FragmentManager.FragmentLifecycleCallbacks() {
            override fun onFragmentStarted(fm: FragmentManager, fragment: Fragment) {
                if (!darkChat || fragment !is androidx.fragment.app.DialogFragment || fragment.view?.findViewById<View>(edna.chatcenter.ui.R.id.file_input_sheet) == null) return
                val dialogWindow = fragment.dialog?.window ?: return
                val color = androidx.core.content.ContextCompat.getColor(this@EdnaChatActivity, R.color.bakai_edna_menu_dark_surface)
                dialogWindow.navigationBarColor = color
                if (android.os.Build.VERSION.SDK_INT >= 29) dialogWindow.isNavigationBarContrastEnforced = false
                androidx.core.view.WindowCompat.getInsetsController(dialogWindow, dialogWindow.decorView).isAppearanceLightNavigationBars = false
                // Cover the bottom inset as well on Android versions enforcing edge-to-edge.
                val decor = dialogWindow.decorView as? android.widget.FrameLayout ?: return
                val insetSurface = View(this@EdnaChatActivity).apply {
                    setBackgroundColor(color)
                    importantForAccessibility = View.IMPORTANT_FOR_ACCESSIBILITY_NO
                }
                decor.addView(insetSurface, android.widget.FrameLayout.LayoutParams(-1, 0, android.view.Gravity.BOTTOM))
                ViewCompat.setOnApplyWindowInsetsListener(insetSurface) { surface, insets ->
                    val height = insets.getInsets(WindowInsetsCompat.Type.navigationBars()).bottom
                    surface.layoutParams = (surface.layoutParams as android.widget.FrameLayout.LayoutParams).apply { this.height = height }
                    insets
                }
                ViewCompat.requestApplyInsets(insetSurface)
            }
            override fun onFragmentViewCreated(fm: FragmentManager, fragment: Fragment, view: View, state: Bundle?) {
                if (fragment !is ChatFragment) return
                BankSendButtonStyle.install(view)
                BankReplyGesture.install(view)
                view.post {
                    view.findViewById<View>(R.id.bakai_edna_profile)?.setOnClickListener {
                        BankContactProfile.show(this@EdnaChatActivity, darkChat)
                    }
                    view.findViewById<View>(edna.chatcenter.ui.R.id.chat_back_button)?.setOnClickListener {
                        onBackPressedDispatcher.onBackPressed()
                    }
                }

                val input = view.findViewById<EditText>(edna.chatcenter.ui.R.id.input_edit_view) ?: return
                input.addTextChangedListener(MessageWhitespaceWatcher(input))
                // Also normalize a restored or prefilled draft.
                input.text?.let { MessageWhitespaceWatcher(input).afterTextChanged(it) }
            }
        }, true)
        // Do not restore SDK fragments after process death before the bank authenticates again.
        super.onCreate(if (EdnaSession.userId == null) null else savedInstanceState)
        EdnaSession.opening = false
        if (EdnaSession.sdk == null || EdnaSession.userId == null || !EdnaSession.unlocked) {
            finish(); return
        }
        sessionRevision = EdnaSession.revision
        current = WeakReference(this)
        val container = FrameLayout(this).apply { id = R.id.bakai_edna_chat_container }
        setContentView(container)
        ViewCompat.setOnApplyWindowInsetsListener(container) { view, insets ->
            val padding = insets.getInsets(WindowInsetsCompat.Type.systemBars() or WindowInsetsCompat.Type.ime())
            view.setPadding(padding.left, padding.top, padding.right, padding.bottom)
            WindowInsetsCompat.CONSUMED
        }
        if (savedInstanceState == null) {
            val chat = EdnaSession.sdk?.getChatFragment() ?: ChatFragment.newInstance(OpenWay.DEFAULT)
            supportFragmentManager.beginTransaction().replace(container.id, chat, "edna-chat").commitNow()
        }
        onBackPressedDispatcher.addCallback(this, object : OnBackPressedCallback(true) {
            override fun handleOnBackPressed() {
                val chat = supportFragmentManager.findFragmentByTag("edna-chat") as? ChatFragment
                if (chat == null || chat.onBackPressed()) finish()
            }
        })
    }

    private val documentMimeTypes = arrayOf("application/pdf", "text/plain", "text/csv", "application/rtf",
        "application/msword", "application/vnd.openxmlformats-officedocument.wordprocessingml.document",
        "application/vnd.ms-excel", "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
        "application/vnd.ms-powerpoint", "application/vnd.openxmlformats-officedocument.presentationml.presentation",
        "application/vnd.oasis.opendocument.text", "application/vnd.oasis.opendocument.spreadsheet",
        "application/vnd.oasis.opendocument.presentation")
    private val fileRequests = mutableSetOf<Int>()

    override fun startActivityForResult(intent: android.content.Intent, requestCode: Int, options: Bundle?) {
        if (intent.action == android.content.Intent.ACTION_OPEN_DOCUMENT || intent.action == android.content.Intent.ACTION_GET_CONTENT) {
            fileRequests.add(requestCode)
            intent.type = "*/*"
            intent.putExtra(android.content.Intent.EXTRA_MIME_TYPES, arrayOf("image/*") + documentMimeTypes)
        }
        super.startActivityForResult(intent, requestCode, options)
    }

    @Deprecated("SDK activity result bridge")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: android.content.Intent?) {
        val uris = buildList {
            data?.data?.let { add(it) }
            data?.clipData?.let { clip -> for (i in 0 until clip.itemCount) add(clip.getItemAt(i).uri) }
        }
        val fileRequest = fileRequests.remove(requestCode)
        val blocked = fileRequest && resultCode == RESULT_OK && uris.any { uri ->
            val mime = runCatching { contentResolver.getType(uri) }.getOrNull()
            mime == null || !(mime.startsWith("image/") || mime in documentMimeTypes)
        }
        if (blocked) {
            android.widget.Toast.makeText(this, "Можно отправлять только изображения и документы", android.widget.Toast.LENGTH_LONG).show()
            super.onActivityResult(requestCode, RESULT_CANCELED, null)
        } else super.onActivityResult(requestCode, resultCode, data)
    }

    override fun onSaveInstanceState(outState: Bundle) {
        outState.putIntArray("bankFileRequests", fileRequests.toIntArray())
        super.onSaveInstanceState(outState)
    }

    private fun persistLastMessageDate() {
        val chat = supportFragmentManager.findFragmentByTag("edna-chat") as? ChatFragment ?: return
        val elements = runCatching {
            chat.javaClass.methods.firstOrNull { it.name.startsWith("getElements") }?.invoke(chat) as? Iterable<*>
        }.getOrNull() ?: return
        val timestamp = elements.mapNotNull { (it as? edna.chatcenter.core.models.ChatItem)?.timeStamp }
            .filter { it > 0L }.maxOrNull() ?: return
        getSharedPreferences("bakai_edna_chat", MODE_PRIVATE).edit()
            .putLong("last_message_timestamp", if (timestamp < 1_000_000_000_000L) timestamp * 1000 else timestamp)
            .apply()
    }

    override fun onDestroy() {
        persistLastMessageDate()
        val wasCurrent = current.get() === this
        if (wasCurrent) current.clear()
        super.onDestroy()
        if (wasCurrent && isFinishing && !isChangingConfigurations) {
            EdnaSession.refreshUnreadAfterClosing(sessionRevision)
        }
    }
}
