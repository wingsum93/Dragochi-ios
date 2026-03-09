//
//  FriendNoteTextView.swift
//  Dragochi
//
//  Created by Codex on 9/3/2026.
//

import SwiftUI
import UIKit

struct FriendNoteTextView: UIViewRepresentable {
    @Binding var text: String
    let accessibilityIdentifier: String

    init(text: Binding<String>, accessibilityIdentifier: String = "input.friendNote") {
        _text = text
        self.accessibilityIdentifier = accessibilityIdentifier
    }

    func makeUIView(context: Context) -> UITextView {
        let textView = UITextView()
        textView.delegate = context.coordinator
        textView.backgroundColor = .clear
        textView.textColor = UIColor.white.withAlphaComponent(0.9)
        textView.font = UIFont(name: "BeVietnamPro-Regular", size: 14) ?? UIFont.systemFont(ofSize: 14)
        textView.tintColor = UIColor(red: 19 / 255, green: 236 / 255, blue: 91 / 255, alpha: 1)
        textView.autocorrectionType = .default
        textView.autocapitalizationType = .sentences
        textView.accessibilityIdentifier = accessibilityIdentifier
        return textView
    }

    func updateUIView(_ uiView: UITextView, context: Context) {
        if uiView.text != text {
            uiView.text = text
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(text: $text)
    }

    final class Coordinator: NSObject, UITextViewDelegate {
        private let text: Binding<String>

        init(text: Binding<String>) {
            self.text = text
        }

        func textViewDidChange(_ textView: UITextView) {
            text.wrappedValue = textView.text
        }
    }
}
