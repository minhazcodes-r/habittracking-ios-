import Foundation

let iconOptions: [String: String] = [
    "droplet": "drop.fill",
    "dumbbell": "dumbbell.fill",
    "book": "book.fill",
    "target": "target",
    "brain": "brain.head.profile",
    "dollar": "dollarsign.circle.fill",
    "heart": "heart.fill",
    "flame": "flame.fill",
    "moon": "moon.fill",
    "sun": "sun.max.fill",
    "coffee": "cup.and.saucer.fill",
    "music": "music.note",
    "bike": "bicycle",
    "footprints": "figure.walk",
    "apple": "leaf.fill",
    "pill": "pills.fill",
    "clock": "clock.fill",
    "circle": "circle.fill",
]

let colorOptions: [String] = [
    "#ffffff", "#ef4444", "#f97316", "#eab308",
    "#22c55e", "#06b6d4", "#3b82f6", "#8b5cf6", "#ec4899",
]

func sfSymbol(for key: String) -> String {
    iconOptions[key] ?? "circle.fill"
}
