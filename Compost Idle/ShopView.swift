import SwiftUI

struct ShopView: View {
    @ObservedObject var engine: HeapEngine
    @State private var showTurnConfirm = false

    var body: some View {
        VStack(spacing: 0) {
            HeapHUD(engine: engine)
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    speedSection
                    wormSection
                    plantSection
                    prestigeSection
                }
                .padding(16)
            }
        }
        .background(HeapTheme.background.edgesIgnoringSafeArea(.all))
        .navigationBarTitle("Shop", displayMode: .inline)
        .alert(isPresented: $showTurnConfirm) {
            Alert(
                title: Text("Turn the Heap?"),
                message: Text("Reset bins, plots and upgrades for a permanent global multiplier. Your heap-turn bonus and lifetime record are kept."),
                primaryButton: .destructive(Text("Turn Heap")) { engine.turnHeap() },
                secondaryButton: .cancel()
            )
        }
    }

    // MARK: Speed upgrades

    private var speedSection: some View {
        HeapCard {
            HeapSectionHeader(title: "Speed Upgrades", icon: AnyView(GearIcon(size: 22, color: HeapTheme.soil)))
            HeapActionButton(
                title: "Decomposition Lv \(engine.decompLevel + 1)",
                subtitle: "Bins fill faster",
                costText: HeapFormat.short(engine.decompCost()),
                enabled: engine.cash >= engine.decompCost(),
                tint: HeapTheme.soil,
                action: { engine.buyDecomp() })
            HeapActionButton(
                title: "Soil Richness Lv \(engine.yieldLevel + 1)",
                subtitle: "More soil per batch",
                costText: HeapFormat.short(engine.yieldCost()),
                enabled: engine.cash >= engine.yieldCost(),
                tint: HeapTheme.soilLight,
                action: { engine.buyYield() })
            HeapActionButton(
                title: "Growth Tonic Lv \(engine.growthLevel + 1)",
                subtitle: "Plants mature faster",
                costText: HeapFormat.short(engine.growthCost()),
                enabled: engine.cash >= engine.growthCost(),
                tint: HeapTheme.leaf,
                action: { engine.buyGrowth() })
            if let binCost = engine.nextBinCost() {
                HeapActionButton(
                    title: "New Composter Bin",
                    subtitle: "\(engine.unlockedBinCount) of \(HeapCatalog.maxBins) active",
                    costText: HeapFormat.short(binCost),
                    enabled: engine.cash >= binCost,
                    tint: HeapTheme.soil,
                    action: { engine.buyBin() })
            }
            if let plotCost = engine.nextPlotCost() {
                HeapActionButton(
                    title: "New Garden Plot",
                    subtitle: "\(engine.unlockedPlotCount) of \(HeapCatalog.maxPlots) active",
                    costText: HeapFormat.short(plotCost),
                    enabled: engine.cash >= plotCost,
                    tint: HeapTheme.leaf,
                    action: { engine.buyPlot() })
            }
            if !engine.autoHarvest {
                HeapActionButton(
                    title: "Auto-Harvester",
                    subtitle: "Ripe crops sell themselves",
                    costText: HeapFormat.short(engine.autoHarvestCost()),
                    enabled: engine.cash >= engine.autoHarvestCost(),
                    tint: HeapTheme.gold,
                    action: { engine.buyAutoHarvest() })
            } else {
                statusRow(text: "Auto-Harvester active", tint: HeapTheme.leafDark, icon: AnyView(LeafIcon(size: 18)))
            }
        }
    }

    // MARK: Worms

    private var wormSection: some View {
        HeapCard {
            HeapSectionHeader(title: "Worm Colony", icon: AnyView(WormIcon(size: 22)))
            let cur = HeapCatalog.wormTiers[engine.wormTier]
            HStack(spacing: 8) {
                WormIcon(size: 20)
                Text("Current: \(cur.name)")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundColor(HeapTheme.text)
                Spacer()
                Text(String(format: "x%.1f soil", cur.mult))
                    .font(.system(size: 13, weight: .heavy, design: .rounded))
                    .foregroundColor(HeapTheme.worm)
            }
            if let cost = engine.nextWormCost() {
                let next = HeapCatalog.wormTiers[engine.wormTier + 1]
                HeapActionButton(
                    title: "Upgrade to \(next.name)",
                    subtitle: String(format: "x%.1f soil output", next.mult),
                    costText: HeapFormat.short(cost),
                    enabled: engine.cash >= cost,
                    tint: HeapTheme.worm,
                    action: { engine.buyWorm() })
            } else {
                statusRow(text: "Top worm tier reached", tint: HeapTheme.worm, icon: AnyView(WormIcon(size: 18)))
            }
        }
    }

    // MARK: Premium plants

    private var plantSection: some View {
        HeapCard {
            HeapSectionHeader(title: "Premium Crops", icon: AnyView(LeafIcon(size: 22)))
            ForEach(HeapCatalog.plants) { p in
                if !engine.unlockedPlants.contains(p.id) {
                    HeapActionButton(
                        title: "Unlock \(p.name)",
                        subtitle: "Worth \(HeapFormat.short(p.baseValue * engine.cashMultiplier)) each",
                        costText: HeapFormat.short(p.unlockCost),
                        enabled: engine.cash >= p.unlockCost && prevUnlocked(p.id),
                        tint: HeapTheme.leaf,
                        action: { engine.unlockPlant(p.id) })
                }
            }
            if engine.unlockedPlants.count == HeapCatalog.plants.count {
                statusRow(text: "All crops unlocked", tint: HeapTheme.leafDark, icon: AnyView(LeafIcon(size: 18)))
            }
        }
    }

    // Gate later plants behind the previous unlock for clean progression.
    private func prevUnlocked(_ id: Int) -> Bool {
        if id == 0 { return true }
        return engine.unlockedPlants.contains(id - 1)
    }

    // MARK: Prestige

    private var prestigeSection: some View {
        HeapCard {
            HeapSectionHeader(title: "Turn the Heap", icon: AnyView(CycleIcon(size: 22, color: HeapTheme.leafDark)))
            Text("Fully turning your heap resets progress but bakes a permanent bonus into everything you grow next.")
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundColor(HeapTheme.textSoft)
            HStack(spacing: 14) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Current bonus")
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                        .foregroundColor(HeapTheme.textSoft)
                    Text(String(format: "x%.2f", engine.prestigeMult))
                        .font(.system(size: 18, weight: .heavy, design: .rounded))
                        .foregroundColor(HeapTheme.leafDark)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text("Turns ready")
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                        .foregroundColor(HeapTheme.textSoft)
                    Text("\(engine.pendingHeapTurns())")
                        .font(.system(size: 18, weight: .heavy, design: .rounded))
                        .foregroundColor(HeapTheme.text)
                }
                Spacer()
            }
            Button(action: { if engine.canTurnHeap() { showTurnConfirm = true } }) {
                HStack(spacing: 8) {
                    CycleIcon(size: 20, color: HeapTheme.cardBackground)
                    Text(engine.canTurnHeap()
                         ? "Turn Heap (+\(String(format: "%.2f", 0.15 * Double(engine.pendingHeapTurns()))))"
                         : "Earn more cash to turn")
                        .font(.system(size: 15, weight: .heavy, design: .rounded))
                        .foregroundColor(HeapTheme.cardBackground)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 13)
                .background(engine.canTurnHeap() ? HeapTheme.leafDark : HeapTheme.divider)
                .cornerRadius(14)
            }
            .buttonStyle(PlainButtonStyle())
            .disabled(!engine.canTurnHeap())
        }
    }

    private func statusRow(text: String, tint: Color, icon: AnyView) -> some View {
        HStack(spacing: 8) {
            icon
            Text(text)
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundColor(tint)
            Spacer()
        }
        .padding(.vertical, 4)
    }
}
