import SwiftUI

// All icons are hand-drawn SwiftUI shapes — no SF Symbols, no emoji.

struct BinIcon: View {
    var size: CGFloat
    var color: Color = HeapTheme.soil
    var body: some View {
        Canvas { ctx, sz in
            let w = sz.width, h = sz.height
            // Lid
            var lid = Path()
            lid.addRoundedRect(in: CGRect(x: w*0.12, y: h*0.16, width: w*0.76, height: h*0.12),
                               cornerSize: CGSize(width: w*0.05, height: w*0.05))
            ctx.fill(lid, with: .color(color))
            // Handle
            var handle = Path()
            handle.addRoundedRect(in: CGRect(x: w*0.42, y: h*0.08, width: w*0.16, height: h*0.10),
                                  cornerSize: CGSize(width: w*0.03, height: w*0.03))
            ctx.fill(handle, with: .color(color))
            // Body (tapered)
            var body = Path()
            body.move(to: CGPoint(x: w*0.20, y: h*0.30))
            body.addLine(to: CGPoint(x: w*0.80, y: h*0.30))
            body.addLine(to: CGPoint(x: w*0.72, y: h*0.90))
            body.addLine(to: CGPoint(x: w*0.28, y: h*0.90))
            body.closeSubpath()
            ctx.fill(body, with: .color(color))
            // Vertical ribs
            for f in [0.40, 0.55, 0.70] {
                var rib = Path()
                rib.move(to: CGPoint(x: w*f, y: h*0.34))
                rib.addLine(to: CGPoint(x: w*(f-0.02), y: h*0.86))
                ctx.stroke(rib, with: .color(HeapTheme.cardBackground.opacity(0.5)), lineWidth: w*0.025)
            }
        }
        .frame(width: size, height: size)
    }
}

struct SoilIcon: View {
    var size: CGFloat
    var color: Color = HeapTheme.soil
    var body: some View {
        Canvas { ctx, sz in
            let w = sz.width, h = sz.height
            // Mound
            var mound = Path()
            mound.move(to: CGPoint(x: w*0.08, y: h*0.82))
            mound.addQuadCurve(to: CGPoint(x: w*0.92, y: h*0.82),
                               control: CGPoint(x: w*0.50, y: h*0.30))
            mound.closeSubpath()
            ctx.fill(mound, with: .color(color))
            // Speckles
            for p in [(0.35,0.62),(0.55,0.55),(0.45,0.72),(0.65,0.68),(0.30,0.75)] {
                let r = w*0.04
                let dot = Path(ellipseIn: CGRect(x: w*p.0 - r, y: h*p.1 - r, width: r*2, height: r*2))
                ctx.fill(dot, with: .color(HeapTheme.soilLight))
            }
        }
        .frame(width: size, height: size)
    }
}

struct LeafIcon: View {
    var size: CGFloat
    var color: Color = HeapTheme.leaf
    var body: some View {
        Canvas { ctx, sz in
            let w = sz.width, h = sz.height
            var leaf = Path()
            leaf.move(to: CGPoint(x: w*0.5, y: h*0.92))
            leaf.addQuadCurve(to: CGPoint(x: w*0.5, y: h*0.08),
                              control: CGPoint(x: w*0.05, y: h*0.40))
            leaf.addQuadCurve(to: CGPoint(x: w*0.5, y: h*0.92),
                              control: CGPoint(x: w*0.95, y: h*0.40))
            ctx.fill(leaf, with: .color(color))
            var vein = Path()
            vein.move(to: CGPoint(x: w*0.5, y: h*0.88))
            vein.addLine(to: CGPoint(x: w*0.5, y: h*0.16))
            ctx.stroke(vein, with: .color(HeapTheme.leafDark), lineWidth: w*0.03)
        }
        .frame(width: size, height: size)
    }
}

struct CoinIcon: View {
    var size: CGFloat
    var color: Color = HeapTheme.gold
    var body: some View {
        Canvas { ctx, sz in
            let w = sz.width, h = sz.height
            let outer = Path(ellipseIn: CGRect(x: w*0.10, y: h*0.10, width: w*0.80, height: h*0.80))
            ctx.fill(outer, with: .color(color))
            let inner = Path(ellipseIn: CGRect(x: w*0.22, y: h*0.22, width: w*0.56, height: h*0.56))
            ctx.stroke(inner, with: .color(HeapTheme.goldDeep), lineWidth: w*0.04)
            // A simple leaf glyph in the center (fits the theme)
            var g = Path()
            g.move(to: CGPoint(x: w*0.5, y: h*0.66))
            g.addQuadCurve(to: CGPoint(x: w*0.5, y: h*0.34), control: CGPoint(x: w*0.34, y: h*0.46))
            g.addQuadCurve(to: CGPoint(x: w*0.5, y: h*0.66), control: CGPoint(x: w*0.66, y: h*0.46))
            ctx.fill(g, with: .color(HeapTheme.goldDeep))
        }
        .frame(width: size, height: size)
    }
}

