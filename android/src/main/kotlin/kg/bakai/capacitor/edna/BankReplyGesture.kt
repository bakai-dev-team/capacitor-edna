package kg.bakai.capacitor.edna

import android.view.MotionEvent
import android.view.View
import android.view.ViewGroup
import androidx.recyclerview.widget.RecyclerView

/** Uses the SDK's existing selection/reply actions so it owns the quote draft. */
internal object BankReplyGesture {
    fun install(root: View) {
        val list = root.findViewById<RecyclerView>(edna.chatcenter.ui.R.id.chatItemsRecycler) ?: return
        val threshold = 56 * root.resources.displayMetrics.density
        val slop = android.view.ViewConfiguration.get(root.context).scaledTouchSlop
        list.addOnChildAttachStateChangeListener(object : RecyclerView.OnChildAttachStateChangeListener {
            override fun onChildViewAttachedToWindow(view: View) = clearTranslation(view)
            override fun onChildViewDetachedFromWindow(view: View) = clearTranslation(view)
            private fun clearTranslation(view: View) {
                view.findViewById<View>(edna.chatcenter.ui.R.id.bubble)?.let {
                    it.animate().cancel()
                    it.translationX = 0f
                }
            }
        })
        list.addOnItemTouchListener(object : RecyclerView.SimpleOnItemTouchListener() {
            var startX = 0f
            var startY = 0f
            var row: View? = null
            var swiping = false
            var moving: View? = null

            fun reset() {
                moving?.animate()?.translationX(0f)?.setDuration(180)?.start()
                moving = null
                row = null
                swiping = false
            }

            fun move(event: MotionEvent) {
                moving?.translationX = (event.x - startX).coerceIn(-threshold * 1.5f, 0f)
            }

            override fun onInterceptTouchEvent(rv: RecyclerView, event: MotionEvent): Boolean {
                when (event.actionMasked) {
                    MotionEvent.ACTION_DOWN -> {
                        reset()
                        startX = event.x; startY = event.y
                        row = rv.findChildViewUnder(event.x, event.y)
                            ?.takeIf { it.findViewById<View>(edna.chatcenter.ui.R.id.bubble) != null }
                    }
                    MotionEvent.ACTION_MOVE -> {
                        val dx = event.x - startX
                        val dy = kotlin.math.abs(event.y - startY)
                        if (dy > threshold / 3 && dy > kotlin.math.abs(dx)) row = null
                        if (row != null && dx < -slop && kotlin.math.abs(dx) > dy * 2) {
                            swiping = true
                            moving = row?.findViewById(edna.chatcenter.ui.R.id.bubble)
                            moving?.animate()?.cancel()
                            move(event)
                            rv.parent.requestDisallowInterceptTouchEvent(true)
                            return true
                        }
                    }
                    MotionEvent.ACTION_CANCEL, MotionEvent.ACTION_UP -> reset()
                }
                return false
            }

            override fun onTouchEvent(rv: RecyclerView, event: MotionEvent) {
                if (event.actionMasked == MotionEvent.ACTION_MOVE) move(event)
                if (event.actionMasked == MotionEvent.ACTION_UP) {
                    val selected = row
                    if (swiping && event.x - startX < -threshold && selected?.parent === rv) {
                        val bubble = selected.findViewById<View>(edna.chatcenter.ui.R.id.bubble)
                        if (longClick(bubble) || longClick(selected)) {
                            root.post {
                                val reply = root.findViewById<View>(edna.chatcenter.ui.R.id.reply)
                                if (reply?.isShown == true && reply.isEnabled) reply.performClick()
                            }
                        }
                    }
                }
                if (event.actionMasked == MotionEvent.ACTION_UP || event.actionMasked == MotionEvent.ACTION_CANCEL) {
                    reset()
                    rv.parent.requestDisallowInterceptTouchEvent(false)
                }
            }
        })
    }

    private fun longClick(view: View?): Boolean {
        if (view == null) return false
        if (view.isLongClickable && view.performLongClick()) return true
        if (view is ViewGroup) for (i in 0 until view.childCount) {
            if (longClick(view.getChildAt(i))) return true
        }
        return false
    }
}
