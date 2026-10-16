import SwiftUI

struct ContentView: View {
    @State private var greetingIndex = 0
    @State private var celebrations = 0
    @State private var tilt: CGSize = .zero
    @State private var hasAppeared = false
    @State private var particles = Particle.makeField(count: 90)

    private let greetings: [(text: String, language: String)] = [
        ("Hello", "English"),
        ("你好", "中文"),
        ("こんにちは", "日本語"),
        ("Bonjour", "Français"),
        ("Hola", "Español"),
        ("안녕하세요", "한국어"),
        ("Ciao", "Italiano"),
        ("Hallo", "Deutsch"),
        ("Olá", "Português"),
        ("Привет", "Русский"),
        ("مرحبا", "العربية"),
        ("สวัสดี", "ไทย")
    ]

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                AuroraBackground()
                SparkleField(particles: particles)
                card
                    // Tilt the card toward the pointer for a subtle 3D parallax.
                    .rotation3DEffect(.degrees(tilt.height), axis: (x: 1, y: 0, z: 0))
                    .rotation3DEffect(.degrees(tilt.width), axis: (x: 0, y: 1, z: 0))
                    .scaleEffect(hasAppeared ? 1 : 0.85)
                    .opacity(hasAppeared ? 1 : 0)
                    .blur(radius: hasAppeared ? 0 : 20)
            }
            .onContinuousHover { phase in
                withAnimation(.spring(duration: 0.6, bounce: 0.3)) {
                    switch phase {
                    case .active(let location):
                        let dx = (location.x - proxy.size.width / 2) / (proxy.size.width / 2)
                        let dy = (location.y - proxy.size.height / 2) / (proxy.size.height / 2)
                        tilt = CGSize(width: dx * 10, height: -dy * 10)
                    case .ended:
                        tilt = .zero
                    }
                }
            }
        }
        .ignoresSafeArea()
        .frame(minWidth: 720, minHeight: 480)
        .onAppear {
            withAnimation(.spring(duration: 1.2, bounce: 0.4)) {
                hasAppeared = true
            }
        }
        .task { await cycleGreetings() }
    }

    private var card: some View {
        VStack(spacing: 18) {
            Image(systemName: "hand.wave.fill")
                .font(.system(size: 56))
                .symbolRenderingMode(.multicolor)
                .symbolEffect(.wiggle, value: celebrations)
                .background {
                    RippleRing(trigger: celebrations)
                        .frame(width: 90, height: 90)
                }

            Text("Hello, World!")
                .font(.system(size: 64, weight: .black, design: .rounded))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.white, .cyan, .pink],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .shadow(color: .pink.opacity(0.5), radius: 18)

            // Rotating greeting in many languages, cross-fading with a blur.
            VStack(spacing: 4) {
                Text(greetings[greetingIndex].text)
                    .font(.system(size: 30, weight: .semibold, design: .rounded))
                    .id(greetingIndex)
                    .transition(.blurReplace)
                Text(greetings[greetingIndex].language)
                    .font(.callout.smallCaps())
                    .foregroundStyle(.secondary)
                    .id("lang-\(greetingIndex)")
                    .transition(.opacity)
            }
            .frame(height: 70)

            Button {
                celebrations += 1
                withAnimation(.smooth) {
                    greetingIndex = (greetingIndex + 1) % greetings.count
                }
            } label: {
                Label("Say Hello", systemImage: "sparkles")
                    .font(.headline)
                    .padding(.horizontal, 8)
            }
            .buttonStyle(.glassProminent)
            .controlSize(.extraLarge)
            .tint(.pink)
            .keyboardShortcut(.defaultAction)
            .sensoryFeedback(.levelChange, trigger: celebrations)
        }
        .padding(.horizontal, 56)
        .padding(.vertical, 40)
        .glassEffect(.regular, in: .rect(cornerRadius: 40))
    }

    /// Advances to the next greeting every few seconds while the view is on screen.
    private func cycleGreetings() async {
        while !Task.isCancelled {
            try? await Task.sleep(for: .seconds(2.5))
            withAnimation(.smooth(duration: 0.8)) {
                greetingIndex = (greetingIndex + 1) % greetings.count
            }
        }
    }
}

