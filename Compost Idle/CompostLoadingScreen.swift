import SwiftUI

struct CompostLoadingScreen: View {
    @State private var spin = false
    @State private var pulse = false

    var body: some View {
        ZStack {
            HeapTheme.background.edgesIgnoringSafeArea(.all)
            VStack(spacing: 24) {
                ZStack {
                    Circle()
                        .fill(HeapTheme.leaf.opacity(0.18))
                        .frame(width: 150, height: 150)
                        .scaleEffect(pulse ? 1.08 : 0.94)
                    CycleIcon(size: 110, color: HeapTheme.leafDark)
                        .rotationEffect(.degrees(spin ? 360 : 0))
                    BinIcon(size: 52, color: HeapTheme.soil)
                }
                Text("Compost Idle")
                    .font(.system(size: 24, weight: .heavy, design: .rounded))
                    .foregroundColor(HeapTheme.text)
                Text("Warming up the heap...")
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundColor(HeapTheme.textSoft)
            }
        }
        .onAppear {
            withAnimation(.linear(duration: 2.2).repeatForever(autoreverses: false)) { spin = true }
            withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) { pulse = true }
        }
    }
}
