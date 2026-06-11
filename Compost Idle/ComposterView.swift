import SwiftUI

struct ComposterView: View {
    @ObservedObject var engine: HeapEngine
    @State private var poppedBin: Int? = nil

    private var columns: [GridItem] {
        let isPad = UIScreen.main.bounds.width > 700
        let count = isPad ? 3 : 2
        return Array(repeating: GridItem(.flexible(), spacing: 14), count: count)
    }

    var body: some View {
        VStack(spacing: 0) {
            HeapHUD(engine: engine)
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    HeapCard {
                        HeapSectionHeader(title: "Composter Bins", icon: AnyView(BinIcon(size: 22)))
                        Text("Each bin breaks down waste into rich soil. Tap a bin to turn it and speed up the batch.")
                            .font(.system(size: 13, weight: .medium, design: .rounded))
                            .foregroundColor(HeapTheme.textSoft)
                        HStack(spacing: 14) {
                            statLabel(title: "Soil / batch", value: HeapFormat.short(engine.soilPerBatch))
                            statLabel(title: "Batch time", value: HeapFormat.time(engine.binSecondsPerBatch()))
                        }
                    }

                    LazyVGrid(columns: columns, spacing: 14) {
                        ForEach(engine.bins.indices, id: \.self) { i in
                            binCell(i)
                        }
                    }
                }
                .padding(16)
            }
        }
        .background(HeapTheme.background.edgesIgnoringSafeArea(.all))
        .navigationBarTitle("Compost", displayMode: .inline)
    }

    private func statLabel(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .foregroundColor(HeapTheme.textSoft)
            Text(value)
                .font(.system(size: 16, weight: .heavy, design: .rounded))
                .foregroundColor(HeapTheme.text)
        }
    }

    private func binCell(_ i: Int) -> some View {
        let bin = engine.bins[i]
        return Group {
            if bin.unlocked {
                Button(action: {
                    engine.tapBin(i)
                    withAnimation(.easeOut(duration: 0.12)) { poppedBin = i }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
                        withAnimation(.easeIn(duration: 0.12)) { if poppedBin == i { poppedBin = nil } }
                    }
                }) {
                    VStack(spacing: 10) {
                        BinIcon(size: 64, color: HeapTheme.soil)
                            .scaleEffect(poppedBin == i ? 1.12 : 1.0)
                        Text(HeapCatalog.binName(i))
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .foregroundColor(HeapTheme.text)
                            .multilineTextAlignment(.center)
                            .lineLimit(2)
                        HeapProgressBar(progress: bin.progress, fill: HeapTheme.waste)
                        Text("Tap to turn")
                            .font(.system(size: 11, weight: .semibold, design: .rounded))
                            .foregroundColor(HeapTheme.textSoft)
                    }
                    .padding(14)
                    .frame(maxWidth: .infinity)
                    .background(HeapTheme.cardBackground)
                    .cornerRadius(16)
                    .overlay(RoundedRectangle(cornerRadius: 16).stroke(HeapTheme.divider, lineWidth: 1))
                }
                .buttonStyle(PlainButtonStyle())
            } else {
                lockedBinCell(i)
            }
        }
    }

    private func lockedBinCell(_ i: Int) -> some View {
        let cost = engine.nextBinCost()
        // Only the very next locked bin is purchasable.
        let isNext = engine.bins.firstIndex(where: { !$0.unlocked }) == i
        return VStack(spacing: 10) {
            BinIcon(size: 64, color: HeapTheme.divider)
            Text(HeapCatalog.binName(i))
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundColor(HeapTheme.textSoft)
                .multilineTextAlignment(.center)
                .lineLimit(2)
            if isNext, let cost = cost {
                Button(action: { engine.buyBin() }) {
                    HStack(spacing: 5) {
                        CoinIcon(size: 15)
                        Text(HeapFormat.short(cost))
                            .font(.system(size: 13, weight: .heavy, design: .rounded))
                            .foregroundColor(engine.cash >= cost ? HeapTheme.goldDeep : HeapTheme.textSoft)
                    }
                    .padding(.horizontal, 12).padding(.vertical, 8)
                    .background((engine.cash >= cost ? HeapTheme.gold : HeapTheme.divider).opacity(0.3))
                    .cornerRadius(11)
                }
                .buttonStyle(PlainButtonStyle())
                .disabled(engine.cash < cost)
            } else {
                Text("Locked")
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundColor(HeapTheme.textSoft)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity)
        .background(HeapTheme.panel.opacity(0.4))
        .cornerRadius(16)
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(HeapTheme.divider, lineWidth: 1))
    }
}
