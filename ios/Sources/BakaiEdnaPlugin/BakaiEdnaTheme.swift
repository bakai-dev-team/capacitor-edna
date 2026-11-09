import UIKit
import ObjectiveC
import QuickLook
import UniformTypeIdentifiers
import CoreImage
import CoreText
import ChatCenterUI

/// Uses the same palette and type sizes as BakaiEdnaTheme.kt.
internal enum BankChatTheme {
    struct Palette {
        let accent: UIColor
        let composerIcon: UIColor
        let background: UIColor
        let incoming: UIColor
        let outgoing: UIColor
        let text: UIColor
        let input: UIColor
        let muted: UIColor
        let read: UIColor
        let status: UIColor
        let isDark: Bool

        init(_ name: String) {
            let values: [UInt32]
            switch name {
            case "dark": values = [0x0085F7, 0x171819, 0x1D2431, 0x1C1E24, 0xF5F5F5, 0x242526, 0x9CA3AF]
            case "ifcDark": values = [0x337872, 0x000606, 0x1D2431, 0x001211, 0xFFFFFF, 0x0F1515, 0x9CA3AF]
            case "ifcLight": values = [0x1D7F76, 0xF5F5F5, 0xFFFFFF, 0xFFFFFF, 0x07203A, 0xE7E8EA, 0x626970]
            default: values = [0x0466EB, 0xF5F5F5, 0xFFFFFF, 0xFFFFFF, 0x07203A, 0xE7E8EA, 0x626970]
            }
            func color(_ hex: UInt32) -> UIColor {
                UIColor(red: CGFloat((hex >> 16) & 255) / 255,
                        green: CGFloat((hex >> 8) & 255) / 255,
                        blue: CGFloat(hex & 255) / 255, alpha: 1)
            }
            composerIcon = color(name.hasPrefix("ifc") ? 0x047857 : 0x007AFF)
            accent = color(values[0]); background = color(values[1])
            incoming = color(values[2]); outgoing = color(values[3])
            text = color(values[4]); input = color(values[5]); muted = color(values[6])
            read = color(name.hasPrefix("ifc") ? 0x5DB6AE : 0x2C9EFF)
            status = name == "dark" ? color(0x9CA3AF) : name == "ifcDark" ? UIColor.white.withAlphaComponent(0.7) : color(0x2D465B).withAlphaComponent(0.7)
            isDark = name == "dark" || name == "ifcDark"
        }
    }

    static func create(_ name: String) -> ChatTheme {
        let p = Palette(name)
        let colors = ChatColors()
        colors.main = p.accent
        colors.secondary = p.muted
        colors.disabled = p.muted
        colors.background = p.background
        colors.backgroundWhite = p.input
        colors.link = p.accent
        colors.linkLight = p.accent
        let fonts = ChatTypography()
        fonts.title = .systemFont(ofSize: 14, weight: .semibold)
        fonts.subtitle = .systemFont(ofSize: 11)
        fonts.body = .systemFont(ofSize: 16)
        fonts.message = .systemFont(ofSize: 16)
        fonts.caption = .systemFont(ofSize: 12)
        fonts.caption2 = .systemFont(ofSize: 10)
        fonts.footnote = .systemFont(ofSize: 12)
        let images = ChatImages()
        if let welcome = BankChatAvatar.welcomeImage() {
            images.emptyChatPlaceholderImage = ChatImage(image: welcome, renderingMode: .alwaysOriginal)
        }
        images.sendButtonImage = ChatImage(image: sendImage(), tintColor: p.composerIcon)
        images.attachButtonImage = ChatImage(image: attachImage(), tintColor: p.muted)
        images.backButtonImage = ChatImage(system: "arrow.left", size: 20, tintColor: p.text)
        let theme = ChatTheme(colors: colors, images: images, typography: fonts)
        let flow = theme.flows.chatFlow
        flow.backgroundColor = p.background
        // Give the sheet a distinct surface and an explicit, independent text style.
        flow.addFileMenuStyle.backgroundColor = p.incoming
        flow.addFileMenuStyle.tintColor = p.text
        flow.addFileMenuStyle.titleTextStyle = ChatTextStyle(font: fonts.body, color: p.text)
        flow.pullToRefreshColor = p.accent
        for (messages, bubble) in [(flow.incomeMessages, p.incoming), (flow.outcomeMessages, p.outgoing)] {
            messages.bubbleTintColor = bubble
            messages.backgroundColor = bubble
            messages.cornerRadius = 14
            let mask = UIGraphicsImageRenderer(size: CGSize(width: 30, height: 30)).image { _ in
                bubble.setFill()
                UIBezierPath(roundedRect: CGRect(x: 0, y: 0, width: 30, height: 30), cornerRadius: 14).fill()
            }.resizableImage(withCapInsets: UIEdgeInsets(top: 14, left: 14, bottom: 14, right: 14))
            messages.bubbleMaskImage = ChatImage(image: mask, renderingMode: .alwaysOriginal)
            messages.bubbleMaskInsets = UIEdgeInsets(top: 14, left: 14, bottom: 14, right: 14)
            messages.textMessageStyle.textViewInsets = .zero
            messages.textMessageStyle.textInsets = UIEdgeInsets(top: 5, left: 10, bottom: 5, right: 10)
            for message in [messages.textMessageStyle as ChatMessageStyle, messages.imageMessageStyle,
                            messages.audioMessageStyle, messages.fileMessageStyle] {
                message.containerLeftOffset = 8
                message.containerRightOffset = 8
                message.messageBubbleEndMargin = 3
                message.textStyle = ChatTextStyle(font: fonts.message, color: p.text)
                message.timeTextStyle = ChatTextStyle(font: fonts.caption2, color: p.muted)
                message.readStatusImage = ChatImage(image: message.readStatusImage.uiImage, tintColor: p.read)
                message.pendingStatusImage = ChatImage(image: message.pendingStatusImage.uiImage, tintColor: p.status)
                message.deliveredStatusImage = ChatImage(image: message.deliveredStatusImage.uiImage, tintColor: p.status)
            }
            messages.textMessageStyle.linkTextStyle = ChatTextStyle(font: fonts.message, color: p.accent)
            messages.quoteStyle.backgroundColor = p.input
            messages.quoteStyle.authorTextStyle.color = p.accent
            messages.quoteStyle.messageTextStyle.color = p.text
            messages.quoteStyle.separatorColor = p.accent
        }
        flow.incomeMessages.avatarOffset = 3
        // Loading is shown in the bank header; hide the SDK HUD's backing
        // surfaces as well as its contents, otherwise an empty square remains.
        flow.loadingChatStyle.backgroundColor = .clear
        flow.loadingChatStyle.indicatorStyle.backgroundColor = .clear
        flow.loadingChatStyle.textStyle.color = .clear
        flow.loadingChatStyle.indicatorStyle.indicatorColor = .clear
        flow.outcomeMessages.showAvatar = true
        flow.outcomeMessages.avatarSize = CGSize(width: 42, height: 42)
        flow.outcomeMessages.avatarOffset = 3
        flow.systemMessages.dateMessageStyle = ChatTextStyle(font: fonts.caption, color: p.muted)
        flow.systemMessages.surveyMessageStyle.questionTitleTextStyle.color = p.text
        flow.systemMessages.surveyMessageStyle.questionSubtitleTextStyle.color = p.muted

        let input = flow.inputViewStyle
        input.backgroundColor = p.background
        input.separatorLineColor = .clear
        input.alignment = .bottom
        input.inputTextStyle.backgroundColor = p.input
        input.inputTextStyle.cornerRadius = 22
        input.inputTextStyle.hasBorder = false
        input.inputTextStyle.borderWidth = 0
        input.inputTextStyle.minimumHeight = 44
        input.inputTextStyle.maximumHeight = 160
        input.inputTextStyle.cursorColor = p.accent
        input.inputTextStyle.textStyle = ChatTextStyle(font: .systemFont(ofSize: 15), color: p.text)
        for button in [input.sendButtonStyle, input.voiceButtonStyle, input.attachButtonStyle] {
            button.backgroundColor = p.input
            button.cornerRadius = 22
            button.tintColor = p.accent
            button.color = ChatButtonColor(normal: p.accent, highlighted: p.accent.withAlphaComponent(0.7), disabled: p.muted)
        }
        for button in [input.sendButtonStyle, input.attachButtonStyle] {
            button.tintColor = p.composerIcon
            button.color = ChatButtonColor(normal: p.composerIcon, highlighted: p.composerIcon.withAlphaComponent(0.7), disabled: p.muted)
        }
        input.attachButtonStyle.tintColor = p.muted
        input.attachButtonStyle.color = ChatButtonColor(normal: p.muted, highlighted: p.muted.withAlphaComponent(0.7), disabled: p.muted)
        input.quoteStyle.backgroundColor = p.input
        input.quoteStyle.titleTextStyle.color = p.text
        input.quoteStyle.subtitleTextStyle.color = p.muted
        input.quoteStyle.messageAuthorTextStyle.color = p.accent
        input.quoteStyle.messageTextStyle.color = p.text
        let bar = flow.navigationBarStyle
        bar.backgroundColor = p.background
        bar.tintColor = p.text
        bar.backButtonColor = p.text
        bar.showCloseButton = false
        bar.keyboardControlVisible = false
        bar.subtitleVisible = true
        bar.subtitleShowOrgUnit = true
        bar.titleTextStyle = ChatTextStyle(font: fonts.title, color: p.text)
        bar.subtitleTextStyle = ChatTextStyle(font: fonts.subtitle, color: p.text)
        bar.searchButtonStyle.backgroundColor = p.input
        bar.searchButtonStyle.cornerRadius = 20
        bar.searchButtonStyle.image = ChatImage(system: "magnifyingglass", size: 20, tintColor: p.text)
        theme.flows.searchFlow.backgroundColor = p.background
        theme.flows.searchFlow.searchMessageStyle.textStyle.color = p.text
        theme.flows.searchFlow.searchMessageStyle.timeTextStyle.color = p.muted
        BankChatAvatar.apply(to: theme)
        return theme
    }

