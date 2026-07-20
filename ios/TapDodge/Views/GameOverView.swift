//
//  GameOverView.swift
//  TapDodge
//

import SwiftUI

/// Final score panel with a Restart button.
struct GameOverView: View {
    let score: Int
    let bestScore: Int
    let isNewBest: Bool
    let onRestart: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.55)
                .ignoresSafeArea()

            VStack(spacing: 20) {
                Text("Game Over")
                    .font(.system(size: 40, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)
                    .shadow(color: .pink.opacity(0.6), radius: 12)

                VStack(spacing: 6) {
                    Text("Score")
                        .font(.subheadline.weight(.semibold))
                        .textCase(.uppercase)
                        .tracking(2)
                        .foregroundStyle(.white.opacity(0.7))
                    Text("\(score)")
                        .font(.system(size: 72, weight: .heavy, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(colors: [.cyan, .pink],
                                           startPoint: .topLeading,
                                           endPoint: .bottomTrailing)
                        )

                    if isNewBest {
                        Label("New Best!", systemImage: "star.fill")
                            .font(.footnote.weight(.bold))
                            .foregroundStyle(.yellow)
                            .transition(.scale.combined(with: .opacity))
                    } else {
                        Text("Best: \(bestScore)")
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(.white.opacity(0.6))
                    }
                }

                Button(action: onRestart) {
                    HStack(spacing: 8) {
                        Image(systemName: "arrow.clockwise")
                            .font(.headline)
                        Text("Restart")
                            .font(.headline.weight(.bold))
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 40)
                    .padding(.vertical, 14)
                    .background(
                        Capsule().fill(
                            LinearGradient(colors: [.pink, .purple],
                                           startPoint: .leading,
                                           endPoint: .trailing)
                        )
                    )
                    .shadow(color: .pink.opacity(0.6), radius: 16, y: 6)
                }
                .buttonStyle(PressButtonStyle())
            }
            .padding(32)
            .background(
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 28, style: .continuous)
                            .strokeBorder(Color.white.opacity(0.18), lineWidth: 1)
                    )
            )
            .padding(.horizontal, 36)
            .transition(.scale(scale: 0.85).combined(with: .opacity))
        }
        .accessibilityElement(children: .contain)
    }
}

/// Bounce-down press feedback for buttons.
struct PressButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.94 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6),
                       value: configuration.isPressed)
    }
}