struct WormIcon: View {
    var size: CGFloat
    var color: Color = HeapTheme.worm
    var body: some View {
        Canvas { ctx, sz in
            let w = sz.width, h = sz.height
            var body = Path()
            body.move(to: CGPoint(x: w*0.14, y: h*0.70))
            body.addCurve(to: CGPoint(x: w*0.86, y: h*0.40),
                          control1: CGPoint(x: w*0.35, y: h*0.10),
                          control2: CGPoint(x: w*0.60, y: h*0.95))
            ctx.stroke(body, with: .color(color),
                       style: StrokeStyle(lineWidth: w*0.16, lineCap: .round))
            let eye = Path(ellipseIn: CGRect(x: w*0.80, y: h*0.36, width: w*0.07, height: h*0.07))
            ctx.fill(eye, with: .color(HeapTheme.text))
        }
        .frame(width: size, height: size)
    }
}

// Plant rendered at a given maturity (sprout -> full plant).
struct PlantGrowthIcon: View {
    var size: CGFloat
    var progress: Double   // 0...1
    var typeId: Int
    var body: some View {
        Canvas { ctx, sz in
            let w = sz.width, h = sz.height
            let p = max(0.05, min(1.0, progress))
            // Stem
            let topY = h * (0.85 - 0.55 * p)
            var stem = Path()
            stem.move(to: CGPoint(x: w*0.5, y: h*0.85))
            stem.addLine(to: CGPoint(x: w*0.5, y: topY))
            ctx.stroke(stem, with: .color(HeapTheme.leafDark),
                       style: StrokeStyle(lineWidth: w*0.05, lineCap: .round))
            // Leaves grow with progress
            let leafSpan = w * 0.16 * p
            if p > 0.15 {
                var l = Path()
                l.move(to: CGPoint(x: w*0.5, y: h*0.62))
                l.addQuadCurve(to: CGPoint(x: w*0.5 - leafSpan, y: h*0.50),
                               control: CGPoint(x: w*0.5 - leafSpan, y: h*0.62))
                l.addQuadCurve(to: CGPoint(x: w*0.5, y: h*0.62),
                               control: CGPoint(x: w*0.5 - leafSpan*0.4, y: h*0.52))
                ctx.fill(l, with: .color(HeapTheme.leaf))
                var r = Path()
                r.move(to: CGPoint(x: w*0.5, y: h*0.62))
                r.addQuadCurve(to: CGPoint(x: w*0.5 + leafSpan, y: h*0.50),
                               control: CGPoint(x: w*0.5 + leafSpan, y: h*0.62))
                r.addQuadCurve(to: CGPoint(x: w*0.5, y: h*0.62),
                               control: CGPoint(x: w*0.5 + leafSpan*0.4, y: h*0.52))
                ctx.fill(r, with: .color(HeapTheme.leaf))
            }
            // Crown / fruit when mature, color by type
            if p > 0.55 {
                let crownColors: [Color] = [
                    Color(red: 0.80, green: 0.30, blue: 0.30),  // radish
                    Color(red: 0.40, green: 0.62, blue: 0.30),  // lettuce
                    Color(red: 0.88, green: 0.42, blue: 0.14),  // carrot
                    Color(red: 0.84, green: 0.28, blue: 0.20),  // tomato
                    Color(red: 0.72, green: 0.20, blue: 0.14),  // pepper
                    Color(red: 0.88, green: 0.52, blue: 0.16),  // pumpkin
                    Color(red: 0.92, green: 0.74, blue: 0.18),  // sunflower
                    Color(red: 0.24, green: 0.34, blue: 0.72),  // blueberry
                    Color(red: 0.58, green: 0.42, blue: 0.78),  // lavender
                    Color(red: 0.70, green: 0.58, blue: 0.46),  // mushroom
                    Color(red: 0.34, green: 0.62, blue: 0.30),  // melon
                    Color(red: 0.66, green: 0.30, blue: 0.55)   // orchard
                ]
                let c = crownColors[max(0, min(crownColors.count-1, typeId))]
                let r = w * 0.16 * ((p - 0.55) / 0.45)
                let crown = Path(ellipseIn: CGRect(x: w*0.5 - r, y: topY - r*0.6, width: r*2, height: r*2))
                ctx.fill(crown, with: .color(c))
            }
        }
        .frame(width: size, height: size)
    }
}

