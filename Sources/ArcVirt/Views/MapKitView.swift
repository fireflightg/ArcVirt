import SwiftUI
import MapKit
import Combine

// MARK: - TrackingMapView
// Custom MKMapView subclass that forwards mouse-move events for live coordinate display.

class TrackingMapView: MKMapView {
    var onMouseMoved: ((CLLocationCoordinate2D) -> Void)?

    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        trackingAreas.forEach { removeTrackingArea($0) }
        addTrackingArea(NSTrackingArea(
            rect: .zero,
            options: [.mouseMoved, .activeInKeyWindow, .inVisibleRect],
            owner: self,
            userInfo: nil
        ))
    }

    override func mouseMoved(with event: NSEvent) {
        let loc = convert(event.locationInWindow, from: nil)
        guard bounds.contains(loc) else { return }
        onMouseMoved?(convert(loc, toCoordinateFrom: self))
    }
}

// MARK: - MapKitView

struct MapKitView: NSViewRepresentable {
    @ObservedObject var viewModel: MapViewModel

    func makeNSView(context: Context) -> TrackingMapView {
        let mapView = TrackingMapView()
        // Give Metal a non-zero initial frame to suppress the zero-size warning
        mapView.frame = CGRect(x: 0, y: 0, width: 800, height: 600)

        mapView.delegate       = context.coordinator
        mapView.mapType        = viewModel.mapType
        mapView.showsScale     = true
        mapView.showsCompass   = true
        mapView.showsZoomControls = true

        mapView.setRegion(
            MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: 20, longitude: 10),
                span:   MKCoordinateSpan(latitudeDelta: 120, longitudeDelta: 200)
            ),
            animated: false
        )

        // Live coordinate tracking
        mapView.onMouseMoved = { [weak viewModel] coord in
            DispatchQueue.main.async { viewModel?.cursorCoordinate = coord }
        }

        // Tool clicks
        let click = NSClickGestureRecognizer(
            target: context.coordinator,
            action: #selector(Coordinator.handleClick(_:))
        )
        mapView.addGestureRecognizer(click)

        context.coordinator.setup(mapView: mapView)
        return mapView
    }

    func updateNSView(_ mapView: TrackingMapView, context: Context) {
        if mapView.mapType != viewModel.mapType {
            mapView.mapType = viewModel.mapType
        }
    }

    func makeCoordinator() -> Coordinator { Coordinator(viewModel: viewModel) }

    // MARK: - Coordinator

    class Coordinator: NSObject, MKMapViewDelegate {
        let viewModel: MapViewModel
        weak var mapView: TrackingMapView?
        private var cancellables = Set<AnyCancellable>()

        // Transient overlays / annotations
        private var measureLine:        MKPolyline?
        private var measureAnnotations: [MKPointAnnotation] = []

        init(viewModel: MapViewModel) {
            self.viewModel = viewModel
        }

        func setup(mapView: TrackingMapView) {
            self.mapView = mapView

            // Rebuild all layer overlays whenever requested
            viewModel.$needsMapUpdate
                .filter { $0 }
                .receive(on: DispatchQueue.main)
                .sink { [weak self] _ in
                    self?.rebuildLayers()
                    self?.viewModel.needsMapUpdate = false
                }
                .store(in: &cancellables)

            // Update measure line whenever measure points change
            viewModel.$measurePoints
                .receive(on: DispatchQueue.main)
                .sink { [weak self] _ in self?.updateMeasureOverlays() }
                .store(in: &cancellables)

            // Zoom to layer via notification
            NotificationCenter.default.publisher(for: .zoomToLayer)
                .compactMap { $0.object as? UUID }
                .receive(on: DispatchQueue.main)
                .sink { [weak self] id in
                    guard let self,
                          let layer  = self.viewModel.layers.first(where: { $0.id == id }),
                          let region = SpatialAnalysis.boundingRegion(for: layer.features)
                    else { return }
                    self.mapView?.setRegion(region, animated: true)
                }
                .store(in: &cancellables)
        }

        // MARK: Layer management

        private func rebuildLayers() {
            guard let mapView else { return }

            // Preserve transient (measure) overlays/annotations
            let savedLine  = measureLine
            let savedAnns  = measureAnnotations

            mapView.removeAnnotations(mapView.annotations.filter { !($0 is MKUserLocation) })
            mapView.removeOverlays(mapView.overlays)

            // Draw bottom-first so the topmost list item renders on top
            for layer in viewModel.layers.reversed() where layer.isVisible {
                mapView.addAnnotations(layer.annotations)
                mapView.addOverlays(layer.overlays, level: .aboveRoads)
            }

            // Restore transient overlays
            if let line = savedLine { mapView.addOverlay(line, level: .aboveLabels) }
            savedAnns.forEach { mapView.addAnnotation($0) }
        }

        private func updateMeasureOverlays() {
            guard let mapView else { return }

            if let old = measureLine { mapView.removeOverlay(old) }
            measureAnnotations.forEach { mapView.removeAnnotation($0) }
            measureAnnotations.removeAll()
            measureLine = nil

            let pts = viewModel.measurePoints
            guard !pts.isEmpty else { return }

            for pt in pts {
                let ann = MKPointAnnotation()
                ann.coordinate = pt
                ann.title = "Measure point"
                mapView.addAnnotation(ann)
                measureAnnotations.append(ann)
            }

            if pts.count >= 2 {
                var c = pts
                let line = MKPolyline(coordinates: &c, count: c.count)
                mapView.addOverlay(line, level: .aboveLabels)
                measureLine = line
            }
        }

        // MARK: Gesture handler

        @objc func handleClick(_ gesture: NSClickGestureRecognizer) {
            guard let mapView else { return }
            let pt    = gesture.location(in: mapView)
            let coord = mapView.convert(pt, toCoordinateFrom: mapView)

            switch viewModel.selectedTool {
            case .pan:
                break
            case .select, .identify:
                identifyFeature(at: pt, mapView: mapView)
            case .measure:
                viewModel.addMeasurePoint(coord)
            case .buffer:
                viewModel.addBufferLayer(center: coord)
            }
        }

        private func identifyFeature(at screenPt: CGPoint, mapView: MKMapView) {
            let hitR: CGFloat = 22
            for layer in viewModel.layers where layer.isVisible {
                for ann in layer.annotations {
                    let ap = mapView.convert(ann.coordinate, toPointTo: mapView)
                    if hypot(screenPt.x - ap.x, screenPt.y - ap.y) < hitR {
                        if let fa = ann as? FeatureAnnotation {
                            let info = fa.properties
                                .sorted { $0.key < $1.key }
                                .map { "\($0.key): \($0.value)" }
                                .joined(separator: "  |  ")
                            viewModel.statusMessage = info.isEmpty ? "Feature identified" : info
                        }
                        return
                    }
                }
            }
            viewModel.statusMessage = "No feature at clicked location"
        }

        // MARK: MKMapViewDelegate — renderers

        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            // Check if this overlay belongs to a layer
            for layer in viewModel.layers {
                if layer.overlays.contains(where: { $0 === overlay }) {
                    return layerRenderer(for: overlay, layer: layer)
                }
            }

            // Measure polyline (orange dashed)
            if let poly = overlay as? MKPolyline {
                let r = MKPolylineRenderer(polyline: poly)
                r.strokeColor   = .systemOrange
                r.lineWidth     = 2.5
                r.lineDashPattern = [8, 5]
                return r
            }

            return MKOverlayRenderer(overlay: overlay)
        }

        private func layerRenderer(for overlay: MKOverlay, layer: Layer) -> MKOverlayRenderer {
            let a      = layer.opacity
            let fill   = NSColor(layer.fillColor).withAlphaComponent(a * 0.45)
            let stroke = NSColor(layer.strokeColor).withAlphaComponent(a)
            let width  = CGFloat(layer.strokeWidth)

            if let poly = overlay as? MKPolyline {
                let r = MKPolylineRenderer(polyline: poly)
                r.strokeColor = stroke
                r.lineWidth   = width
                return r
            }
            if let poly = overlay as? MKPolygon {
                let r = MKPolygonRenderer(polygon: poly)
                r.fillColor   = fill
                r.strokeColor = stroke
                r.lineWidth   = width
                return r
            }
            return MKOverlayRenderer(overlay: overlay)
        }

        // MARK: MKMapViewDelegate — annotation views

        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            guard !(annotation is MKUserLocation) else { return nil }

            // Measure point — plain orange pin, no callout
            if annotation is MKPointAnnotation {
                let id   = "measure"
                let view = (mapView.dequeueReusableAnnotationView(withIdentifier: id) as? MKMarkerAnnotationView)
                    ?? MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: id)
                view.annotation       = annotation
                view.markerTintColor  = .systemOrange
                view.glyphText        = "●"
                view.canShowCallout   = false
                view.displayPriority  = .required
                return view
            }

            // Feature annotation — tinted with layer colour
            if let fa = annotation as? FeatureAnnotation {
                let id   = "feature"
                let view = (mapView.dequeueReusableAnnotationView(withIdentifier: id) as? MKMarkerAnnotationView)
                    ?? MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: id)
                view.annotation     = fa
                view.canShowCallout = true

                var tint = NSColor.systemRed
                for layer in viewModel.layers {
                    if layer.annotations.contains(where: { $0 === annotation }) {
                        tint = NSColor(layer.fillColor)
                        break
                    }
                }
                view.markerTintColor = tint
                return view
            }

            return nil
        }

        // MARK: MKMapViewDelegate — region change

        func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
            let zoom = log2(360 / max(mapView.region.span.longitudeDelta, 0.001))
            DispatchQueue.main.async { self.viewModel.zoomLevel = max(0, zoom) }
        }
    }
}
