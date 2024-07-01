//
//  MiniMapView.swift
//  ApplicazioniMobiliProgetto
//
//  Created by Simone Paolo Petta on 29/06/24.
//

import Foundation
import MapKit
import SwiftUI

struct MiniMapView: UIViewRepresentable {
    var path: RecordedPath

    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.isScrollEnabled = false
        mapView.isZoomEnabled = false
        mapView.isPitchEnabled = false
        mapView.isRotateEnabled = false
        return mapView
    }

    func updateUIView(_ uiView: MKMapView, context: Context) {
        let coordinates = path.segments.flatMap { $0.coordinates.map { $0.coordinate } }
        let polyline = MKPolyline(coordinates: coordinates, count: coordinates.count)
        uiView.addOverlay(polyline)
        uiView.setVisibleMapRect(polyline.boundingMapRect, edgePadding: UIEdgeInsets(top: 5, left: 5, bottom: 5, right: 5), animated: false)
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, MKMapViewDelegate {
        var parent: MiniMapView

        init(_ parent: MiniMapView) {
            self.parent = parent
        }

        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            if let polyline = overlay as? MKPolyline {
                let renderer = MKPolylineRenderer(polyline: polyline)
                renderer.strokeColor = .blue
                renderer.lineWidth = 3
                return renderer
            }
            return MKOverlayRenderer()
        }
    }
}
