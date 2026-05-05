import Foundation

enum MapTool: String, CaseIterable, Identifiable {
    case pan      = "Pan"
    case select   = "Select"
    case measure  = "Measure"
    case buffer   = "Buffer"
    case identify = "Identify"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .pan:      return "hand.point.up.left.fill"
        case .select:   return "cursorarrow.rays"
        case .measure:  return "ruler"
        case .buffer:   return "circle.dashed"
        case .identify: return "info.circle"
        }
    }

    var tooltip: String {
        switch self {
        case .pan:      return "Pan: Drag to navigate the map"
        case .select:   return "Select: Click a feature to select it"
        case .measure:  return "Measure: Click points to measure distance"
        case .buffer:   return "Buffer: Click to create a circular buffer zone"
        case .identify: return "Identify: Click to get feature attributes"
        }
    }
}
