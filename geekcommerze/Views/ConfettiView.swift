import SwiftUI

struct ConfettiParticle: Identifiable {
    let id = UUID()
    let color: Color
    let xFraction: CGFloat
    let delay: Double
    let duration: Double
    let width: CGFloat
    let height: CGFloat
    let endRotation: Double
    let xDrift: CGFloat
}

struct ConfettiView: View {
    private let colors: [Color] = [.red, .blue, .green, .yellow, .orange, .purple, .pink, .cyan, .mint, .teal]
    @State private var particles: [ConfettiParticle] = []

    var body: some View {
        GeometryReader { geo in
            ZStack {
                ForEach(particles) { p in
                    ConfettiPiece(particle: p, totalHeight: geo.size.height, totalWidth: geo.size.width)
                }
            }
        }
        .onAppear {
            particles = (0..<70).map { i in
                ConfettiParticle(
                    color: colors[i % colors.count],
                    xFraction: CGFloat.random(in: 0.05...0.95),
                    delay: Double(i) * 0.028,
                    duration: Double.random(in: 2.0...3.5),
                    width: CGFloat.random(in: 5...13),
                    height: CGFloat.random(in: 8...18),
                    endRotation: Double.random(in: -540...540),
                    xDrift: CGFloat.random(in: -50...50)
                )
            }
        }
        .allowsHitTesting(false)
    }
}

struct ConfettiPiece: View {
    let particle: ConfettiParticle
    let totalHeight: CGFloat
    let totalWidth: CGFloat

    @State private var yOffset: CGFloat = -30
    @State private var opacity: Double = 1
    @State private var rotation: Double = 0
    @State private var xOffset: CGFloat = 0

    var body: some View {
        Rectangle()
            .fill(particle.color)
            .frame(width: particle.width, height: particle.height)
            .rotationEffect(.degrees(rotation))
            .opacity(opacity)
            .offset(x: totalWidth * particle.xFraction + xOffset, y: yOffset)
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + particle.delay) {
                    withAnimation(.easeIn(duration: particle.duration)) {
                        yOffset = totalHeight + 60
                        xOffset = particle.xDrift
                    }
                    withAnimation(.linear(duration: particle.duration)) {
                        rotation = particle.endRotation
                    }
                    withAnimation(.easeIn(duration: 0.5).delay(particle.duration * 0.65)) {
                        opacity = 0
                    }
                }
            }
    }
}
