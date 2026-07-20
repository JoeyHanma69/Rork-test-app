//
//  StartView.swift
//  TapDodge
//

import SwiftUI

/// Title screen shown before the first game and after Game Over dismissal.
struct StartView: View {
    let bestScore: Int
    let onStart: () -> Void

    var body: some View {
        VStack(spacing: 28) {
            Spacer()

            VStack(spacing: 10) {
                Image(systemName: "circle.fill")
                    .font(.system(size: 70))
                    .foregroundStyle(
                        LinearGradient(colors: [.cyan, .pink],
                                       startPoint: .top, endPoint: .bottom)
                    )
                    .shadow(color: .pink.opacity(0.7), radius: 18)
                    .offset(y: -6)

                Text("Tap Dodge")
                    .font(.system(size: 46, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)
                    .shadow(color: .pink.opacity(0.5), radius: 10)

                Text("Dodge the falling balls.")
                    .font(.body.weight(.medium))
                    .foregroundStyle(.white.opacity(0.75))
            }

            VStack(spacing: 8) {
                Label("Tap ◀ / ▶ to steer the paddle",
                      systemImage: "arrow.left.and.right")
                Label("Or swipe left & right anywhere",
                      systemImage: "hand.draw")
            }
            .font(.footnote.weight(.medium))
            .foregroundStyle(.white.opacity(0.6))
            .multilineTextAlignment(.center)

            Spacer()

            VStack(spacing: 16) {
                if bestScore > 0 {
                    Text("Best: \(bestScore)")
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(.white.opacity(0.7))
                }

                Button(action: onStart) {
                    HStack(spacing: 10) {
                        Image(systemName: "play.fill")
                        Text("Play")
                            .font(.title3.weight(.bold))
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 56)
                    .padding(.vertical, 16)
                    .background(
                        Capsule().fill(
                            LinearGradient(colors: [.pink, .purple],
                                           startPoint: .leading,
                                           endPoint: .trailing)
                        )
                    )
                    .shadow(color: .pink.opacity(0.6), radius: 18, y: 8)
                }
                .buttonStyle(PressButtonStyle())
            }
            .padding(.bottom, 48)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityElement(children: .contain)
    }
}
