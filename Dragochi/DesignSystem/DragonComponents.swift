//
//  DragonComponents.swift
//  Dragochi
//
//  Created by Codex on 12/2/2026.
//

import SwiftUI

enum SelectionState {
    case selected
    case unselected
    case add
}

enum ControlState {
    case enabled
    case pressed
    case disabled
    case loading
}

enum TrendDirection {
    case up
    case down
    case neutral

    var iconName: String {
        switch self {
        case .up:
            return "arrow.up.right"
        case .down:
            return "arrow.down.right"
        case .neutral:
            return "minus"
        }
    }
}

struct GameCardModel: Identifiable, Hashable {
    let id: String
    let title: String
    let imageURL: URL?
}

struct TeammateChipModel: Identifiable, Hashable {
    let id: String
    let name: String
    let avatarURL: URL?
}

struct PlatformOption: Identifiable, Hashable {
    let id: String
    let iconName: String
    let title: String
    var isEnabled: Bool = true
}

struct NotesQuickAction: Identifiable, Hashable {
    let id: String
    let iconName: String
}

struct DragonBottomSheetContainer<Content: View, Footer: View>: View {
    private let content: Content
    private let footer: Footer

    init(
        @ViewBuilder content: () -> Content,
        @ViewBuilder footer: () -> Footer
    ) {
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
                        .padding(.top, DragonTheme.current.spacing(.sm))
                        .padding(.bottom, 100)
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
                    .frame(height: 54)

                    footer
                        .padding(.horizontal, DragonTheme.current.spacing(.lg))
                        .padding(.bottom, DragonTheme.current.spacing(.lg))
                        .padding(.top, DragonTheme.current.spacing(.md))
                        .background(DragonTheme.current.color(.bgBase))
                }
            }
            .padding(.top, 70)
        }
    }
}

struct DragonSessionHero: View {
    let title: String
    let durationText: String
    let trendText: String
    let trendDirection: TrendDirection

    var body: some View {
        VStack(spacing: DragonTheme.current.spacing(.xs)) {
            Text(title)
                .font(DragonTheme.current.font(.titleSection))
                .foregroundStyle(DragonTheme.current.color(.textSecondary))
                .tracking(0.7)
                .textCase(.uppercase)

            Text(durationText)
                .font(DragonTheme.current.font(.displayTimer))
                .foregroundStyle(DragonTheme.current.color(.accentPrimary))
                .minimumScaleFactor(0.6)
                .lineLimit(1)

            HStack(spacing: DragonTheme.current.spacing(.xxs)) {
                Image(systemName: trendDirection.iconName)
                    .font(.system(size: 12, weight: .semibold))
                Text(trendText)
                    .font(DragonTheme.current.font(.labelSmall))
            }
            .foregroundStyle(DragonTheme.current.color(.accentPrimary))
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(DragonTheme.current.color(.accentPrimarySoft))
            .overlay(
                Capsule()
                    .stroke(DragonTheme.current.color(.borderNeon), lineWidth: 1)
            )
            .clipShape(Capsule())
        }
        .frame(maxWidth: .infinity)
    }
}

struct DragonSectionHeader: View {
    let title: String
    let trailingText: String?
    let trailingAction: (() -> Void)?

    init(
        title: String,
        trailingText: String? = nil,
        trailingAction: (() -> Void)? = nil
    ) {
        self.title = title
        self.trailingText = trailingText
        self.trailingAction = trailingAction
    }

    var body: some View {
        HStack {
            Text(title)
                .font(DragonTheme.current.font(.titleSection))
                .foregroundStyle(DragonTheme.current.color(.textPrimary))

            Spacer()

            if let trailingText {
                if let trailingAction {
                    Button(trailingText, action: trailingAction)
                        .buttonStyle(.plain)
                        .font(DragonTheme.current.font(.labelSmall))
                        .foregroundStyle(DragonTheme.current.color(.accentPrimary))
                } else {
                    Text(trailingText)
                        .font(DragonTheme.current.font(.labelSmall))
                        .foregroundStyle(DragonTheme.current.color(.textTertiary))
                }
            }
        }
    }
}

