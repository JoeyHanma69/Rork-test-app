//
//  PaddleView.swift
//  TapDodge
//

import SwiftUI

/// A glowing rounded paddle the player steers.
struct PaddleView: View {
    let width: CGFloat
    let height: CGFloat

    var body: some View {
        RoundedRectangle(cornerRadius: height / 2, style: .continuous)
            .fill(
                LinearGradient(
                    colors: [Color(red: 1.0, green: 0.30, blue: 0.55),
                             Color(red: 1.0, green: 0.55, blue: 0.85)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .frame(width: width, height: height)
            .shadow(color: Color(red: 1.0, green: 0.35, blue: 0.7).opacity(0.9),
                    radius: 14, x: 0, y: 0)
            .overlay(
                RoundedRectangle(cornerRadius: height / 2, style: .continuous)
                    .strokeBorder(Color.white.opacity(0.45), lineWidth: 1.5)
            )
            .overlay(
                Capsule()
                    .fill(Color.white.opacity(0.5))
                    .frame(width: width * 0.5, height: height * 0.32)
                    .offset(y: -height * 0.22)
                    .blur(radius: 2)
            )
            .accessibilityHidden(true)
    }
}
