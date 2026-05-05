import MapKit

struct GeoFeature: Identifiable {
    let id = UUID()
    let geometry: GeoGeometry
    var properties: [String: Any]

    init(geometry: GeoGeometry, properties: [String: Any] = [:]) {
        self.geometry = geometry
        self.properties = properties
    }
}

enum GeoGeometry {
    case point(CLLocationCoordinate2D)
    case lineString([CLLocationCoordinate2D])
    case polygon([CLLocationCoordinate2D], holes: [[CLLocationCoordinate2D]])
    case multiPoint([CLLocationCoordinate2D])
    case multiLineString([[CLLocationCoordinate2D]])
    case multiPolygon([[CLLocationCoordinate2D]])
}
