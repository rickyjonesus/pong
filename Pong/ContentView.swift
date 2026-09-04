import SwiftUI

struct ContentView: View {
    @StateObject private var engine = GameEngine()
    @StateObject private var safeArea = SafeAreaProvider()
    @State private var showNearbyDuel = false

    var body: some View {
        GeometryReader { geo in
            ZStack {
                Color.black.ignoresSafeArea()

                CourtView(engine: engine)
                    .onAppear {
                        engine.configureCourt(geo.size)
                        safeArea.begin()
                    }
                    .onChange(of: geo.size) { newSize in engine.configureCourt(newSize) }
                    .onReceive(safeArea.$insets) { insets in
                        engine.configureSafeArea(leading: insets.left, trailing: insets.right)
                    }

                switch engine.phase {
                case .menu:
                    MenuOverlay(engine: engine, showNearbyDuel: $showNearbyDuel)
                case .serving:
                    ServeOverlay(engine: engine)
                case .gameOver:
                    GameOverOverlay(engine: engine)
                default:
                    EmptyView()
                }
            }
        }
        .ignoresSafeArea()
        .background(Color.black)
        .fullScreenCover(isPresented: $showNearbyDuel) {
            DuelView()
        }
    }
}

// MARK: - Court (gameplay canvas)

private struct CourtView: View {
    @ObservedObject var engine: GameEngine

    var body: some View {
        TimelineView(.animation(paused: engine.phase != .playing)) { context in
            Canvas { ctx, size in
                drawNet(ctx: &ctx, size: size)
                drawPaddle(ctx: &ctx, x: engine.leftPaddleX, y: engine.leftPaddleY, engine: engine)
                drawPaddle(ctx: &ctx, x: engine.rightPaddleX, y: engine.rightPaddleY, engine: engine)
                drawBall(ctx: &ctx, engine: engine)
            }
            .onChange(of: context.date) { newDate in
                engine.tick(now: newDate)
            }
        }
        .overlay(alignment: .top) {
            ScoreBar(engine: engine)
                .padding(.top, 24)
        }
        .contentShape(Rectangle())
        .gesture(dragGesture)
    }

    private var dragGesture: some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                if engine.phase == .serving {
                    engine.serve()
                }
                let width = engine.courtSize.width
                guard width > 0 else { return }
                let isLeftSide = value.location.x < width / 2
                if isLeftSide {
                    if engine.twoPlayerMode {
                        engine.leftPaddleTarget = value.location.y
                    }
                } else {
                    engine.rightPaddleTarget = value.location.y
                }
            }
    }

    private func drawNet(ctx: inout GraphicsContext, size: CGSize) {
        var path = Path()
        let dashHeight: CGFloat = 12
        let gap: CGFloat = 10
        var y: CGFloat = 0
        while y < size.height {
            path.addRect(CGRect(x: size.width / 2 - 2, y: y, width: 4, height: dashHeight))
            y += dashHeight + gap
        }
        ctx.fill(path, with: .color(.white.opacity(0.4)))
    }

    private func drawPaddle(ctx: inout GraphicsContext, x: CGFloat, y: CGFloat, engine: GameEngine) {
        let rect = CGRect(x: x - engine.paddleWidth / 2, y: y - engine.paddleHeight / 2,
                           width: engine.paddleWidth, height: engine.paddleHeight)
        let path = Path(roundedRect: rect, cornerRadius: 3)
        ctx.fill(path, with: .color(.white))
    }

    private func drawBall(ctx: inout GraphicsContext, engine: GameEngine) {
        let rect = CGRect(x: engine.ballPos.x - engine.ballSize / 2, y: engine.ballPos.y - engine.ballSize / 2,
                           width: engine.ballSize, height: engine.ballSize)
        let path = Path(ellipseIn: rect)
        ctx.fill(path, with: .color(.white))
    }
}

private struct ScoreBar: View {
    @ObservedObject var engine: GameEngine

