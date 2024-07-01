//
//  LocationManager.swift
//  ApplicazioniMobiliProgetto
//
//  Created by Simone Paolo Petta on 21/06/24.
//

import Combine
import CoreLocation
import Foundation
import UIKit
import SwiftUI
import CoreData

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    internal let locationManager = CLLocationManager()
    internal let motionManager = MotionManager()
    @Published var lastLocation: CLLocation?
    @Published var recordedSegments: [(location: CLLocation, behavior: String, timestamp: Date)] = []
    @Published var authorizationStatus: CLAuthorizationStatus?
    @Published var behaviorTimes: [String: TimeInterval] = [:]
    @Published var coordinates: [CLLocationCoordinate2D] = []
    @Published var behaviorColors: [UIColor] = []
    @Published var recordedPath: RecordedPath?

    private var model: DrivingBehaviorClassifier?
    internal let categories = ["cruise", "fun", "overtake", "traffic", "wait"]
    private var cancellables = Set<AnyCancellable>()
    private var lastUpdateTime: Date?
    private var startTime: Date?
    private let minDistance: CLLocationDistance = 5.0 // Minimum distance in meters to consider as movement

    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestAlwaysAuthorization()

        motionManager.$predictedBehavior
            .sink { [weak self] behavior in
                self?.updatePathWithBehavior(behavior)
            }
            .store(in: &cancellables)
    }
    
    func requestAuthorization(){
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestAlwaysAuthorization()
    }

    func startTracking() {
        resetData()
        locationManager.startUpdatingLocation()
        motionManager.startUpdates()
        startTime = Date()
        lastUpdateTime = Date()
    }

    func stopTracking() {
        locationManager.stopUpdatingLocation()
        motionManager.stopUpdates()

        let endTime = Date()
        let pathSegments = recordedSegments.map { segment in
            RecordedSegment(
                coordinates: [CodableCoordinate(from: segment.location.coordinate)],
                behavior: segment.behavior
            )
        }
        let path = RecordedPath(id: UUID(), segments: pathSegments, startTime: startTime ?? Date(), endTime: endTime, behaviorTimes: behaviorTimes)
        recordedPath = path

        savePath(path)
        
        behaviorTimes = [:]
    }

    private func resetData() {
        lastLocation = nil
        recordedSegments.removeAll()
        behaviorTimes = [:]
        coordinates.removeAll()
        behaviorColors.removeAll()
        lastUpdateTime = nil
    }

    private func updatePathWithBehavior(_ behavior: String) {
        guard let location = lastLocation else { return }
        let timestamp = Date()
        recordedSegments.append((location, behavior, timestamp))
        coordinates.append(location.coordinate)
        behaviorColors.append(behaviorColor(for: behavior).uiColor())
        print("Location: \(location), Behavior: \(behavior), Timestamp: \(timestamp)")

        if lastUpdateTime == nil {
            lastUpdateTime = Date()
        } else {
            let elapsed = timestamp.timeIntervalSince(lastUpdateTime!)
            behaviorTimes[behavior, default: 0] += elapsed
            lastUpdateTime = timestamp
        }
    }

    private func behaviorColor(for behavior: String) -> Color {
        switch behavior {
        case "cruise":
            return Color.green
        case "fun":
            return Color.yellow
        case "overtake":
            return Color.orange
        case "traffic":
            return Color.red
        case "wait":
            return Color.gray
        default:
            return Color.black
        }
    }

    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        authorizationStatus = status
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        if lastLocation == nil || location.distance(from: lastLocation!) >= minDistance {
            lastLocation = location
        }
    }

    private func savePath(_ path: RecordedPath) {
        let context = PersistenceController.shared.container.viewContext
        let entity = RecordedPathEntity(context: context)
        entity.id = path.id
        entity.startTime = path.startTime
        entity.endTime = path.endTime

        do {
            let segmentsData = try JSONEncoder().encode(path.segments)
            entity.segments = segmentsData
            let behaviorTimesData = try JSONEncoder().encode(path.behaviorTimes)
            entity.behaviorTimes = behaviorTimesData
            try context.save()
        } catch {
            print("Failed to save path: \(error)")
        }
    }

    func loadPaths() -> [RecordedPath] {
        let context = PersistenceController.shared.container.viewContext
        let fetchRequest: NSFetchRequest<RecordedPathEntity> = RecordedPathEntity.fetchRequest()

        do {
            let entities = try context.fetch(fetchRequest)
            return entities.compactMap { entity in
                guard let id = entity.id,
                      let startTime = entity.startTime,
                      let endTime = entity.endTime,
                      let segmentsData = entity.segments,
                      let behaviorTimesData = entity.behaviorTimes,
                      let segments = try? JSONDecoder().decode([RecordedSegment].self, from: segmentsData),
                      let behaviorTimes = try? JSONDecoder().decode([String: TimeInterval].self, from: behaviorTimesData)
                else {
                    return nil
                }
                return RecordedPath(id: id, segments: segments, startTime: startTime, endTime: endTime, behaviorTimes: behaviorTimes)
            }
        } catch {
            print("Failed to load paths: \(error)")
            return []
        }
    }
}

extension Color {
    func uiColor() -> UIColor {
        return UIColor(self)
    }
}
