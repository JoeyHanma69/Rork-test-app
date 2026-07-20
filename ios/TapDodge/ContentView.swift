//
//  ContentView.swift
//  TapDodge
//

import SwiftUI
import UIKit

/// Main game container: background, playfield, HUD, and overlay states.
struct ContentView: View {
    @State private var viewModel = GameViewModel()
    @State private var leftHeld = false
    @State private var rightHeld = false
    @State private var showStart = true
    @State private var scorePulse = false

    private let haptic = UIImpactFeedbackGenerator(style: .light)

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                backgroundGradient(proxy.size)

                PlayfieldView(viewModel: viewModel,
                              leftHeld: $leftHeld,
                              rightHeld: $rightHeld,
                              onPulse: { triggerScorePulse() })
                    .onAppear { viewModel.setPlayfieldSize(proxy.size) }
                    .onChange(of: proxy.size) { _, newValue in
                        viewModel.setPlayfieldSize(newValue)
                    }

                HUDView(score: viewModel.score,
                        bestScore: viewModel.bestScore,
                        pulse: scorePulse)
                    .padding(.top, 54)
                    .allowsHitTesting(false)

                if showStart {
                    StartView(bestScore: viewModel.bestScore) {
                        showStart = false
                        viewModel.start()
                    }
                    .transition(.opacity)
                }

                if viewModel.isGameOver {
                    GameOverView(score: viewModel.score,
                                 bestScore: viewModel.bestScore,
                                 isNewBest: viewModel.score > 0 && viewModel.score >= viewModel.bestScore,
                                 onRestart: {
                        viewModel.restart()
                    })
                    .transition(.scale(scale: 0.9).combined(with: .opacity))
                    .zIndex(10)
                }
            }
        }
        .preferredColorScheme(.dark)
        .animation(.spring(response: 0.45, dampingFraction: 0.8), value: viewModel.isGameOver)
        .animation(.easeInOut(duration: 0.25), value: showStart)
        .onAppear { haptic.prepare() }
    }

    private func triggerScorePulse() {
        haptic.impactOccurred()
        withAnimation(.spring(response: 0.28, dampingFraction: 0.55)) {
            scorePulse = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                scorePulse = false
            }
        }
    }

    private func backgroundGradient(_ size: CGSize) -> some View {
        ZStack {
            LinearGradient(
                colors: [Color(red: 0.05, green: 0.06, blue: 0.16),
                         Color(red: 0.15, green: 0.06, blue: 0.28),
                         Color(red: 0.25, green: 0.08, blue: 0.40)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            // Floating ambient orbs for atmosphere.
            Circle()
                .fill(Color.cyan.opacity(0.22))
                .frame(width: size.width * 0.7)
                .blur(radius: 60)
                .offset(x: -size.width * 0.25, y: -size.height * 0.2)
            Circle()
                .fill(Color.pink.opacity(0.22))
                .frame(width: size.width * 0.65)
                .blur(radius: 60)
                .offset(x: size.width * 0.3, y: size.height * 0.25)
        }
    }
}

// MARK: - Playfield

private struct PlayfieldView: View {
    let viewModel: GameViewModel
    @Binding var leftHeld: Bool
    @Binding var rightHeld: Bool
    let onPulse: () -> Void

    var body: some View {
        GeometryReader { proxy in
            let width = proxy.size.width
            let height = proxy.size.height

            ZStack {
                // Trail line behind paddle.
                Capsule()
                    .fill(Color.white.opacity(0.06))
                    .frame(width: width, height: 2)
                    .position(x: width / 2, y: viewModel.paddleY)

                // Falling balls.
                ForEach(viewModel.balls) { ball in
                    BallView(ball: ball)
                        .position(x: ball.x, y: ball.y)
                }

                // Paddle.
                PaddleView(width: viewModel.paddleWidth, height: 18)
                    .position(x: viewModel.paddleX, y: viewModel.paddleY)
                    .animation(.interactiveSpring(response: 0.18, dampingFraction: 0.9),
                               value: viewModel.paddleX)
            }
            .frame(width: width, height: height)
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        // Drag anywhere to move paddle.
                        viewModel.movePaddle(toX: value.location.x)
                    }
            )
            .overlay(alignment: .bottom) {
                if !viewModel.isGameOver {
                    ControlBar(leftHeld: $leftHeld, rightHeld: $rightHeld,
                               onLeft: { viewModel.steer(-1) },
                               onRight: { viewModel.steer(1) },
                               onRelease: { viewModel.steer(0) })
                        .padding(.bottom, 16)
                }
            }
            .onChange(of: viewModel.score) { _, _ in onPulse() }
        }
    }
}

// MARK: - HUD

private struct HUDView: View {
    let score: Int
    let bestScore: Int
    let pulse: Bool

    var body: some View {
        VStack(spacing: 4) {
            Text("SCORE")
                .font(.caption.weight(.bold))
                .tracking(3)
                .foregroundStyle(.white.opacity(0.6))
            Text("\(score)")
                .font(.system(size: pulse ? 56 : 48, weight: .heavy, design: .rounded))
                .foregroundStyle(
                    LinearGradient(colors: [.cyan, .pink],
                                   startPoint: .topLeading,
                                   endPoint: .bottomTrailing)
                )
                .shadow(color: .pink.opacity(0.5), radius: pulse ? 14 : 6)
                .animation(.spring(response: 0.28, dampingFraction: 0.55), value: pulse)
            if bestScore > 0 {
                Text("Best \(bestScore)")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.45))
            }
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Controls

private struct ControlBar: View {
    @Binding var leftHeld: Bool
    @Binding var rightHeld: Bool
    let onLeft: () -> Void
    let onRight: () -> Void
    let onRelease: () -> Void

    var body: some View {
        HStack(spacing: 20) {
            ControlButton(systemName: "arrow.left",
                          isPressed: leftHeld,
                          onPress: { leftHeld = true; onLeft() },
                          onRelease: { leftHeld = false; onRelease() })
            ControlButton(systemName: "arrow.right",
                          isPressed: rightHeld,
                          onPress: { rightHeld = true; onRight() },
                          onRelease: { rightHeld = false; onRelease() })
        }
        .padding(.horizontal, 24)
    }
}

private struct ControlButton: View {
    let systemName: String
    let isPressed: Bool
    let onPress: () -> Void
    let onRelease: () -> Void

    var body: some View {
        Image(systemName: systemName)
            .font(.title.weight(.bold))
            .foregroundStyle(.white)
            .frame(width: 76, height: 76)
            .background(
                Circle()
                    .fill(.ultraThinMaterial)
                    .overlay(Circle().strokeBorder(Color.white.opacity(0.2), lineWidth: 1.5))
            )
            .scaleEffect(isPressed ? 0.9 : 1.0)
            .shadow(color: .pink.opacity(isPressed ? 0.5 : 0.2),
                    radius: isPressed ? 14 : 8)
            .animation(.spring(response: 0.25, dampingFraction: 0.6), value: isPressed)
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in if !isPressed { onPress() } }
                    .onEnded { _ in onRelease() }
            )
            .accessibilityLabel(systemName == "arrow.left" ? "Move left" : "Move right")
    }
}

#Preview {
    ContentView()
}