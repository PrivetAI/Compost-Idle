import SwiftUI
import Combine

// MARK: - Static catalog data

struct PlantType: Identifiable {
    let id: Int
    let name: String
    let soilCost: Double      // soil spent to plant
    let growSeconds: Double   // base time to mature
    let baseValue: Double     // cash on harvest (before multipliers)
    let unlockCost: Double    // one-time cash to unlock
}

enum HeapCatalog {
    // Premium plant types — later ones are worth far more but cost more soil/time.
    static let plants: [PlantType] = [
        PlantType(id: 0, name: "Radish",   soilCost: 8,    growSeconds: 12,  baseValue: 6,     unlockCost: 0),
        PlantType(id: 1, name: "Lettuce",  soilCost: 22,   growSeconds: 20,  baseValue: 20,    unlockCost: 120),
        PlantType(id: 2, name: "Tomato",   soilCost: 65,   growSeconds: 34,  baseValue: 75,    unlockCost: 900),
        PlantType(id: 3, name: "Pumpkin",  soilCost: 220,  growSeconds: 55,  baseValue: 320,   unlockCost: 6500),
        PlantType(id: 4, name: "Sunflower",soilCost: 800,  growSeconds: 80,  baseValue: 1500,  unlockCost: 48000),
        PlantType(id: 5, name: "Orchard",  soilCost: 3200, growSeconds: 120, baseValue: 7200,  unlockCost: 380000)
    ]

    // Worm tiers multiply soil output of every bin.
    static let wormTiers: [(name: String, mult: Double, cost: Double)] = [
        ("Garden Worms",   1.0,  0),
        ("Red Wigglers",   1.6,  450),
        ("Tiger Worms",    2.6,  4200),
        ("Blue Worms",     4.2,  41000),
        ("Nightcrawlers",  7.0,  420000),
        ("Composting Kings", 12.0, 4200000)
    ]

    static let maxBins = 6
    static let maxPlots = 6
}

// MARK: - Bin model (waste -> soil over time)

struct BinState: Codable {
    var unlocked: Bool
    var progress: Double   // 0...1 of current batch
}

// MARK: - Plot model (soil -> plant -> cash)

struct PlotState: Codable {
    var unlocked: Bool
    var plantTypeId: Int   // -1 == empty
    var progress: Double   // 0...1 maturity
}

// MARK: - Engine

final class HeapEngine: ObservableObject {
    // Resources
    @Published var soil: Double = 0
    @Published var cash: Double = 0
    @Published var prestigeMult: Double = 1.0   // permanent global multiplier from "turning the heap"
    @Published var totalHeapTurns: Int = 0

    // Upgrade levels
    @Published var decompLevel: Int = 0      // faster decomposition
    @Published var yieldLevel: Int = 0       // more soil per batch
    @Published var growthLevel: Int = 0      // faster plant growth
    @Published var wormTier: Int = 0
    @Published var autoHarvest: Bool = false // auto-harvest unlock

    // Entities
    @Published var bins: [BinState] = []
    @Published var plots: [PlotState] = []

    // Selected plant for new plantings
    @Published var selectedPlantId: Int = 0
    @Published var unlockedPlants: Set<Int> = [0]

    // Lifetime stats
    @Published var lifetimeCash: Double = 0

    private var timer: AnyCancellable?
    private let tickInterval: Double = 0.1
    private let defaultsKey = "compostHeapSave_v1"
    private let lastActiveKey = "compostHeapLastActive_v1"

    // Tuning ----------------------------------------------------------------
    private let baseBinSeconds: Double = 6.0     // seconds for a fresh bin to fill
    private let baseSoilPerBatch: Double = 5.0
    private let tapBoost: Double = 0.10          // fraction of a batch advanced per tap

    init() {
        load()
        if bins.isEmpty {
            bins = (0..<HeapCatalog.maxBins).map { BinState(unlocked: $0 == 0, progress: 0) }
        }
        if plots.isEmpty {
            plots = (0..<HeapCatalog.maxPlots).map { PlotState(unlocked: $0 == 0, plantTypeId: -1, progress: 0) }
        }
        creditOffline()
        startTimer()
    }

