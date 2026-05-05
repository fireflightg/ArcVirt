import SwiftUI

struct StatusBarView: View {
    @ObservedObject var viewModel: MapViewModel

    var body: some View {
        HStack(spacing: 10) {
            if viewModel.isLoading {
                ProgressView()
                    .scaleEffect(0.55)
                    .frame(width: 14, height: 14)
            }

            Text(viewModel.statusMessage)
                .font(.system(size: 11))
                .foregroundColor(.secondary)
                .lineLimit(1)
                .truncationMode(.tail)

            Spacer()

            Divider()

            // Cursor coordinates
            HStack(spacing: 4) {
                Image(systemName: "location.viewfinder")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
                Text(coordinateText)
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundColor(.secondary)
            }

            Divider()

            // Zoom level
            HStack(spacing: 3) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
                Text(String(format: "%.1f", viewModel.zoomLevel))
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundColor(.secondary)
            }

            Divider()

            // Layer count
            HStack(spacing: 3) {
                Image(systemName: "square.stack.3d.up")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
                Text("\(viewModel.layers.count) layer\(viewModel.layers.count == 1 ? "" : "s")")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }
        }
    }

    private var coordinateText: String {
        let c   = viewModel.cursorCoordinate
        let lat = String(format: "%.4f%@", abs(c.latitude),  c.latitude  >= 0 ? "°N" : "°S")
        let lon = String(format: "%.4f%@", abs(c.longitude), c.longitude >= 0 ? "°E" : "°W")
        return "\(lat)  \(lon)"
    }
}
