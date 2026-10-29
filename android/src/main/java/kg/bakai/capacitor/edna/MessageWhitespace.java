package kg.bakai.capacitor.edna;

/** Bounds whitespace without changing words, emoji or ordinary paragraph breaks. */
public final class MessageWhitespace {
    private MessageWhitespace() {}

    public static String normalize(String text) {
        return text.replace("\r\n", "\n").replace('\r', '\n')
            .replaceAll("[\\t\\p{Zs}]+", " ")
            .replaceAll(" *\\n *", "\n")
            .replaceAll("\\n{3,}", "\n\n")
            .replaceAll("^[ \\n]+", "");
    }
}