// MARK: - Animated aurora background

struct AuroraBackground: View {
    var body: some View {
        TimelineView(.animation) { context in
            let t = context.date.timeIntervalSinceReferenceDate
            MeshGradient(
                width: 3,
                height: 3,
                points: points(at: t),
                colors: [
                    .indigo, .purple, .pink,
                    .blue, .purple, .orange,
                    .mint, .indigo, .purple
                ]
            )
            .hueRotation(.degrees(sin(t * 0.2) * 25))
        }
    }

    /// Gently wobbles the interior mesh points so the gradient flows like an aurora.
    private func points(at t: Double) -> [SIMD2<Float>] {
        func wobble(_ base: Float, _ speed: Double, _ amplitude: Float) -> Float {
            base + amplitude * Float(sin(t * speed))
        }
        let points: [SIMD2<Float>] = [
            SIMD2(0, 0), SIMD2(wobble(0.5, 0.7, 0.2), 0), SIMD2(1, 0),
            SIMD2(0, wobble(0.5, 0.9, 0.2)), SIMD2(wobble(0.5, 0.6, 0.25), wobble(0.5, 0.8, 0.25)), SIMD2(1, wobble(0.5, 1.1, 0.2)),
            SIMD2(0, 1), SIMD2(wobble(0.5, 0.5, 0.2), 1), SIMD2(1, 1)
        ]
        return points
    }
}

// MARK: - Floating sparkles

struct Particle {
    var x: Double
    var y: Double
    var size: Double
    var speed: Double
    var phase: Double

    static func makeField(count: Int) -> [Particle] {
        (0..<count).map { _ in
            Particle(
                x: .random(in: 0...1),
                y: .random(in: 0...1),
                size: .random(in: 1.5...4.5),
                speed: .random(in: 0.01...0.05),
                phase: .random(in: 0...(2 * .pi))
            )
        }
    }
}

struct SparkleField: View {
    let particles: [Particle]

    var body: some View {
        TimelineView(.animation) { context in
            let t = context.date.timeIntervalSinceReferenceDate
            Canvas { ctx, size in
                ctx.blendMode = .plusLighter
                ctx.addFilter(.shadow(color: .white, radius: 4))
                for p in particles {
                    // Drift upward and wrap around; sway sideways and twinkle.
                    var y = (p.y - t * p.speed).truncatingRemainder(dividingBy: 1)
                    if y < 0 { y += 1 }
                    let x = p.x + 0.015 * sin(t * 0.8 + p.phase)
                    ctx.opacity = 0.35 + 0.65 * (0.5 + 0.5 * sin(t * 3 + p.phase))
                    let rect = CGRect(
                        x: x * size.width - p.size / 2,
                        y: y * size.height - p.size / 2,
                        width: p.size,
                        height: p.size
                    )
                    ctx.fill(Path(ellipseIn: rect), with: .color(.white))
                }
            }
        }
        .allowsHitTesting(false)
    }
}

// MARK: - Ripple burst

struct RippleRing: View {
    let trigger: Int

    private struct RippleState {
        var scale = 0.6
        var opacity = 0.0
    }

    var body: some View {
        Circle()
            .stroke(.white, lineWidth: 3)
            .keyframeAnimator(initialValue: RippleState(), trigger: trigger) { content, value in
                content
                    .scaleEffect(value.scale)
                    .opacity(value.opacity)
            } keyframes: { _ in
                KeyframeTrack(\.scale) {
                    LinearKeyframe(0.6, duration: 0)
                    CubicKeyframe(3.0, duration: 0.9)
                }
                KeyframeTrack(\.opacity) {
                    LinearKeyframe(1, duration: 0)
                    LinearKeyframe(0, duration: 0.9)
                }
            }
    }
}

#Preview {
    ContentView()
        .frame(width: 900, height: 600)
}
