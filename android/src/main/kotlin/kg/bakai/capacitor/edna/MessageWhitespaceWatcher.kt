package kg.bakai.capacitor.edna

import android.text.Editable
import android.text.TextWatcher
import android.widget.EditText

/** Uses a minimal edit so selection and IME spans outside the changed range survive. */
internal class MessageWhitespaceWatcher(private val input: EditText) : TextWatcher {
    private var updating = false
    override fun beforeTextChanged(s: CharSequence?, start: Int, count: Int, after: Int) = Unit
    override fun onTextChanged(s: CharSequence?, start: Int, before: Int, count: Int) = Unit
    override fun afterTextChanged(editable: Editable?) {
        if (updating || editable == null) return
        val original = editable.toString()
        val normalized = MessageWhitespace.normalize(original)
        if (original == normalized) return
        val start = input.selectionStart.coerceIn(0, original.length)
        val end = input.selectionEnd.coerceIn(0, original.length)
        var prefix = 0
        while (prefix < normalized.length && prefix < original.length && original[prefix] == normalized[prefix]) prefix++
        var suffix = 0
        while (suffix < normalized.length - prefix && suffix < original.length - prefix &&
            original[original.lastIndex - suffix] == normalized[normalized.lastIndex - suffix]) suffix++
        updating = true
        try {
            editable.replace(prefix, original.length - suffix, normalized.substring(prefix, normalized.length - suffix))
            input.setSelection(
                MessageWhitespace.normalize(original.substring(0, start)).length.coerceAtMost(editable.length),
                MessageWhitespace.normalize(original.substring(0, end)).length.coerceAtMost(editable.length))
        } finally { updating = false }
    }
}
