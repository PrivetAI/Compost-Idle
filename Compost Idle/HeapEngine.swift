import SwiftUI
import Combine

// MARK: - Static catalog data

struct PlantType: Identifiable {
    let id: Int
    let name: String
    let note: String
    let soilCost: Double      // soil spent to plant
    let growSeconds: Double   // base time to mature
    let baseValue: Double     // cash on harvest (before multipliers)
    let unlockCost: Double    // one-time cash to unlock
}

struct CompostContract: Identifiable {
    let id: Int
    let title: String
    let plantTypeId: Int
    let requiredHarvests: Int
    let cashReward: Double
    let soilReward: Double
}

struct HeapAchievement: Identifiable {
    let id: Int
    let title: String
    let detail: String
    let isComplete: (HeapEngine) -> Bool
}

enum HeapCatalog {
    // Premium plant types — later ones are worth far more but cost more soil/time.
    static let plants: [PlantType] = [
        PlantType(id: 0, name: "Radish",    note: "quick starter crop", soilCost: 8,     growSeconds: 12,  baseValue: 6,      unlockCost: 0),
        PlantType(id: 1, name: "Lettuce",   note: "steady salad cash",   soilCost: 22,    growSeconds: 20,  baseValue: 20,     unlockCost: 120),
        PlantType(id: 2, name: "Carrot",    note: "cheap root bundles",  soilCost: 45,    growSeconds: 28,  baseValue: 48,     unlockCost: 420),
        PlantType(id: 3, name: "Tomato",    note: "market favorite",     soilCost: 85,    growSeconds: 36,  baseValue: 95,     unlockCost: 1100),
        PlantType(id: 4, name: "Pepper",    note: "spicy premium crop",  soilCost: 160,   growSeconds: 48,  baseValue: 210,    unlockCost: 3500),
        PlantType(id: 5, name: "Pumpkin",   note: "big autumn payout",   soilCost: 320,   growSeconds: 65,  baseValue: 480,    unlockCost: 11000),
        PlantType(id: 6, name: "Sunflower", note: "golden seed heads",   soilCost: 720,   growSeconds: 90,  baseValue: 1250,   unlockCost: 42000),
        PlantType(id: 7, name: "Blueberry", note: "slow berry crates",   soilCost: 1500,  growSeconds: 115, baseValue: 3200,   unlockCost: 140000),
        PlantType(id: 8, name: "Lavender",  note: "fragrant bundles",    soilCost: 3400,  growSeconds: 145, baseValue: 8200,   unlockCost: 520000),
        PlantType(id: 9, name: "Mushroom",  note: "dark heap delicacy",  soilCost: 7800,  growSeconds: 175, baseValue: 21000,  unlockCost: 1900000),
        PlantType(id: 10, name: "Melon",    note: "heavy summer haul",   soilCost: 18000, growSeconds: 220, baseValue: 54000,  unlockCost: 7500000),
        PlantType(id: 11, name: "Orchard",  note: "late-game grove",     soilCost: 42000, growSeconds: 280, baseValue: 145000, unlockCost: 30000000)
    ]

    // Worm tiers multiply soil output of every bin.
    static let wormTiers: [(name: String, mult: Double, cost: Double)] = [
        ("Garden Worms",       1.0,  0),
        ("Red Wigglers",       1.6,  450),
        ("Tiger Worms",        2.6,  4200),
        ("Blue Worms",         4.2,  41000),
        ("Nightcrawlers",      7.0,  420000),
        ("Composting Kings",   12.0, 4200000),
        ("Soil Alchemists",    20.0, 42000000),
        ("Mycelium Network",   34.0, 420000000),
        ("Earth Shapers",      58.0, 4200000000)
    ]

    static let contracts: [CompostContract] = [
        CompostContract(id: 0, title: "Cafe Salad Box", plantTypeId: 1, requiredHarvests: 6, cashReward: 180, soilReward: 30),
        CompostContract(id: 1, title: "Root Cellar Restock", plantTypeId: 2, requiredHarvests: 8, cashReward: 720, soilReward: 80),
        CompostContract(id: 2, title: "Sauce Stand Rush", plantTypeId: 3, requiredHarvests: 10, cashReward: 2600, soilReward: 180),
        CompostContract(id: 3, title: "Spicy Market Day", plantTypeId: 4, requiredHarvests: 10, cashReward: 8500, soilReward: 420),
        CompostContract(id: 4, title: "Harvest Festival", plantTypeId: 5, requiredHarvests: 12, cashReward: 32000, soilReward: 1000),
        CompostContract(id: 5, title: "Birdseed Co-op", plantTypeId: 6, requiredHarvests: 14, cashReward: 130000, soilReward: 2400),
        CompostContract(id: 6, title: "Bakery Berry Crates", plantTypeId: 7, requiredHarvests: 16, cashReward: 520000, soilReward: 5800),
        CompostContract(id: 7, title: "Apothecary Bundle", plantTypeId: 8, requiredHarvests: 18, cashReward: 2200000, soilReward: 14000),
        CompostContract(id: 8, title: "Chef's Mushroom Run", plantTypeId: 9, requiredHarvests: 20, cashReward: 9200000, soilReward: 34000),
        CompostContract(id: 9, title: "Summer Fair Melons", plantTypeId: 10, requiredHarvests: 22, cashReward: 38000000, soilReward: 85000),
        CompostContract(id: 10, title: "Cider Orchard Reserve", plantTypeId: 11, requiredHarvests: 24, cashReward: 165000000, soilReward: 210000)
    ]