// Generic shop / nav glyphs

struct GearIcon: View {
    var size: CGFloat
    var color: Color
    var body: some View {
        Canvas { ctx, sz in
            let w = sz.width, h = sz.height
            let cx = w*0.5, cy = h*0.5
            let outer = w*0.40, inner = w*0.30
            var teeth = Path()
            let count = 8
            for i in 0..<(count*2) {
                let r = i % 2 == 0 ? outer : inner
                let a = Double(i) / Double(count*2) * 2 * .pi
                let pt = CGPoint(x: cx + cos(a)*r, y: cy + sin(a)*r)
                if i == 0 { teeth.move(to: pt) } else { teeth.addLine(to: pt) }
            }
            teeth.closeSubpath()
            ctx.fill(teeth, with: .color(color))
            let hole = Path(ellipseIn: CGRect(x: cx - w*0.12, y: cy - w*0.12, width: w*0.24, height: w*0.24))
            ctx.blendMode = .clear
            ctx.fill(hole, with: .color(.black))
        }
        .frame(width: size, height: size)
    }
}

struct ShopIcon: View {
    var size: CGFloat
    var color: Color
    var body: some View {
        Canvas { ctx, sz in
            let w = sz.width, h = sz.height
            // Awning
            var awning = Path()
            awning.move(to: CGPoint(x: w*0.10, y: h*0.40))
            awning.addLine(to: CGPoint(x: w*0.90, y: h*0.40))
            awning.addLine(to: CGPoint(x: w*0.82, y: h*0.22))
            awning.addLine(to: CGPoint(x: w*0.18, y: h*0.22))
            awning.closeSubpath()
            ctx.fill(awning, with: .color(color))
            // Body
            var b = Path()
            b.addRect(CGRect(x: w*0.16, y: h*0.40, width: w*0.68, height: h*0.46))
            ctx.fill(b, with: .color(color.opacity(0.7)))
            // Door
            var d = Path()
            d.addRect(CGRect(x: w*0.42, y: h*0.54, width: w*0.16, height: h*0.32))
            ctx.fill(d, with: .color(HeapTheme.cardBackground))
        }
        .frame(width: size, height: size)
    }
}

struct CycleIcon: View {   // for prestige "turn the heap"
    var size: CGFloat
    var color: Color
    var body: some View {
        Canvas { ctx, sz in
            let w = sz.width, h = sz.height
            let cx = w*0.5, cy = h*0.5
            let r = w*0.32
            var arc = Path()
            arc.addArc(center: CGPoint(x: cx, y: cy), radius: r,
                       startAngle: .degrees(-50), endAngle: .degrees(220), clockwise: false)
            ctx.stroke(arc, with: .color(color), style: StrokeStyle(lineWidth: w*0.10, lineCap: .round))
            // Arrowhead
            var head = Path()
            let a = Angle.degrees(-50).radians
            let tip = CGPoint(x: cx + cos(a)*r, y: cy + sin(a)*r)
            head.move(to: tip)
            head.addLine(to: CGPoint(x: tip.x - w*0.04, y: tip.y - w*0.14))
            head.addLine(to: CGPoint(x: tip.x + w*0.14, y: tip.y - w*0.04))
            head.closeSubpath()
            ctx.fill(head, with: .color(color))
        }
        .frame(width: size, height: size)
    }
}

struct GardenIcon: View {
    var size: CGFloat
    var color: Color
    var body: some View {
        Canvas { ctx, sz in
            let w = sz.width, h = sz.height
            // Ground
            var g = Path()
            g.addRoundedRect(in: CGRect(x: w*0.10, y: h*0.62, width: w*0.80, height: h*0.24),
                             cornerSize: CGSize(width: w*0.04, height: w*0.04))
            ctx.fill(g, with: .color(color.opacity(0.55)))
            // Two sprouts
            for fx in [0.35, 0.65] {
                var stem = Path()
                stem.move(to: CGPoint(x: w*fx, y: h*0.64))
                stem.addLine(to: CGPoint(x: w*fx, y: h*0.30))
                ctx.stroke(stem, with: .color(color), style: StrokeStyle(lineWidth: w*0.04, lineCap: .round))
                let bud = Path(ellipseIn: CGRect(x: w*fx - w*0.07, y: h*0.20, width: w*0.14, height: w*0.14))
                ctx.fill(bud, with: .color(color))
            }
        }
        .frame(width: size, height: size)
    }
}
