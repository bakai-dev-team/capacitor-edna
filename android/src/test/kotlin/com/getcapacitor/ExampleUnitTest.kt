package kg.bakai.capacitor.edna

import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

class EdnaPushTest {
    @Test
    fun classifiesOnlyEdnaOrigin() {
        assertTrue(EdnaPush.isEdnaPush(mapOf("origin" to "threads")))
        assertTrue(EdnaPush.isEdnaPush(mapOf("origin" to "THREADS")))
        assertFalse(EdnaPush.isEdnaPush(emptyMap()))
        assertFalse(EdnaPush.isEdnaPush(mapOf("origin" to "bank", "body" to "threads")))
        assertFalse(EdnaPush.isEdnaPush(mapOf("origin" to "threads-other")))
    }
}
