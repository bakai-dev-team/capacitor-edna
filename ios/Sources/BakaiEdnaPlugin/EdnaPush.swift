import Foundation
import ChatCenterUI

/// Call directly from AppDelegate; its Capacitor registration event may contain an FCM token.
public enum EdnaPush {
    internal static func deviceToken(fromHex value: String) -> Data? {
        let characters = Array(value.utf8)
        guard !characters.isEmpty, characters.count.isMultiple(of: 2) else { return nil }
        func nibble(_ character: UInt8) -> UInt8? {
            switch character {
            case 48...57: return character - 48
            case 65...70: return character - 65 + 10
            case 97...102: return character - 97 + 10
            default: return nil
            }
        }
        var bytes = [UInt8]()
        for index in stride(from: 0, to: characters.count, by: 2) {
            guard let high = nibble(characters[index]), let low = nibble(characters[index + 1]) else { return nil }
            bytes.append(high * 16 + low)
        }
        return Data(bytes)
    }

    public static func setDeviceToken(_ token: Data) {
        ChatCenterUISDK.setDeviceToken(token)
    }

    public static func isEdnaPush(_ data: [AnyHashable: Any]) -> Bool {
        guard let payload = data as? [String: Any] else { return false }
        return ChatCenterUISDK.isChatCenterNotification(payload)
    }
}
