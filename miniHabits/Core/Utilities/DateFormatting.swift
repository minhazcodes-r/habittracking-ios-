import Foundation

func toLocalDateStr(_ date: Date) -> String {
    let c = Calendar.current.dateComponents([.year, .month, .day], from: date)
    return String(format: "%04d-%02d-%02d", c.year!, c.month!, c.day!)
}

func displayUnit(_ metricType: String, _ unit: String) -> String {
    switch metricType {
    case "boolean": return ""
    case "count": return "times"
    case "duration": return "min"
    default: return unit
    }
}
