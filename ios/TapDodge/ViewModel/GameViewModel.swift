//
//  GameViewModel.swift
//  TapDodge
//

import Foundation
import SwiftUI
import QuartzCore

/// Drives the Tap Dodge game loop on a display-link-synced timer.
@MainActor
@Observable
final class GameViewModel {

    // MARK: - Tunables

    /// Paddle travel speed in points per second.
    private let paddleSpeed: CGFloat = 620
    /// Ball fall speed in points per second (ramps up over time).
    private let baseBallSpeed: CGFloat = 380
    private let ballSpeedRampPerSecond: CGFloat = 14
    private let maxBallSpeed: CGFloat = 820
    /// Spawn interval range (seconds) — shortens as score grows.
    private let minSpawnInterval: CGFloat = 0.45
    private let maxSpawnInterval: CGFloat = 1.1
    /// Paddle dimensions relative to playfield.
    private let paddleWidthRatio: CGFloat = 0.26
    private let paddleHeight: CGFloat = 18
    /// Ball radius range.
    private let ballRadiusRange: ClosedRange<CGFloat> = 14...22

    // MARK: - State

    private(set) var balls: [FallingBall] = []
    private(set) var score: Int = 0
    private(set) var bestScore: Int = 0
    private(set) var isGameOver: Bool = false
    private(set) var isPlaying: Bool = false
    private(set) var paddleX: CGFloat = 0
    private(set) var playfieldSize: CGSize = .zero
    private(set) var recentDodgeAt: CFTimeInterval = 0

    /// Direction the paddle is currently moving (-1, 0, +1).
    private(set) var paddleDirection: CGFloat = 0

    private var displayLink: CADisplayLink?
    private var lastTimestamp: CFTimeInterval = 0
    private var spawnTimer: CFTimeInterval = 0
    private var nextSpawnInterval: CFTimeInterval = 1.0
    private var elapsed: CFTimeInterval = 0

    private let defaults = UserDefaults.standard
    private let bestScoreKey = "tapDodge.bestScore"

    // MARK: - Lifecycle

    init() {
        bestScore = defaults.integer(forKey: bestScoreKey)
    }

    func setPlayfieldSize(_ size: CGSize) {
        let isInitial = playfieldSize == .zero
        playfieldSize = size
        if isInitial || paddleX == 0 {
            paddleX = size.width / 2
        } else {
            // Keep paddle within bounds on resize.
            paddleX = min(max(paddleX, paddleHalfWidth), size.width - paddleHalfWidth)
        }
    }

    var paddleWidth: CGFloat { playfieldSize.width * paddleWidthRatio }
    private var paddleHalfWidth: CGFloat { paddleWidth / 2 }
    var paddleY: CGFloat { playfieldSize.height - 70 }

    // MARK: - Start / Restart

    func start() {
        balls.removeAll()
        score = 0
        isGameOver = false
        isPlaying = true
        elapsed = 0
        spawnTimer = 0
        nextSpawnInterval = CGFloat.random(in: 0.6...1.0)
        paddleX = playfieldSize.width / 2
        lastTimestamp = CACurrentMediaTime()
        startDisplayLink()
    }

    func restart() {
        stopDisplayLink()
        start()
    }

    func endGame() {
        isGameOver = true
        isPlaying = false
        stopDisplayLink()
        if score > bestScore {
            bestScore = score
            defaults.set(bestScore, forKey: bestScoreKey)
        }
    }

    // MARK: - Input

    /// Set the paddle direction. Pass -1 for left, +1 for right, 0 to stop.
    func steer(_ direction: CGFloat) {
        paddleDirection = direction
    }

    /// Instantly move the paddle toward a target x (used by swipe/drag).
    func movePaddle(toX x: CGFloat) {
        guard playfieldSize.width > 0 else { return }
        paddleX = min(max(x, paddleHalfWidth), playfieldSize.width - paddleHalfWidth)
    }

    // MARK: - Game loop

    private func startDisplayLink() {
        stopDisplayLink()
        let link = CADisplayLink(target: LoopProxy(target: self), selector: #selector(LoopProxy.tick(_:)))
        link.preferredFrameRateRange = CAFrameRateRange(minimum: 60, maximum: 120, preferred: 120)
        link.add(to: .main, forMode: .common)
        displayLink = link
    }

    private func stopDisplayLink() {
        displayLink?.invalidate()
        displayLink = nil
    }

    fileprivate func tick(link: CADisplayLink) {
        let now = link.timestamp
        let dt = min(now - lastTimestamp, 1.0 / 30.0) // clamp to avoid huge jumps
        lastTimestamp = now
        guard isPlaying, dt > 0 else { return }
        update(dt: dt)
    }

    private func update(dt: CGFloat) {
        elapsed += dt

        // Move paddle (held buttons).
        if paddleDirection != 0 {
            let dx = paddleDirection * paddleSpeed * dt
            paddleX = min(max(paddleX + dx, paddleHalfWidth), playfieldSize.width - paddleHalfWidth)
        }

        // Spawn new balls.
        spawnTimer += dt
        if spawnTimer >= nextSpawnInterval {
            spawnTimer = 0
            spawnBall()
            let progress = min(CGFloat(score) / 40.0, 1.0)
            let interval = maxSpawnInterval - (maxSpawnInterval - minSpawnInterval) * progress
            nextSpawnInterval = CGFloat.random(in: (interval * 0.8)...(interval * 1.2))
        }

        // Advance balls.
        let speed = min(baseBallSpeed + ballSpeedRampPerSecond * CGFloat(elapsed), maxBallSpeed)
        let paddleTop = paddleY - paddleHeight / 2
        let paddleLeft = paddleX - paddleHalfWidth
        let paddleRight = paddleX + paddleHalfWidth

        var newBalls: [FallingBall] = []
        newBalls.reserveCapacity(balls.count)
        for var ball in balls {
            ball.y += speed * dt
            // Check collision when the ball reaches the paddle band.
            if !ball.dodged, ball.y + ball.radius >= paddleTop, ball.y - ball.radius <= paddleY + paddleHeight / 2 {
                let ballLeft = ball.x - ball.radius
                let ballRight = ball.x + ball.radius
                if ballRight >= paddleLeft && ballLeft <= paddleRight {
                    endGame()
                    return
                }
            }
            // Ball passed the paddle entirely → score + remove.
            if ball.y - ball.radius > paddleY + paddleHeight / 2 + 4, !ball.dodged {
                ball.dodged = true
                score += 1
                recentDodgeAt = CACurrentMediaTime()
            }
            // Drop balls that are off-screen.
            if ball.y - ball.radius < playfieldSize.height + 40 {
                newBalls.append(ball)
            }
        }
        balls = newBalls
    }

    private func spawnBall() {
        guard playfieldSize.width > 0 else { return }
        let radius = CGFloat.random(in: ballRadiusRange)
        let margin = radius + 6
        let x = CGFloat.random(in: margin...(playfieldSize.width - margin))
        let hue = Double.random(in: 0...1)
        balls.append(FallingBall(x: x, y: -radius - 4, radius: radius, hue: hue))
    }
}

/// Proxy to hold a weak ref so CADisplayLink doesn't retain the view model.
private final class LoopProxy {
    weak var target: GameViewModel?
    init(target: GameViewModel) { self.target = target }
    @objc func tick(_ link: CADisplayLink) {
        target?.tick(link: link)
    }
}
