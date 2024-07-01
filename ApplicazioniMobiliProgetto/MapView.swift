//
//  MapView.swift
//  ApplicazioniMobiliProgetto
//
//  Created by Simone Paolo Petta on 21/06/24.
//

import MapKit
import SwiftUI

struct MapView: UIViewRepresentable {
    var path: [CLLocationCoordinate2D]
    var behaviorColors: [UIColor]
    let requestInterval: TimeInterval = 2.0

    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        return mapView
    }

    func updateUIView(_ uiView: MKMapView, context: Context) {
        uiView.removeOverlays(uiView.overlays)
        let coordinates = path

        guard coordinates.count > 1 else { return }

        var currentIndex = 0

        func requestNextRoute() {
            guard currentIndex < coordinates.count - 1 else { return }

            let start = coordinates[currentIndex]
            let end = coordinates[currentIndex + 1]

            requestRoute(from: start, to: end) { polyline, error in
                guard let polyline = polyline else {
                    print("Error getting route: \(String(describing: error))")
                    return
                }
                let colorPolyline = ColorPolyline(coordinates: polyline.coordinates, count: polyline.pointCount)
                colorPolyline.color = behaviorColors[currentIndex]
                uiView.addOverlay(colorPolyline)

                currentIndex += 1
                DispatchQueue.main.asyncAfter(deadline: .now() + requestInterval) {
                    requestNextRoute()
                }
            }
        }

        requestNextRoute()

        if let region = makeRegion(for: coordinates) {
            uiView.setRegion(region, animated: true)
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeRegion(for coordinates: [CLLocationCoordinate2D]) -> MKCoordinateRegion? {
        guard !coordinates.isEmpty else { return nil }

        let latitudes = coordinates.map { $0.latitude }
        let longitudes = coordinates.map { $0.longitude }

        let minLat = latitudes.min()!
        let maxLat = latitudes.max()!
        let minLon = longitudes.min()!
        let maxLon = longitudes.max()!

        let center = CLLocationCoordinate2D(latitude: (minLat + maxLat) / 2, longitude: (minLon + maxLon) / 2)
        let span = MKCoordinateSpan(latitudeDelta: (maxLat - minLat) * 1.2, longitudeDelta: (maxLon - minLon) * 1.2)

        return MKCoordinateRegion(center: center, span: span)
    }

    func requestRoute(from start: CLLocationCoordinate2D, to end: CLLocationCoordinate2D, completion: @escaping (MKPolyline?, Error?) -> Void) {
        let request = MKDirections.Request()
        request.source = MKMapItem(placemark: MKPlacemark(coordinate: start))
        request.destination = MKMapItem(placemark: MKPlacemark(coordinate: end))
        request.transportType = .automobile

        let directions = MKDirections(request: request)
        directions.calculate { response, error in
            guard let route = response?.routes.first else {
                print("Error calculating route: \(String(describing: error))")
                completion(nil, error)
                return
            }
            completion(route.polyline, nil)
        }
    }

    class Coordinator: NSObject, MKMapViewDelegate {
        var parent: MapView

        init(_ parent: MapView) {
            self.parent = parent
        }

        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            guard let polyline = overlay as? ColorPolyline else {
                return MKOverlayRenderer(overlay: overlay)
            }

            let renderer = MKPolylineRenderer(polyline: polyline)
            renderer.strokeColor = polyline.color
            renderer.lineWidth = 4
            return renderer
        }
    }
}

class ColorPolyline: MKPolyline {
    var color: UIColor?
}

extension MKPolyline {
    var coordinates: [CLLocationCoordinate2D] {
        var coords = [CLLocationCoordinate2D](repeating: kCLLocationCoordinate2DInvalid, count: pointCount)
        getCoordinates(&coords, range: NSRange(location: 0, length: pointCount))
        return coords
    }
}

