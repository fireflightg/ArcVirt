import SwiftUI

struct LayerPanelView: View {
    @ObservedObject var viewModel: MapViewModel

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack(spacing: 6) {
                Image(systemName: "square.stack.3d.up.fill")
                    .foregroundColor(.accentColor)
                Text("Layers")
                    .font(.headline)
                Spacer()
                Text("\(viewModel.layers.count)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color(nsColor: .controlColor))
                    .clipShape(Capsule())
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(Color(nsColor: .controlBackgroundColor))

            Divider()

            if viewModel.layers.isEmpty {
                VStack(spacing: 10) {
                    Image(systemName: "map")
                        .font(.system(size: 36))
                        .foregroundColor(.secondary)
                    Text("No Layers")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    Text("Import a GeoJSON file to\nadd a layer to the map")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding()
            } else {
                List(
                    selection: Binding(
                        get: { viewModel.selectedLayer?.id },
                        set: { id in viewModel.selectedLayer = viewModel.layers.first { $0.id == id } }
                    )
                ) {
                    ForEach(viewModel.layers) { layer in
                        LayerRowView(layer: layer, viewModel: viewModel)
                            .tag(layer.id)
                    }
                    .onMove   { from, to  in viewModel.moveLayer(from: from, to: to) }
                    .onDelete { indices   in indices.forEach { viewModel.removeLayer(viewModel.layers[$0]) } }
                }
                .listStyle(.sidebar)
            }

            Divider()

            // Footer hint
            Text("Drag to reorder  •  Swipe to delete")
                .font(.system(size: 10))
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.vertical, 5)
                .background(Color(nsColor: .controlBackgroundColor))
        }
    }
}

// MARK: - Layer Row

struct LayerRowView: View {
    @ObservedObject var layer: Layer
    @ObservedObject var viewModel: MapViewModel

    var body: some View {
        HStack(spacing: 7) {
            // Visibility toggle
            Button {
                layer.isVisible.toggle()
                viewModel.needsMapUpdate = true
            } label: {
                Image(systemName: layer.isVisible ? "eye.fill" : "eye.slash")
                    .font(.system(size: 12))
                    .foregroundColor(layer.isVisible ? .accentColor : .secondary)
                    .frame(width: 16)
            }
            .buttonStyle(.plain)
            .help(layer.isVisible ? "Hide layer" : "Show layer")

            // Type icon (tinted by layer colour)
            Image(systemName: layer.layerIcon)
                .font(.system(size: 12))
                .foregroundColor(layer.fillColor)
                .frame(width: 16)

            // Name + metadata
            VStack(alignment: .leading, spacing: 2) {
                Text(layer.name)
                    .font(.system(size: 12, weight: .medium))
                    .lineLimit(1)
                Text("\(layer.typeDescription) · \(layer.featureCount) feature\(layer.featureCount == 1 ? "" : "s")")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
            }

            Spacer(minLength: 0)

            // Opacity dot indicator
            Circle()
                .fill(layer.fillColor.opacity(layer.opacity))
                .frame(width: 8, height: 8)
                .overlay(Circle().stroke(Color(nsColor: .separatorColor), lineWidth: 0.5))
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
        .opacity(layer.isVisible ? 1 : 0.5)
    }
}
