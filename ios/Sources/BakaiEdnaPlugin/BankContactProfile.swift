import UIKit
import WebKit

internal final class BankContactProfile: UIViewController, WKNavigationDelegate {
    private let dark: Bool
    init(dark: Bool) {
        self.dark = dark
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .pageSheet
        if let sheet = sheetPresentationController {
            sheet.detents = [.large()]
            sheet.prefersGrabberVisible = false
            sheet.preferredCornerRadius = 24
        }
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    override func viewDidLoad() {
        super.viewDidLoad()
        overrideUserInterfaceStyle = dark ? .dark : .light
        let web = WKWebView(frame: view.bounds)
        web.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        web.navigationDelegate = self
        web.isOpaque = false
        web.backgroundColor = dark ? UIColor(red: 23/255, green: 24/255, blue: 25/255, alpha: 1) : .systemGroupedBackground
        web.scrollView.contentInsetAdjustmentBehavior = .never
        view.backgroundColor = web.backgroundColor
        view.addSubview(web)
        #if SWIFT_PACKAGE
        let resources = Bundle.module
        #else
        guard let bundleURL = Bundle(for: BakaiEdnaPlugin.self).url(forResource: "BakaiEdnaResources", withExtension: "bundle"),
              let resources = Bundle(url: bundleURL) else { return }
        #endif
        guard let url = resources.url(forResource: "bakai_edna_profile", withExtension: "html"),
              var html = try? String(contentsOf: url, encoding: .utf8) else { return }
        let russian = BankEdnaLocalization.language == "ru"
        let kyrgyz = BankEdnaLocalization.language == "ky"
        for (key, value) in ["__THEME__": dark ? "dark" : "light", "__BANK__": russian ? "БАКАЙ БАНК" : kyrgyz ? "БАКАЙ БАНК" : "BAKAI BANK",
            "__CONTACTS__": russian ? "Контакты" : kyrgyz ? "Байланыш маалыматы" : "Contacts", "__SITE__": russian ? "Сайт" : kyrgyz ? "Сайт" : "Website",
            "__PHONE__": russian ? "Номер" : kyrgyz ? "Номер" : "Phone", "__CLOSE__": russian ? "Закрыть" : kyrgyz ? "Жабуу" : "Close"] {
            html = html.replacingOccurrences(of: key, with: value)
        }
        web.loadHTMLString(html, baseURL: nil)
    }
    func webView(_ webView: WKWebView, decidePolicyFor action: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        guard action.navigationType == .linkActivated, let url = action.request.url else { decisionHandler(.allow); return }
        decisionHandler(.cancel)
        if url.scheme == "bankprofile" { dismiss(animated: true); return }
        if url.scheme == "https" || url.scheme == "tel" { UIApplication.shared.open(url) }
    }
}