    var body: some View {
        HStack {
            Spacer()
            Text("\(engine.leftScore)")
                .frame(minWidth: 60)
            Spacer()
            Button {
                engine.backToMenu()
            } label: {
                Image(systemName: "pause.fill")
                    .foregroundStyle(.white.opacity(0.6))
                    .padding(10)
            }
            Spacer()
            Text("\(engine.rightScore)")
                .frame(minWidth: 60)
            Spacer()
        }
        .font(.system(size: 44, weight: .bold, design: .monospaced))
        .foregroundStyle(.white)
    }
}

// MARK: - Overlays

private struct MenuOverlay: View {
    @ObservedObject var engine: GameEngine
    @Binding var showNearbyDuel: Bool

    var body: some View {
        VStack(spacing: 28) {
            Text("PONG")
                .font(.system(size: 72, weight: .heavy, design: .monospaced))
                .foregroundStyle(.white)
                .kerning(8)

            VStack(spacing: 16) {
                Button {
                    engine.startGame(twoPlayer: false)
                } label: {
                    menuLabel("1 PLAYER  (VS CPU)")
                }
                Button {
                    engine.startGame(twoPlayer: true)
                } label: {
                    menuLabel("2 PLAYER  (PASS & PLAY)")
                }
                Button {
                    showNearbyDuel = true
                } label: {
                    menuLabel("PLAY NEARBY  (2 DEVICES)")
                }
            }

            Text("Drag on your half to move your paddle\nFirst to \(GameEngine.winningScore) wins\n\nPlay Nearby: hold two iPhones side by side\nand rally the ball across both screens")
                .multilineTextAlignment(.center)
                .font(.system(size: 15, weight: .medium, design: .monospaced))
                .foregroundStyle(.white.opacity(0.5))
        }
        .padding(40)
        .background(Color.black.opacity(0.001)) // capture taps but stay invisible
    }

    private func menuLabel(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 20, weight: .bold, design: .monospaced))
            .foregroundStyle(.black)
            .padding(.vertical, 14)
            .frame(width: 340)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

private struct ServeOverlay: View {
    @ObservedObject var engine: GameEngine

    var body: some View {
        VStack(spacing: 14) {
            Text("TAP TO SERVE")
                .font(.system(size: 26, weight: .bold, design: .monospaced))
                .foregroundStyle(.white)
            Text(engine.twoPlayerMode ? "Player 1 (left) vs Player 2 (right)" : "You are the right paddle")
                .font(.system(size: 14, weight: .medium, design: .monospaced))
                .foregroundStyle(.white.opacity(0.6))
        }
        .padding(20)
        .background(.black.opacity(0.55))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .allowsHitTesting(false)
    }
}

private struct GameOverOverlay: View {
    @ObservedObject var engine: GameEngine

    var body: some View {
        VStack(spacing: 24) {
            Text("\(engine.winner ?? "") WINS")
                .font(.system(size: 40, weight: .heavy, design: .monospaced))
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)

            Text("\(engine.leftScore) — \(engine.rightScore)")
                .font(.system(size: 24, weight: .bold, design: .monospaced))
                .foregroundStyle(.white.opacity(0.7))

            HStack(spacing: 16) {
                Button {
                    engine.startGame(twoPlayer: engine.twoPlayerMode)
                } label: {
                    Text("REMATCH")
                        .font(.system(size: 17, weight: .bold, design: .monospaced))
                        .foregroundStyle(.black)
                        .padding(.vertical, 12)
                        .frame(width: 160)
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                Button {
                    engine.backToMenu()
                } label: {
                    Text("MENU")
                        .font(.system(size: 17, weight: .bold, design: .monospaced))
                        .foregroundStyle(.white)
                        .padding(.vertical, 12)
                        .frame(width: 160)
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.white, lineWidth: 2))
                }
            }
        }
        .padding(40)
    }
}

#Preview {
    ContentView()
}
