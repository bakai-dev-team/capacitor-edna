import UIKit
import PhotosUI
import UniformTypeIdentifiers
import ChatCenterUI

/// Bank attachment sheet. Selection and uploading remain handled by Edna.
internal final class BankAttachmentMenu: UIViewController {
    private let picker: SystemFilePickerViewController
    private let dark: Bool
    private let availableSources: [Bool]
    private let panel = UIView()
    private let buttons = UIStackView()

    init(picker: SystemFilePickerViewController, dark: Bool, availableSources: [Bool]) {
        self.availableSources = availableSources
        self.picker = picker
        self.dark = dark
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .overFullScreen
        modalTransitionStyle = .crossDissolve
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func viewDidLoad() {
        super.viewDidLoad()
        overrideUserInterfaceStyle = dark ? .dark : .light
        let backdrop = UIControl()
        backdrop.backgroundColor = UIColor.black.withAlphaComponent(0.35)
        backdrop.addTarget(self, action: #selector(close), for: .touchUpInside)
        backdrop.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(backdrop)
        panel.backgroundColor = color(dark ? 0x1B1D23 : 0xFFFFFF)
        panel.layer.cornerRadius = 0
        panel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(panel)
        buttons.axis = .horizontal
        buttons.distribution = .fillEqually
        buttons.spacing = 12
        buttons.translatesAutoresizingMaskIntoConstraints = false
        panel.addSubview(buttons)
        let russian = BankEdnaLocalization.language == "ru" || BankEdnaLocalization.language == "ky"
        for (index, item) in [(russian ? "Камера" : "Camera", "camera"), (russian ? "Галерея" : "Gallery", "gallery"), (russian ? "Файл" : "File", "document")].enumerated() {
            let button = UIButton(type: .system)
            var configuration = UIButton.Configuration.plain()
            configuration.title = item.0
            configuration.image = resourceImage(item.1)
            configuration.imagePlacement = .top
            configuration.imagePadding = 6
            configuration.baseForegroundColor = color(dark ? 0xFFFFFF : 0x000000)
            configuration.background.backgroundColor = color(dark ? 0x242526 : 0xF5F6FA)
            configuration.background.cornerRadius = 32
            configuration.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { attributes in
                var result = attributes
                result.font = UIFont.systemFont(ofSize: 16)
                return result
            }
            button.configuration = configuration
            button.tag = index
            button.isEnabled = availableSources[index]
            button.accessibilityLabel = item.0
            button.addTarget(self, action: #selector(selectSource(_:)), for: .touchUpInside)
            buttons.addArrangedSubview(button)
        }
        NSLayoutConstraint.activate([
            backdrop.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            backdrop.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            backdrop.topAnchor.constraint(equalTo: view.topAnchor),
            backdrop.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            panel.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            panel.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            panel.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            buttons.leadingAnchor.constraint(equalTo: panel.leadingAnchor, constant: 20),
            buttons.trailingAnchor.constraint(equalTo: panel.trailingAnchor, constant: -20),
            buttons.topAnchor.constraint(equalTo: panel.topAnchor, constant: 18),
            buttons.bottomAnchor.constraint(equalTo: panel.safeAreaLayoutGuide.bottomAnchor, constant: -22),
            buttons.heightAnchor.constraint(equalToConstant: 66)
        ])
        (buttons.arrangedSubviews.first as? UIButton)?.isEnabled = availableSources[0] && UIImagePickerController.isSourceTypeAvailable(.camera)
    }

    @objc private func close() { dismiss(animated: true) }

    @objc private func selectSource(_ sender: UIButton) {
        guard let presenter = presentingViewController else { return }
        let next: UIViewController
        switch sender.tag {
        case 0:
            let camera = UIImagePickerController()
            camera.sourceType = .camera
            camera.delegate = picker
            next = camera
        case 1:
            var configuration = PHPickerConfiguration()
            configuration.filter = .images
            configuration.selectionLimit = max(1, picker.maxImagesCount)
            let gallery = PHPickerViewController(configuration: configuration)
            gallery.delegate = picker
            next = gallery
        default:
            let documents = UIDocumentPickerViewController(forOpeningContentTypes: CCFileSettings.getDocumentTypes(), asCopy: false)
            documents.delegate = picker
            next = documents
        }
        next.overrideUserInterfaceStyle = dark ? .dark : .light
        dismiss(animated: false) { presenter.present(next, animated: true) }
    }

    private func resourceImage(_ name: String) -> UIImage? {
        BankAttachmentIcons.image(name, tint: color(dark ? 0x9CA3AF : 0xAFB4BE))
    }

    private func color(_ hex: UInt32) -> UIColor {
        UIColor(red: CGFloat((hex >> 16) & 255) / 255,
                green: CGFloat((hex >> 8) & 255) / 255,
                blue: CGFloat(hex & 255) / 255, alpha: 1)
    }
}
