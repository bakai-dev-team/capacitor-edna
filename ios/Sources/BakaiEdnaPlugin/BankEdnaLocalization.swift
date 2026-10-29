import Foundation
import ChatCenterUI

internal enum BankEdnaLocalization {
    static var language = "en"
    static func configure(_ sdk: ChatCenterUISDK, language selected: String? = nil, systemLanguage: String? = nil) throws {
        let preferred = selected ?? systemLanguage ?? (UserDefaults.standard.stringArray(forKey: "AppleLanguages") ?? Locale.preferredLanguages).first ?? "en"
        let code = preferred.lowercased().replacingOccurrences(of: "_", with: "-").split(separator: "-").first.map(String.init) ?? "en"
        let language = ["ru", "ky"].contains(code) ? code : "en"
        self.language = language
        let locale = Locale(identifier: language)
        let sdkBundle = Bundle(for: ChatCenterUISDK.self)
        let localizationBundle: Bundle
        if language == "ky" {
            #if SWIFT_PACKAGE
            localizationBundle = Bundle.module
            #else
            if let url = Bundle(for: BakaiEdnaPlugin.self).url(forResource: "BakaiEdnaResources", withExtension: "bundle"),
               let resources = Bundle(url: url) {
                localizationBundle = resources
            } else {
                localizationBundle = sdkBundle
            }
            #endif
        } else {
            localizationBundle = sdkBundle
        }
        // A root bundle resolves localizedString using iOS preferred languages.
        // Pin the bundle itself to the host app's selected language.
        guard let path = localizationBundle.path(forResource: language, ofType: "lproj"),
              let selectedBundle = Bundle(path: path) else {
            throw NSError(domain: "BakaiEdnaLocalization", code: 1,
                          userInfo: [NSLocalizedDescriptionKey: "Missing EDNA localization: \(language)"])
        }
        sdk.localizationConfig = ChatLocalizationConfig(bundle: selectedBundle,
            tableName: "ChatLocalizable", locale: locale)
        MigrationServiceLocator.currentLocale = locale
    }
}
