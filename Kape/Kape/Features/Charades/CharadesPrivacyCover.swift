import SwiftUI

/// UIKit covers the existing window synchronously before its app-switcher snapshot.
/// The game also pauses; removing the cover never reveals a running/private state.
struct CharadesPrivacyCover: UIViewRepresentable {
    var hidePrivateContent: () -> Void
    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        view.isUserInteractionEnabled = false
        context.coordinator.anchor = view
        return view
    }
    func updateUIView(_ uiView: UIView, context: Context) { context.coordinator.hide = hidePrivateContent }
    func makeCoordinator() -> Coordinator { Coordinator(hide: hidePrivateContent) }
    static func dismantleUIView(_ uiView: UIView, coordinator: Coordinator) { coordinator.remove() }

    final class Coordinator: NSObject {
        weak var anchor: UIView?
        var hide: () -> Void
        private var cover: UIView?
        init(hide: @escaping () -> Void) {
            self.hide = hide
            super.init()
            NotificationCenter.default.addObserver(self, selector: #selector(resign), name: UIApplication.willResignActiveNotification, object: nil)
            NotificationCenter.default.addObserver(self, selector: #selector(active), name: UIApplication.didBecomeActiveNotification, object: nil)
        }
        nonisolated deinit { NotificationCenter.default.removeObserver(self) }
        @objc private func resign() {
            hide()
            guard let window = anchor?.window, cover == nil else { return }
            let shield = UIView(frame: window.bounds)
            shield.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            shield.backgroundColor = UIColor(CharadesTheme.background)
            let label = UILabel()
            label.text = "Kape!"
            label.font = .systemFont(ofSize: 34, weight: .bold)
            label.textColor = UIColor(CharadesTheme.accent)
            label.translatesAutoresizingMaskIntoConstraints = false
            shield.addSubview(label)
            NSLayoutConstraint.activate([label.centerXAnchor.constraint(equalTo: shield.centerXAnchor),
                                         label.centerYAnchor.constraint(equalTo: shield.centerYAnchor)])
            shield.accessibilityIdentifier = "PrivacyCover"
            window.addSubview(shield)
            cover = shield
        }
        @objc private func active() {
            // Allow the paused SwiftUI hierarchy to render before uncovering it.
            DispatchQueue.main.async { [weak self] in self?.remove() }
        }
        func remove() { cover?.removeFromSuperview(); cover = nil }
    }
}
