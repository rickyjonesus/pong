import SwiftUI
import AudioToolbox
import Combine

enum GamePhase {
    case menu
    case serving
    case playing
    case pointScored
    case gameOver
}

final class GameEngine: ObservableObject {

    // MARK: - Tunables
    static let winningScore = 11
    let paddleWidth: CGFloat = 14
    let paddleHeight: CGFloat = 90
    let ballSize: CGFloat = 16
    let paddleSpeed: CGFloat = 620   // AI max speed, points/sec
    let baseBallSpeed: CGFloat = 380
    let maxBallSpeed: CGFloat = 900

    // MARK: - Published state
    @Published var phase: GamePhase = .menu
    @Published var twoPlayerMode: Bool = false

    @Published var courtSize: CGSize = .zero
    @Published var safeAreaLeading: CGFloat = 0
    @Published var safeAreaTrailing: CGFloat = 0

    /// Paddle margin from the screen edge, pushed inward past the notch / Dynamic Island cutout when present.
    private let paddleMargin: CGFloat = 28
    var leftPaddleX: CGFloat { paddleMargin + safeAreaLeading }
    var rightPaddleX: CGFloat { courtSize.width - paddleMargin - safeAreaTrailing }

    @Published var leftPaddleY: CGFloat = 0
    @Published var rightPaddleY: CGFloat = 0
    @Published var ballPos: CGPoint = .zero

    @Published var leftScore: Int = 0
    @Published var rightScore: Int = 0
    @Published var winner: String? = nil

    // internal physics
    private var ballVelocity: CGVector = .zero
    private var servingToRight: Bool = true
    private var lastTick: Date? = nil

    // targets set by touch input; nil = no active touch (AI or idle)
    var leftPaddleTarget: CGFloat? = nil
    var rightPaddleTarget: CGFloat? = nil

    private var soundEnabled = true

    // MARK: - Lifecycle

    func configureCourt(_ size: CGSize) {
        guard size.width > 0, size.height > 0 else { return }
        let firstTime = courtSize == .zero
        courtSize = size
        if firstTime {
            leftPaddleY = size.height / 2
            rightPaddleY = size.height / 2
            ballPos = CGPoint(x: size.width / 2, y: size.height / 2)
        }
    }

    func configureSafeArea(leading: CGFloat, trailing: CGFloat) {
        safeAreaLeading = leading
        safeAreaTrailing = trailing
    }

    func startGame(twoPlayer: Bool) {
        twoPlayerMode = twoPlayer
        leftScore = 0
        rightScore = 0
        winner = nil
        resetPositions()
        servingToRight = Bool.random()
        phase = .serving
    }

    func backToMenu() {
        phase = .menu
    }

    private func resetPositions() {
        leftPaddleY = courtSize.height / 2
        rightPaddleY = courtSize.height / 2
        ballPos = CGPoint(x: courtSize.width / 2, y: courtSize.height / 2)
        ballVelocity = .zero
    }

    func serve() {
        guard phase == .serving else { return }
        let angle = CGFloat.random(in: -0.35...0.35)
        let dir: CGFloat = servingToRight ? 1 : -1
        ballVelocity = CGVector(dx: cos(angle) * baseBallSpeed * dir,
                                 dy: sin(angle) * baseBallSpeed)
        phase = .playing
        playSound(1103) // pop
    }

    // MARK: - Game loop

    func tick(now: Date) {
        defer { lastTick = now }
        guard courtSize != .zero else { return }
        guard phase == .playing else {
            lastTick = now
            return
        }
        let dt = min(lastTick.map { now.timeIntervalSince($0) } ?? 1.0/60.0, 1.0/30.0)

        updatePaddles(dt: dt)
        updateBall(dt: dt)
    }

    private func updatePaddles(dt: TimeInterval) {
        let half = paddleHeight / 2
        let minY = half
        let maxY = courtSize.height - half

        // Right paddle: player-controlled always
        if let target = rightPaddleTarget {
            rightPaddleY = clampMove(current: rightPaddleY, target: target, dt: dt, minY: minY, maxY: maxY)
        }

        // Left paddle: AI unless two-player mode
        if twoPlayerMode {
            if let target = leftPaddleTarget {
                leftPaddleY = clampMove(current: leftPaddleY, target: target, dt: dt, minY: minY, maxY: maxY)
            }
        } else {
            let aiTarget = ballVelocity.dx < 0 ? ballPos.y : courtSize.height / 2
            leftPaddleY = clampMove(current: leftPaddleY, target: aiTarget, dt: dt, minY: minY, maxY: maxY, speedScale: 0.86)
        }
    }

