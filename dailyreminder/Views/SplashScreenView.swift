import SwiftUI

struct SplashScreenView: View {
    @State private var iconScale: CGFloat = 0.5
    @State private var iconOpacity: Double = 0
    @State private var titleOffset: CGFloat = 30
    @State private var titleOpacity: Double = 0
    @State private var subtitleOpacity: Double = 0
    @State private var ringScale: CGFloat = 0.8
    @State private var ringOpacity: Double = 0
    @State private var shimmerOffset: CGFloat = -200

    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [
                    Color(red: 0.08, green: 0.08, blue: 0.18),
                    Color(red: 0.12, green: 0.10, blue: 0.28),
                    Color(red: 0.06, green: 0.06, blue: 0.14)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            // Subtle radial glow behind icon
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color.blue.opacity(0.3),
                            Color.purple.opacity(0.1),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 20,
                        endRadius: 200
                    )
                )
                .frame(width: 400, height: 400)
                .scaleEffect(ringScale)
                .opacity(ringOpacity)

            VStack(spacing: 24) {
                // Animated icon
                ZStack {
                    // Outer ring
                    Circle()
                        .stroke(
                            LinearGradient(
                                colors: [.blue, .purple, .blue],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 3
                        )
                        .frame(width: 120, height: 120)
                        .scaleEffect(ringScale)
                        .opacity(ringOpacity)

                    // Icon background
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.25, green: 0.35, blue: 0.95),
                                    Color(red: 0.45, green: 0.25, blue: 0.85)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 100, height: 100)
                        .shadow(color: .blue.opacity(0.5), radius: 20, y: 8)

                    // Bell icon
                    Image(systemName: "bell.badge.fill")
                        .font(.system(size: 44, weight: .semibold))
                        .foregroundStyle(.white)
                        .shadow(color: .white.opacity(0.3), radius: 4)
                }
                .scaleEffect(iconScale)
                .opacity(iconOpacity)

                // App name
                VStack(spacing: 8) {
                    Text("Daily Reminder")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.white, .white.opacity(0.85)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )

                    Text("Never miss what matters")
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .foregroundStyle(.white.opacity(0.5))
                        .opacity(subtitleOpacity)
                }
                .offset(y: titleOffset)
                .opacity(titleOpacity)
            }

            // Shimmer overlay
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [
                            .clear,
                            .white.opacity(0.05),
                            .clear
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(width: 100)
                .rotationEffect(.degrees(20))
                .offset(x: shimmerOffset)
                .ignoresSafeArea()
        }
        .onAppear {
            withAnimation(.spring(response: 0.7, dampingFraction: 0.6).delay(0.1)) {
                iconScale = 1.0
                iconOpacity = 1.0
            }

            withAnimation(.spring(response: 0.7, dampingFraction: 0.7).delay(0.15)) {
                ringScale = 1.0
                ringOpacity = 1.0
            }

            withAnimation(.easeOut(duration: 0.6).delay(0.35)) {
                titleOffset = 0
                titleOpacity = 1.0
            }

            withAnimation(.easeOut(duration: 0.5).delay(0.6)) {
                subtitleOpacity = 1.0
            }

            withAnimation(.easeInOut(duration: 0.8).delay(0.5)) {
                shimmerOffset = 400
            }
        }
    }
}
