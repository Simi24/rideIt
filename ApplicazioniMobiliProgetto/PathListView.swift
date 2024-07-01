//
//  PathListView.swift
//  ApplicazioniMobiliProgetto
//
//  Created by Simone Paolo Petta on 25/06/24.
//

import SwiftUI
import CoreLocation

struct PathListView: View {
    @EnvironmentObject var locationManager: LocationManager
    @State private var recordedPaths: [RecordedPath] = []
    
    var body: some View {
        NavigationView {
            VStack {
                Text("Your Paths")
                    .font(.largeTitle)
                    .padding()
                
                if recordedPaths.isEmpty {
                    Text("No saved paths available")
                        .padding()
                } else {
                    List(recordedPaths, id: \.id) { path in
                        NavigationLink(destination: SummaryView(recordedPath: path)) {
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Text(getRideTitle(path.startTime))
                                        .font(.headline)
                                    Spacer()
                                    Text(formatDate(path.startTime))
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                                
                                HStack {
                                    Label(
                                        formatDuration(from: path.startTime, to: path.endTime),
                                        systemImage: "clock"
                                    )
                                    Spacer()
                                    Label(
                                        formatDistance(path: path),
                                        systemImage: "map"
                                    )
                                }
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                
                                if let mainBehavior = getMainBehavior(path.behaviorTimes) {
                                    Label(
                                        mainBehavior.capitalized,
                                        systemImage: behaviorIcon(for: mainBehavior)
                                    )
                                    .font(.caption)
                                    .foregroundColor(behaviorColor(for: mainBehavior))
                                }
                            }
                            .padding(.vertical, 8)
                        }
                    }
                }
                
                Spacer()
            }
            .onAppear {
                loadRecordedPaths()
            }
        }
    }
    
    private func loadRecordedPaths() {
        recordedPaths = locationManager.loadPaths()
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    private func getRideTitle(_ date: Date) -> String {
        let hour = Calendar.current.component(.hour, from: date)
        switch hour {
        case 5..<12: return "Morning Ride"
        case 12..<17: return "Afternoon Ride"
        case 17..<22: return "Evening Ride"
        default: return "Night Ride"
        }
    }

    private func formatDuration(from start: Date, to end: Date) -> String {
        let duration = end.timeIntervalSince(start)
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute]
        formatter.unitsStyle = .abbreviated
        formatter.zeroFormattingBehavior = .pad
        return formatter.string(from: duration) ?? ""
    }

    private func formatDistance(path: RecordedPath) -> String {
        guard path.segments.count > 1 else {
            return "0 m"
        }

        var totalDistance: CLLocationDistance = 0
        for i in 1..<path.segments.count {
            let prevSegment = path.segments[i-1]
            let currentSegment = path.segments[i]
            
            guard let prevCoordinate = prevSegment.coordinates.last?.coordinate,
                  let currentCoordinate = currentSegment.coordinates.first?.coordinate else {
                continue
            }

            let from = CLLocation(latitude: prevCoordinate.latitude, longitude: prevCoordinate.longitude)
            let to = CLLocation(latitude: currentCoordinate.latitude, longitude: currentCoordinate.longitude)
            
            let segmentDistance = from.distance(from: to)
            totalDistance += segmentDistance
        }

        if totalDistance < 1000 {
            let meters = Int(round(totalDistance))
            return "\(meters) m"
        } else {
            let kilometers = (totalDistance / 1000).rounded(toDecimalPlaces: 1)
            return "\(kilometers) km"
        }
    }

    private func calculateDistance(_ coordinates: [CLLocationCoordinate2D]) -> CLLocationDistance {
        guard coordinates.count > 1 else {
            print("Meno di 2 coordinate")
            return 0
        }
        var totalDistance: CLLocationDistance = 0
        for i in 1..<coordinates.count {
            let from = CLLocation(latitude: coordinates[i-1].latitude, longitude: coordinates[i-1].longitude)
            let to = CLLocation(latitude: coordinates[i].latitude, longitude: coordinates[i].longitude)
            let segmentDistance = from.distance(from: to)
            print("Distanza segmento \(i): \(segmentDistance)")
            totalDistance += segmentDistance
        }
        print("Distanza totale: \(totalDistance)")
        return totalDistance
    }

    private func getMainBehavior(_ behaviorTimes: [String: TimeInterval]) -> String? {
        return behaviorTimes.max(by: { $0.value < $1.value })?.key
    }

    private func behaviorIcon(for behavior: String) -> String {
        switch behavior {
        case "cruise": return "car"
        case "fun": return "sparkles"
        case "overtake": return "arrow.left.and.right"
        case "traffic": return "exclamationmark.triangle"
        case "wait": return "hourglass"
        default: return "questionmark"
        }
    }

    private func behaviorColor(for behavior: String) -> Color {
        switch behavior {
        case "cruise": return .green
        case "fun": return .yellow
        case "overtake": return .orange
        case "traffic": return .red
        case "wait": return .blue
        default: return .black
        }
    }
}

extension Double {
    func rounded(toDecimalPlaces places: Int) -> Double {
        let divisor = pow(10.0, Double(places))
        return (self * divisor).rounded() / divisor
    }
}
