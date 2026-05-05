import SwiftUI
import MapKit

struct MapToolbarView: View {
    @ObservedObject var viewModel: MapViewModel
    @Binding var showingImporter: Bool
    @Binding var showInspector: Bool

    var body: some View {
        HStack(spacing: 10) {

            // ── Tool palette ─────────────────────────────────
            HStack(spacing: 2) {
                ForEach(MapTool.allCases) { tool in
                    ToolButton(tool: tool, isSelected: viewModel.selectedTool == tool) {
                        viewModel.selectedTool = tool
                        switch tool {
                        case .pan:
                            viewModel.statusMessage = "Pan — drag to navigate"
                        case .select:
                            viewModel.statusMessage = "Select — click a feature"
                        case .measure:
                            viewModel.statusMessage = viewModel.measurePoints.isEmpty
                                ? "Measure — click points on the map"
                                : "Measure active — click to add more points"
                        case .buffer:
                            viewModel.statusMessage = "Buffer (\(Int(viewModel.bufferRadius)) km) — click to place"
                        case .identify:
                            viewModel.statusMessage = "Identify — click a feature to inspect"
                        }
                    }
                }
            }
            .padding(3)
            .background(Color(nsColor: .controlBackgroundColor))
            .clipShape(RoundedRectangle(cornerRadius: 7))
            .overlay(
                RoundedRectangle(cornerRadius: 7)
                    .stroke(Color(nsColor: .separatorColor), lineWidth: 0.5)
            )

            Divider().frame(height: 30)

            // ── Map type ─────────────────────────────────────
            Picker("", selection: $viewModel.mapType) {
                Text("Map").tag(MKMapType.standard)
                Text("Satellite").tag(MKMapType.satellite)
                Text("Hybrid").tag(MKMapType.hybrid)
            }
            .pickerStyle(.segmented)
            .frame(width: 195)
            .help("Switch base map style")

            Divider().frame(height: 30)

            // ── Import ───────────────────────────────────────
            Button {
                showingImporter = true
            } label: {
                Label("Import GeoJSON", systemImage: "square.and.arrow.down")
            }
            .buttonStyle(.bordered)
            .help("Import a GeoJSON file as a new layer")

            // ── Clear measure (contextual) ────────────────────
            if viewModel.selectedTool == .measure && !viewModel.measurePoints.isEmpty {
                Button {
                    viewModel.clearMeasurement()
                } label: {
                    Label("Clear", systemImage: "xmark.circle")
                }
                .buttonStyle(.bordered)
                .foregroundColor(.orange)
                .help("Clear measurement points")
            }

            Spacer()

            // ── Active tool badge ─────────────────────────────
            Label(viewModel.selectedTool.rawValue, systemImage: viewModel.selectedTool.icon)
                .font(.system(size: 11))
                .foregroundColor(.secondary)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.accentColor.opacity(0.1))
                .clipShape(Capsule())

            Divider().frame(height: 30)

            // ── Inspector toggle ──────────────────────────────
            Button {
                withAnimation(.easeInOut(duration: 0.2)) { showInspector.toggle() }
            } label: {
                Image(systemName: showInspector ? "sidebar.right" : "sidebar.trailing")
            }
            .buttonStyle(.bordered)
            .help(showInspector ? "Hide Inspector" : "Show Inspector")
        }
    }
}

// MARK: - ToolButton

struct ToolButton: View {
    let tool: MapTool
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 2) {
                Image(systemName: tool.icon)
                    .font(.system(size: 13, weight: isSelected ? .semibold : .regular))
                    .frame(height: 16)
                Text(tool.rawValue)
                    .font(.system(size: 9))
            }
            .frame(width: 54, height: 40)
            .background(isSelected ? Color.accentColor.opacity(0.15) : Color.clear)
            .clipShape(RoundedRectangle(cornerRadius: 5))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .foregroundColor(isSelected ? .accentColor : .primary)
        .help(tool.tooltip)
    }
}
