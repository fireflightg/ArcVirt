import MapKit
import SwiftUI
import Foundation

enum GeoJSONError: Error, LocalizedError {
    case invalidFormat
    case unsupportedGeometry(String)
    case missingCoordinates

    var errorDescription: String? {
        switch self {
        case .invalidFormat:               return "Invalid GeoJSON format"
        case .unsupportedGeometry(let t):  return "Unsupported geometry: \(t)"
        case .missingCoordinates:          return "Missing or invalid coordinates"
        }
    }
}

struct GeoJSONParser {

    static func parse(data: Data, name: String) throws -> Layer {
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw GeoJSONError.invalidFormat
        }

        var rawFeatures: [GeoFeature] = []

        switch json["type"] as? String ?? "" {
        case "FeatureCollection":
            rawFeatures = (json["features"] as? [[String: Any]] ?? []).compactMap { try? parseFeature($0) }
        case "Feature":
            if let f = try? parseFeature(json) { rawFeatures = [f] }
        default:
            if let g = try? parseGeometry(json) {
                rawFeatures = [GeoFeature(geometry: g)]
            } else {
                throw GeoJSONError.invalidFormat
            }
        }

        let layer = Layer(name: name)
        layer.features    = rawFeatures
        layer.overlays    = buildOverlays(for: rawFeatures)
        layer.annotations = buildAnnotations(for: rawFeatures)
        layer.layerType   = determineType(from: rawFeatures)
        layer.fillColor   = defaultFill(for: layer.layerType)
        layer.strokeColor = defaultStroke(for: layer.layerType)
        return layer
    }

    // MARK: - Private Parsers

    private static func parseFeature(_ json: [String: Any]) throws -> GeoFeature {
        guard let geomJson = json["geometry"] as? [String: Any] else { throw GeoJSONError.invalidFormat }
        let geometry   = try parseGeometry(geomJson)
        let properties = json["properties"] as? [String: Any] ?? [:]
        return GeoFeature(geometry: geometry, properties: properties)
    }

    private static func parseGeometry(_ json: [String: Any]) throws -> GeoGeometry {
        guard let type = json["type"] as? String else { throw GeoJSONError.invalidFormat }

        switch type {
        case "Point":
            let c = json["coordinates"] as? [Double] ?? []
            guard c.count >= 2 else { throw GeoJSONError.missingCoordinates }
            return .point(CLLocationCoordinate2D(latitude: c[1], longitude: c[0]))

        case "LineString":
            let coords = coordArray(json["coordinates"])
            guard !coords.isEmpty else { throw GeoJSONError.missingCoordinates }
            return .lineString(coords)

        case "Polygon":
            guard let rings = json["coordinates"] as? [[[Double]]], let outer = rings.first else {
                throw GeoJSONError.missingCoordinates
            }
            let outerCoords = outer.compactMap { coord($0) }
            let holes       = rings.dropFirst().map { $0.compactMap { coord($0) } }
            return .polygon(outerCoords, holes: holes)

        case "MultiPoint":
            return .multiPoint(coordArray(json["coordinates"]))

        case "MultiLineString":
            let lines = (json["coordinates"] as? [[[Double]]] ?? []).map { $0.compactMap { coord($0) } }
            return .multiLineString(lines)

        case "MultiPolygon":
            let polys = (json["coordinates"] as? [[[[Double]]]] ?? []).map { poly -> [CLLocationCoordinate2D] in
                (poly.first ?? []).compactMap { coord($0) }
            }
            return .multiPolygon(polys)

        case "GeometryCollection":
            let geoms = json["geometries"] as? [[String: Any]] ?? []
            if let first = geoms.first, let g = try? parseGeometry(first) { return g }
            throw GeoJSONError.unsupportedGeometry("Empty GeometryCollection")

        default:
            throw GeoJSONError.unsupportedGeometry(type)
        }
    }

    // MARK: - Coordinate helpers

    private static func coord(_ arr: [Double]) -> CLLocationCoordinate2D? {
        guard arr.count >= 2 else { return nil }
        return CLLocationCoordinate2D(latitude: arr[1], longitude: arr[0])
    }

    private static func coordArray(_ raw: Any?) -> [CLLocationCoordinate2D] {
        (raw as? [[Double]] ?? []).compactMap { coord($0) }
    }

    // MARK: - Overlay / Annotation builders

    private static func buildOverlays(for features: [GeoFeature]) -> [MKOverlay] {
        var result: [MKOverlay] = []
        for feature in features {
            switch feature.geometry {
            case .lineString(let cs):
                var c = cs; result.append(MKPolyline(coordinates: &c, count: c.count))

            case .polygon(let outer, let holes):
                var oc = outer
                if holes.isEmpty {
                    result.append(MKPolygon(coordinates: &oc, count: oc.count))
                } else {
                    let holePolys = holes.map { h -> MKPolygon in var hc = h; return MKPolygon(coordinates: &hc, count: hc.count) }
                    result.append(MKPolygon(coordinates: &oc, count: oc.count, interiorPolygons: holePolys))
                }

            case .multiLineString(let lines):
                for var line in lines { result.append(MKPolyline(coordinates: &line, count: line.count)) }

            case .multiPolygon(let polys):
                for var poly in polys { result.append(MKPolygon(coordinates: &poly, count: poly.count)) }

            default: break
            }
        }
        return result
    }

    private static func buildAnnotations(for features: [GeoFeature]) -> [MKAnnotation] {
        var result: [MKAnnotation] = []
        for feature in features {
            switch feature.geometry {
            case .point(let c):
                result.append(FeatureAnnotation(coordinate: c, properties: feature.properties))
            case .multiPoint(let cs):
                cs.forEach { result.append(FeatureAnnotation(coordinate: $0, properties: feature.properties)) }
            default: break
            }
        }
        return result
    }

    // MARK: - Helpers

    private static func determineType(from features: [GeoFeature]) -> Layer.LayerType {
        var p = false, l = false, poly = false
        for f in features {
            switch f.geometry {
            case .point, .multiPoint:           p    = true
            case .lineString, .multiLineString: l    = true
            case .polygon, .multiPolygon:       poly = true
            }
        }
        if p && !l && !poly { return .point }
        if l && !p && !poly { return .line }
        if poly && !p && !l { return .polygon }
        return .mixed
    }

    private static func defaultFill(for type: Layer.LayerType) -> Color {
        switch type {
        case .point:   return .red
        case .line:    return .blue
        case .polygon: return .green
        case .mixed:   return .purple
        }
    }

    private static func defaultStroke(for type: Layer.LayerType) -> Color {
        switch type {
        case .point:   return .red
        case .line:    return .blue
        case .polygon: return Color(nsColor: .darkGray)
        case .mixed:   return .purple
        }
    }
}

// MARK: - FeatureAnnotation

class FeatureAnnotation: NSObject, MKAnnotation {
    let coordinate: CLLocationCoordinate2D
    let properties: [String: Any]

    var title: String? {
        for key in ["name", "NAME", "label", "title", "id", "ID", "nom", "nombre"] {
            if let v = properties[key] as? String, !v.isEmpty { return v }
        }
        return "Feature"
    }

    var subtitle: String? {
        if let pop = properties["population"] as? Int { return "Pop: \(pop.formatted())" }
        if let t = properties["type"] as? String      { return t }
        if let d = properties["description"] as? String { return d }
        return nil
    }

    init(coordinate: CLLocationCoordinate2D, properties: [String: Any]) {
        self.coordinate = coordinate
        self.properties = properties
    }
}