struct DragonSelectableGameCard: View {
    let model: GameCardModel
    let state: SelectionState
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack(alignment: .bottomLeading) {
                RoundedRectangle(cornerRadius: DragonTheme.current.radius(.card), style: .continuous)
                    .fill(DragonTheme.current.color(.surfaceCard))
                    .frame(width: 80, height: 112)
                    .overlay {
                        gameContent
                    }

                if state != .add {
                    LinearGradient(
                        colors: [.clear, .black.opacity(0.85)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .clipShape(RoundedRectangle(cornerRadius: DragonTheme.current.radius(.card), style: .continuous))
                    .frame(width: 80, height: 112)

                    Text(model.title)
                        .font(DragonTheme.current.font(.labelSmall))
                        .foregroundStyle(.white)
                        .padding(.leading, 8)
                        .padding(.bottom, 8)
                }
            }
            .overlay(alignment: .topTrailing) {
                if state == .selected {
                    Circle()
                        .fill(DragonTheme.current.color(.accentPrimary))
                        .frame(width: 16, height: 16)
                        .overlay {
                            Image(systemName: "checkmark")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(.black)
                        }
                        .padding(6)
                }
            }
            .overlay {
                RoundedRectangle(cornerRadius: DragonTheme.current.radius(.card), style: .continuous)
                    .stroke(borderColor, lineWidth: borderWidth)
            }
            .shadow(color: glowColor, radius: 12)
            .opacity(opacityValue)
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private var gameContent: some View {
        switch state {
        case .add:
            Image(systemName: "plus")
                .font(.system(size: 24, weight: .regular))
                .foregroundStyle(DragonTheme.current.color(.textTertiary))
        case .selected, .unselected:
            AsyncImage(url: model.imageURL) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFill()
                default:
                    LinearGradient(
                        colors: [
                            DragonTheme.current.color(.surfaceCard),
                            DragonTheme.current.color(.bgBase)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                }
            }
            .frame(width: 78, height: 110)
            .clipShape(RoundedRectangle(cornerRadius: DragonTheme.current.radius(.card) - 2, style: .continuous))
        }
    }

    private var borderColor: Color {
        switch state {
        case .selected:
            return DragonTheme.current.color(.accentPrimary)
        case .unselected:
            return DragonTheme.current.color(.borderSoft)
        case .add:
            return DragonTheme.current.color(.borderSoft)
        }
    }

    private var borderWidth: CGFloat {
        state == .selected ? 2 : 1
    }

    private var glowColor: Color {
        state == .selected ? DragonTheme.current.color(.accentPrimary).opacity(0.3) : .clear
    }

    private var opacityValue: Double {
        state == .unselected ? 0.62 : 1
    }
}

struct DragonPlatformPill: View {
    let platform: PlatformOption
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: platform.iconName)
                    .font(.system(size: 22, weight: .regular))
                Text(platform.title)
                    .font(DragonTheme.current.font(.labelSmall))
            }
            .foregroundStyle(foregroundColor)
            .frame(maxWidth: .infinity, minHeight: 70)
            .background(backgroundColor)
            .overlay(
                RoundedRectangle(cornerRadius: DragonTheme.current.radius(.card), style: .continuous)
                    .stroke(borderColor, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: DragonTheme.current.radius(.card), style: .continuous))
            .overlay(alignment: .topTrailing) {
                if isSelected {
                    Circle()
                        .fill(DragonTheme.current.color(.accentPrimary))
                        .frame(width: 6, height: 6)
                        .shadow(color: DragonTheme.current.color(.accentPrimary), radius: 6)
                        .padding(10)
                }
            }
        }
        .disabled(!platform.isEnabled)
        .buttonStyle(.plain)
        .opacity(platform.isEnabled ? 1 : 0.45)
    }

    private var foregroundColor: Color {
        if isSelected {
            return DragonTheme.current.color(.accentPrimary)
        }
        return DragonTheme.current.color(.textTertiary)
    }

    private var backgroundColor: Color {
        if isSelected {
            return DragonTheme.current.color(.accentPrimaryDim)
        }
        return DragonTheme.current.color(.surfaceCard)
    }

    private var borderColor: Color {
        if isSelected {
            return DragonTheme.current.color(.accentPrimary)
        }
        return DragonTheme.current.color(.borderSoft).opacity(0.5)
    }
}

struct DragonTeammateAvatarChip: View {
    let model: TeammateChipModel
    let state: SelectionState
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                ZStack(alignment: .bottomTrailing) {
                    avatar

                    if state == .selected {
                        Circle()
                            .fill(DragonTheme.current.color(.accentPrimary))
                            .frame(width: 16, height: 16)
                            .overlay {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundStyle(.black)
                            }
                            .offset(x: 2, y: 2)
                    }
                }

