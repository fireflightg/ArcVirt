import MapKit
import SwiftUI
import Combine

class MapViewModel: ObservableObject {
    @Published var layers: [Layer] = []
    @Published var selectedTool: MapTool = .pan
    @Published var mapType: MKMapType = .standard
    @Published var cursorCoordinate = CLLocationCoordinate2D(latitude: 0, longitude: 0)
    @Published var zoomLevel: Double = 0
    @Published var measurePoints: [CLLocationCoordinate2D] = []
    @Published var totalMeasureDistance: Double = 0
    @Published var selectedLayer: Layer?
    @Published var bufferRadius: Double = 50.0
    @Published var statusMessage: String = "Ready — ArcVirt GIS Platform"
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var needsMapUpdate = false

    init() {
        loadSampleData()
    }

    private func loadSampleData() {
        let cities = SampleData.worldCitiesLayer()
        addLayer(cities)
    }

    func addLayer(_ layer: Layer) {
        DispatchQueue.main.async {
            self.layers.append(layer)
            if self.selectedLayer == nil {
                self.selectedLayer = layer
            }
            self.needsMapUpdate = true
        }
    }

    func removeLayer(_ layer: Layer) {
        layers.removeAll { $0.id == layer.id }
        if selectedLayer?.id == layer.id {
            selectedLayer = layers.first
        }
        needsMapUpdate = true
    }

    func moveLayer(from source: IndexSet, to destination: Int) {
        layers.move(fromOffsets: source, toOffset: destination)
        needsMapUpdate = true
    }

    func importGeoJSON(url: URL) {
        isLoading = true
        statusMessage = "Importing \(url.lastPathComponent)..."

        DispatchQueue.global(qos: .userInitiated).async {
            do {
                let data = try Data(contentsOf: url)
                let layer = try GeoJSONParser.parse(data: data, name: url.deletingPathExtension().lastPathComponent)
                DispatchQueue.main.async {
                    self.addLayer(layer)
                    self.isLoading = false
                    self.statusMessage = "Imported \(url.lastPathComponent) — \(layer.featureCount) features"
                }
            } catch {
                DispatchQueue.main.async {
                    self.isLoading = false
                    self.errorMessage = "Failed to import: \(error.localizedDescription)"
                    self.statusMessage = "Import failed"
                }
            }
        }
    }

    func addMeasurePoint(_ coordinate: CLLocationCoordinate2D) {
        measurePoints.append(coordinate)
        if measurePoints.count >= 2 {
            totalMeasureDistance = SpatialAnalysis.totalDistance(coordinates: measurePoints)
            let miles = totalMeasureDistance * 0.621371
            statusMessage = String(format: "Distance: %.2f km (%.2f mi) — %d segment(s)",
                                   totalMeasureDistance, miles, measurePoints.count - 1)
        } else {
            statusMessage = "Click another point to measure distance"
        }
    }

    func clearMeasurement() {
        measurePoints.removeAll()
        totalMeasureDistance = 0
        statusMessage = "Measurement cleared"
    }

    func addBufferLayer(center: CLLocationCoordinate2D) {
        let buffer = SpatialAnalysis.createBuffer(center: center, radiusKm: bufferRadius)
        buffer.name = String(format: "Buffer %.0f km", bufferRadius)
        addLayer(buffer)
        statusMessage = String(format: "Buffer created: %.0f km radius at %.4f, %.4f",
                               bufferRadius, center.latitude, center.longitude)
    }
}
