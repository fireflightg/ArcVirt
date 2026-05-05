# ArcVirt

A native macOS GIS platform inspired by ArcGIS, built with SwiftUI and MapKit. Import, visualize, and analyze geographic data without a subscription.

![macOS](https://img.shields.io/badge/macOS-14%2B-blue) ![Swift](https://img.shields.io/badge/Swift-6.1-orange) ![License](https://img.shields.io/badge/license-MIT-green)

---

## Download

**[→ Download ArcVirt v1.0](https://github.com/fireflightg/ArcVirt/releases/latest)**

Unzip and drag `ArcVirt.app` to your `/Applications` folder.

> On first launch, if macOS shows a security warning: **right-click → Open → Open**. This only happens once.

---

## Features

| Feature | Description |
|---|---|
| 🗺 **2D Mapping** | Standard, Satellite, and Hybrid base maps |
| 📂 **Layer Management** | Import GeoJSON, drag to reorder, toggle visibility |
| 📏 **Measure Tool** | Multi-point distance measurement in km, mi, and nautical miles |
| ⭕ **Buffer Tool** | Create circular buffer zones at a configurable radius |
| 🔍 **Identify Tool** | Click any feature to inspect its attributes |
| 🎨 **Symbology** | Per-layer fill color, stroke color, width, and opacity |
| 📍 **Sample Data** | 50 major world cities pre-loaded on launch |
| 📡 **Live Coordinates** | Cursor lat/lon and zoom level shown in the status bar |

---

## Interface

```
┌──────────────────────────────────────────────────────────────────────┐
│  [Pan][Select][Measure][Buffer][Identify]   [Map|Satellite|Hybrid]  ≡ │  Toolbar
├─────────────┬──────────────────────────────────────┬─────────────────┤
│             │                                      │                 │
│   Layers    │                                      │   Inspector     │
│  ─────────  │           Map View                   │  ────────────   │
│  👁 World   │                                      │  Layer Info     │
│    Cities   │      (MapKit — pan, zoom, click)     │  Symbology      │
│             │                                      │  Actions        │
│  drag to    │                                      │  Measurement    │
│  reorder    │                                      │  Buffer Config  │
│             │                                      │                 │
├─────────────┴──────────────────────────────────────┴─────────────────┤
│  Status message                   20.0000°N  10.0000°E   Zoom 2.1    │  Status bar
└──────────────────────────────────────────────────────────────────────┘
```

---

## Tools

### Pan
Default mode. Click and drag to navigate the map.

### Select / Identify
Click any point feature to see all its attributes in the status bar.

### Measure
Click two or more points on the map to measure the distance between them. Results show in km, miles, and nautical miles in the Inspector panel. Click **Clear** to reset.

### Buffer
Set a radius in the Inspector panel, then click anywhere on the map to create a circular buffer zone. The buffer is added as a new layer you can style and remove.

---

## Importing Data

ArcVirt supports the **GeoJSON** format (`.json` or `.geojson`).

1. Click **Import GeoJSON** in the toolbar
2. Pick your file
3. The layer appears in the panel with auto-detected geometry type and default styling

Supported geometry types:
- `Point` / `MultiPoint`
- `LineString` / `MultiLineString`
- `Polygon` / `MultiPolygon`
- `FeatureCollection`

---

## Building from Source

**Requirements:**
- macOS 14+
- Swift 6.1 (Command Line Tools 16.3+)

```bash
git clone https://github.com/fireflightg/ArcVirt.git
cd ArcVirt
swift run
```

To build a release `.app` bundle:

```bash
sudo xcodebuild -license accept   # first time only
bash make_app.sh
```

This produces `ArcVirt.app` in the project folder, ready to drag to `/Applications`.

---

## Project Structure

```
ArcVirt/
├── Package.swift
├── make_app.sh                       ← builds the .app bundle
└── Sources/ArcVirt/
    ├── ArcVirtApp.swift              ← app entry point
    ├── ContentView.swift             ← 3-pane split layout
    ├── Models/
    │   ├── Layer.swift               ← layer data model
    │   ├── MapTool.swift             ← tool enum
    │   └── GeoFeature.swift          ← GeoJSON geometry model
    ├── ViewModels/
    │   └── MapViewModel.swift        ← central state (Combine)
    ├── Views/
    │   ├── MapKitView.swift          ← MKMapView wrapper
    │   ├── LayerPanelView.swift      ← left sidebar
    │   ├── InspectorView.swift       ← right panel
    │   ├── MapToolbarView.swift      ← toolbar
    │   └── StatusBarView.swift       ← bottom status bar
    ├── GeoJSON/
    │   └── GeoJSONParser.swift       ← full GeoJSON parser
    ├── Analysis/
    │   └── SpatialAnalysis.swift     ← distance, buffer, bounding region
    └── Data/
        └── SampleData.swift          ← 50 world cities
```

---

## Requirements

- macOS 14 (Sonoma) or later
- Apple Silicon or Intel Mac

---

## License

MIT — free to use, modify, and distribute.