    // Exact contours from Android res/drawable/bakai_edna_send.xml.
    private static func sendImage() -> UIImage {
        UIGraphicsImageRenderer(size: CGSize(width: 20, height: 20)).image { _ in
            let path = UIBezierPath()
            path.move(to: CGPoint(x: 15.0581, y: 7.09153))
            path.addLine(to: CGPoint(x: 7.92473, y: 3.52487))
            path.addCurve(to: CGPoint(x: 3.5664, y: 7.8832), controlPoint1: CGPoint(x: 3.13306, y: 1.12487), controlPoint2: CGPoint(x: 1.1664, y: 3.09153))
            path.addLine(to: CGPoint(x: 4.2914, y: 9.3332))
            path.addCurve(to: CGPoint(x: 4.2914, y: 10.6749), controlPoint1: CGPoint(x: 4.49973, y: 9.7582), controlPoint2: CGPoint(x: 4.49973, y: 10.2499))
            path.addLine(to: CGPoint(x: 3.5664, y: 12.1165))
            path.addCurve(to: CGPoint(x: 7.92473, y: 16.4749), controlPoint1: CGPoint(x: 1.1664, y: 16.9082), controlPoint2: CGPoint(x: 3.12473, y: 18.8749))
            path.addLine(to: CGPoint(x: 15.0581, y: 12.9082))
            path.addCurve(to: CGPoint(x: 15.0581, y: 7.09153), controlPoint1: CGPoint(x: 18.2581, y: 11.3082), controlPoint2: CGPoint(x: 18.2581, y: 8.69153))
            path.close()
            path.move(to: CGPoint(x: 12.3664, y: 10.6249))
            path.addLine(to: CGPoint(x: 7.8664, y: 10.6249))
            path.addCurve(to: CGPoint(x: 7.2414, y: 9.99987), controlPoint1: CGPoint(x: 7.52473, y: 10.6249), controlPoint2: CGPoint(x: 7.2414, y: 10.3415))
            path.addCurve(to: CGPoint(x: 7.8664, y: 9.37487), controlPoint1: CGPoint(x: 7.2414, y: 9.6582), controlPoint2: CGPoint(x: 7.52473, y: 9.37487))
            path.addLine(to: CGPoint(x: 12.3664, y: 9.37487))
            path.addCurve(to: CGPoint(x: 12.9914, y: 9.99987), controlPoint1: CGPoint(x: 12.7081, y: 9.37487), controlPoint2: CGPoint(x: 12.9914, y: 9.6582))
            path.addCurve(to: CGPoint(x: 12.3664, y: 10.6249), controlPoint1: CGPoint(x: 12.9914, y: 10.3415), controlPoint2: CGPoint(x: 12.7081, y: 10.6249))
            path.close()
            UIColor.white.setFill()
            path.fill()
        }.withRenderingMode(.alwaysTemplate)
    }

    // Exact contours from Android res/drawable/bakai_edna_attach.xml.
    private static func attachImage() -> UIImage {
        UIGraphicsImageRenderer(size: CGSize(width: 22, height: 22.0 * 278 / 286)).image { context in
            context.cgContext.scaleBy(x: 22.0 / 286, y: 22.0 / 286)
            context.cgContext.translateBy(x: 0, y: 278)
            context.cgContext.scaleBy(x: 0.1, y: -0.1)
            let path = UIBezierPath()
            path.move(to: CGPoint(x: 819, y: 2704))
            path.addCurve(to: CGPoint(x: 489, y: 2578), controlPoint1: CGPoint(x: 710, y: 2685), controlPoint2: CGPoint(x: 585, y: 2637))
            path.addCurve(to: CGPoint(x: 176, y: 2262), controlPoint1: CGPoint(x: 379, y: 2510), controlPoint2: CGPoint(x: 241, y: 2372))
            path.addCurve(to: CGPoint(x: 51, y: 1907), controlPoint1: CGPoint(x: 118, y: 2165), controlPoint2: CGPoint(x: 65, y: 2015))
            path.addCurve(to: CGPoint(x: 51, y: 853), controlPoint1: CGPoint(x: 37, y: 1804), controlPoint2: CGPoint(x: 37, y: 956))
            path.addCurve(to: CGPoint(x: 176, y: 498), controlPoint1: CGPoint(x: 65, y: 745), controlPoint2: CGPoint(x: 118, y: 595))
            path.addCurve(to: CGPoint(x: 467, y: 196), controlPoint1: CGPoint(x: 237, y: 397), controlPoint2: CGPoint(x: 370, y: 258))
            path.addCurve(to: CGPoint(x: 759, y: 67), controlPoint1: CGPoint(x: 552, y: 141), controlPoint2: CGPoint(x: 652, y: 97))
            path.addCurve(to: CGPoint(x: 1387, y: 42), controlPoint1: CGPoint(x: 832, y: 47), controlPoint2: CGPoint(x: 859, y: 46))
            path.addCurve(to: CGPoint(x: 2203, y: 100), controlPoint1: CGPoint(x: 1999, y: 39), controlPoint2: CGPoint(x: 2040, y: 42))
            path.addCurve(to: CGPoint(x: 2746, y: 623), controlPoint1: CGPoint(x: 2439, y: 186), controlPoint2: CGPoint(x: 2649, y: 388))
            path.addCurve(to: CGPoint(x: 2815, y: 1290), controlPoint1: CGPoint(x: 2813, y: 786), controlPoint2: CGPoint(x: 2815, y: 807))
            path.addLine(to: CGPoint(x: 2815, y: 1725))
            path.addLine(to: CGPoint(x: 2535, y: 1730))
            path.addCurve(to: CGPoint(x: 2196, y: 1758), controlPoint1: CGPoint(x: 2278, y: 1735), controlPoint2: CGPoint(x: 2250, y: 1737))
            path.addCurve(to: CGPoint(x: 1905, y: 1995), controlPoint1: CGPoint(x: 2067, y: 1805), controlPoint2: CGPoint(x: 1972, y: 1883))
            path.addCurve(to: CGPoint(x: 1831, y: 2435), controlPoint1: CGPoint(x: 1840, y: 2103), controlPoint2: CGPoint(x: 1837, y: 2125))
            path.addLine(to: CGPoint(x: 1825, y: 2715))
            path.addLine(to: CGPoint(x: 1360, y: 2717))
            path.addCurve(to: CGPoint(x: 819, y: 2704), controlPoint1: CGPoint(x: 1002, y: 2718), controlPoint2: CGPoint(x: 878, y: 2715))
            path.close()
            path.move(to: CGPoint(x: 1068, y: 1297))
            path.addCurve(to: CGPoint(x: 1082, y: 1159), controlPoint1: CGPoint(x: 1075, y: 1289), controlPoint2: CGPoint(x: 1081, y: 1230))
            path.addLine(to: CGPoint(x: 1085, y: 1035))
            path.addLine(to: CGPoint(x: 1209, y: 1032))
            path.addCurve(to: CGPoint(x: 1347, y: 1018), controlPoint1: CGPoint(x: 1280, y: 1031), controlPoint2: CGPoint(x: 1339, y: 1025))
            path.addCurve(to: CGPoint(x: 1343, y: 948), controlPoint1: CGPoint(x: 1365, y: 1003), controlPoint2: CGPoint(x: 1363, y: 970))
            path.addCurve(to: CGPoint(x: 1203, y: 930), controlPoint1: CGPoint(x: 1329, y: 932), controlPoint2: CGPoint(x: 1310, y: 930))
            path.addLine(to: CGPoint(x: 1080, y: 930))
            path.addLine(to: CGPoint(x: 1080, y: 808))
            path.addCurve(to: CGPoint(x: 1063, y: 668), controlPoint1: CGPoint(x: 1080, y: 709), controlPoint2: CGPoint(x: 1077, y: 683))
            path.addCurve(to: CGPoint(x: 1000, y: 670), controlPoint1: CGPoint(x: 1042, y: 645), controlPoint2: CGPoint(x: 1025, y: 645))
            path.addCurve(to: CGPoint(x: 980, y: 810), controlPoint1: CGPoint(x: 982, y: 688), controlPoint2: CGPoint(x: 980, y: 703))
            path.addLine(to: CGPoint(x: 980, y: 930))
            path.addLine(to: CGPoint(x: 860, y: 930))
            path.addCurve(to: CGPoint(x: 720, y: 950), controlPoint1: CGPoint(x: 753, y: 930), controlPoint2: CGPoint(x: 738, y: 932))
            path.addCurve(to: CGPoint(x: 717, y: 1012), controlPoint1: CGPoint(x: 696, y: 974), controlPoint2: CGPoint(x: 695, y: 988))
            path.addCurve(to: CGPoint(x: 857, y: 1030), controlPoint1: CGPoint(x: 731, y: 1028), controlPoint2: CGPoint(x: 750, y: 1030))
            path.addLine(to: CGPoint(x: 980, y: 1030))
            path.addLine(to: CGPoint(x: 980, y: 1152))
            path.addCurve(to: CGPoint(x: 997, y: 1292), controlPoint1: CGPoint(x: 980, y: 1251), controlPoint2: CGPoint(x: 983, y: 1277))
            path.addCurve(to: CGPoint(x: 1068, y: 1297), controlPoint1: CGPoint(x: 1016, y: 1313), controlPoint2: CGPoint(x: 1053, y: 1316))
            path.close()
            path.move(to: CGPoint(x: 1932, y: 2400))
            path.addLine(to: CGPoint(x: 1935, y: 2155))
            path.addLine(to: CGPoint(x: 1967, y: 2090))
            path.addCurve(to: CGPoint(x: 2132, y: 1900), controlPoint1: CGPoint(x: 2008, y: 2006), controlPoint2: CGPoint(x: 2060, y: 1946))
            path.addCurve(to: CGPoint(x: 2528, y: 1832), controlPoint1: CGPoint(x: 2227, y: 1838), controlPoint2: CGPoint(x: 2282, y: 1829))
            path.addLine(to: CGPoint(x: 2740, y: 1835))
            path.addLine(to: CGPoint(x: 2335, y: 2240))
            path.addLine(to: CGPoint(x: 1929, y: 2645))
            path.addLine(to: CGPoint(x: 1932, y: 2400))
            path.close()
            UIColor.white.setFill()
            path.fill()
        }.withRenderingMode(.alwaysTemplate)
    }
}

