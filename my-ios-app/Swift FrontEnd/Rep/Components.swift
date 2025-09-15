import SwiftUI
import WebKit

// MARK: - AuthSession Helper

enum AuthSession {
    static func handleUnauthorized(_ context: String = "") {
        DispatchQueue.main.async {
            UserDefaults.standard.set("", forKey: "jwtToken")
            UserDefaults.standard.set(0, forKey: "userId")
            NotificationCenter.default.post(name: Notification.Name("ForceRootReload"), object: nil)
            #if DEBUG
            print("AuthSession.handleUnauthorized triggered from:", context)
            #endif
        }
    }
}

// MARK: - GrowingTextEditor

struct GrowingTextEditor: View {
    @Binding var text: String
    var minHeight: CGFloat = 36 // 1 line
    var maxHeight: CGFloat = 36 * 4 // 4 lines

    @State private var textViewHeight: CGFloat = 36

    var body: some View {
        ZStack(alignment: .topLeading) {
            if text.isEmpty {
                Text("Type a message...")
                    .foregroundColor(.gray)
                    .padding(.vertical, 6)
                    .padding(.horizontal, 8)
            }
            UITextViewWrapper(
                text: Binding<String>(get: { self.text }, set: { self.text = $0 }),
                calculatedHeight: $textViewHeight,
                minHeight: minHeight,
                maxHeight: maxHeight
            )
            .frame(height: textViewHeight)
            .background(Color(UIColor.systemGray6))
            .cornerRadius(8)
        }
    }
}

// MARK: - UITextViewWrapper for dynamic height

struct UITextViewWrapper: UIViewRepresentable {
    var text: Binding<String>
    @Binding var calculatedHeight: CGFloat

    let minHeight: CGFloat
    let maxHeight: CGFloat

    func makeUIView(context: Context) -> UITextView {
        let textView = UITextView()
        textView.isScrollEnabled = false
        textView.font = UIFont.preferredFont(forTextStyle: .body)
        textView.backgroundColor = UIColor.clear
        textView.delegate = context.coordinator
        textView.textContainerInset = UIEdgeInsets(top: 6, left: 4, bottom: 6, right: 4)
        textView.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        return textView
    }

    func updateUIView(_ uiView: UITextView, context: Context) {
        if uiView.text != self.text.wrappedValue {
            uiView.text = self.text.wrappedValue
        }
        UITextViewWrapper.recalculateHeight(view: uiView, result: $calculatedHeight, minHeight: minHeight, maxHeight: maxHeight)
        uiView.isScrollEnabled = calculatedHeight >= maxHeight
    }

    static func recalculateHeight(view: UIView, result: Binding<CGFloat>, minHeight: CGFloat, maxHeight: CGFloat) {
        let size = view.sizeThatFits(CGSize(width: view.bounds.width, height: CGFloat.greatestFiniteMagnitude))
        let newHeight = min(max(size.height, minHeight), maxHeight)
        if result.wrappedValue != newHeight {
            DispatchQueue.main.async {
                result.wrappedValue = newHeight
            }
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    class Coordinator: NSObject, UITextViewDelegate {
        var parent: UITextViewWrapper

        init(parent: UITextViewWrapper) {
            self.parent = parent
        }

        func textViewDidChange(_ textView: UITextView) {
            self.parent.text.wrappedValue = textView.text
            UITextViewWrapper.recalculateHeight(view: textView, result: self.parent.$calculatedHeight, minHeight: parent.minHeight, maxHeight: parent.maxHeight)
        }
    }
}

// MARK: - Safari WebView

struct SafariWebView: UIViewControllerRepresentable {
    let url: URL
    let onDismiss: () -> Void

    func makeUIViewController(context: Context) -> UINavigationController {
        let webVC = WKWebViewController(url: url, onDismiss: onDismiss)
        let navController = UINavigationController(rootViewController: webVC)
        return navController
    }

    func updateUIViewController(_ uiViewController: UINavigationController, context: Context) {
        // No updates needed
    }
}

class WKWebViewController: UIViewController, WKNavigationDelegate {
    var webView: WKWebView!
    let url: URL
    let onDismiss: () -> Void
    
    init(url: URL, onDismiss: @escaping () -> Void) {
        self.url = url
        self.onDismiss = onDismiss
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Set up the WKWebView
        webView = WKWebView(frame: view.bounds)
        webView.navigationDelegate = self
        webView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(webView)

        // Custom back button: chevron.left with "Rep" in light green
        let backButton = UIBarButtonItem()
        let chevronImage = UIImage(systemName: "chevron.left", withConfiguration: UIImage.SymbolConfiguration(weight: .bold)) // bolder chevron
        let button = UIButton(type: .system)
        button.setImage(chevronImage, for: .normal)
        button.setTitle(" Rep", for: .normal)
        button.setTitleColor(UIColor(red: 0.549, green: 0.78, blue: 0.365, alpha: 1.0), for: .normal) // light green
        button.tintColor = UIColor(red: 0.549, green: 0.78, blue: 0.365, alpha: 1.0) // light green
        button.titleLabel?.font = UIFont.systemFont(ofSize: 17, weight: .semibold)
        button.addTarget(self, action: #selector(closeWebView), for: .touchUpInside)
        backButton.customView = button
        navigationItem.leftBarButtonItem = backButton

        navigationItem.title = ""

        // Load the initial URL only once
        let request = URLRequest(url: url)
        webView.load(request)
    }
    
    @objc func closeWebView() {
        dismiss(animated: true) {
            self.onDismiss()
        }
    }
    
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        if let navURL = navigationAction.request.url {
            // Detect Stripe payment return
            if navURL.absoluteString.contains("/payment-return?status=success") {
                let components = URLComponents(url: navURL, resolvingAgainstBaseURL: false)
                let sessionId = components?.queryItems?.first(where: { $0.name == "session_id" })?.value ?? ""
                #if DEBUG
                print("[WKWebViewController] Posting PaymentCompleted notification: success, session_id:", sessionId)
                #endif
                NotificationCenter.default.post(
                    name: Notification.Name("PaymentCompleted"),
                    object: nil,
                    userInfo: ["status": "success", "session_id": sessionId]
                )
                closeWebView()
                decisionHandler(.cancel)
                return
            } else if navURL.absoluteString.contains("/payment-return?status=canceled") {
                #if DEBUG
                print("[WKWebViewController] Posting PaymentCompleted notification: canceled")
                #endif
                NotificationCenter.default.post(
                    name: Notification.Name("PaymentCompleted"),
                    object: nil,
                    userInfo: ["status": "canceled"]
                )
                closeWebView()
                decisionHandler(.cancel)
                return
            } else if navURL.scheme == "rep" {
                UIApplication.shared.open(navURL, options: [:], completionHandler: nil)
                closeWebView()
                decisionHandler(.cancel)
                return
            }
        }
        decisionHandler(.allow)
    }
}