package kg.bakai.capacitor.edna

import android.content.ComponentName
import androidx.test.ext.junit.runners.AndroidJUnit4
import androidx.test.platform.app.InstrumentationRegistry
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNotEquals
import org.junit.Test
import org.junit.runner.RunWith

@RunWith(AndroidJUnit4::class)
class EdnaChatManifestTest {
    @Test
    fun chatActivityIsRegisteredAndNotExported() {
        val context = InstrumentationRegistry.getInstrumentation().targetContext
        val info = context.packageManager.getActivityInfo(ComponentName(context, EdnaChatActivity::class.java), 0)
        assertFalse(info.exported)
        assertNotEquals(0, info.theme)
    }
}
