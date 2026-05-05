import SwiftUI

// MARK: - Notification

extension Notification.Name {
    static let zoomToLayer = Notification.Name("arcvirt.zoomToLayer")
}

// MARK: - InspectorView

struct InspectorView: View {
    @ObservedObject var viewModel: MapViewModel

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 6) {
                Image(systemName: "slider.horizontal.3")
                    .foregroundColor(.accentColor)
                Text("Inspector")
                    .font(.headline)
                Spacer()
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(Color(nsColor: .controlBackgroundColor))

            Divider()

            if let layer = viewModel.selectedLayer {
                LayerInspectorView(layer: layer, viewModel: viewModel)
            } else {
                VStack(spacing: 10) {
                    Image(systemName: "sidebar.squares.right")
                        .font(.system(size: 36))
                        .foregroundColor(.secondary)
                    Text("No layer selected")
                        .foregroundColor(.secondary)
                    Text("Select a layer in the panel\nto inspect its properties")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding()
            }
        }
    }
}

// MARK: - LayerInspectorView

struct LayerInspectorView: View {
    @ObservedObject var layer: Layer
    @ObservedObject var viewModel: MapViewModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 10) {

                // ── Layer Info ──────────────────────────────────
                InspectorSection(title: "Layer Info") {
                    InspectorRow(label: "Name") {
                        TextField("Layer name", text: $layer.name)
                            .textFieldStyle(.roundedBorder)
                            .font(.system(size: 12))
                    }
                    InspectorRow(label: "Type",     value: layer.typeDescription)
                    InspectorRow(label: "Features", value: "\(layer.featureCount)")
                    InspectorRow(label: "Visible",  value: layer.isVisible ? "Yes" : "No")
                }

                // ── Symbology ───────────────────────────────────
                InspectorSection(title: "Symbology") {
                    InspectorRow(label: "Fill") {
                        ColorPicker("", selection: $layer.fillColor)
                            .labelsHidden()
                            .onChange(of: layer.fillColor) { viewModel.needsMapUpdate = true }
                    }
                    InspectorRow(label: "Stroke") {
                        ColorPicker("", selection: $layer.strokeColor)
                            .labelsHidden()
                            .onChange(of: layer.strokeColor) { viewModel.needsMapUpdate = true }
                    }
                    InspectorRow(label: "Width") {
                        Stepper("\(Int(layer.strokeWidth)) pt",
                                value: $layer.strokeWidth, in: 1...12, step: 1)
                        .font(.system(size: 12))
                        .onChange(of: layer.strokeWidth) { viewModel.needsMapUpdate = true }
                    }
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("Opacity")
                                .font(.system(size: 11))
                                .foregroundColor(.secondary)
                                .frame(width: 55, alignment: .leading)
                            Slider(value: $layer.opacity, in: 0...1)
                                .onChange(of: layer.opacity) { viewModel.needsMapUpdate = true }
                            Text("\(Int(layer.opacity * 100))%")
                                .font(.system(size: 11))
                                .frame(width: 34, alignment: .trailing)
                        }
                    }
                }

                // ── Actions ─────────────────────────────────────
                InspectorSection(title: "Actions") {
                    Button("Zoom to Layer") {
                        NotificationCenter.default.post(name: .zoomToLayer, object: layer.id)
                        viewModel.statusMessage = "Zooming to \(layer.name)"
                    }
                    .frame(maxWidth: .infinity)
                    .buttonStyle(.borderedProminent)

                    Button("Toggle Visibility") {
                        layer.isVisible.toggle()
                        viewModel.needsMapUpdate = true
                    }
                    .frame(maxWidth: .infinity)
                    .buttonStyle(.bordered)

                    Button("Remove Layer", role: .destructive) {
                        viewModel.removeLayer(layer)
                    }
                    .frame(maxWidth: .infinity)
                    .buttonStyle(.bordered)
                    .foregroundColor(.red)
                }

                // ── Measure Results (contextual) ─────────────────
                if viewModel.selectedTool == .measure {
                    InspectorSection(title: "Measurement") {
                        InspectorRow(label: "Points",   value: "\(viewModel.measurePoints.count)")
                        InspectorRow(label: "km",       value: String(format: "%.3f", viewModel.totalMeasureDistance))
                        InspectorRow(label: "mi",       value: String(format: "%.3f", viewModel.totalMeasureDistance * 0.621371))
                        InspectorRow(label: "nm",       value: String(format: "%.3f", viewModel.totalMeasureDistance * 0.539957))

                        if !viewModel.measurePoints.isEmpty {
                            Button("Clear Measurement") { viewModel.clearMeasurement() }
                                .frame(maxWidth: .infinity)
                                .buttonStyle(.bordered)
                        } else {
                            Text("Click on the map to start measuring")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }

                // ── Buffer Settings (contextual) ─────────────────
                if viewModel.selectedTool == .buffer {
                    InspectorSection(title: "Buffer Settings") {
                        InspectorRow(label: "Radius") {
                            Stepper("\(Int(viewModel.bufferRadius)) km",
                                    value: $viewModel.bufferRadius, in: 1...5000, step: 10)
                            .font(.system(size: 12))
                        }
                        Text("Click anywhere on the map to place a buffer zone at the specified radius.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }

            }
            .padding(10)
        }
    }
}

// MARK: - Reusable sub-components

struct InspectorSection<Content: View>: View {
    let title: String
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            Text(title.uppercased())
                .font(.system(size: 9, weight: .bold))
                .foregroundColor(.secondary)
                .kerning(0.8)
            content()
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(nsColor: .controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color(nsColor: .separatorColor), lineWidth: 0.5)
        )
    }
}

struct InspectorRow<Content: View>: View {
    let label: String
    @ViewBuilder let content: () -> Content

    var body: some View {
        HStack(alignment: .center, spacing: 6) {
            Text(label)
                .font(.system(size: 11))
                .foregroundColor(.secondary)
                .frame(width: 52, alignment: .leading)
            content()
        }
    }
}

extension InspectorRow where Content == Text {
    init(label: String, value: String) {
        self.label   = label
        self.content = { Text(value).font(.system(size: 11)) }
    }
}
