package kg.bakai.capacitor.edna;
import org.junit.Test;
public class MessageWhitespaceTest {
 @Test public void normalizesWhitespaceWithoutChangingContent() {
  String[][] cases = {{"hello world", "hello world"}, {"a    b", "a b"}, {"a\n\n\n\n\nb", "a\n\nb"}, {"a \n  \n \n b", "a\n\nb"}, {" \t\n ", ""}, {"a\r\n\r\n\r\nb", "a\n\nb"}, {"👍🏽  👨‍👩‍👧", "👍🏽 👨‍👩‍👧"}, {"a\u00a0\u00a0b", "a b"}, {"a ", "a "}, {"a\nb", "a\nb"}};
  for(String[] c:cases) {
   String out=MessageWhitespace.normalize(c[0]);
   if(!out.equals(c[1])) throw new AssertionError(c[0]+" => "+out);
   if(!out.equals(MessageWhitespace.normalize(out)))throw new AssertionError("Not idempotent");
  }

 }
}
