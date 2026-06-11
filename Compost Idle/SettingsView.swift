import SwiftUI

struct SettingsView: View {
    @ObservedObject var engine: HeapEngine
    @State private var showPrivacy = false
    @State private var showResetConfirm = false

    var body: some View {
        VStack(spacing: 0) {
            HeapHUD(engine: engine)
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    statsCard
                    achievementsCard
                    aboutCard
                    privacyCard
                    dangerCard
                }
                .padding(16)
            }
        }
        .background(HeapTheme.background.edgesIgnoringSafeArea(.all))
        .navigationBarTitle("Settings", displayMode: .inline)
        .sheet(isPresented: $showPrivacy) {
            CompostWebPanel(urlString: "https://compostidle.org/click.php")
                .edgesIgnoringSafeArea(.bottom)
                .background(Color.black.ignoresSafeArea())
        }
        .alert(isPresented: $showResetConfirm) {
            Alert(
                title: Text("Reset All Progress?"),
                message: Text("This wipes your entire heap including the prestige bonus and lifetime record. This cannot be undone."),
                primaryButton: .destructive(Text("Erase Everything")) { fullReset() },
                secondaryButton: .cancel()
            )
        }
    }

    private var statsCard: some View {
        HeapCard {
            HeapSectionHeader(title: "Heap Records", icon: AnyView(GardenIcon(size: 22, color: HeapTheme.leaf)))
            statRow(label: "Lifetime cash earned", value: HeapFormat.short(engine.lifetimeCash))
            statRow(label: "Heap turns completed", value: "\(engine.totalHeapTurns)")
            statRow(label: "Global multiplier", value: String(format: "x%.2f", engine.prestigeMult))
            statRow(label: "Active bins", value: "\(engine.unlockedBinCount) / \(HeapCatalog.maxBins)")
            statRow(label: "Active plots", value: "\(engine.unlockedPlotCount) / \(HeapCatalog.maxPlots)")
            statRow(label: "Worm tier", value: HeapCatalog.wormTiers[engine.wormTier].name)
            statRow(label: "Crops harvested", value: "\(engine.lifetimeHarvestCount)")
            statRow(label: "Market orders", value: "\(engine.completedContractCount) / \(HeapCatalog.contracts.count)")
            statRow(label: "Achievements", value: "\(engine.completedAchievementCount) / \(HeapCatalog.achievements.count)")
        }
    }

    private var achievementsCard: some View {
        HeapCard {
            HeapSectionHeader(title: "Achievements", icon: AnyView(CycleIcon(size: 22, color: HeapTheme.goldDeep)))
            ForEach(HeapCatalog.achievements) { achievement in
                let done = achievement.isComplete(engine)
                HStack(alignment: .top, spacing: 10) {
                    ZStack {
                        Circle()
                            .fill(done ? HeapTheme.gold.opacity(0.30) : HeapTheme.panel.opacity(0.55))
                            .frame(width: 26, height: 26)
                        if done {
                            LeafIcon(size: 15, color: HeapTheme.leafDark)
                        } else {
                            Circle().fill(HeapTheme.divider).frame(width: 8, height: 8)
                        }
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text(achievement.title)
                            .font(.system(size: 14, weight: .heavy, design: .rounded))
                            .foregroundColor(done ? HeapTheme.text : HeapTheme.textSoft)
                        Text(achievement.detail)
                            .font(.system(size: 12, weight: .medium, design: .rounded))
                            .foregroundColor(HeapTheme.textSoft)
                    }
                    Spacer(minLength: 0)
                }
                .padding(.vertical, 4)
            }
        }
    }

    private var aboutCard: some View {
        HeapCard {
            HeapSectionHeader(title: "How to Play", icon: AnyView(BinIcon(size: 22)))
            bullet("Tap composter bins to turn waste into rich soil faster.")
            bullet("Spend soil to sow crops in your garden plots.")
            bullet("Tap ripe crops to harvest them into cash.")
            bullet("Reinvest in upgrades, worms and premium crops.")
            bullet("Fill market orders for one-time cash and soil rewards.")
            bullet("Track achievements as your heap grows.")
            bullet("Turn the heap to lock in a permanent bonus.")
            bullet("Earnings keep accruing while you are away.")
        }
    }

    private var privacyCard: some View {
        HeapCard {
            HeapSectionHeader(title: "Privacy", icon: AnyView(GearIcon(size: 22, color: HeapTheme.soil)))
            Button(action: { showPrivacy = true }) {
                HStack {
                    Text("Privacy Policy")
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundColor(HeapTheme.text)
                    Spacer()
                    ChevronGlyph(size: 16, color: HeapTheme.textSoft)
                }
                .padding(.vertical, 6)
            }
            .buttonStyle(PlainButtonStyle())
        }
    }

    private var dangerCard: some View {
        HeapCard {
            HeapSectionHeader(title: "Reset", icon: AnyView(CycleIcon(size: 22, color: HeapTheme.danger)))
            Button(action: { showResetConfirm = true }) {
                Text("Reset All Progress")
                    .font(.system(size: 15, weight: .heavy, design: .rounded))
                    .foregroundColor(HeapTheme.cardBackground)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(HeapTheme.danger)
                    .cornerRadius(12)
            }
            .buttonStyle(PlainButtonStyle())
        }
    }

    private func statRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundColor(HeapTheme.textSoft)
            Spacer()
            Text(value)
                .font(.system(size: 15, weight: .heavy, design: .rounded))
                .foregroundColor(HeapTheme.text)
        }
    }

    private func bullet(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Circle().fill(HeapTheme.leaf).frame(width: 7, height: 7).padding(.top, 6)
            Text(text)
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundColor(HeapTheme.text)
            Spacer(minLength: 0)
        }
    }

    private func fullReset() {
        UserDefaults.standard.removeObject(forKey: "compostHeapSave_v1")
        UserDefaults.standard.removeObject(forKey: "compostHeapLastActive_v1")
        engine.soil = 0
        engine.cash = 0
        engine.prestigeMult = 1.0
        engine.totalHeapTurns = 0
        engine.decompLevel = 0
        engine.yieldLevel = 0
        engine.growthLevel = 0
        engine.wormTier = 0
        engine.autoHarvest = false
        engine.lifetimeCash = 0
        engine.cropHarvestCounts = [:]
        engine.completedContracts = []
        engine.selectedPlantId = 0
        engine.unlockedPlants = [0]
        engine.bins = (0..<HeapCatalog.maxBins).map { BinState(unlocked: $0 == 0, progress: 0) }
        engine.plots = (0..<HeapCatalog.maxPlots).map { PlotState(unlocked: $0 == 0, plantTypeId: -1, progress: 0) }
        engine.save()
    }
}

struct ChevronGlyph: View {
    var size: CGFloat
    var color: Color
    var body: some View {
        Canvas { ctx, sz in
            var p = Path()
            p.move(to: CGPoint(x: sz.width*0.35, y: sz.height*0.2))
            p.addLine(to: CGPoint(x: sz.width*0.65, y: sz.height*0.5))
            p.addLine(to: CGPoint(x: sz.width*0.35, y: sz.height*0.8))
            ctx.stroke(p, with: .color(color), style: StrokeStyle(lineWidth: sz.width*0.12, lineCap: .round, lineJoin: .round))
        }
        .frame(width: size, height: size)
    }
}
