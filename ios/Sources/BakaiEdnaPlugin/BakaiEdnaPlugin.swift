import Foundation
import UIKit
import Capacitor
import ChatCenterUI

@objc(BakaiEdnaPlugin)
public class BakaiEdnaPlugin: CAPPlugin, CAPBridgedPlugin, ChatCenterUISDKDelegate {
    public let identifier = "BakaiEdnaPlugin"
    public let jsName = "BakaiEdna"
    public let pluginMethods: [CAPPluginMethod] = [
        CAPPluginMethod(name: "refreshUnreadCount", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "initialize", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "authorize", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "openChat", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "closeChat", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "lockChat", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "setPushToken", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "isEdnaPush", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "logout", returnType: CAPPluginReturnPromise)
    ]

    private var sdk: ChatCenterUISDK?
    private var userId: String?
    private weak var chatNavigation: UINavigationController?
    private var presenting = false
    private var unlocked = false
    private var sessionRevision = 0
    private var unreadRevision = 0

    private func required(_ call: CAPPluginCall, _ key: String) -> String? {
        guard let value = call.getString(key), !value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            call.reject("\(key) is required", "INVALID_ARGUMENT")
            return nil
        }
        return value
    }

    private func endpoint(_ call: CAPPluginCall, _ key: String, scheme: String) -> String? {
        guard let value = required(call, key) else { return nil }
        guard let url = URLComponents(string: value), url.scheme == scheme,
              let host = url.host, !host.isEmpty, url.user == nil, url.password == nil else {
            call.reject("\(key) must be an absolute \(scheme) URL without credentials", "INVALID_ARGUMENT")
            return nil
        }
        return value
    }

    private func requireSDK(_ call: CAPPluginCall) -> ChatCenterUISDK? {
        guard let sdk else { call.reject("Call initialize first", "NOT_INITIALIZED"); return nil }
        return sdk
    }

    @objc func initialize(_ call: CAPPluginCall) {
        DispatchQueue.main.async {
            guard self.sdk == nil else {
                call.reject("Already initialized; restart the app to change deployment", "ALREADY_INITIALIZED")
                return
            }
            guard let provider = self.required(call, "providerUid"),
                  let rest = self.endpoint(call, "restUrl", scheme: "https"),
                  let socket = self.endpoint(call, "webSocketUrl", scheme: "wss"),
                  let store = self.endpoint(call, "dataStoreUrl", scheme: "https") else { return }
            let transport = ChatTransportConfig(rest: rest, webSocket: socket, dataStore: store)
            var config = ChatConfig(transportConfig: transport)
            config.voiceRecordingEnabled = false
            self.sdk = ChatCenterUISDK(providerUid: provider, appMarker: call.getString("appMarker"),
                                       chatConfig: config)
            // Apply localization in openChat, once the host app provides its language.
            self.sdk?.delegate = self
            call.resolve()
        }
    }

    @objc func authorize(_ call: CAPPluginCall) {
        DispatchQueue.main.async {
            guard let sdk = self.requireSDK(call),
                  let id = self.required(call, "userId") else { return }
            let token = call.getString("token")
            let scheme = call.getString("scheme")
            if let token, token.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                call.reject("token must not be blank when provided", "INVALID_ARGUMENT")
                return
            }
            if let scheme, token == nil || scheme.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                call.reject("scheme requires a token", "INVALID_ARGUMENT")
                return
            }
            guard !self.presenting else { call.reject("Chat is transitioning", "CHAT_BUSY"); return }
            if let current = self.userId, current != id {
                call.reject("Call logout before changing user", "LOGOUT_REQUIRED")
                return
            }
            let fullName = call.getString("fullName")?.trimmingCharacters(in: .whitespacesAndNewlines)
            let deviceId = call.getString("deviceId")?.trimmingCharacters(in: .whitespacesAndNewlines)
            guard fullName?.isEmpty != true, deviceId?.isEmpty != true else {
                call.reject("fullName and deviceId must not be blank when provided", "INVALID_ARGUMENT")
                return
            }
            let user = ChatUser(identifier: id, name: fullName,
                                data: deviceId.map { ["deviceId": $0] })
            if self.userId != id { self.sessionRevision += 1 }
            // authorize may synchronously report the initial unread count.
            self.userId = id
            if let token {
                sdk.authorize(user: user, auth: ChatAuth(token: token, scheme: scheme))
            } else {
                sdk.authorize(user: user)
            }
            self.unlocked = true
            call.resolve()
        }
    }

    public func chatCenterUI(chatCenter: ChatCenterUISDK, didChangeUnreadMessages count: Int) {
        guard let id = userId else { return }
        unreadRevision += 1
        notifyListeners("unreadCountChanged", data: ["count": count, "userId": id])
    }

    @objc func refreshUnreadCount(_ call: CAPPluginCall) {
        DispatchQueue.main.async {
            guard let sdk = self.requireSDK(call) else { return }
            guard let id = self.userId else { call.reject("Call authorize first", "NOT_AUTHORIZED"); return }
            let session = self.sessionRevision
            let revision = self.unreadRevision
            do {
                try sdk.getUnreadMessagesCount { result in
                    DispatchQueue.main.async {
                        guard self.userId == id, self.sessionRevision == session else {
                            call.reject("Session changed", "SESSION_CHANGED"); return
                        }
                        switch result {
                        case .success(let count):
                            // A live read event is newer than this REST request.
                            if self.unreadRevision == revision {
                                self.unreadRevision += 1
                                self.notifyListeners("unreadCountChanged", data: ["count": count, "userId": id])
                            }
                            call.resolve()
                        case .failure:
                            call.reject("Could not get unread count", "EDNA_ERROR")
                        }
                    }
                }
            } catch { call.reject("Could not get unread count", "EDNA_ERROR") }
        }
    }

    @objc func openChat(_ call: CAPPluginCall) {
        DispatchQueue.main.async {
            guard let sdk = self.requireSDK(call) else { return }
            guard self.userId != nil, self.unlocked else { call.reject("Call authorize first", "NOT_AUTHORIZED"); return }
            guard !self.presenting, self.chatNavigation == nil else {
                call.reject("Chat is already open", "CHAT_ALREADY_OPEN"); return
            }
            guard let host = self.bridge?.viewController, host.viewIfLoaded?.window != nil,
                  host.presentedViewController == nil else {
                call.reject("Host is unavailable or already presenting a screen", "NO_ACTIVITY"); return
            }
            do {
                if let message = call.getString("prefilledMessage") { sdk.prefill(message: BankChatWhitespace.normalize(message)) }
                let themeName = call.getString("theme") ?? "light"
                let palette = BankChatTheme.Palette(themeName)
                let theme = BankChatTheme.create(themeName)
                sdk.theme = theme
                sdk.darkTheme = theme
                try BankEdnaLocalization.configure(sdk, language: call.getString("language"), systemLanguage: call.getString("systemLanguage"))
                let chat = try sdk.getChat()
                let navigation = BankChatNavigationController(rootViewController: chat, palette: palette)
                navigation.clientAvatar = BankChatAvatar.clientPlaceholder()
                if let value = call.getString("clientAvatarDataUrl"), value.count <= 131072,
                   let payload = value.split(separator: ",", maxSplits: 1).last,
                   let data = Data(base64Encoded: String(payload)) {
                    navigation.clientAvatar = UIImage(data: data)
                }
                navigation.onClose = { [weak self] in self?.dismissChatButton() }
                navigation.overrideUserInterfaceStyle = palette.isDark ? .dark : .light
                navigation.modalPresentationStyle = .fullScreen
                self.chatNavigation = navigation
                self.unreadRevision += 1
                self.presenting = true
                host.present(navigation, animated: true) {
                    self.presenting = false
                    call.resolve()
                }
            } catch { call.reject("Could not open edna chat", "EDNA_ERROR") }
        }
    }

    @objc private func dismissChatButton() {
        guard !presenting, let navigation = chatNavigation else { return }
        presenting = true
        navigation.dismiss(animated: true) {
            self.chatNavigation = nil
            self.presenting = false
            self.refreshUnreadAfterClosing()
        }
    }

    private func refreshUnreadAfterClosing() {
        guard let sdk, let id = userId, unlocked else { return }
        let session = sessionRevision
        // Read receipts can reach the server after the dismissal animation.
        for delay in [0.0, 1.0, 3.0] {
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
                guard let self, self.sessionRevision == session, self.userId == id,
                      self.unlocked, self.chatNavigation == nil else { return }
                let revision = self.unreadRevision
                try? sdk.getUnreadMessagesCount { [weak self] result in
                    DispatchQueue.main.async {
                        guard let self, self.sessionRevision == session, self.userId == id,
                              self.unlocked, self.chatNavigation == nil,
                              self.unreadRevision == revision,
                              case let .success(count) = result else { return }
                        self.unreadRevision += 1
                        self.notifyListeners("unreadCountChanged", data: ["count": count, "userId": id])
                    }
                }
            }
        }
    }

    private func close(_ call: CAPPluginCall, completion: @escaping () -> Void) {
        guard !presenting else { call.reject("Chat is opening; retry once presented", "CHAT_BUSY"); return }
        if let navigation = chatNavigation {
            presenting = true
            navigation.dismiss(animated: true) {
                self.chatNavigation = nil
                self.presenting = false
                completion()
            }
        } else { completion() }
    }

    @objc func closeChat(_ call: CAPPluginCall) {
        DispatchQueue.main.async {
            self.close(call) {
                self.refreshUnreadAfterClosing()
                call.resolve()
            }
        }
    }

    @objc func lockChat(_ call: CAPPluginCall) {
        DispatchQueue.main.async {
            self.unlocked = false
            self.close(call) { call.resolve() }
        }
    }

    @objc func setPushToken(_ call: CAPPluginCall) {
        DispatchQueue.main.async {
            guard let token = self.required(call, "token") else { return }
            guard let deviceToken = EdnaPush.deviceToken(fromHex: token) else {
                call.reject("Expected a hexadecimal APNs device token, not an FCM token", "INVALID_ARGUMENT")
                return
            }
            EdnaPush.setDeviceToken(deviceToken)
            call.resolve()
        }
    }

    @objc func isEdnaPush(_ call: CAPPluginCall) {
        let data = call.getObject("data") ?? [:]
        call.resolve(["matches": ChatCenterUISDK.isChatCenterNotification(data)])
    }

    @objc func logout(_ call: CAPPluginCall) {
        DispatchQueue.main.async {
            self.unlocked = false
            self.sessionRevision += 1
            guard let sdk = self.sdk, self.userId != nil else { call.resolve(); return }
            self.close(call) {
                do {
                    self.unlocked = false
                    try sdk.logout()
                    self.userId = nil
                    call.resolve()
                } catch { call.reject("Could not log out of edna", "EDNA_ERROR") }
            }
        }
    }
}
