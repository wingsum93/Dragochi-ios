//
//  DragonBottomSheetContainer.swift
//  Dragochi
//
//  Created by Codex on 17/2/2026.
//

import SwiftUI

struct DragonBottomSheetContainer<Content: View, Footer: View>: View {
    private let topInset: CGFloat
    private let contentTopPadding: CGFloat
    private let minimumContentBottomPadding: CGFloat
    private let footerGradientHeight: CGFloat
    private let extraContentBottomPadding: CGFloat
    private let content: Content
    private let footer: Footer
    @State private var bottomOverlayHeight: CGFloat = 0

    init(
        topInset: CGFloat = 70,
        contentTopPadding: CGFloat = 12,
        minimumContentBottomPadding: CGFloat = 100,
        footerGradientHeight: CGFloat = 54,
        extraContentBottomPadding: CGFloat = 12,
        @ViewBuilder content: () -> Content,
        @ViewBuilder footer: () -> Footer
    ) {
        self.topInset = topInset
        self.contentTopPadding = contentTopPadding
        self.minimumContentBottomPadding = minimumContentBottomPadding
        self.footerGradientHeight = footerGradientHeight
        self.extraContentBottomPadding = extraContentBottomPadding
        self.content = content()
        self.footer = footer()
    }

    var body: some View {
        ZStack {
            DragonTheme.current.color(.bgBase).ignoresSafeArea()
            DragonTheme.current.color(.overlayScrim)
                .ignoresSafeArea()
                .blur(radius: 2)

            VStack(spacing: 0) {
                Capsule()
                    .fill(Color.white.opacity(0.2))
                    .frame(width: 48, height: 6)
                    .padding(.top, 16)
                    .padding(.bottom, 8)

                ScrollView(showsIndicators: false) {
                    content
                        .padding(.horizontal, DragonTheme.current.spacing(.lg))
                        .padding(.top, contentTopPadding)
                        .padding(
                            .bottom,
                            max(
                                minimumContentBottomPadding,
                                bottomOverlayHeight + extraContentBottomPadding
                            )
                        )
                }
            }
            .background(
                DragonTheme.current.color(.bgBase).opacity(0.92)
            )
            .clipShape(
                RoundedRectangle(
                    cornerRadius: DragonTheme.current.radius(.bottomSheetTop),
                    style: .continuous
                )
            )
            .overlay(alignment: .bottom) {
                VStack(spacing: 0) {
                    LinearGradient(
                        colors: [
                            DragonTheme.current.color(.bgBase).opacity(0),
                            DragonTheme.current.color(.bgBase).opacity(0.85),
                            DragonTheme.current.color(.bgBase)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: footerGradientHeight)

                    footer
                        .padding(.horizontal, DragonTheme.current.spacing(.lg))
                        .padding(.bottom, DragonTheme.current.spacing(.lg))
                        .padding(.top, DragonTheme.current.spacing(.md))
                        .background(DragonTheme.current.color(.bgBase))
                }
                .background(
                    GeometryReader { proxy in
                        Color.clear.preference(
                            key: DragonFooterOverlayHeightPreferenceKey.self,
                            value: proxy.size.height
                        )
                    }
                )
            }
            .onPreferenceChange(DragonFooterOverlayHeightPreferenceKey.self) { height in
                bottomOverlayHeight = height
            }
            .padding(.top, topInset)
        }
    }
}

private struct DragonFooterOverlayHeightPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0

    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}
