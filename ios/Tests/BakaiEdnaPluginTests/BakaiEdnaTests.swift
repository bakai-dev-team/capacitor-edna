import Foundation
import XCTest
@testable import BakaiEdnaPlugin

final class BakaiEdnaTests: XCTestCase {
    func testDeviceTokenPreservesBytesAndAcceptsBothHexCases() {
        XCTAssertEqual(EdnaPush.deviceToken(fromHex: "00aB10Ff"), Data([0, 171, 16, 255]))
    }

    func testInvalidDeviceTokensAreRejected() {
        for token in ["", "0", "abc", "gg", "00 11", "<0011>", "fcm:token", "ＡＢ"] {
            XCTAssertNil(EdnaPush.deviceToken(fromHex: token), "Unexpectedly accepted: \(token)")
        }
    }
}