    deinit { timer?.cancel() }

    // MARK: Derived rates

    var decompMultiplier: Double { pow(1.18, Double(decompLevel)) }     // speeds bins
    var soilPerBatch: Double {
        baseSoilPerBatch * pow(1.5, Double(yieldLevel)) * HeapCatalog.wormTiers[wormTier].mult * prestigeMult
    }
    var growthMultiplier: Double { pow(1.16, Double(growthLevel)) }
    var cashMultiplier: Double { prestigeMult }

    var unlockedBinCount: Int { bins.filter { $0.unlocked }.count }
    var unlockedPlotCount: Int { plots.filter { $0.unlocked }.count }

    func binSecondsPerBatch() -> Double {
        max(0.4, baseBinSeconds / decompMultiplier)
    }

    func plotGrowSeconds(_ typeId: Int) -> Double {
        guard let t = HeapCatalog.plants.first(where: { $0.id == typeId }) else { return 9999 }
        return max(0.5, t.growSeconds / growthMultiplier)
    }

    // MARK: Upgrade costs (steep growth keeps the economy bounded)

    func decompCost() -> Double { 30 * pow(1.55, Double(decompLevel)) }
    func yieldCost() -> Double { 80 * pow(1.7, Double(yieldLevel)) }
    func growthCost() -> Double { 55 * pow(1.6, Double(growthLevel)) }

    func nextBinCost() -> Double? {
        let n = unlockedBinCount
        guard n < HeapCatalog.maxBins else { return nil }
        return 150 * pow(6.0, Double(n - 1))
    }
    func nextPlotCost() -> Double? {
        let n = unlockedPlotCount
        guard n < HeapCatalog.maxPlots else { return nil }
        return 200 * pow(6.5, Double(n - 1))
    }
    func nextWormCost() -> Double? {
        let n = wormTier + 1
        guard n < HeapCatalog.wormTiers.count else { return nil }
        return HeapCatalog.wormTiers[n].cost
    }
    func autoHarvestCost() -> Double { 2500 }

    // MARK: Prestige

    // Heap turns earned are based on lifetime cash. Each turn adds +0.15 to mult.
    func pendingHeapTurns() -> Int {
        let earned = Int((lifetimeCash / 25000).squareRootClamped())
        return max(0, earned - totalHeapTurns)
    }

    func canTurnHeap() -> Bool { pendingHeapTurns() >= 1 }

    func turnHeap() {
        let gained = pendingHeapTurns()
        guard gained >= 1 else { return }
        totalHeapTurns += gained
        prestigeMult = 1.0 + 0.15 * Double(totalHeapTurns)
        // Reset progress but keep prestige + heap-turn count + lifetime stat.
        soil = 0
        cash = 0
        decompLevel = 0
        yieldLevel = 0
        growthLevel = 0
        wormTier = 0
        autoHarvest = false
        selectedPlantId = 0
        unlockedPlants = [0]
        bins = (0..<HeapCatalog.maxBins).map { BinState(unlocked: $0 == 0, progress: 0) }
        plots = (0..<HeapCatalog.maxPlots).map { PlotState(unlocked: $0 == 0, plantTypeId: -1, progress: 0) }
        save()
    }

    // MARK: Actions

    func tapBin(_ index: Int) {
        guard bins.indices.contains(index), bins[index].unlocked else { return }
        bins[index].progress += tapBoost
        settleBin(index)
    }

    func buyDecomp() { spend(decompCost()) { self.decompLevel += 1 } }
    func buyYield() { spend(yieldCost()) { self.yieldLevel += 1 } }
    func buyGrowth() { spend(growthCost()) { self.growthLevel += 1 } }

