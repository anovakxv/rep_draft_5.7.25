
import SwiftUI

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
                text: $text,
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
    @Binding var text: String
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
        if uiView.text != self.text {
            uiView.text = self.text
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
            self.parent.text = textView.text
            UITextViewWrapper.recalculateHeight(view: textView, result: self.parent.$calculatedHeight, minHeight: parent.minHeight, maxHeight: parent.maxHeight)
        }
    }
}
