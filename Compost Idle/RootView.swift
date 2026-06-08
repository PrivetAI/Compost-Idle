import SwiftUI

struct RootView: View {
    @StateObject private var engine = HeapEngine()
    @Environment(\.scenePhase) private var scenePhase
    @State private var selectedTab = 0
    @State private var offlineSummary: (soil: Double, seconds: Double)? = nil

    var body: some View {
        ZStack {
            HeapTheme.background.edgesIgnoringSafeArea(.all)
            VStack(spacing: 0) {
                Group {
                    switch selectedTab {
                    case 0:
                        NavigationView { ComposterView(engine: engine) }
                            .navigationViewStyle(StackNavigationViewStyle())
                    case 1:
                        NavigationView { GardenView(engine: engine) }
                            .navigationViewStyle(StackNavigationViewStyle())
                    case 2:
                        NavigationView { ShopView(engine: engine) }
                            .navigationViewStyle(StackNavigationViewStyle())
                    default:
                        NavigationView { SettingsView(engine: engine) }
                            .navigationViewStyle(StackNavigationViewStyle())
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)

                tabBar
            }

            if let summary = offlineSummary {
                offlineOverlay(summary)
            }
        }
        .environment(\.colorScheme, .light)
        .onAppear { offlineSummary = engine.consumeOfflineSummary() }
        .onChange(of: scenePhase) { phase in
            // Stamp lastActive ONLY on .background — .inactive fires on both
            // directions and would zero the offline credit.
            if phase == .background {
                engine.stampLastActive()
            }
        }
    }

    private var tabBar: some View {
        HStack(spacing: 0) {
            tabButton(0, "Compost", AnyView(BinIcon(size: 26, color: tabTint(0))))
            tabButton(1, "Garden", AnyView(GardenIcon(size: 26, color: tabTint(1))))
            tabButton(2, "Shop", AnyView(ShopIcon(size: 26, color: tabTint(2))))
            tabButton(3, "More", AnyView(GearIcon(size: 26, color: tabTint(3))))
        }
        .padding(.top, 8)
        .padding(.bottom, 4)
        .background(HeapTheme.cardBackground.edgesIgnoringSafeArea(.bottom))
        .overlay(Rectangle().fill(HeapTheme.divider).frame(height: 1), alignment: .top)
    }

    private func tabTint(_ i: Int) -> Color {
        selectedTab == i ? HeapTheme.accent : HeapTheme.textSoft.opacity(0.55)
    }

    private func tabButton(_ index: Int, _ label: String, _ icon: AnyView) -> some View {
        Button(action: { selectedTab = index }) {
            VStack(spacing: 4) {
                icon.frame(height: 28)
                Text(label)
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundColor(tabTint(index))
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(PlainButtonStyle())
    }

    private func offlineOverlay(_ summary: (soil: Double, seconds: Double)) -> some View {
        ZStack {
            Color.black.opacity(0.45).edgesIgnoringSafeArea(.all)
                .onTapGesture { offlineSummary = nil }
            VStack(spacing: 16) {
                CycleIcon(size: 54, color: HeapTheme.leafDark)
                Text("Welcome Back!")
                    .font(.system(size: 22, weight: .heavy, design: .rounded))
                    .foregroundColor(HeapTheme.text)
                Text("Your heap kept working for \(HeapFormat.time(summary.seconds)).")
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundColor(HeapTheme.textSoft)
                    .multilineTextAlignment(.center)
                HStack(spacing: 8) {
                    SoilIcon(size: 28)
                    Text("+\(HeapFormat.short(summary.soil)) soil")
                        .font(.system(size: 18, weight: .heavy, design: .rounded))
                        .foregroundColor(HeapTheme.soil)
                }
                .padding(.horizontal, 16).padding(.vertical, 10)
                .background(HeapTheme.panel.opacity(0.5))
                .cornerRadius(12)
                Button(action: { offlineSummary = nil }) {
                    Text("Collect")
                        .font(.system(size: 16, weight: .heavy, design: .rounded))
                        .foregroundColor(HeapTheme.cardBackground)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(HeapTheme.leafDark)
                        .cornerRadius(13)
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding(24)
            .frame(maxWidth: 320)
            .background(HeapTheme.cardBackground)
            .cornerRadius(22)
            .overlay(RoundedRectangle(cornerRadius: 22).stroke(HeapTheme.divider, lineWidth: 1))
            .padding(30)
        }
    }
}