    func buyBin() {
        guard let cost = nextBinCost() else { return }
        spend(cost) {
            if let idx = self.bins.firstIndex(where: { !$0.unlocked }) {
                self.bins[idx].unlocked = true
            }
        }
    }
    func buyPlot() {
        guard let cost = nextPlotCost() else { return }
        spend(cost) {
            if let idx = self.plots.firstIndex(where: { !$0.unlocked }) {
                self.plots[idx].unlocked = true
            }
        }
    }
    func buyWorm() {
        guard let cost = nextWormCost() else { return }
        spend(cost) { self.wormTier += 1 }
    }
    func buyAutoHarvest() {
        guard !autoHarvest else { return }
        spend(autoHarvestCost()) { self.autoHarvest = true }
    }

    func unlockPlant(_ id: Int) {
        guard let t = HeapCatalog.plants.first(where: { $0.id == id }), !unlockedPlants.contains(id) else { return }
        spend(t.unlockCost) {
            self.unlockedPlants.insert(id)
            self.selectedPlantId = id
        }
    }

    func selectPlant(_ id: Int) {
        guard unlockedPlants.contains(id) else { return }
        selectedPlantId = id
    }

    // Plant the selected type into a plot if soil allows.
    func plant(_ index: Int) {
        guard plots.indices.contains(index), plots[index].unlocked, plots[index].plantTypeId == -1 else { return }
        guard let t = HeapCatalog.plants.first(where: { $0.id == selectedPlantId }) else { return }
        guard soil >= t.soilCost else { return }
        soil -= t.soilCost
        plots[index].plantTypeId = t.id
        plots[index].progress = 0
        save()
    }

    // Tap a plot: if mature, harvest; if growing, nudge it along.
    func tapPlot(_ index: Int) {
        guard plots.indices.contains(index), plots[index].unlocked else { return }
        let typeId = plots[index].plantTypeId
        if typeId == -1 {
            plant(index)
            return
        }
        if plots[index].progress >= 1.0 {
            harvest(index)
        } else {
            plots[index].progress = min(1.0, plots[index].progress + 0.08)
            if plots[index].progress >= 1.0 && autoHarvest {
                harvest(index)
            }
        }
    }

    private func harvest(_ index: Int) {
        let typeId = plots[index].plantTypeId
        guard let t = HeapCatalog.plants.first(where: { $0.id == typeId }) else { return }
        let earned = t.baseValue * cashMultiplier
        cash += earned
        lifetimeCash += earned
        plots[index].plantTypeId = -1
        plots[index].progress = 0
        save()
    }

    private func spend(_ cost: Double, _ action: () -> Void) {
        guard cash >= cost else { return }
        cash -= cost
        action()
        save()
    }

    // MARK: Simulation

    private func startTimer() {
        timer = Timer.publish(every: tickInterval, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in self?.advance(self?.tickInterval ?? 0.1) }
    }

    private func advance(_ dt: Double) {
        let batchSeconds = binSecondsPerBatch()
        for i in bins.indices where bins[i].unlocked {
            bins[i].progress += dt / batchSeconds
            settleBin(i)
        }
        for i in plots.indices where plots[i].unlocked {
            let typeId = plots[i].plantTypeId
            guard typeId != -1, plots[i].progress < 1.0 else { continue }
            let grow = plotGrowSeconds(typeId)
            plots[i].progress = min(1.0, plots[i].progress + dt / grow)
            if plots[i].progress >= 1.0 && autoHarvest {
                harvest(i)
            }
        }
    }

    // Convert any completed batches in a bin into soil.
    private func settleBin(_ i: Int) {
        if bins[i].progress >= 1.0 {
            let batches = floor(bins[i].progress)
            soil += batches * soilPerBatch
            bins[i].progress -= batches
        }
    }

    // MARK: Offline credit

