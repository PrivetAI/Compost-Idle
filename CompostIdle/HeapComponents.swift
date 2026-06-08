import SwiftUI

// Top resource HUD shared across screens.
struct HeapHUD: View {
    @ObservedObject var engine: HeapEngine
    var body: some View {
        HStack(spacing: 10) {
            resourceChip(icon: AnyView(SoilIcon(size: 22)), value: engine.soil, tint: HeapTheme.soil)
            resourceChip(icon: AnyView(CoinIcon(size: 22)), value: engine.cash, tint: HeapTheme.goldDeep)
            if engine.prestigeMult > 1.0 {
                HStack(spacing: 5) {
                    CycleIcon(size: 18, color: HeapTheme.leafDark)
                    Text(String(format: "x%.2f", engine.prestigeMult))
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundColor(HeapTheme.leafDark)
                }
                .padding(.horizontal, 9).padding(.vertical, 7)
                .background(HeapTheme.leaf.opacity(0.18))
                .cornerRadius(11)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(HeapTheme.cardBackground)
    }

    private func resourceChip(icon: AnyView, value: Double, tint: Color) -> some View {
        HStack(spacing: 6) {
            icon
            Text(HeapFormat.short(value))
                .font(.system(size: 15, weight: .heavy, design: .rounded))
                .foregroundColor(tint)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
        }
        .padding(.horizontal, 11).padding(.vertical, 7)
        .background(HeapTheme.panel.opacity(0.6))
        .cornerRadius(12)
    }
}

// Simple progress bar.
struct HeapProgressBar: View {
    var progress: Double
    var fill: Color
    var height: CGFloat = 10
    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: height/2)
                    .fill(HeapTheme.progressTrack)
                RoundedRectangle(cornerRadius: height/2)
                    .fill(fill)
                    .frame(width: max(0, min(1, progress)) * geo.size.width)
            }
        }
        .frame(height: height)
    }
}

// A standardized buy / action button.
struct HeapActionButton: View {
    var title: String
    var subtitle: String?
    var costText: String?
    var enabled: Bool
    var tint: Color
    var action: () -> Void

    var body: some View {
        Button(action: { if enabled { action() } }) {
            HStack(spacing: 10) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundColor(HeapTheme.text)
                    if let subtitle = subtitle {
                        Text(subtitle)
                            .font(.system(size: 12, weight: .medium, design: .rounded))
                            .foregroundColor(HeapTheme.textSoft)
                    }
                }
                Spacer(minLength: 6)
                if let costText = costText {
                    HStack(spacing: 5) {
                        CoinIcon(size: 16)
                        Text(costText)
                            .font(.system(size: 14, weight: .heavy, design: .rounded))
                            .foregroundColor(enabled ? HeapTheme.goldDeep : HeapTheme.textSoft.opacity(0.6))
                    }
                    .padding(.horizontal, 10).padding(.vertical, 7)
                    .background((enabled ? tint : HeapTheme.divider).opacity(0.25))
                    .cornerRadius(10)
                }
            }
            .padding(.horizontal, 14).padding(.vertical, 12)
            .background(HeapTheme.cardBackground)
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(enabled ? tint.opacity(0.5) : HeapTheme.divider, lineWidth: 1.5)
            )
            .cornerRadius(14)
            .opacity(enabled ? 1.0 : 0.55)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// Section header with a small icon.
struct HeapSectionHeader: View {
    var title: String
    var icon: AnyView
    var body: some View {
        HStack(spacing: 8) {
            icon
            Text(title)
                .font(.system(size: 18, weight: .heavy, design: .rounded))
                .foregroundColor(HeapTheme.text)
            Spacer()
        }
    }
}

// Card container.
struct HeapCard<Content: View>: View {
    var content: () -> Content
    init(@ViewBuilder content: @escaping () -> Content) { self.content = content }
    var body: some View {
        VStack(alignment: .leading, spacing: 10) { content() }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(HeapTheme.cardBackground)
            .cornerRadius(16)
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(HeapTheme.divider, lineWidth: 1))
    }
}
