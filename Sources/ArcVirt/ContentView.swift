import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    @StateObject private var viewModel = MapViewModel()
    @State private var showingImporter = false
    @State private var showInspector   = true

    var body: some View {
        HSplitView {
            // ── Left: Layer panel ────────────────────────────
            LayerPanelView(viewModel: viewModel)
                .frame(minWidth: 200, idealWidth: 240, maxWidth: 320)

            // ── Centre: Map + toolbar + status ───────────────
            VStack(spacing: 0) {
                MapToolbarView(
                    viewModel: viewModel,
                    showingImporter: $showingImporter,
                    showInspector: $showInspector
                )
                .padding(.horizontal, 8)
                .padding(.vertical, 6)
                .background(Color(nsColor: .windowBackgroundColor))

                Divider()

                MapKitView(viewModel: viewModel)

                Divider()

                StatusBarView(viewModel: viewModel)
                    .frame(height: 26)
                    .padding(.horizontal, 10)
                    .background(Color(nsColor: .windowBackgroundColor))
            }

            // ── Right: Inspector (toggleable) ────────────────
            if showInspector {
                InspectorView(viewModel: viewModel)
                    .frame(minWidth: 220, idealWidth: 265, maxWidth: 340)
                    .transition(.move(edge: .trailing))
            }
        }
        .fileImporter(
            isPresented: $showingImporter,
            allowedContentTypes: [.json],
            allowsMultipleSelection: false
        ) { result in
            guard case .success(let urls) = result, let url = urls.first else { return }
            let accessing = url.startAccessingSecurityScopedResource()
            viewModel.importGeoJSON(url: url)
            if accessing { url.stopAccessingSecurityScopedResource() }
        }
        .alert("Import Error", isPresented: Binding(
            get: { viewModel.errorMessage != nil },
            set: { if !$0 { viewModel.errorMessage = nil } }
        )) {
            Button("OK") { viewModel.errorMessage = nil }
        } message: {
            Text(viewModel.errorMessage ?? "Unknown error")
        }
    }
}