    private func creditOffline() {
        let last = UserDefaults.standard.double(forKey: lastActiveKey)
        guard last > 0 else { return }
        let now = Date().timeIntervalSince1970
        var elapsed = now - last
        guard elapsed > 1 else { return }
        // Cap offline accrual to a generous 8 hours so it stays bounded.
        elapsed = min(elapsed, 8 * 3600)

        // Soil from bins.
        let batchSeconds = binSecondsPerBatch()
        let activeBins = Double(bins.filter { $0.unlocked }.count)
        let soilGain = (elapsed / batchSeconds) * activeBins * soilPerBatch
        soil += soilGain

        // Plants: advance growth. Plots never auto-replant in live play (a harvested
        // plot is left EMPTY until the player re-sows), so offline must credit at most
        // ONE harvest per ripe plot — never repeated regrowth cycles.
        for i in plots.indices where plots[i].unlocked {
            let typeId = plots[i].plantTypeId
            guard typeId != -1, let t = HeapCatalog.plants.first(where: { $0.id == typeId }) else { continue }
            let grow = plotGrowSeconds(typeId)
            let remaining = (1.0 - plots[i].progress) * grow
            if elapsed < remaining {
                plots[i].progress = min(1.0, plots[i].progress + elapsed / grow)
            } else if autoHarvest {
                // Matured while away: auto-harvest sells it once, leaving the plot empty
                // (identical to the live auto-harvest path in advance()).
                let earned = t.baseValue * cashMultiplier
                cash += earned
                lifetimeCash += earned
                plots[i].plantTypeId = -1
                plots[i].progress = 0
            } else {
                // Matured while away but no auto-harvest: one ripe crop waits to be tapped.
                plots[i].progress = 1.0
            }
        }
        lastOfflineSoil = soilGain
        lastOfflineSeconds = elapsed
        save()
    }

    // Surface offline summary to the UI once.
    @Published var lastOfflineSoil: Double = 0
    @Published var lastOfflineSeconds: Double = 0
    func consumeOfflineSummary() -> (soil: Double, seconds: Double)? {
        guard lastOfflineSeconds > 2, lastOfflineSoil > 0.01 else { return nil }
        let s = (lastOfflineSoil, lastOfflineSeconds)
        lastOfflineSoil = 0
        lastOfflineSeconds = 0
        return s
    }

    // MARK: Persistence

    struct SaveData: Codable {
        var soil: Double
        var cash: Double
        var prestigeMult: Double
        var totalHeapTurns: Int
        var decompLevel: Int
        var yieldLevel: Int
        var growthLevel: Int
        var wormTier: Int
        var autoHarvest: Bool
        var bins: [BinState]
        var plots: [PlotState]
        var selectedPlantId: Int
        var unlockedPlants: [Int]
        var lifetimeCash: Double
    }

    func save() {
        let data = SaveData(
            soil: soil, cash: cash, prestigeMult: prestigeMult, totalHeapTurns: totalHeapTurns,
            decompLevel: decompLevel, yieldLevel: yieldLevel, growthLevel: growthLevel,
            wormTier: wormTier, autoHarvest: autoHarvest, bins: bins, plots: plots,
            selectedPlantId: selectedPlantId, unlockedPlants: Array(unlockedPlants),
            lifetimeCash: lifetimeCash)
        if let encoded = try? JSONEncoder().encode(data) {
            UserDefaults.standard.set(encoded, forKey: defaultsKey)
        }
    }

    private func load() {
        guard let raw = UserDefaults.standard.data(forKey: defaultsKey),
              let data = try? JSONDecoder().decode(SaveData.self, from: raw) else { return }
        soil = data.soil
        cash = data.cash
        prestigeMult = data.prestigeMult
        totalHeapTurns = data.totalHeapTurns
        decompLevel = data.decompLevel
        yieldLevel = data.yieldLevel
        growthLevel = data.growthLevel
        wormTier = data.wormTier
        autoHarvest = data.autoHarvest
        bins = data.bins
        plots = data.plots
        selectedPlantId = data.selectedPlantId
        unlockedPlants = Set(data.unlockedPlants)
        lifetimeCash = data.lifetimeCash
    }

    // Stamp last-active ONLY on background (see RootView scenePhase handling).
    func stampLastActive() {
        UserDefaults.standard.set(Date().timeIntervalSince1970, forKey: lastActiveKey)
        save()
    }
}

private extension Double {
    func squareRootClamped() -> Double { self <= 0 ? 0 : self.squareRoot() }
}
