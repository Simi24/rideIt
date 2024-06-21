//
//  LocationManager.swift
//  ApplicazioniMobiliProgetto
//
//  Created by Simone Paolo Petta on 21/06/24.
//

import SwiftUI
import CoreLocation
import CoreML
import MapKit
import Combine

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    internal let locationManager = CLLocationManager()
    internal let motionManager = MotionManager()
    @Published var lastLocation: CLLocation?
    @Published var recordedPath: [(location: CLLocation, behavior: String, timestamp: Date)] = []
    @Published var authorizationStatus: CLAuthorizationStatus?
    private var model: DrivingBehaviorClassifier?
    private let categories = ["cruise", "fun", "overtake", "traffic", "wait"]
    
    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestAlwaysAuthorization()
        
        // Inizia l'aggiornamento dei dati del MotionManager
        motionManager.startUpdates()
        
        // Osserva le modifiche al comportamento predetto
        motionManager.$predictedBehavior
            .sink { [weak self] behavior in
                self?.updatePathWithBehavior(behavior)
            }
            .store(in: &cancellables)
    }
    
    private var cancellables = Set<AnyCancellable>()
    
    func startTracking() {
        locationManager.startUpdatingLocation()
    }
    
    func stopTracking() {
        locationManager.stopUpdatingLocation()
        motionManager.stopUpdates()
    }
    
    private func updatePathWithBehavior(_ behavior: String) {
        guard let location = lastLocation else { return }
        let timestamp = Date()
        recordedPath.append((location, behavior, timestamp))
        print("Location: \(location), Behavior: \(behavior), Timestamp: \(timestamp)")
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        authorizationStatus = status
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        lastLocation = location
        // Il comportamento verrà aggiornato dal MotionManager
    }
}
