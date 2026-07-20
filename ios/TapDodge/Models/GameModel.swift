//
//  GameModel.swift
//  TapDodge
//

import Foundation
import CoreGraphics

/// A single falling ball in the game.
struct FallingBall: Identifiable, Equatable {
    let id: UUID
    var x: CGFloat          // center x in points, relative to playfield width
    var y: CGFloat          // center y in points, top = 0
    var radius: CGFloat
    var hue: Double         // 0...1 for colorful balls
    var dodged: Bool

    init(id: UUID = UUID(), x: CGFloat, y: CGFloat, radius: CGFloat, hue: Double) {
        self.id = id
        self.x = x
        self.y = y
        self.radius = radius
        self.hue = hue
        self.dodged = false
    }
}

/// One frame of the game state used for rendering.
struct GameSnapshot: Equatable {
    var balls: [FallingBall]
    var paddleX: CGFloat
    var paddleWidth: CGFloat
    var paddleY: CGFloat
    var score: Int
    var isGameOver: Bool
}