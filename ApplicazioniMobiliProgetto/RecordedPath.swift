//
//  RecordedPath.swift
//  ApplicazioniMobiliProgetto
//
//  Created by Simone Paolo Petta on 28/06/24.
//

import Foundation
import CoreLocation

struct RecordedSegment: Codable {
    let coordinates: [CodableCoordinate]
    let behavior: String
}

struct CodableCoordinate: Codable, Hashable {
    var latitude: Double
    var longitude: Double

    init(from coordinate: CLLocationCoordinate2D) {
        self.latitude = coordinate.latitude
        self.longitude = coordinate.longitude
    }

    var coordinate: CLLocationCoordinate2D {
        return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(latitude)
        hasher.combine(longitude)
    }

    static func == (lhs: CodableCoordinate, rhs: CodableCoordinate) -> Bool {
        return lhs.latitude == rhs.latitude && lhs.longitude == rhs.longitude
    }
}

struct RecordedPath: Codable {
    let id: UUID
    let segments: [RecordedSegment]
    let startTime: Date
    let endTime: Date
    let behaviorTimes: [String: TimeInterval]
}
