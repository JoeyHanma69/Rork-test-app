//
//  BallView.swift
//  TapDodge
//

import SwiftUI

/// A glowing, colorful falling ball with a soft trail aura.
struct BallView: View {
    let ball: FallingBall

    var body: some View {
        Circle()
            .fill(
                RadialGradient(
                    colors: [
                        Color(hue: ball.hue, saturation: 0.85, brightness: 1),
                        Color(hue: ball.hue, saturation: 0.9, brightness: 0.75)
                    ],
                    center: .center,
                    startRadius: 0,
                    endRadius: ball.radius
                )
            )
            .frame(width: ball.radius * 2, height: ball.radius * 2)
            .shadow(color: Color(hue: ball.hue, saturation: 0.9, brightness: 1).opacity(0.9),
                    radius: ball.radius * 0.9, x: 0, y: 0)
            .overlay(
                Circle()
                    .fill(Color.white.opacity(0.85))
                    .frame(width: ball.radius * 0.55, height: ball.radius * 0.55)
                    .offset(x: -ball.radius * 0.3, y: -ball.radius * 0.3)
                    .blur(radius: 1)
            )
            .accessibilityHidden(true)
    }
}