internal enum BankChatAvatar {
    static func welcomeImage() -> UIImage? {
        #if SWIFT_PACKAGE
        let resources = Bundle.module
        #else
        guard let bundleURL = Bundle(for: BakaiEdnaPlugin.self).url(forResource: "BakaiEdnaResources", withExtension: "bundle"),
              let resources = Bundle(url: bundleURL) else { return nil }
        #endif
        // Prefer the supplied WebP; PNG is a compatibility fallback for UIKit decoders.
        for ext in ["webp", "png"] {
            guard let url = resources.url(forResource: "bakai_edna_welcome", withExtension: ext),
                  let data = try? Data(contentsOf: url), let decoded = UIImage(data: data) else { continue }
            let pixels = CGFloat(decoded.cgImage?.width ?? Int(decoded.size.width))
            if let image = UIImage(data: data, scale: pixels / 143.0) {
                return image.withRenderingMode(.alwaysOriginal)
            }
        }
        return nil
    }

    static func clientPlaceholder() -> UIImage? {
        #if SWIFT_PACKAGE
        let resources = Bundle.module
        #else
        guard let url = Bundle(for: BakaiEdnaPlugin.self).url(forResource: "BakaiEdnaResources", withExtension: "bundle"),
              let resources = Bundle(url: url) else { return nil }
        #endif
        guard let url = resources.url(forResource: "bakai_edna_client_avatar", withExtension: "png") else { return nil }
        return UIImage(contentsOfFile: url.path)
    }

    static let operatorPlaceholder: UIImage? = {
        #if SWIFT_PACKAGE
        let resources = Bundle.module
        #else
        let pluginBundle = Bundle(for: BakaiEdnaPlugin.self)
        guard let url = pluginBundle.url(forResource: "BakaiEdnaResources", withExtension: "bundle"),
              let resources = Bundle(url: url) else { return nil }
        #endif
        guard let url = resources.url(forResource: "bakai_edna_operator_avatar", withExtension: "png"),
              let image = UIImage(contentsOfFile: url.path) else { return nil }
        let size = CGSize(width: 28, height: 28)
        return UIGraphicsImageRenderer(size: size).image { _ in
            let bounds = CGRect(origin: .zero, size: size)
            UIBezierPath(ovalIn: bounds).addClip()
            UIColor.white.setFill()
            UIRectFill(bounds)
            image.draw(in: bounds.insetBy(dx: 3, dy: 3))
        }
    }()

    static func apply(to theme: ChatTheme) {
        let incoming = theme.flows.chatFlow.incomeMessages
        incoming.showAvatar = true
        incoming.avatarSize = CGSize(width: 30, height: 42)
        if let image = operatorPlaceholder {
            incoming.avatarPlaceholderImage = ChatImage(image: image, renderingMode: .alwaysOriginal)
        }
    }
}


internal enum BankChatWhitespace {
    static func normalize(_ text: String) -> String {
        text.replacingOccurrences(of: "\r\n", with: "\n")
            .replacingOccurrences(of: "\r", with: "\n")
            .replacingOccurrences(of: "[\\t\\p{Zs}]+", with: " ", options: .regularExpression)
            .replacingOccurrences(of: " *\\n *", with: "\n", options: .regularExpression)
            .replacingOccurrences(of: "\\n{3,}", with: "\n\n", options: .regularExpression)
            .replacingOccurrences(of: "^[ \\n]+", with: "", options: .regularExpression)
    }
}

/// Only Edna's exported Objective-C outlets are used here in the bundled SDK.
/// Guard every lookup so an SDK upgrade falls back to its own working controls.
internal enum BankEdnaOutlet {
    static func get<T>(_ object: NSObject, _ name: String) -> T? {
        guard object.responds(to: NSSelectorFromString(name)) else { return nil }
        return object.value(forKey: name) as? T
    }
}

private final class BankChatHeader: UIView {
    let back = UIButton(type: .custom)
    let search = UIButton(type: .custom)
    let title = UILabel()
    let subtitle = UILabel()
    let pill = UIView()
    let searchHost = UIView()
    private let loadingDots = UIView()
    private var isLoading = false
    private let icon = UIImageView(image: UIImage(systemName: "headphones"))

    init(palette: BankChatTheme.Palette) {
        super.init(frame: .zero)
        accessibilityIdentifier = "bankChatHeader"
        backgroundColor = palette.background
        for (button, symbol) in [(back, "arrow.left"), (search, "magnifyingglass")] {
            button.setImage(UIImage(systemName: symbol, withConfiguration: UIImage.SymbolConfiguration(pointSize: 20)), for: .normal)
            button.tintColor = palette.text
            button.backgroundColor = palette.input
            button.layer.cornerRadius = 20
            addSubview(button)
        }
        back.accessibilityLabel = NSLocalizedString("Back", comment: "Close support chat")
        search.accessibilityLabel = NSLocalizedString("Search", comment: "Search support chat")
        pill.backgroundColor = palette.input
        pill.layer.cornerRadius = 24
        addSubview(pill)
        searchHost.isHidden = true
        addSubview(searchHost)
        icon.tintColor = palette.text
        icon.contentMode = .scaleAspectFit
        pill.addSubview(icon)
        loadingDots.isHidden = true
        loadingDots.isAccessibilityElement = true
        loadingDots.accessibilityLabel = NSLocalizedString("Loading", comment: "Chat loading")
        pill.addSubview(loadingDots)
        // Matches .tg-typing-dots / tg-dots-bounce in the bank chat.
        for index in 0..<3 {
            let dot = UIView(frame: CGRect(x: index * 5, y: 3, width: 3, height: 3))
            dot.backgroundColor = palette.text
            dot.layer.cornerRadius = 1.5
            loadingDots.addSubview(dot)
        }
        title.font = .systemFont(ofSize: 14, weight: .semibold)
        subtitle.font = .systemFont(ofSize: 11)
        for label in [title, subtitle] {
            label.textColor = palette.text
            label.lineBreakMode = .byTruncatingTail
            pill.addSubview(label)
        }
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func layoutSubviews() {
        super.layoutSubviews()
        back.frame = CGRect(x: 8, y: 12, width: 40, height: 40)
        search.frame = CGRect(x: bounds.width - 48, y: 12, width: 40, height: 40)
        pill.frame = CGRect(x: 60, y: 8, width: max(0, bounds.width - 120), height: 48)
        searchHost.frame = CGRect(x: 56, y: 8, width: max(0, bounds.width - 64), height: 48)
        searchHost.subviews.forEach { $0.frame = searchHost.bounds }
        icon.frame = CGRect(x: 12, y: 14, width: 20, height: 20)
        loadingDots.frame = CGRect(x: 50, y: 20, width: 13, height: 9)
        title.isHidden = isLoading
        subtitle.isHidden = isLoading || subtitle.text?.isEmpty != false
        let width = max(0, pill.bounds.width - 64)
        title.frame = CGRect(x: 50, y: subtitle.isHidden ? 14 : 8, width: width, height: 19)
        subtitle.frame = CGRect(x: 50, y: 28, width: width, height: 14)
    }

    func setLoading(_ loading: Bool) {
        title.isHidden = loading
        subtitle.isHidden = loading || subtitle.text?.isEmpty != false
        loadingDots.isHidden = !loading
        guard isLoading != loading else { return }
        isLoading = loading
        for (index, dot) in loadingDots.subviews.enumerated() {
            dot.layer.removeAnimation(forKey: "bankChatLoading")
            guard loading, !UIAccessibility.isReduceMotionEnabled else { continue }
            let opacity = CAKeyframeAnimation(keyPath: "opacity")
            opacity.values = [0.3, 1, 0.3, 0.3]
            opacity.keyTimes = [0, 0.4, 0.8, 1]
            let bounce = CAKeyframeAnimation(keyPath: "transform.translation.y")
            bounce.values = [0, -2, 0, 0]
            bounce.keyTimes = opacity.keyTimes
            let animation = CAAnimationGroup()
            animation.animations = [opacity, bounce]
            animation.duration = 1
            animation.beginTime = CACurrentMediaTime() + Double(index) * 0.15
            animation.repeatCount = .infinity
            dot.layer.add(animation, forKey: "bankChatLoading")
        }
        setNeedsLayout()
    }

}

/// Delay only query changes; all other optional search-bar callbacks stay with Edna.
internal final class BankDebouncedSearchDelegate: NSObject, UISearchBarDelegate {
    private weak var downstream: UISearchBarDelegate?
    private let delay: TimeInterval
    private var pending: Timer?

    init(downstream: UISearchBarDelegate, delay: TimeInterval = 0.4) {
        self.downstream = downstream
        self.delay = delay
        super.init()
    }

