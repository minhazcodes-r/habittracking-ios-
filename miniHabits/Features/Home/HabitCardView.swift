import SwiftUI

struct HabitCardView: View {
    let item: HabitWithProgress
    let onDone: () -> Void
    let onIncrement: (Double) -> Void

    private var h: Habit { item.habit }
    private var isBoolean: Bool { h.metricType == "boolean" }
    private var isDone: Bool { item.current >= h.goal }
    private var progress: Double { min(item.current / max(h.goal, 1), 1) }
    private var unitLabel: String { displayUnit(h.metricType, h.unit) }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 12) {
                Image(systemName: sfSymbol(for: h.icon))
                    .font(.body).foregroundColor(hexColor(h.color))
                    .frame(width: 40, height: 40)
                    .background(hexColor(h.color).opacity(0.15))
                    .clipShape(Circle())
                VStack(alignment: .leading, spacing: 2) {
                    Text(h.name).font(.bodyMedium).foregroundColor(.white)
                    Text(h.category.capitalized).font(.caption2).foregroundColor(.mutedForeground)
                }
                Spacer()
            }

            if isBoolean {
                Text(isDone ? "Done" : "Not done")
                    .font(.caption2).fontWeight(.medium)
                    .foregroundColor(isDone ? .green : .mutedForeground)
            } else {
                VStack(spacing: 8) {
                    HStack {
                        Text("Progress").font(.caption2).foregroundColor(.mutedForeground)
                        Spacer()
                        Text("\(Int(item.current)) / \(Int(h.goal))\(unitLabel.isEmpty ? "" : " \(unitLabel)")")
                            .font(.caption2).foregroundColor(.white)
                    }
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule().fill(Color.secondaryBg).frame(height: 6)
                            Capsule().fill(hexColor(h.color))
                                .frame(width: geo.size.width * progress, height: 6)
                        }
                    }.frame(height: 6)
                }
            }

            HStack(spacing: 8) {
                Button { onDone() } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "checkmark.circle.fill").font(.caption)
                        Text(isDone ? "Done" : "Complete").font(.caption2).fontWeight(.medium)
                    }
                    .frame(maxWidth: .infinity).padding(.vertical, 10)
                    .background(isDone ? Color.green.opacity(0.2) : Color.secondaryBg)
                    .foregroundColor(isDone ? .green : .white)
                    .cornerRadius(12)
                }

                if !isBoolean {
                    Button { onIncrement(h.increments.first ?? 10) } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "plus").font(.caption)
                            Text("+\(Int(h.increments.first ?? 10))\(unitLabel.isEmpty ? "" : " \(unitLabel)")")
                                .font(.caption2).fontWeight(.medium)
                        }
                        .frame(maxWidth: .infinity).padding(.vertical, 10)
                        .background(Color.secondaryBg).foregroundColor(.white)
                        .cornerRadius(12)
                    }
                }
            }
        }
        .padding(24)
        .background(Color.card)
        .cornerRadius(16)
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.borderColor))
    }
}
