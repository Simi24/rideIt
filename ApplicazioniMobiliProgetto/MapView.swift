//
//  MapView.swift
//  ApplicazioniMobiliProgetto
//
//  Created by Simone Paolo Petta on 21/06/24.
//

import Foundation
import SwiftUI
import MapKit

struct MapView: UIViewRepresentable {
    @EnvironmentObject var locationManager: LocationManager
    
    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        return mapView
    }
    
    func updateUIView(_ uiView: MKMapView, context: Context) {
        guard !locationManager.recordedPath.isEmpty else { return }
        
        // Rimuove tutte le sovrapposizioni esistenti
        uiView.removeOverlays(uiView.overlays)
        
        var coordinates = [CLLocationCoordinate2D]()
        var currentBehavior: String?
        var currentCoordinates = [CLLocationCoordinate2D]()
        
        for (location, behavior, _) in locationManager.recordedPath {
            if currentBehavior == nil {
                currentBehavior = behavior
            }
            
            if behavior != currentBehavior {
                if !currentCoordinates.isEmpty {
                    let polyline = ColoredPolyline(coordinates: currentCoordinates, count: currentCoordinates.count)
                    polyline.color = color(for: currentBehavior ?? "unknown")
                    uiView.addOverlay(polyline)
                }
                currentCoordinates.removeAll()
                currentBehavior = behavior
            }
            
            currentCoordinates.append(location.coordinate)
        }
        
        if !currentCoordinates.isEmpty {
            let polyline = ColoredPolyline(coordinates: currentCoordinates, count: currentCoordinates.count)
            polyline.color = color(for: currentBehavior ?? "unknown")
            uiView.addOverlay(polyline)
        }
        
        // Centro della mappa sul percorso
        if let lastCoordinate = currentCoordinates.last {
            let region = MKCoordinateRegion(center: lastCoordinate, span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01))
            uiView.setRegion(region, animated: true)
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, MKMapViewDelegate {
        var parent: MapView
        
        init(_ parent: MapView) {
            self.parent = parent
        }
        
        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            if let polyline = overlay as? ColoredPolyline {
                let renderer = MKPolylineRenderer(polyline: polyline)
                renderer.strokeColor = polyline.color
                renderer.lineWidth = 5
                return renderer
            }
            return MKOverlayRenderer(overlay: overlay)
        }
    }
    
    private func color(for behavior: String) -> UIColor {
        switch behavior {
        case "cruise":
            return .blue
        case "fun":
            return .green
        case "overtake":
            return .red
        case "traffic":
            return .yellow
        case "wait":
            return .gray
        default:
            return .black
        }
    }
}

class ColoredPolyline: MKPolyline {
    var color: UIColor?
}
