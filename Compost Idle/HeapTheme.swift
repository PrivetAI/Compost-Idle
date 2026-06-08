import SwiftUI

// Centralized, theme-independent palette. Colors are fixed RGB values so the
// app never shifts with the device's light/dark appearance.
enum HeapTheme {
    static let background = Color(red: 0.93, green: 0.91, blue: 0.84)   // warm parchment
    static let cardBackground = Color(red: 0.99, green: 0.98, blue: 0.94)
    static let panel = Color(red: 0.87, green: 0.83, blue: 0.72)

    static let soil = Color(red: 0.36, green: 0.25, blue: 0.16)         // dark earth
    static let soilLight = Color(red: 0.52, green: 0.38, blue: 0.25)
    static let leaf = Color(red: 0.30, green: 0.55, blue: 0.25)         // plant green
    static let leafDark = Color(red: 0.18, green: 0.40, blue: 0.18)
    static let waste = Color(red: 0.62, green: 0.55, blue: 0.30)        // peel / scrap
    static let gold = Color(red: 0.86, green: 0.65, blue: 0.18)         // money
    static let goldDeep = Color(red: 0.70, green: 0.48, blue: 0.10)
    static let worm = Color(red: 0.82, green: 0.45, blue: 0.45)

    static let text = Color(red: 0.20, green: 0.16, blue: 0.10)
    static let textSoft = Color(red: 0.40, green: 0.35, blue: 0.27)
    static let accent = Color(red: 0.30, green: 0.55, blue: 0.25)
    static let divider = Color(red: 0.78, green: 0.73, blue: 0.62)
    static let danger = Color(red: 0.78, green: 0.32, blue: 0.22)
    static let progressTrack = Color(red: 0.80, green: 0.76, blue: 0.66)
}

// Compact number formatting (1.2K, 3.4M, ...). Keeps HUD readable as the
// economy snowballs.
enum HeapFormat {
    static func short(_ value: Double) -> String {
        let v = value
        if v < 0 { return "-" + short(-v) }
        if v < 1000 { return String(format: v == floor(v) ? "%.0f" : "%.1f", v) }
        let units = ["", "K", "M", "B", "T", "Qa", "Qi", "Sx", "Sp", "Oc", "No", "Dc"]
        var idx = 0
        var n = v
        while n >= 1000 && idx < units.count - 1 {
            n /= 1000
            idx += 1
        }
        if n >= 100 { return String(format: "%.0f%@", n, units[idx]) }
        return String(format: "%.2f%@", n, units[idx])
    }

    static func time(_ seconds: Double) -> String {
        if seconds <= 0 { return "ready" }
        let s = Int(seconds.rounded())
        if s < 60 { return "\(s)s" }
        let m = s / 60
        let rs = s % 60
        if m < 60 { return "\(m)m \(rs)s" }
        let h = m / 60
        let rm = m % 60
        if h < 24 { return "\(h)h \(rm)m" }
        let d = h / 24
        let rh = h % 24
        return "\(d)d \(rh)h"
    }
}
