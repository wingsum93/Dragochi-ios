//
//  FriendImportOptionSheet.swift
//  Dragochi
//
//  Created by Codex on 29/5/2026.
//

import SwiftUI

struct FriendImportOptionSheet: View {
    let onImportFromApple: () -> Void
    let onImportFromGoogle: () -> Void
    let onCancel: () -> Void

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: DragonTheme.current.spacing(.sm)) {
                Button {
                    onImportFromApple()
                } label: {
                    HStack {
                        Text("button_import_from_apple")
                            .font(DragonTheme.current.font(.labelSmall))
                            .foregroundStyle(DragonTheme.current.color(.textPrimary))
                        Spacer()
                    }
                    .padding(.vertical, 8)
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("action.importFromAppleInSheet")

                Button {
                    onImportFromGoogle()
                } label: {
                    HStack {
                        Text("button_import_from_google")
                            .font(DragonTheme.current.font(.labelSmall))
                            .foregroundStyle(DragonTheme.current.color(.textPrimary))
                        Spacer()
                    }
                    .padding(.vertical, 8)
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("action.importFromGoogleInSheet")

                Spacer()
            }
            .padding(DragonTheme.current.spacing(.lg))
            .overlay(alignment: .topLeading) {
                Color.clear
                    .frame(width: 1, height: 1)
                    .accessibilityIdentifier("sheet.friendImportOptions")
            }
            .navigationTitle("title_import_friends")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("button_cancel") {
                        onCancel()
                    }
                }
            }
            .background(DragonTheme.current.color(.bgBase).ignoresSafeArea())
        }
        .presentationDetents([.height(220)])
    }
}

#Preview("Dark Mode") {
    FriendImportOptionSheet(
        onImportFromApple: {},
        onImportFromGoogle: {},
        onCancel: {}
    )
    .frame(height: 220)
}
