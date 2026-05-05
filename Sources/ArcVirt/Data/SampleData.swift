import CoreLocation
import MapKit
import SwiftUI

struct SampleData {
    static func worldCitiesLayer() -> Layer {
        let cities: [(name: String, lat: Double, lon: Double, pop: Int)] = [
            ("Tokyo",           35.6762,  139.6503, 13960000),
            ("Delhi",           28.7041,   77.1025, 11034555),
            ("Shanghai",        31.2304,  121.4737, 24183300),
            ("São Paulo",      -23.5505,  -46.6333, 12325232),
            ("Mexico City",     19.4326,  -99.1332,  9218653),
            ("Cairo",           30.0444,   31.2357, 10107125),
            ("Mumbai",          19.0760,   72.8777, 12442373),
            ("Beijing",         39.9042,  116.4074, 21707000),
            ("Dhaka",           23.8103,   90.4125,  8906039),
            ("Osaka",           34.6937,  135.5023,  2693440),
            ("New York",        40.7128,  -74.0060,  8336817),
            ("Karachi",         24.8607,   67.0011, 14910352),
            ("Buenos Aires",   -34.6037,  -58.3816,  2890151),
            ("Chongqing",       29.5630,  106.5516,  8810100),
            ("Istanbul",        41.0082,   28.9784, 15462452),
            ("Kolkata",         22.5726,   88.3639,  4631392),
            ("Manila",          14.5995,  120.9842,  1780148),
            ("Lagos",            6.5244,    3.3792,  9000000),
            ("Rio de Janeiro",  -22.9068,  -43.1729,  6718903),
            ("Kinshasa",        -4.4419,   15.2663, 11855000),
            ("Los Angeles",     34.0522, -118.2437,  3898747),
            ("Moscow",          55.7558,   37.6173, 12195221),
            ("Paris",           48.8566,    2.3522,  2140526),
            ("Jakarta",         -6.2088,  106.8456, 10562088),
            ("Bangkok",         13.7563,  100.5018, 10539000),
            ("Seoul",           37.5665,  126.9780,  9720846),
            ("London",          51.5074,   -0.1278,  8982000),
            ("Tehran",          35.6892,   51.3890,  8693706),
            ("Chicago",         41.8781,  -87.6298,  2693976),
            ("Lima",           -12.0464,  -77.0428,  9562280),
            ("Bogotá",           4.7110,  -74.0721,  7412566),
            ("Lahore",          31.5497,   74.3436, 11318745),
            ("Bangalore",       12.9716,   77.5946,  8443675),
            ("Singapore",        1.3521,  103.8198,  5850343),
            ("Ho Chi Minh City",10.8231,  106.6297,  8993082),
            ("Kuala Lumpur",     3.1390,  101.6869,  1790000),
            ("Sydney",         -33.8688,  151.2093,  5312000),
            ("Toronto",         43.6532,  -79.3832,  2731571),
            ("Johannesburg",   -26.2041,   28.0473,  5635127),
            ("Nairobi",         -1.2921,   36.8219,  4397073),
            ("Casablanca",      33.5731,   -7.5898,  3752000),
            ("Riyadh",          24.7136,   46.6753,  7676654),
            ("Dubai",           25.2048,   55.2708,  3331420),
            ("Taipei",          25.0330,  121.5654,  2646204),
            ("Hong Kong",       22.3193,  114.1694,  7481800),
            ("Santiago",       -33.4489,  -70.6693,  5614000),
            ("Guadalajara",     20.6597, -103.3496,  5023000),
            ("Baghdad",         33.3152,   44.3661,  7511000),
            ("Kabul",           34.5553,   69.2075,  4434560),
            ("Addis Ababa",      9.0250,   38.7469,  4794000),
            ("Berlin",          52.5200,   13.4050,  3669491),
        ]

        let layer = Layer(name: "World Cities", layerType: .point)
        layer.fillColor   = .red
        layer.strokeColor = .red

        layer.features = cities.map { city in
            GeoFeature(
                geometry: .point(CLLocationCoordinate2D(latitude: city.lat, longitude: city.lon)),
                properties: ["name": city.name, "population": city.pop]
            )
        }

        layer.annotations = cities.map { city -> MKAnnotation in
            FeatureAnnotation(
                coordinate: CLLocationCoordinate2D(latitude: city.lat, longitude: city.lon),
                properties: ["name": city.name, "population": city.pop]
            )
        }

        return layer
    }
}