    static let achievements: [HeapAchievement] = [
        HeapAchievement(id: 0, title: "First Sale", detail: "Earn 100 lifetime cash") { $0.lifetimeCash >= 100 },
        HeapAchievement(id: 1, title: "Bin Row", detail: "Unlock 4 composter bins") { $0.unlockedBinCount >= 4 },
        HeapAchievement(id: 2, title: "Garden Patch", detail: "Unlock 4 garden plots") { $0.unlockedPlotCount >= 4 },
        HeapAchievement(id: 3, title: "Worm Wrangler", detail: "Reach Tiger Worms") { $0.wormTier >= 2 },
        HeapAchievement(id: 4, title: "Crop Collector", detail: "Unlock 6 crops") { $0.unlockedPlants.count >= 6 },
        HeapAchievement(id: 5, title: "Market Regular", detail: "Complete 3 market orders") { $0.completedContractCount >= 3 },
        HeapAchievement(id: 6, title: "Busy Harvester", detail: "Harvest 100 crops") { $0.lifetimeHarvestCount >= 100 },
        HeapAchievement(id: 7, title: "Automation Age", detail: "Buy the Auto-Harvester") { $0.autoHarvest },
        HeapAchievement(id: 8, title: "Turned Soil", detail: "Turn the heap once") { $0.totalHeapTurns >= 1 },
        HeapAchievement(id: 9, title: "Compost Tycoon", detail: "Earn 10M lifetime cash") { $0.lifetimeCash >= 10000000 }
    ]

    static let binNames = [
        "Kitchen Scraps", "Coffee Grounds", "Leaf Mulch", "Fruit Peels", "Grass Clippings",
        "Bakery Waste", "Tea Leaves", "Market Scraps", "Mushroom Log"
    ]

    static let plotNames = [
        "Starter Bed", "Sunny Row", "Herb Patch", "Root Bed", "Vine Row",
        "Flower Corner", "Berry Frame", "Shade Bed", "Orchard Strip"
    ]

    static let maxBins = 9
    static let maxPlots = 9

    static func binName(_ index: Int) -> String {
        index < binNames.count ? binNames[index] : "Bin \(index + 1)"
    }

    static func plotName(_ index: Int) -> String {
        index < plotNames.count ? plotNames[index] : "Plot \(index + 1)"
    }

    static func plantName(_ id: Int) -> String {
        plants.first(where: { $0.id == id })?.name ?? "Crop"
    }
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
    @Published var cropHarvestCounts: [Int: Int] = [:]
    @Published var completedContracts: Set<Int> = []

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
        normalizeLoadedState()
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
    var completedContractCount: Int { completedContracts.count }
    var lifetimeHarvestCount: Int { cropHarvestCounts.values.reduce(0, +) }
    var completedAchievementCount: Int {
        HeapCatalog.achievements.filter { $0.isComplete(self) }.count
    }

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

    func harvestCount(for plantTypeId: Int) -> Int {
        cropHarvestCounts[plantTypeId, default: 0]
    }

    func canCompleteContract(_ contract: CompostContract) -> Bool {
        !completedContracts.contains(contract.id)
            && harvestCount(for: contract.plantTypeId) >= contract.requiredHarvests
    }

    func completeContract(_ contract: CompostContract) {
        guard canCompleteContract(contract) else { return }
        completedContracts.insert(contract.id)
        cash += contract.cashReward
        soil += contract.soilReward
        lifetimeCash += contract.cashReward
        save()
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
        cropHarvestCounts[typeId, default: 0] += 1
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
                cropHarvestCounts[typeId, default: 0] += 1
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
        var cropHarvestCounts: [Int: Int]?
        var completedContracts: [Int]?
    }

    func save() {
        let data = SaveData(
            soil: soil, cash: cash, prestigeMult: prestigeMult, totalHeapTurns: totalHeapTurns,
            decompLevel: decompLevel, yieldLevel: yieldLevel, growthLevel: growthLevel,
            wormTier: wormTier, autoHarvest: autoHarvest, bins: bins, plots: plots,
            selectedPlantId: selectedPlantId, unlockedPlants: Array(unlockedPlants),
            lifetimeCash: lifetimeCash, cropHarvestCounts: cropHarvestCounts,
            completedContracts: Array(completedContracts))
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
        cropHarvestCounts = data.cropHarvestCounts ?? [:]
        completedContracts = Set(data.completedContracts ?? [])
    }

    private func normalizeLoadedState() {
        if bins.count < HeapCatalog.maxBins {
            bins.append(contentsOf: (bins.count..<HeapCatalog.maxBins).map { _ in BinState(unlocked: false, progress: 0) })
        }
        if plots.count < HeapCatalog.maxPlots {
            plots.append(contentsOf: (plots.count..<HeapCatalog.maxPlots).map { _ in PlotState(unlocked: false, plantTypeId: -1, progress: 0) })
        }
        if bins.allSatisfy({ !$0.unlocked }) {
            bins[0].unlocked = true
        }
        if plots.allSatisfy({ !$0.unlocked }) {
            plots[0].unlocked = true
        }
        let validPlantIds = Set(HeapCatalog.plants.map(\.id))
        unlockedPlants = unlockedPlants.intersection(validPlantIds)
        unlockedPlants.insert(0)
        if !unlockedPlants.contains(selectedPlantId) {
            selectedPlantId = 0
        }
        wormTier = min(max(0, wormTier), HeapCatalog.wormTiers.count - 1)
        completedContracts = completedContracts.intersection(Set(HeapCatalog.contracts.map(\.id)))
        cropHarvestCounts = cropHarvestCounts.filter { validPlantIds.contains($0.key) }
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
