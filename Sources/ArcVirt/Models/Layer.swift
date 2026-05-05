import MapKit
import SwiftUI

class Layer: ObservableObject, Identifiable {
    let id = UUID()
    @Published var name: String
    @Published var isVisible: Bool = true
    @Published var opacity: Double = 1.0
    @Published var fillColor: Color = .blue
    @Published var strokeColor: Color = .black
    @Published var strokeWidth: Double = 2.0

    var features: [GeoFeature] = []
    var overlays: [MKOverlay] = []
    var annotations: [MKAnnotation] = []
    var layerType: LayerType

    enum LayerType {
        case point, line, polygon, mixed
    }

    init(name: String, layerType: LayerType = .mixed) {
        self.name = name
        self.layerType = layerType
    }

    var featureCount: Int { features.count }

    var typeDescription: String {
        switch layerType {
        case .point:   return "Point"
        case .line:    return "Line"
        case .polygon: return "Polygon"
        case .mixed:   return "Mixed"
        }
    }

    var layerIcon: String {
        switch layerType {
        case .point:   return "mappin.circle.fill"
        case .line:    return "line.diagonal"
        case .polygon: return "square.fill"
        case .mixed:   return "map.fill"
        }
    }
}