    private func clampMove(current: CGFloat, target: CGFloat, dt: TimeInterval, minY: CGFloat, maxY: CGFloat, speedScale: CGFloat = 1.0) -> CGFloat {
        let maxDelta = paddleSpeed * speedScale * CGFloat(dt)
        let delta = (target - current)
        let clampedDelta = max(-maxDelta, min(maxDelta, delta))
        return min(maxY, max(minY, current + clampedDelta))
    }

    private func updateBall(dt: TimeInterval) {
        var pos = ballPos
        var vel = ballVelocity

        pos.x += vel.dx * CGFloat(dt)
        pos.y += vel.dy * CGFloat(dt)

        let half = ballSize / 2

        // Top / bottom walls
        if pos.y - half < 0 {
            pos.y = half
            vel.dy = abs(vel.dy)
            playSound(1104)
        } else if pos.y + half > courtSize.height {
            pos.y = courtSize.height - half
            vel.dy = -abs(vel.dy)
            playSound(1104)
        }

        // Left paddle collision
        if vel.dx < 0,
           pos.x - half <= leftPaddleX + paddleWidth / 2,
           pos.x - half >= leftPaddleX - paddleWidth / 2,
           pos.y >= leftPaddleY - paddleHeight / 2 - half,
           pos.y <= leftPaddleY + paddleHeight / 2 + half {
            pos.x = leftPaddleX + paddleWidth / 2 + half
            vel = bounced(vel: vel, paddleY: leftPaddleY, ballY: pos.y, movingRight: true)
            playSound(1103)
        }

        // Right paddle collision
        if vel.dx > 0,
           pos.x + half >= rightPaddleX - paddleWidth / 2,
           pos.x + half <= rightPaddleX + paddleWidth / 2,
           pos.y >= rightPaddleY - paddleHeight / 2 - half,
           pos.y <= rightPaddleY + paddleHeight / 2 + half {
            pos.x = rightPaddleX - paddleWidth / 2 - half
            vel = bounced(vel: vel, paddleY: rightPaddleY, ballY: pos.y, movingRight: false)
            playSound(1103)
        }

        ballPos = pos
        ballVelocity = vel

        // Scoring
        if pos.x < -ballSize {
            rightScore += 1
            handlePointScored(servingToRightNext: false)
        } else if pos.x > courtSize.width + ballSize {
            leftScore += 1
            handlePointScored(servingToRightNext: true)
        }
    }

    private func bounced(vel: CGVector, paddleY: CGFloat, ballY: CGFloat, movingRight: Bool) -> CGVector {
        let relative = (ballY - paddleY) / (paddleHeight / 2) // -1...1
        let clampedRel = max(-1, min(1, relative))
        let bounceAngle = clampedRel * (.pi / 3) // up to 60 degrees
        let currentSpeed = sqrt(vel.dx * vel.dx + vel.dy * vel.dy)
        let newSpeed = min(maxBallSpeed, currentSpeed * 1.06)
        let dir: CGFloat = movingRight ? 1 : -1
        return CGVector(dx: cos(bounceAngle) * newSpeed * dir, dy: sin(bounceAngle) * newSpeed)
    }

    private func handlePointScored(servingToRightNext: Bool) {
        playSound(1025) // score sound
        servingToRight = servingToRightNext
        if leftScore >= Self.winningScore || rightScore >= Self.winningScore {
            winner = leftScore > rightScore ? "PLAYER 1" : (twoPlayerMode ? "PLAYER 2" : "COMPUTER")
            phase = .gameOver
            resetPositions()
        } else {
            resetPositions()
            phase = .serving
        }
    }

    private func playSound(_ id: SystemSoundID) {
        guard soundEnabled else { return }
        AudioServicesPlaySystemSound(id)
    }
}
