package kg.bakai.capacitor.edna

import android.graphics.Rect
import android.graphics.drawable.GradientDrawable
import android.util.TypedValue
import android.view.MotionEvent
import android.view.View
import android.view.ViewGroup
import android.view.ViewTreeObserver
import android.widget.RelativeLayout
import android.widget.LinearLayout
import android.widget.TextView
import android.view.Gravity
import androidx.recyclerview.widget.RecyclerView

/** Float the SDK's original action buttons above the touched message. */
internal object BankMessageActions {
    fun install(root: View, dismissSelection: () -> Unit) {
        val parent = root.findViewById<RelativeLayout>(edna.chatcenter.ui.R.id.chat_root) ?: return
        val list = root.findViewById<RecyclerView>(edna.chatcenter.ui.R.id.chatItemsRecycler) ?: return
        val controls = root.findViewById<LinearLayout>(edna.chatcenter.ui.R.id.copy_controls) ?: return
        val density = root.resources.displayMetrics.density
        fun dp(value: Int) = (value * density).toInt()
        (controls.parent as? ViewGroup)?.removeView(controls)
        parent.addView(controls, RelativeLayout.LayoutParams(
            ViewGroup.LayoutParams.WRAP_CONTENT, ViewGroup.LayoutParams.WRAP_CONTENT))
        val surface = TypedValue()
        root.context.theme.resolveAttribute(R.attr.bakaiEdnaSurface, surface, true)
        controls.background = GradientDrawable().apply {
            setColor(surface.data)
            cornerRadius = dp(16).toFloat()
        }
        controls.elevation = dp(8).toFloat()
        controls.setPadding(dp(8), dp(4), dp(8), dp(4))
        val outside = View(root.context).apply {
            visibility = View.GONE
            elevation = dp(7).toFloat()
            importantForAccessibility = View.IMPORTANT_FOR_ACCESSIBILITY_NO
            setOnClickListener { dismissSelection() }
        }
        parent.addView(outside, RelativeLayout.LayoutParams(-1, -1))
        val textColor = TypedValue()
        root.context.theme.resolveAttribute(R.attr.bakaiEdnaText, textColor, true)
        val actions = listOf(
            edna.chatcenter.ui.R.id.reply to R.string.bakai_edna_action_reply,
            edna.chatcenter.ui.R.id.content_copy to R.string.bakai_edna_action_copy
        ).map { (id, title) ->
            val sdkButton = controls.findViewById<View>(id)
            // Retain SDK ImageButton IDs/types/listeners, including swipe-to-reply.
            sdkButton.layoutParams = LinearLayout.LayoutParams(0, 0)
            sdkButton.importantForAccessibility = View.IMPORTANT_FOR_ACCESSIBILITY_NO
            val label = TextView(root.context).apply {
                setText(title)
                setTextColor(textColor.data)
                textSize = 15f
                gravity = Gravity.CENTER
                setPadding(dp(16), 0, dp(16), 0)
                minHeight = dp(48)
                isClickable = true
                isFocusable = true
                val selectable = TypedValue()
                context.theme.resolveAttribute(android.R.attr.selectableItemBackground, selectable, true)
                setBackgroundResource(selectable.resourceId)
                setOnClickListener {
                    if (sdkButton.isEnabled) sdkButton.performClick()
                    if (controls.visibility == View.VISIBLE) dismissSelection()
                }
            }
            controls.addView(label, LinearLayout.LayoutParams(-2, dp(48)))
            sdkButton to label
        }
        var anchor: View? = null
        list.addOnItemTouchListener(object : RecyclerView.SimpleOnItemTouchListener() {
            override fun onInterceptTouchEvent(rv: RecyclerView, event: MotionEvent): Boolean {
                if (event.actionMasked == MotionEvent.ACTION_DOWN && controls.visibility != View.VISIBLE) {
                    anchor = rv.findChildViewUnder(event.x, event.y)
                        ?.findViewById(edna.chatcenter.ui.R.id.bubble)
                }
                return false
            }
        })
        val observer = ViewTreeObserver.OnPreDrawListener {
            outside.visibility = controls.visibility
            for ((button, label) in actions) {
                label.visibility = button.visibility
                label.isEnabled = button.isEnabled
            }
            if (controls.visibility == View.VISIBLE) {
                val bubble = anchor
                if (bubble != null && bubble.isAttachedToWindow) {
                    val bounds = Rect()
                    bubble.getDrawingRect(bounds)
                    parent.offsetDescendantRectToMyCoords(bubble, bounds)
                    val listBounds = Rect()
                    list.getDrawingRect(listBounds)
                    parent.offsetDescendantRectToMyCoords(list, listBounds)
                    val margin = dp(8)
                    val x = (bounds.centerX() - controls.width / 2)
                        .coerceIn(margin, (parent.width - controls.width - margin).coerceAtLeast(margin))
                    val above = bounds.top - controls.height - margin
                    // At the top edge, place below the bubble instead of covering the header.
                    val preferredY = if (above >= listBounds.top) above else bounds.bottom + margin
                    val y = preferredY.coerceIn(listBounds.top,
                        (listBounds.bottom - controls.height).coerceAtLeast(listBounds.top))
                    controls.x = x.toFloat()
                    controls.y = y.toFloat()
                }
            }
            true
        }
        parent.viewTreeObserver.addOnPreDrawListener(observer)
        parent.addOnAttachStateChangeListener(object : View.OnAttachStateChangeListener {
            override fun onViewAttachedToWindow(v: View) {
                v.viewTreeObserver.removeOnPreDrawListener(observer)
                v.viewTreeObserver.addOnPreDrawListener(observer)
            }
            override fun onViewDetachedFromWindow(v: View) {
                v.viewTreeObserver.removeOnPreDrawListener(observer)
                anchor = null
                outside.visibility = View.GONE
            }
        })
    }
}