                Text(state == .add ? "Add" : model.name)
                    .font(DragonTheme.current.font(.labelSmall))
                    .foregroundStyle(labelColor)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .frame(width: 56)
        }
        .buttonStyle(.plain)
        .opacity(state == .unselected ? 0.55 : 1)
    }

    @ViewBuilder
    private var avatar: some View {
        switch state {
        case .add:
            Circle()
                .stroke(style: StrokeStyle(lineWidth: 1, dash: [4, 4]))
                .foregroundStyle(DragonTheme.current.color(.textTertiary))
                .frame(width: 56, height: 56)
                .overlay {
                    Image(systemName: "plus")
                        .font(.system(size: 20, weight: .regular))
                        .foregroundStyle(DragonTheme.current.color(.textTertiary))
                }
        case .selected, .unselected:
            ZStack {
                Circle()
                    .fill(
                        AngularGradient(
                            colors: [
                                DragonTheme.current.color(.accentPrimary),
                                DragonTheme.current.color(.accentPrimary).opacity(0),
                                DragonTheme.current.color(.accentPrimary)
                            ],
                            center: .center
                        )
                    )
                    .frame(width: 56, height: 56)
                    .opacity(state == .selected ? 1 : 0)

                AsyncImage(url: model.avatarURL) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                    default:
                        Circle()
                            .fill(DragonTheme.current.color(.surfaceCard))
                            .overlay {
                                Image(systemName: "person.fill")
                                    .foregroundStyle(DragonTheme.current.color(.textTertiary))
                            }
                    }
                }
                .frame(width: 52, height: 52)
                .clipShape(Circle())
                .overlay {
                    Circle().stroke(DragonTheme.current.color(.bgBase), lineWidth: 2)
                }
            }
        }
    }

    private var labelColor: Color {
        switch state {
        case .selected:
            return .white
        case .unselected, .add:
            return DragonTheme.current.color(.textTertiary)
        }
    }
}

struct DragonNotesInput: View {
    @Binding var text: String
    let placeholder: String
    let actions: [NotesQuickAction]
    var onAction: ((NotesQuickAction) -> Void)?

    @FocusState private var isFocused: Bool

    private var state: NotesState {
        if isFocused { return .focused }
        return text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? .idle : .filled
    }

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            TextEditor(text: $text)
                .focused($isFocused)
                .scrollContentBackground(.hidden)
                .frame(minHeight: 96, maxHeight: 96)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .foregroundStyle(DragonTheme.current.color(.textPrimary))
                .font(DragonTheme.current.font(.body))
                .background(DragonTheme.current.color(.surfaceCard))
                .overlay(
                    RoundedRectangle(cornerRadius: DragonTheme.current.radius(.bottomSheetTop), style: .continuous)
                        .stroke(borderColor, lineWidth: 1)
                )
                .clipShape(
                    RoundedRectangle(cornerRadius: DragonTheme.current.radius(.bottomSheetTop), style: .continuous)
                )

            if text.isEmpty {
                Text(placeholder)
                    .font(DragonTheme.current.font(.body))
                    .foregroundStyle(DragonTheme.current.color(.textPlaceholder))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                    .allowsHitTesting(false)
            }

            HStack(spacing: 4) {
                ForEach(actions) { item in
                    Button {
                        onAction?(item)
                    } label: {
                        Image(systemName: item.iconName)
                            .font(.system(size: 14, weight: .regular))
                            .foregroundStyle(DragonTheme.current.color(.textTertiary))
                            .frame(width: 22, height: 28)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.trailing, 12)
            .padding(.bottom, 10)
        }
    }

    private var borderColor: Color {
        switch state {
        case .focused:
            return DragonTheme.current.color(.borderNeon)
        case .idle, .filled:
            return .clear
        }
    }
}

private enum NotesState {
    case idle
    case focused
    case filled
}

struct DragonPrimaryCTAButton: View {
    let title: String
    let icon: String?
    let state: ControlState
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if state == .loading {
                    ProgressView()
                        .tint(.black)
                } else {
                    Text(title)
                        .font(DragonTheme.current.font(.cta))
                    if let icon {
                        Image(systemName: icon)
                            .font(.system(size: 20, weight: .semibold))
                    }
                }
            }
            .foregroundStyle(.black)
            .frame(maxWidth: .infinity)
            .frame(height: 60)
            .background(backgroundColor)
            .clipShape(Capsule())
            .shadow(color: shadowColor, radius: 12, y: 4)
        }
        .buttonStyle(.plain)
        .disabled(state == .disabled || state == .loading)
    }

    private var backgroundColor: Color {
        switch state {
        case .enabled:
            return DragonTheme.current.color(.accentPrimary)
        case .pressed:
            return DragonTheme.current.color(.accentPrimary).opacity(0.85)
        case .disabled, .loading:
            return DragonTheme.current.color(.accentPrimary).opacity(0.55)
        }
    }

    private var shadowColor: Color {
        state == .enabled ? DragonTheme.current.color(.accentPrimary).opacity(0.35) : .clear
    }
}

struct DragonTextButton: View {
    let title: String
    let state: ControlState
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(DragonTheme.current.font(.body))
                .foregroundStyle(textColor)
                .frame(maxWidth: .infinity)
                .frame(height: 20)
        }
        .buttonStyle(.plain)
        .disabled(state == .disabled || state == .loading)
    }

    private var textColor: Color {
        switch state {
        case .enabled:
            return DragonTheme.current.color(.textTertiary)
        case .pressed:
            return DragonTheme.current.color(.textSecondary)
        case .disabled, .loading:
            return DragonTheme.current.color(.textTertiary).opacity(0.5)
        }
    }
}
