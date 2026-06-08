import SwiftUI

struct GardenView: View {
    @ObservedObject var engine: HeapEngine
    @State private var poppedPlot: Int? = nil

    private var columns: [GridItem] {
        let isPad = UIScreen.main.bounds.width > 700
        let count = isPad ? 3 : 2
        return Array(repeating: GridItem(.flexible(), spacing: 14), count: count)
    }

    private var selectedPlant: PlantType? {
        HeapCatalog.plants.first(where: { $0.id == engine.selectedPlantId })
    }

    var body: some View {
        VStack(spacing: 0) {
            HeapHUD(engine: engine)
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    plantPicker
                    LazyVGrid(columns: columns, spacing: 14) {
                        ForEach(engine.plots.indices, id: \.self) { i in
                            plotCell(i)
                        }
                    }
                }
                .padding(16)
            }
        }
        .background(HeapTheme.background.edgesIgnoringSafeArea(.all))
        .navigationBarTitle("Garden", displayMode: .inline)
    }

    private var plantPicker: some View {
        HeapCard {
            HeapSectionHeader(title: "Seed Tray", icon: AnyView(LeafIcon(size: 22)))
            Text("Pick a crop, then tap an open plot to sow it. Tap a ripe plot to harvest for cash.")
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundColor(HeapTheme.textSoft)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(HeapCatalog.plants) { p in
                        if engine.unlockedPlants.contains(p.id) {
                            seedChip(p)
                        }
                    }
                }
                .padding(.vertical, 2)
            }
            if let sel = selectedPlant {
                HStack(spacing: 14) {
                    miniStat(icon: AnyView(SoilIcon(size: 16)), text: "\(HeapFormat.short(sel.soilCost)) soil")
                    miniStat(icon: AnyView(CoinIcon(size: 16)), text: "\(HeapFormat.short(sel.baseValue * engine.cashMultiplier))")
                    miniStat(icon: AnyView(LeafIcon(size: 16)), text: HeapFormat.time(engine.plotGrowSeconds(sel.id)))
                }
            }
        }
    }

    private func seedChip(_ p: PlantType) -> some View {
        let selected = engine.selectedPlantId == p.id
        return Button(action: { engine.selectPlant(p.id) }) {
            VStack(spacing: 4) {
                PlantGrowthIcon(size: 34, progress: 1.0, typeId: p.id)
                Text(p.name)
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundColor(selected ? HeapTheme.cardBackground : HeapTheme.text)
            }
            .padding(.horizontal, 12).padding(.vertical, 8)
            .background(selected ? HeapTheme.leaf : HeapTheme.panel.opacity(0.5))
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }

    private func miniStat(icon: AnyView, text: String) -> some View {
        HStack(spacing: 5) {
            icon
            Text(text)
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundColor(HeapTheme.text)
        }
    }

    private func plotCell(_ i: Int) -> some View {
        let plot = engine.plots[i]
        return Group {
            if plot.unlocked {
                Button(action: {
                    engine.tapPlot(i)
                    withAnimation(.easeOut(duration: 0.12)) { poppedPlot = i }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
                        withAnimation(.easeIn(duration: 0.12)) { if poppedPlot == i { poppedPlot = nil } }
                    }
                }) {
                    plotContent(plot, i)
                }
                .buttonStyle(PlainButtonStyle())
            } else {
                lockedPlotCell(i)
            }
        }
    }

    private func plotContent(_ plot: PlotState, _ i: Int) -> some View {
        let empty = plot.plantTypeId == -1
        let mature = plot.progress >= 1.0
        return VStack(spacing: 10) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(HeapTheme.soil.opacity(0.18))
                    .frame(height: 78)
                if empty {
                    VStack(spacing: 4) {
                        LeafIcon(size: 30, color: HeapTheme.leaf.opacity(0.5))
                        Text("Sow")
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                            .foregroundColor(HeapTheme.textSoft)
                    }
                } else {
                    PlantGrowthIcon(size: 60, progress: plot.progress, typeId: plot.plantTypeId)
                        .scaleEffect(poppedPlot == i ? 1.12 : 1.0)
                }
            }
            Text("Plot \(i + 1)")
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundColor(HeapTheme.text)
            if empty {
                Text("Tap to plant")
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundColor(HeapTheme.textSoft)
            } else if mature {
                Text("Ripe — tap!")
                    .font(.system(size: 12, weight: .heavy, design: .rounded))
                    .foregroundColor(HeapTheme.leafDark)
            } else {
                HeapProgressBar(progress: plot.progress, fill: HeapTheme.leaf)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity)
        .background(HeapTheme.cardBackground)
        .cornerRadius(16)
        .overlay(RoundedRectangle(cornerRadius: 16)
            .stroke(mature ? HeapTheme.leaf : HeapTheme.divider, lineWidth: mature ? 2 : 1))
    }

    private func lockedPlotCell(_ i: Int) -> some View {
        let cost = engine.nextPlotCost()
        let isNext = engine.plots.firstIndex(where: { !$0.unlocked }) == i
        return VStack(spacing: 10) {
            RoundedRectangle(cornerRadius: 12)
                .fill(HeapTheme.panel.opacity(0.5))
                .frame(height: 78)
                .overlay(GardenIcon(size: 36, color: HeapTheme.divider))
            Text("Plot \(i + 1)")
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundColor(HeapTheme.textSoft)
            if isNext, let cost = cost {
                Button(action: { engine.buyPlot() }) {
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
