import MapKit
import SwiftUI

struct SpatialAnalysis {

    // MARK: - Distance

    /// Haversine formula — returns distance in kilometres
    static func distance(from: CLLocationCoordinate2D, to: CLLocationCoordinate2D) -> Double {
        let R    = 6371.0
        let dLat = (to.latitude  - from.latitude)  * .pi / 180
        let dLon = (to.longitude - from.longitude) * .pi / 180
        let lat1 = from.latitude  * .pi / 180
        let lat2 = to.latitude    * .pi / 180
        let a    = sin(dLat/2)*sin(dLat/2) + cos(lat1)*cos(lat2)*sin(dLon/2)*sin(dLon/2)
        return R * 2 * atan2(sqrt(a), sqrt(1 - a))
    }

    static func totalDistance(coordinates: [CLLocationCoordinate2D]) -> Double {
        guard coordinates.count >= 2 else { return 0 }
        return zip(coordinates, coordinates.dropFirst()).reduce(0) { $0 + distance(from: $1.0, to: $1.1) }
    }

    // MARK: - Buffer

    /// Approximate circular buffer as a polygon layer
    static func createBuffer(center: CLLocationCoordinate2D, radiusKm: Double) -> Layer {
        let layer = Layer(name: "Buffer", layerType: .polygon)
        let n     = 72
        var coords = (0..<n).map { i -> CLLocationCoordinate2D in
            let angle = 2 * Double.pi * Double(i) / Double(n)
            let dLat  = (radiusKm / 6371.0) * cos(angle) * 180 / .pi
            let dLon  = (radiusKm / 6371.0) * sin(angle) / cos(center.latitude * .pi / 180) * 180 / .pi
            return CLLocationCoordinate2D(latitude: center.latitude + dLat, longitude: center.longitude + dLon)
        }
        coords.append(coords[0]) // close the ring

        var coordsCopy = coords
        layer.overlays  = [MKPolygon(coordinates: &coordsCopy, count: coordsCopy.count)]
        layer.features  = [GeoFeature(geometry: .polygon(coords, holes: []))]
        layer.fillColor   = .cyan
        layer.strokeColor = .blue
        layer.opacity     = 0.4
        return layer
    }

    // MARK: - Bounding region

    static func boundingRegion(for features: [GeoFeature]) -> MKCoordinateRegion? {
        var coords: [CLLocationCoordinate2D] = []
        for f in features {
            switch f.geometry {
            case .point(let c):             coords.append(c)
            case .lineString(let cs):       coords.append(contentsOf: cs)
            case .polygon(let o, _):        coords.append(contentsOf: o)
            case .multiPoint(let cs):       coords.append(contentsOf: cs)
            case .multiLineString(let ls):  ls.forEach  { coords.append(contentsOf: $0) }
            case .multiPolygon(let ps):     ps.forEach  { coords.append(contentsOf: $0) }
            }
        }
        guard !coords.isEmpty else { return nil }

        let lats = coords.map { $0.latitude }
        let lons = coords.map { $0.longitude }
        let center = CLLocationCoordinate2D(
            latitude:  (lats.min()! + lats.max()!) / 2,
            longitude: (lons.min()! + lons.max()!) / 2
        )
        let span = MKCoordinateSpan(
            latitudeDelta:  max((lats.max()! - lats.min()!) * 1.3, 0.05),
            longitudeDelta: max((lons.max()! - lons.min()!) * 1.3, 0.05)
        )
        return MKCoordinateRegion(center: center, span: span)
    }
}
