//
//  DragonLottieView.swift
//  Dragochi
//
//  Created by Codex on 17/2/2026.
//

import SwiftUI
import UIKit
import Lottie

struct DragonLottieView: UIViewRepresentable {
    let animationName: String
    var loopMode: LottieLoopMode = .loop
    var contentMode: UIView.ContentMode = .scaleAspectFit
    var speed: CGFloat = 1.0

    static func canLoadAnimation(named animationName: String, bundle: Bundle = .main) -> Bool {
        LottieAnimation.named(animationName, bundle: bundle) != nil
    }

    func makeUIView(context: Context) -> UIView {
        let container = UIView(frame: .zero)
        container.backgroundColor = .clear

        let animationView = LottieAnimationView()
        animationView.translatesAutoresizingMaskIntoConstraints = false
        animationView.backgroundBehavior = .pauseAndRestore
        container.addSubview(animationView)

        NSLayoutConstraint.activate([
            animationView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            animationView.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            animationView.topAnchor.constraint(equalTo: container.topAnchor),
            animationView.bottomAnchor.constraint(equalTo: container.bottomAnchor),
        ])

        context.coordinator.animationView = animationView
        configure(animationView, coordinator: context.coordinator)
        return container
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        guard let animationView = context.coordinator.animationView else { return }
        configure(animationView, coordinator: context.coordinator)
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    private func configure(_ animationView: LottieAnimationView, coordinator: Coordinator) {
        if coordinator.loadedAnimationName != animationName {
            animationView.animation = LottieAnimation.named(animationName, bundle: .main)
            coordinator.loadedAnimationName = animationName
        }

        animationView.loopMode = loopMode
        animationView.contentMode = contentMode
        animationView.animationSpeed = speed

        guard animationView.animation != nil else {
            animationView.stop()
            return
        }

        if !animationView.isAnimationPlaying {
            animationView.play()
        }
    }

    final class Coordinator {
        var animationView: LottieAnimationView?
        var loadedAnimationName: String?
    }
}