    func cancel() {
        pending?.invalidate()
        pending = nil
    }

    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        cancel()
        guard searchBar.searchTextField.markedTextRange == nil else { return }
        let timer = Timer(timeInterval: delay, repeats: false) { [weak self, weak searchBar] _ in
            guard let self, let searchBar, searchBar.text == searchText,
                  searchBar.searchTextField.markedTextRange == nil else { return }
            self.pending = nil
            self.downstream?.searchBar?(searchBar, textDidChange: searchText)
        }
        pending = timer
        RunLoop.main.add(timer, forMode: .common)
    }

    override func responds(to aSelector: Selector!) -> Bool {
        super.responds(to: aSelector) || downstream?.responds(to: aSelector) == true
    }

    override func forwardingTarget(for aSelector: Selector!) -> Any? {
        downstream?.responds(to: aSelector) == true ? downstream : super.forwardingTarget(for: aSelector)
    }

    deinit { pending?.invalidate() }
}

/// Keep dismissal routing scoped to this SDK search instance, even after a
/// selected result removes it from the chat's child-controller hierarchy.
private final class BankInlineSearchOwner: NSObject {
    weak var navigation: BankChatNavigationController?
    init(_ navigation: BankChatNavigationController) { self.navigation = navigation }
}

/// The SDK recalculates both text and placeholder insets from drawRect:.
/// Apply one shared origin on every such pass for the bank composer only.
private enum BankComposerTextLayout {
    static var configuredKey: UInt8 = 0
    private static let installed: Void = {
        guard let sdkClass = NSClassFromString("THRJSQMessagesComposerTextView"),
              let original = class_getInstanceMethod(sdkClass, NSSelectorFromString("configureInsetsWith:")),
              let replacement = class_getInstanceMethod(UITextView.self, #selector(UITextView.bankConfigureComposerInsets(with:))) else { return }
        let selector = #selector(UITextView.bankConfigureComposerInsets(with:))
        class_addMethod(sdkClass, selector, method_getImplementation(replacement), method_getTypeEncoding(replacement))
        guard let localReplacement = class_getInstanceMethod(sdkClass, selector) else { return }
        method_exchangeImplementations(original, localReplacement)
    }()

    static func install(on text: UITextView) {
        _ = installed
        objc_setAssociatedObject(text, &configuredKey, true, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        text.textContainer.lineFragmentPadding = 0
        text.textContainer.widthTracksTextView = true
        text.contentInset = .zero
        text.contentOffset.x = 0
        text.clipsToBounds = true
        apply(to: text)
    }

    static func apply(to text: UITextView) {
        let insets = UIEdgeInsets(top: 12, left: 0, bottom: 12, right: 0)
        if text.textContainerInset != insets { text.textContainerInset = insets }
        if text.responds(to: NSSelectorFromString("setPlaceHolderInsets:")),
           (text.value(forKey: "placeHolderInsets") as? NSValue)?.uiEdgeInsetsValue != insets {
            text.setValue(NSValue(uiEdgeInsets: insets), forKey: "placeHolderInsets")
            text.setNeedsDisplay()
        }
    }
}

private extension UITextView {
    @objc(bankConfigureComposerInsetsWith:)
    dynamic func bankConfigureComposerInsets(with size: CGSize) {
        if objc_getAssociatedObject(self, &BankComposerTextLayout.configuredKey) as? Bool == true {
            BankComposerTextLayout.apply(to: self)
        } else {
            bankConfigureComposerInsets(with: size)
        }
    }
}

/// Changes geometry only; Edna retains its composer, delegates, targets, draft,
/// attachment picker, keyboard handling and send/voice state.
private final class BankChatComposerLayout {
    weak var content: UIView?
    private var installed = false

    func install(in root: UIView, palette: BankChatTheme.Palette) {
        guard !installed else { return }
        guard let toolbar = descendants(root).first(where: {
            $0.responds(to: NSSelectorFromString("preferredDefaultHeight")) &&
            $0.responds(to: NSSelectorFromString("contentView"))
        }),
        let content: UIView = BankEdnaOutlet.get(toolbar, "contentView"),
        let text: UITextView = BankEdnaOutlet.get(content, "textView"),
        let left: UIView = BankEdnaOutlet.get(content, "leftBarButtonContainerView"),
        let right: UIView = BankEdnaOutlet.get(content, "rightBarButtonContainerView"),
        let attach: UIButton = BankEdnaOutlet.get(content, "leftBarButtonItem"),
        let send: UIButton = BankEdnaOutlet.get(content, "rightBarButtonItem"),
        text.superview === content, left.superview === content, right.superview === content else { return }

        // These outlets belong to the bundled Edna toolbar, not UIKit internals.
        if toolbar.responds(to: NSSelectorFromString("setPreferredDefaultHeight:")) {
            toolbar.setValue(60.0, forKey: "preferredDefaultHeight")
        }
        let controls: [UIView] = [text, left, right]
        NSLayoutConstraint.deactivate(content.constraints.filter { constraint in
            // Edna updates the text view's vertical constraints when a reply is
            // opened or dismissed. Keep that chain so the quote reserves space
            // above the input, including when the keyboard or draft height changes.
            let first = constraint.firstItem as? UIView
            let second = constraint.secondItem as? UIView
            let vertical: [NSLayoutConstraint.Attribute] = [.top, .bottom, .height, .centerY]
            let positionsTextVertically =
                (first === text && vertical.contains(constraint.firstAttribute)) ||
                (second === text && vertical.contains(constraint.secondAttribute))
            let positionsButton = first === left || first === right || second === left || second === right
            if !positionsButton {
                if positionsTextVertically { return false }
                // Also retain quote constraints anchored to the text view.
                if first === text, let second, second !== content { return false }
                if second === text, let first, first !== content { return false }
            }
            return controls.contains { first === $0 || second === $0 }
        })
        for container in [left, right] {
            NSLayoutConstraint.deactivate(container.constraints.filter {
                ($0.firstItem as? UIView) === container && $0.secondItem == nil &&
                ($0.firstAttribute == .width || $0.firstAttribute == .height)
            })
        }
        let pill = UIView()
        pill.isUserInteractionEnabled = false
        pill.backgroundColor = palette.input
        pill.layer.cornerRadius = 22
        content.insertSubview(pill, at: 0)
        for item in controls + [pill] { item.translatesAutoresizingMaskIntoConstraints = false }
        text.backgroundColor = .clear
        text.layer.borderWidth = 0
        text.layer.cornerRadius = 0
        // Reserve the horizontal padding with layout, rather than a scrollable
        // text-container inset, so the caret and SDK placeholder share an origin.
        BankComposerTextLayout.install(on: text)
        left.backgroundColor = .clear
        right.backgroundColor = .clear
        BankSendSurface.install(in: right, button: send, textColor: palette.text)
        right.layer.cornerRadius = 22
        right.clipsToBounds = true
        for (button, container) in [(attach, left), (send, right)] {
            NSLayoutConstraint.deactivate(container.constraints.filter {
                ($0.firstItem as? UIView) === button || ($0.secondItem as? UIView) === button
            })
            NSLayoutConstraint.deactivate(button.constraints.filter {
                $0.secondItem == nil && ($0.firstAttribute == .width || $0.firstAttribute == .height)
            })
            button.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                button.leadingAnchor.constraint(equalTo: container.leadingAnchor),
                button.trailingAnchor.constraint(equalTo: container.trailingAnchor),
                button.topAnchor.constraint(equalTo: container.topAnchor),
                button.bottomAnchor.constraint(equalTo: container.bottomAnchor)
            ])
            button.configuration = nil
            for state: UIControl.State in [.normal, .highlighted, .disabled] {
                button.setBackgroundImage(nil, for: state)
            }
            button.backgroundColor = .clear
            button.layer.cornerRadius = 0
            button.tintColor = button === attach ? palette.muted : palette.composerIcon
            button.imageView?.contentMode = .scaleAspectFit
            button.contentEdgeInsets = UIEdgeInsets(top: 11, left: 11, bottom: 11, right: 11)
        }
        NSLayoutConstraint.activate([
            right.trailingAnchor.constraint(equalTo: content.trailingAnchor, constant: -8),
            right.bottomAnchor.constraint(equalTo: content.bottomAnchor, constant: -8),
            right.widthAnchor.constraint(equalToConstant: 44), right.heightAnchor.constraint(equalToConstant: 44),
            left.trailingAnchor.constraint(equalTo: right.leadingAnchor, constant: -6),
            left.bottomAnchor.constraint(equalTo: right.bottomAnchor),
            left.widthAnchor.constraint(equalToConstant: 44), left.heightAnchor.constraint(equalToConstant: 44),
            pill.leadingAnchor.constraint(equalTo: content.leadingAnchor, constant: 8),
            text.leadingAnchor.constraint(equalTo: pill.leadingAnchor, constant: 16),
            text.trailingAnchor.constraint(equalTo: left.leadingAnchor),
            pill.trailingAnchor.constraint(equalTo: left.trailingAnchor),
            pill.topAnchor.constraint(equalTo: text.topAnchor),
            pill.bottomAnchor.constraint(equalTo: text.bottomAnchor)
        ])
        self.content = content
        installed = true
    }

    func updateSurveyVisibility(in root: UIViewController) {
        func controllers(_ screen: UIViewController) -> [UIViewController] {
            [screen] + screen.children.flatMap { controllers($0) }
        }
        let hasPendingSurvey = controllers(root).contains { controller in
            let model: CCChatModel? = BankEdnaOutlet.get(controller, "chatModel") ?? BankEdnaOutlet.get(controller, "chat")
            return model?.messages.contains { message in
                message.type == .survey && (message.media as? THRSurvey)?.completed == false
            } == true
        }
        // Keep the surface visible while preserving Edna's disabled editor and
        // button states until the survey allows input again.
        if hasPendingSurvey { content?.isHidden = false }
    }

