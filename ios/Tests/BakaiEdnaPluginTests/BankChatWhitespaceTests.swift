import XCTest
@testable import BakaiEdnaPlugin

final class BankChatWhitespaceTests: XCTestCase {
    func testWhitespaceNormalization() {
let cases = [("hello world", "hello world"), ("a    b", "a b"), ("a\n\n\n\nb", "a\n\nb"), ("a \n  \n \n b", "a\n\nb"), (" \t\n ", ""), ("a\r\n\r\n\r\nb", "a\n\nb"), ("👍🏽  👨‍👩‍👧", "👍🏽 👨‍👩‍👧"), ("a\u{00a0}\u{00a0}b", "a b"), ("a ", "a "), ("a\nb", "a\nb")]
for (input, expected) in cases {
    let output = BankChatWhitespace.normalize(input)
    XCTAssertEqual(output, expected)
    XCTAssertEqual(BankChatWhitespace.normalize(output), output)
}


    }
}