    private func descendants(_ view: UIView) -> [UIView] {
        [view] + view.subviews.flatMap { descendants($0) }
    }
}

/// The root chat has one bank header. Pushed SDK screens keep native navigation.
internal final class BankChatNavigationController: UINavigationController, UIGestureRecognizerDelegate {
    private var inlineSearch: THRSearchViewController?
    private var inlineSearchBar: UISearchBar?
    private var inlineSearchDelegate: BankDebouncedSearchDelegate?
    private var normalizing = false
    private let bankPalette: BankChatTheme.Palette
    private let bankHeader: BankChatHeader
    private let composer = BankChatComposerLayout()
    var clientAvatar: UIImage?
    private var messageDisplayLink: CADisplayLink?
    private let statusBackground = UIView()
    private var titleObservations: [NSKeyValueObservation] = []
    private weak var observedTitle: UIView?
    private var originalTopInset: CGFloat = 0
    private var rootInsetInstalled = false
    private var loadingTimer: Timer?
    private var updatingAppearance = false
    private var awaitingInitialAppearance = true
    private var initialChatLoading = true
    var onClose: (() -> Void)?
    var onLastMessageDate: ((Date) -> Void)?
    private var lastReportedMessageDate: Date?

    init(rootViewController: UIViewController, palette: BankChatTheme.Palette) {
        bankPalette = palette
        bankHeader = BankChatHeader(palette: palette)
        super.init(rootViewController: rootViewController)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    override var preferredStatusBarStyle: UIStatusBarStyle { bankPalette.isDark ? .lightContent : .darkContent }
    override var childForStatusBarStyle: UIViewController? { nil }

    override func viewDidLoad() {
        super.viewDidLoad()
        BankChatPresentation.install()
        let dismissKeyboardTap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboardFromHistory))
        dismissKeyboardTap.cancelsTouchesInView = false
        dismissKeyboardTap.delegate = self
        view.addGestureRecognizer(dismissKeyboardTap)
        view.backgroundColor = bankPalette.background
        // Keep SDK views in the layout hierarchy, but do not expose their first,
        // unstyled frames during presentation or initial history loading.
        viewControllers.first?.view.alpha = 0
        bankHeader.setLoading(true)
        bankHeader.pill.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(openContactProfile)))
        bankHeader.back.addTarget(self, action: #selector(closeChat), for: .touchUpInside)
        bankHeader.search.addTarget(self, action: #selector(searchChat), for: .touchUpInside)
        statusBackground.backgroundColor = bankPalette.background
        view.addSubview(statusBackground)
        view.addSubview(bankHeader)
        NotificationCenter.default.addObserver(self, selector: #selector(textChanged(_:)),
            name: UITextView.textDidChangeNotification, object: nil)
    }

    @objc private func dismissKeyboardFromHistory() {
        view.endEditing(true)
    }

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        guard let root = viewControllers.first, topViewController === root,
              presentedViewController == nil, let touched = touch.view,
              touched.isDescendant(of: root.view) else { return false }
        var candidate: UIView? = touched
        while let current = candidate {
            if current === composer.content || current is UIControl { return false }
            if let text = current as? UITextView, text.isEditable { return false }
            candidate = current.superview
        }
        return true
    }

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer,
                           shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        true
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateLoadingState()
        messageDisplayLink?.invalidate()
        messageDisplayLink = CADisplayLink(target: self, selector: #selector(updateMessageSides))
        // Apply recycled-cell appearance before every displayed frame.
        messageDisplayLink?.preferredFramesPerSecond = 0
        messageDisplayLink?.add(to: .main, forMode: .common)
        loadingTimer?.invalidate()
        // CCChatState exposes getState(), not a KVO-observable state property.
        loadingTimer = Timer.scheduledTimer(withTimeInterval: 0.25, repeats: true) { [weak self] _ in
            self?.updateLoadingState()
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        inlineSearchDelegate?.cancel()
        super.viewWillDisappear(animated)
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        loadingTimer?.invalidate()
        loadingTimer = nil
        messageDisplayLink?.invalidate()
        messageDisplayLink = nil
        bankHeader.setLoading(false)
        // A media presentation can finish after the chat display link stops.
        mediaTimer?.invalidate()
        mediaTimer = Timer.scheduledTimer(withTimeInterval: 0.2, repeats: true) { [weak self] timer in
            guard let self, self.presentedViewController != nil else { timer.invalidate(); return }
            self.prepareMediaNavigation()
        }
    }

    private func updateLoadingState() {
        guard let root = viewControllers.first, topViewController === root else {
            bankHeader.setLoading(false)
            return
        }
        func controllers(_ controller: UIViewController) -> [UIViewController] {
            [controller] + controller.children.flatMap { controllers($0) }
        }
        let screens = controllers(root)
        let preload: LoadingChatViewController? = screens.compactMap { $0 as? LoadingChatViewController }.first
            ?? BankEdnaOutlet.get(root, "preloadChatViewController")
        let model: CCChatModel? = screens.compactMap { controller -> CCChatModel? in
            BankEdnaOutlet.get(controller, "chatModel") ?? BankEdnaOutlet.get(controller, "chat")
        }.first
        if let latestDate = model?.messages.map(\.date).max(), latestDate != lastReportedMessageDate {
            lastReportedMessageDate = latestDate
            onLastMessageDate?(latestDate)
        }
        let loading: Bool
        if preload?.error != nil {
            loading = false
        } else if let model {
            switch model.stateModel.getState() {
            case .notConnected, .connecting, .reconnecting, .loadingHistory: loading = true
            default: loading = false
            }
        } else {
            loading = preload != nil
        }
        // Hide only the initial loading screen, never the SDK's error/retry UI.
        preload?.viewIfLoaded?.alpha = loading ? 0 : 1
        updateTitle(from: root)
        initialChatLoading = loading
        bankHeader.setLoading(loading)
    }

    override func viewWillLayoutSubviews() {
        let isRoot = topViewController === viewControllers.first
        if isNavigationBarHidden != isRoot { setNavigationBarHidden(isRoot, animated: false) }
        super.viewWillLayoutSubviews()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        guard let root = viewControllers.first else { return }
        let isRoot = topViewController === root
        bankHeader.isHidden = !isRoot
        statusBackground.isHidden = !isRoot
        guard isRoot else { return }
        view.backgroundColor = bankPalette.background
        if !rootInsetInstalled {
            originalTopInset = root.additionalSafeAreaInsets.top
            root.additionalSafeAreaInsets.top = originalTopInset + 64
            rootInsetInstalled = true
        }
        bankHeader.frame = CGRect(x: view.safeAreaInsets.left, y: view.safeAreaInsets.top,
                                  width: view.bounds.width - view.safeAreaInsets.left - view.safeAreaInsets.right, height: 64)
        statusBackground.frame = CGRect(x: 0, y: 0, width: view.bounds.width, height: view.safeAreaInsets.top)
        view.bringSubviewToFront(statusBackground)
        view.bringSubviewToFront(bankHeader)
        updateTitle(from: root)
        updateMessageSides()
    }

    private func updateTitle(from root: UIViewController) {
        // Keep the original title in its SDK navigation item. Moving it into a
        // wrapper breaks the SDK's title constraints and loses operator updates.
        let source: UIView? = BankEdnaOutlet.get(root, "titleView") ?? root.navigationItem.titleView
        if observedTitle !== source {
            observedTitle = source
            titleObservations.removeAll()
            if let source {
                let labels = titleLabels(source)
                for label in labels {
                    titleObservations.append(label.observe(\.text, options: [.new]) { [weak self, weak root] _, _ in
                        guard let self, let root else { return }
                        self.copyTitle(from: source, fallback: root.title)
                    })
                }
            }
        }
        copyTitle(from: source, fallback: root.title)
        bankHeader.search.isEnabled = searchContext != nil
    }

    private func titleLabels(_ view: UIView) -> [UILabel] {
        (view as? UILabel).map { [$0] } ?? view.subviews.flatMap { titleLabels($0) }
    }

    private func copyTitle(from source: UIView?, fallback: String?) {
        let title: UILabel? = source.flatMap { BankEdnaOutlet.get($0, "titleLabel") }
        let subtitle: UILabel? = source.flatMap { BankEdnaOutlet.get($0, "subtitleLabel") }
        let labels = source.map { titleLabels($0) } ?? []
        let titleText: String? = source.flatMap { BankEdnaOutlet.get($0, "titleText") }
        let subtitleText: String? = source.flatMap { BankEdnaOutlet.get($0, "subtitleText") }
        bankHeader.title.text = titleText ?? title?.text ?? labels.first?.text ?? fallback
        bankHeader.subtitle.text = subtitleText ?? subtitle?.text ?? labels.dropFirst().first?.text
        if BankEdnaLocalization.language == "ky",
           let text = bankHeader.subtitle.text?.trimmingCharacters(in: .whitespacesAndNewlines),
           text.range(of: "^Отдел обслуживания физ\\.\\s*лиц$", options: [.regularExpression, .caseInsensitive]) != nil {
            bankHeader.subtitle.text = "Жеке жактарды тейлөө бөлүмү"
        }
        bankHeader.setNeedsLayout()
    }

    private var searchContext: (controller: UIViewController, model: CCChatModel)? {
        guard let root = viewControllers.first else { return nil }
        func screens(_ controller: UIViewController) -> [UIViewController] {
            [controller] + controller.children.flatMap { screens($0) }
        }
        return screens(root).compactMap { controller in
            guard !(controller is THRSearchViewController),
                  let model: CCChatModel = BankEdnaOutlet.get(controller, "chatModel") ?? BankEdnaOutlet.get(controller, "chat"),
                  model.dataProvider != nil,
                  controller.responds(to: NSSelectorFromString("scrollToMessage:animated:")) else { return nil }
            return (controller, model)
        }.first
    }

    @objc private func updateMessageSides() {
        guard !updatingAppearance else { return }
        updatingAppearance = true
        defer { updatingAppearance = false }
        updatePresentedAlertAppearance()
        restrictFileAttachments()
        prepareMediaNavigation()
        guard let root = viewControllers.first, topViewController === root else { return }
        // SDK content can arrive after presentation. Install the composer and
        // style newly created cells before revealing the first complete layout.
        composer.install(in: root.view, palette: bankPalette)
        composer.updateSurveyVisibility(in: root)
        root.view.layoutIfNeeded()
        BankClientMessageSide.update(in: root.view, avatar: clientAvatar, palette: bankPalette)
        if awaitingInitialAppearance {
            updateLoadingState()
            guard !initialChatLoading else { return }
            UIView.performWithoutAnimation { root.view.alpha = 1 }
            awaitingInitialAppearance = false
        }
    }

    private weak var restrictedPicker: SystemFilePickerViewController?

    private func restrictFileAttachments() {
        guard let root = viewControllers.first,
              let picker: SystemFilePickerViewController = BankEdnaOutlet.get(root, "systemFilePickerViewController"),
              restrictedPicker !== picker, let sendFile = picker.selectFileAction else { return }
        picker.selectFileAction = { [weak self] url in
            let type = UTType(filenameExtension: url.pathExtension)
            let documents: Set<String> = ["pdf", "txt", "csv", "rtf", "doc", "docx", "xls", "xlsx", "ppt", "pptx", "odt", "ods", "odp"]
            guard type?.conforms(to: .image) == true || documents.contains(url.pathExtension.lowercased()) else {
                guard let self else { return }
                let alert = UIAlertController(title: "Неподдерживаемый файл",
                    message: "Можно отправлять только изображения и документы", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default))
                var presenter: UIViewController = self
                while let presented = presenter.presentedViewController { presenter = presented }
                presenter.present(alert, animated: true)
                return
            }
            sendFile(url)
        }
        restrictedPicker = picker
    }

    private var mediaTimer: Timer?
    private weak var styledMediaNavigation: UINavigationController?

    private func prepareMediaNavigation() {
        // Inspect only the presented UIKit hierarchy. Do not query SDK helpers,
        // call Quick Look's data source, or replace its navigation stack while
        // the SDK is presenting/downloading a preview.
        var presented = presentedViewController
        while let controller = presented {
            if let navigation = controller as? UINavigationController,
               navigation.viewControllers.contains(where: { $0 is QLPreviewController }) {
                guard !navigation.isBeingPresented,
                      navigation.transitionCoordinator == nil,
                      navigation.viewIfLoaded?.window != nil,
                      styledMediaNavigation !== navigation else { return }
                navigation.overrideUserInterfaceStyle = bankPalette.isDark ? .dark : .light
                navigation.view.tintColor = bankPalette.text
                let appearance = UINavigationBarAppearance()
                appearance.configureWithOpaqueBackground()
                appearance.backgroundColor = bankPalette.input
                appearance.titleTextAttributes = [.foregroundColor: bankPalette.text]
                navigation.navigationBar.standardAppearance = appearance
                navigation.navigationBar.scrollEdgeAppearance = appearance
                navigation.navigationBar.compactAppearance = appearance
                navigation.navigationBar.tintColor = bankPalette.text
                let toolbar = UIToolbarAppearance()
                toolbar.configureWithOpaqueBackground()
                toolbar.backgroundColor = bankPalette.input
                navigation.toolbar.standardAppearance = toolbar
                navigation.toolbar.scrollEdgeAppearance = toolbar
                navigation.toolbar.tintColor = bankPalette.text
                styledMediaNavigation = navigation
                return
            }
            presented = controller.presentedViewController
        }
    }

    fileprivate func attachmentMenu(for alert: UIAlertController) -> UIViewController? {
        guard alert.preferredStyle == .actionSheet else { return nil }
        restrictFileAttachments()
        guard let root = viewControllers.first,
              let picker: SystemFilePickerViewController = BankEdnaOutlet.get(root, "systemFilePickerViewController") else { return nil }
        let keys = ["attachments.menu.take_photo", "attachments.menu.my_albums", "alert.picker_files_btn"]
        let sources = keys.map { key in
            let title = Localization.localize(key: key)
            return alert.actions.contains { $0.title == title && $0.isEnabled }
        }
        guard sources.contains(true) else { return nil }
        return BankAttachmentMenu(picker: picker, dark: bankPalette.isDark, availableSources: sources)
    }

    private weak var styledAlert: UIAlertController?

    private func updatePresentedAlertAppearance() {
        // The attachment picker presents a UIKit alert. Apply the palette to the
        // actual controller too: SDK menu styling alone does not reliably style
        // the system action buttons on newer iOS versions.
        var controller: UIViewController = self
        while let presented = controller.presentedViewController {
            controller = presented
        }
        guard let alert = controller as? UIAlertController else {
            styledAlert = nil
            return
        }
        guard styledAlert !== alert else { return }
        alert.overrideUserInterfaceStyle = bankPalette.isDark ? .dark : .light
        alert.loadViewIfNeeded()
        alert.view.tintColor = bankPalette.text
        alert.view.tintAdjustmentMode = .normal
        styledAlert = alert
    }

    @objc private func openContactProfile() {
        guard presentedViewController == nil else { return }
        present(BankContactProfile(dark: bankPalette.isDark), animated: true)
    }

    @objc private func closeChat() {
        if inlineSearch != nil { closeInlineSearch() }
        else { onClose?() }
    }

    /// Mount SDK results directly. This path never invokes SDK's search action
    /// or UIViewController.present(), including when the search bar is unavailable.
    @discardableResult
    internal func showInlineSearch(_ search: THRSearchViewController) -> Bool {
        guard let root = viewControllers.first, topViewController === root else { return false }
        if inlineSearch != nil { return true }
        let selectMessage = search.didSelectMessage
        search.didSelectMessage = { [weak self] message in
            self?.closeInlineSearch()
            selectMessage?(message)
        }
        objc_setAssociatedObject(search, &BankChatPresentation.inlineSearchOwnerKey,
                                 BankInlineSearchOwner(self), .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        root.addChild(search)
        search.loadViewIfNeeded()
        func findBar(in view: UIView) -> UISearchBar? {
            if let bar = view as? UISearchBar { return bar }
            return view.subviews.lazy.compactMap { findBar(in: $0) }.first
        }
        guard let bar = search.navigationItem.titleView.flatMap({ findBar(in: $0) })
                ?? findBar(in: search.view) else {
            search.willMove(toParent: nil)
            search.removeFromParent()
            search.didSelectMessage = selectMessage
            objc_setAssociatedObject(search, &BankChatPresentation.inlineSearchOwnerKey, nil, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            return false
        }
        view.endEditing(true)
        inlineSearch = search
        search.view.backgroundColor = bankPalette.background
        search.view.frame = root.view.bounds
        search.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        root.view.addSubview(search.view)
        search.didMove(toParent: root)
        var ancestor = bar.superview
        while let parent = ancestor {
            NSLayoutConstraint.deactivate(parent.constraints.filter {
                ($0.firstItem as? UIView) === bar || ($0.secondItem as? UIView) === bar
            })
            ancestor = parent.superview
        }
        if search.navigationItem.titleView === bar { search.navigationItem.titleView = nil }
        bar.removeFromSuperview()
        bar.translatesAutoresizingMaskIntoConstraints = true
        bar.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        bar.showsCancelButton = false
        bar.searchBarStyle = .minimal
        bar.tintColor = bankPalette.text
        bar.searchTextField.textColor = bankPalette.text
        bar.searchTextField.backgroundColor = bankPalette.input
        let delegate = BankDebouncedSearchDelegate(downstream: search)
        inlineSearchDelegate = delegate
        bar.delegate = delegate
        inlineSearchBar = bar
        bankHeader.searchHost.addSubview(bar)
        bar.frame = bankHeader.searchHost.bounds
        bankHeader.searchHost.isHidden = false
        bankHeader.pill.isHidden = true
        bankHeader.search.isHidden = true
        bankHeader.setNeedsLayout()
        bankHeader.layoutIfNeeded()
        // Focus after containment and header layout have completed.
        DispatchQueue.main.async { [weak self, weak bar] in
            guard self?.inlineSearch === search else { return }
            bar?.becomeFirstResponder()
        }
        return true
    }

    fileprivate func closeInlineSearch() {
        guard let search = inlineSearch else { return }
        inlineSearchDelegate?.cancel()
        inlineSearchBar?.resignFirstResponder()
        inlineSearchBar?.removeFromSuperview()
        inlineSearchBar = nil
        inlineSearchDelegate = nil
        search.willMove(toParent: nil)
        search.view.removeFromSuperview()
        search.removeFromParent()
        inlineSearch = nil
        bankHeader.searchHost.isHidden = true
        bankHeader.pill.isHidden = false
        bankHeader.search.isHidden = false
    }

    @objc private func searchChat() {
        guard let context = searchContext else { return }
        let search = THRSearchViewController(nibName: nil, bundle: nil)
        search.dataProvider = context.model.dataProvider
        search.avatarService = context.model.avatarService
        search.didSelectMessage = { [weak controller = context.controller] message in
            guard let controller else { return }
            // Match the bundled SDK's own result-selection callback. The
            // Objective-C entry point is guarded before enabling search.
            let selector = NSSelectorFromString("scrollToMessage:animated:")
            guard controller.responds(to: selector), let implementation = controller.method(for: selector) else { return }
            typealias ScrollToMessage = @convention(c) (AnyObject, Selector, AnyObject, Bool) -> Void
            let scroll = unsafeBitCast(implementation, to: ScrollToMessage.self)
            scroll(controller, selector, message, true)
        }
        showInlineSearch(search)
    }

    @objc private func textChanged(_ notification: Notification) {
        guard !normalizing, let input = notification.object as? UITextView,
              input.isEditable, input.markedTextRange == nil,
              let root = viewControllers.first, topViewController === root,
              input.isDescendant(of: root.view) else { return }
        let original = input.text ?? ""
        let normalized = BankChatWhitespace.normalize(original)
        guard original != normalized else { return }
        let selection = input.selectedRange
        let prefix = (original as NSString).substring(to: min(selection.location, (original as NSString).length))
        normalizing = true
        input.text = normalized
        input.selectedRange = NSRange(location: min((BankChatWhitespace.normalize(prefix) as NSString).length,
                                                    (normalized as NSString).length), length: 0)
        input.delegate?.textViewDidChange?(input)
        normalizing = false
    }

    deinit {
        loadingTimer?.invalidate()
        NotificationCenter.default.removeObserver(self)
    }
}

/// Frosted backing is separate from the send icon, so the icon stays sharp.
private final class BankSendSurface: UIView {
    private let shade = UIView()
    private let backdrop = UIImageView()
    private let textColor: UIColor
    private var capturedSize = CGSize.zero
    private weak var button: UIButton?

    init(textColor: UIColor) {
        self.textColor = textColor
        super.init(frame: .zero)
        isUserInteractionEnabled = false
        addSubview(backdrop); addSubview(shade)
        layer.borderWidth = 0.5
        layer.borderColor = textColor.withAlphaComponent(textColor.cgColor.alpha * 0.08).cgColor
        shade.backgroundColor = textColor.withAlphaComponent(textColor.cgColor.alpha * 0.06)
        clipsToBounds = true
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    static func install(in container: UIView, button: UIButton, textColor: UIColor) {
        let surface = BankSendSurface(textColor: textColor)
        surface.button = button
        surface.frame = container.bounds
        surface.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        container.insertSubview(surface, at: 0)
        button.addTarget(surface, action: #selector(pressed), for: [.touchDown, .touchDragEnter])
        button.addTarget(surface, action: #selector(released), for: [.touchUpInside, .touchUpOutside, .touchCancel, .touchDragExit])
        button.addGestureRecognizer(UIHoverGestureRecognizer(target: surface, action: #selector(hover(_:))))
    }
    @objc private func pressed() { shade.backgroundColor = textColor.withAlphaComponent(textColor.cgColor.alpha * 0.14) }
    @objc private func released() { shade.backgroundColor = textColor.withAlphaComponent(textColor.cgColor.alpha * 0.06) }
    @objc private func hover(_ gesture: UIHoverGestureRecognizer) {
        shade.backgroundColor = textColor.withAlphaComponent(textColor.cgColor.alpha * (gesture.state == .began || gesture.state == .changed ? 0.10 : 0.06))
    }
    override func layoutSubviews() {
        super.layoutSubviews()
        layer.cornerRadius = bounds.height / 2
        backdrop.frame = bounds; shade.frame = bounds
        guard bounds.width > 0, bounds.size != capturedSize,
              let container = superview, let parent = container.superview else { return }
        capturedSize = bounds.size
        let format = UIGraphicsImageRendererFormat(); format.scale = 1
        let wasHidden = container.isHidden
        container.isHidden = true
        let snapshot = UIGraphicsImageRenderer(size: bounds.size, format: format).image { context in
            let origin = convert(CGPoint.zero, to: parent)
            context.cgContext.translateBy(x: -origin.x, y: -origin.y)
            parent.layer.render(in: context.cgContext)
        }
        container.isHidden = wasHidden
        guard let input = CIImage(image: snapshot) else { return }
        let filtered = input.clampedToExtent()
            .applyingFilter("CIGaussianBlur", parameters: [kCIInputRadiusKey: 14])
            .applyingFilter("CIColorControls", parameters: [kCIInputSaturationKey: 1.8])
            .cropped(to: input.extent)
        if let cgImage = CIContext().createCGImage(filtered, from: input.extent) {
            backdrop.image = UIImage(cgImage: cgImage)
        }
    }
}

private final class BankReplySwipe: UIPanGestureRecognizer, UIGestureRecognizerDelegate {
    private weak var messageAtStart: THRMessage?

    init() {
        super.init(target: nil, action: nil)
        delegate = self
        maximumNumberOfTouches = 1
        addTarget(self, action: #selector(drag))
    }

    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        let speed = velocity(in: view)
        guard speed.x < 0, abs(speed.x) > abs(speed.y) * 2,
              let cell = view as? UICollectionViewCell,
              let message: THRMessage = BankEdnaOutlet.get(cell, "data"),
              message.type == .message else { return false }
        messageAtStart = message
        return true
    }

    @objc private func drag() {
        guard let cell = view as? UICollectionViewCell else { return }
        let offset = translation(in: cell.superview).x
        switch state {
        case .began, .changed:
            cell.contentView.layer.removeAllAnimations()
            cell.contentView.transform = CGAffineTransform(translationX: max(-84, min(0, offset)), y: 0)
        case .ended, .cancelled, .failed:
            UIView.animate(withDuration: UIAccessibility.isReduceMotionEnabled ? 0 : 0.18,
                           delay: 0, options: [.beginFromCurrentState, .curveEaseOut]) {
                cell.contentView.transform = .identity
            }
            let message: THRMessage? = BankEdnaOutlet.get(cell, "data")
            guard state == .ended, offset <= -56, message === messageAtStart else { return }
            // The bundled SDK's quoteAction: takes the message cell as its sender.
            let action = NSSelectorFromString("quoteAction:")
            var responder = cell.next
            while let current = responder {
                if current is UIViewController, current.responds(to: action) {
                    UIApplication.shared.sendAction(action, to: current, from: cell, for: nil)
                    return
                }
                responder = current.next
            }
        default: break
        }
    }
}

private final class BankClientMessageSide: UIView {
    private let photo = UIImageView()
    private let time = UILabel()
    private let status = UIImageView()
    private let bubbleMask = CAShapeLayer()
    private static let tagValue = 0xBA2401
    private var outgoing = false
    override init(frame: CGRect) {
        super.init(frame: frame)
        isUserInteractionEnabled = false
        photo.contentMode = .scaleAspectFill; photo.clipsToBounds = true; photo.layer.cornerRadius = 11
        time.font = .monospacedDigitSystemFont(ofSize: 8, weight: .regular)
        status.contentMode = .scaleAspectFit
        addSubview(photo); addSubview(time); addSubview(status)
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    override func layoutSubviews() {
        super.layoutSubviews()
        photo.frame = CGRect(x: outgoing ? 0 : bounds.width - 22, y: 0, width: 22, height: 22)
        let textWidth = ceil(time.intrinsicContentSize.width)
        let x = (bounds.width - textWidth - (status.isHidden ? 0 : 16)) / 2
        time.frame = CGRect(x: x, y: 26, width: textWidth, height: 10)
        status.frame = CGRect(x: x + textWidth + 3, y: 24, width: 13, height: 13)
    }
    private static func compactText(in cell: UICollectionViewCell, message: THRMessage, palette: BankChatTheme.Palette) {
        guard message.media == nil,
              let text: UITextView = BankEdnaOutlet.get(cell, "textView") else { return }
        // Background restoration must not depend on a sizing outlet. Some SDK
        // cells have different constraints but still need a visible bubble.
        if let background: UIImageView = BankEdnaOutlet.get(cell, "messageBubbleImageView") {
            background.image = nil
            background.backgroundColor = message.isOutgoing ? palette.outgoing : palette.incoming
            background.layer.cornerRadius = 14
            background.layer.masksToBounds = true
            background.alpha = 1
            background.isHidden = false
        }
        guard let width: NSLayoutConstraint = BankEdnaOutlet.get(cell, "textViewEstimatedWidth") else { return }
        text.textContainer.lineFragmentPadding = 0
        text.textContainerInset = UIEdgeInsets(top: 5, left: 10, bottom: 5, right: 10)
        let sdkMaxWidth: NSNumber? = BankEdnaOutlet.get(cell, "maxTextWidth")
        let availableWidth = cell.contentView.bounds.width - 16 - (message.isOutgoing ? 42 : 30) - 3
        let maxWidth = max(40, min(availableWidth, CGFloat(sdkMaxWidth?.doubleValue ?? Double(availableWidth))) - 20)
        let content = text.attributedText ?? NSAttributedString(string: text.text ?? "", attributes: [.font: text.font ?? UIFont.systemFont(ofSize: 16)])
        let measured = content.boundingRect(with: CGSize(width: maxWidth, height: .greatestFiniteMagnitude), options: [.usesLineFragmentOrigin, .usesFontLeading], context: nil)
        // SDK adds time/status width plus 32pt in layoutTextView:. The timestamp
        // now lives outside the bubble, so size only the rendered message text.
        // A quote has its own required width; do not shrink its containing cell.
        if message.quotedMessage == nil {
            let compactWidth = min(maxWidth, ceil(measured.width)) + 20
            if abs(width.constant - compactWidth) > 0.5 { width.constant = compactWidth }
        }
    }

    private static func visibleTextBounds(in text: UITextView) -> CGRect? {
        let layout = text.layoutManager
        layout.ensureLayout(for: text.textContainer)
        let range = layout.glyphRange(for: text.textContainer)
        var bounds = CGRect.null
        layout.enumerateLineFragments(forGlyphRange: range) { lineRect, _, _, glyphRange, _ in
            let characters = layout.characterRange(forGlyphRange: glyphRange, actualGlyphRange: nil)
            guard characters.length > 0 else { return }
            let line = CTLineCreateWithAttributedString(text.textStorage.attributedSubstring(from: characters))
            let ink = CTLineGetImageBounds(line, nil)
            guard !ink.isNull, !ink.isEmpty else { return }
            // TextKit uses a downward Y axis; Core Text ink bounds are relative
            // to an upward baseline. Exclude unused font descent/leading.
            let baseline = lineRect.minY + layout.location(forGlyphAt: glyphRange.location).y
            let visible = CGRect(x: 0, y: baseline - ink.maxY, width: 1, height: ink.height)
            bounds = bounds.union(visible)
        }
        return bounds.isNull ? nil : bounds
    }

    private static func fitTextBubble(in cell: UICollectionViewCell, message: THRMessage) {
        guard message.media == nil,
              let text: UITextView = BankEdnaOutlet.get(cell, "textView"),
              let background: UIImageView = BankEdnaOutlet.get(cell, "messageBubbleImageView"),
              let side = cell.contentView.viewWithTag(tagValue) as? BankClientMessageSide else { return }
        // Link previews have their own content below the text.
        let previewHeight: NSLayoutConstraint? = BankEdnaOutlet.get(cell, "opengGraphContainerHeight")
        guard (previewHeight?.constant ?? 0) <= 0,
              let visibleText = visibleTextBounds(in: text) else { return }
        let top = text.convert(CGPoint(x: 0,
            y: text.textContainerInset.top + visibleText.minY - 5), to: background).y
        let bottom = text.convert(CGPoint(x: 0,
            y: text.textContainerInset.top + visibleText.maxY + 5), to: background).y
        // Auto Layout owns the image view's frame. Clip its painted surface
        // instead, so a subsequent SDK layout cannot restore timestamp space.
        let minY = message.quotedMessage == nil ? top : background.bounds.minY
        let visible = CGRect(x: background.bounds.minX, y: minY,
                             width: background.bounds.width, height: max(0, bottom - minY))
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        side.bubbleMask.frame = background.bounds
        side.bubbleMask.path = UIBezierPath(roundedRect: visible, cornerRadius: 14).cgPath
        background.layer.mask = side.bubbleMask
        CATransaction.commit()
    }

    static func update(in view: UIView, avatar: UIImage?, palette: BankChatTheme.Palette) {
        if let collection = view as? UICollectionView {
            for cell in collection.visibleCells {
                // A recycled text cell can become a media or system cell.
                if let side = cell.contentView.viewWithTag(tagValue) as? BankClientMessageSide,
                   let background: UIImageView = BankEdnaOutlet.get(cell, "messageBubbleImageView"),
                   background.layer.mask === side.bubbleMask {
                    background.layer.mask = nil
                }
                let message: THRMessage? = BankEdnaOutlet.get(cell, "data")
                guard let message, message.type == .message else {
                    cell.contentView.viewWithTag(tagValue)?.isHidden = true
                    continue
                }
                if !(cell.gestureRecognizers ?? []).contains(where: { $0 is BankReplySwipe }) {
                    cell.addGestureRecognizer(BankReplySwipe())
                }
                let label: UILabel? = BankEdnaOutlet.get(cell, "messageBubbleTimeLabel")
                let icon: UIImageView? = BankEdnaOutlet.get(cell, "statusImageView") ?? BankEdnaOutlet.get(cell, "messageStatusImageView")
                guard let label else {
                    cell.contentView.viewWithTag(tagValue)?.isHidden = true
                    continue
                }
                let originalAvatar: UIImageView? = BankEdnaOutlet.get(cell, message.isOutgoing ? "avatarImageView" : "leftAvatarImageView")
                let avatarContainer: UIView? = BankEdnaOutlet.get(cell, message.isOutgoing ? "avatarContainerView" : "leftAvatarContainer")
                let side: BankClientMessageSide
                if let existing = cell.contentView.viewWithTag(tagValue) as? BankClientMessageSide { side = existing }
                else { side = BankClientMessageSide(frame: .zero); side.tag = tagValue; cell.contentView.addSubview(side) }
                side.isHidden = false
                side.outgoing = message.isOutgoing
                let operatorPhoto = message.author?.avatar
                    ?? (message.author?.avatarURL == nil ? nil : originalAvatar?.image)
                    ?? BankChatAvatar.operatorPlaceholder
                side.photo.image = message.isOutgoing
                    ? (avatar ?? originalAvatar?.image ?? BankChatAvatar.clientPlaceholder())
                    : operatorPhoto
                side.photo.image = side.photo.image?.withRenderingMode(.alwaysOriginal)
                side.photo.backgroundColor = message.isOutgoing ? .clear : .white
                side.time.text = label.text
                side.time.textColor = palette.status
                side.status.image = icon?.image?.withRenderingMode(.alwaysTemplate)
                side.status.tintColor = message.status == .read ? palette.read : message.status == .failed ? icon?.tintColor : palette.status
                side.status.isHidden = !message.isOutgoing || icon == nil || icon?.isHidden == true
                let sending = message.isOutgoing && (message.status == .sending || message.status == .unqueued)
                if sending && !side.status.isHidden {
                    if side.status.layer.animation(forKey: "bankSending") == nil {
                        let rotation = CABasicAnimation(keyPath: "transform.rotation.z")
                        rotation.fromValue = 0
                        rotation.toValue = CGFloat.pi * 2
                        rotation.duration = 1
                        rotation.repeatCount = .infinity
                        side.status.layer.add(rotation, forKey: "bankSending")
                    }
                } else {
                    side.status.layer.removeAnimation(forKey: "bankSending")
                }
                compactText(in: cell, message: message, palette: palette)
                cell.contentView.layoutIfNeeded()
                fitTextBubble(in: cell, message: message)
                let bubble: UIView? = BankEdnaOutlet.get(cell, "messageBubbleContainerView")
                let bubbleRect = bubble.map { $0.convert($0.bounds, to: cell.contentView) }
                let width: CGFloat = message.isOutgoing ? 42 : 30
                let x = bubbleRect.map { message.isOutgoing ? $0.maxX + 3 : $0.minX - 3 - width }
                    ?? (message.isOutgoing ? cell.contentView.bounds.width - 50 : 8)
                // The SDK container includes space above the visible bubble.
                // Align the avatar with the bubble itself, not that outer container.
                let bubbleImage: UIImageView? = BankEdnaOutlet.get(cell, "messageBubbleImageView")
                let visibleBubbleRect = bubbleImage.flatMap { image -> CGRect? in
                    guard !image.isHidden, image.alpha > 0, !image.bounds.isEmpty else { return nil }
                    let visible = image.layer.mask === side.bubbleMask
                        ? (side.bubbleMask.path?.boundingBoxOfPath ?? image.bounds) : image.bounds
                    return image.convert(visible, to: cell.contentView)
                }
                let top = visibleBubbleRect?.minY ?? bubbleRect?.minY ?? 0
                side.frame = CGRect(x: x, y: top, width: width, height: 42)
                side.setNeedsLayout()
                side.layoutIfNeeded()
                label.alpha = 0; icon?.alpha = 0; originalAvatar?.alpha = 0
                avatarContainer?.alpha = 0
                // SDK cell types use different avatar outlets. Hide both source
                // containers so a reused cell cannot leave a second photo visible.
                for name in ["avatarContainerView", "leftAvatarContainer", "avatarImageView", "leftAvatarImageView"] {
                    let source: UIView? = BankEdnaOutlet.get(cell, name)
                    source?.alpha = 0
                }
                let timeBackground: UIView? = BankEdnaOutlet.get(cell, "messageBubbleTimeLabelBackground")
                timeBackground?.alpha = 0
                cell.contentView.bringSubviewToFront(side)
            }
        } else { for child in view.subviews { update(in: child, avatar: avatar, palette: palette) } }
    }
}

/// Adapt attachment sheets and route embedded search cancellation locally.
private enum BankChatPresentation {
    static var inlineSearchOwnerKey: UInt8 = 0
    private static let installed: Void = {
        guard let original = class_getInstanceMethod(UIViewController.self, #selector(UIViewController.present(_:animated:completion:))),
              let replacement = class_getInstanceMethod(UIViewController.self, #selector(UIViewController.bankPresent(_:animated:completion:))) else { return }
        method_exchangeImplementations(original, replacement)
        guard let dismiss = class_getInstanceMethod(UIViewController.self, #selector(UIViewController.dismiss(animated:completion:))),
              let embeddedDismiss = class_getInstanceMethod(UIViewController.self, #selector(UIViewController.bankDismiss(animated:completion:))) else { return }
        method_exchangeImplementations(dismiss, embeddedDismiss)
    }()
    static func install() { _ = installed }
}
private extension UIViewController {
    @objc dynamic func bankDismiss(animated: Bool, completion: (() -> Void)?) {
        if let owner = objc_getAssociatedObject(self, &BankChatPresentation.inlineSearchOwnerKey) as? BankInlineSearchOwner {
            owner.navigation?.closeInlineSearch()
            completion?()
        } else {
            bankDismiss(animated: animated, completion: completion)
        }
    }

    @objc dynamic func bankPresent(_ controller: UIViewController, animated: Bool, completion: (() -> Void)?) {
        let navigation = (self as? BankChatNavigationController) ?? (navigationController as? BankChatNavigationController)
        if let alert = controller as? UIAlertController,
           let menu = navigation?.attachmentMenu(for: alert) {
            bankPresent(menu, animated: animated, completion: completion)
        } else {
            bankPresent(controller, animated: animated, completion: completion)
        }
    }
}
