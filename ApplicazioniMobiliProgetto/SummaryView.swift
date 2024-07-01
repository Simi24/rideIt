//
//  SummaryView.swift
//  ApplicazioniMobiliProgetto
//
//  Created by Simone Paolo Petta on 25/06/24.
//

import SwiftUI
import MapKit
import Combine
import Foundation
import UIKit
import CoreData

struct SummaryView: View {
    var recordedPath: RecordedPath
    @EnvironmentObject var locationManager: LocationManager
    @Environment(\.presentationMode) var presentationMode
    var context = PersistenceController.shared.container.viewContext

    var body: some View {
            NavigationView {
                ScrollView {
                    VStack {
                        Text("Summary")
                            .font(.largeTitle)
                            .padding()
                        
                        ForEach(locationManager.categories, id: \.self) { category in
                            VStack(alignment: .leading) {
                                Text("\(emoji(for: category)) Behavior: \(category)")
                                    .font(.headline)
                                    .foregroundColor(behaviorColor(for: category))
                                                    
                                if let time = recordedPath.behaviorTimes[category] {
                                    Text("Time: \(formatTime(time))")
                                } else {
                                    Text("No time recorded for this behavior")
                                        .italic()
                                        .foregroundColor(.gray)
                                }
                            }
                                .padding()
                        }

                        MapView(path: recordedPath.segments.flatMap { $0.coordinates.map { $0.coordinate } },
                            behaviorColors: recordedPath.segments.map { behaviorColor(for: $0.behavior).uiColor() })
                                .edgesIgnoringSafeArea(.all)
                                .frame(height: 200)
                                .padding()
                        
                        VStack(alignment: .leading, spacing: 10) {
                            HStack{
                                Text("Travel Time: \(formatDuration(from: recordedPath.startTime, to: recordedPath.endTime))")
                                    .font(.title2)
                                    .padding()
                                    .cornerRadius(10)
                                    .font(.headline)
                                Image(systemName: "clock")
                                    .font(.title2)
                            }
                            
                            HStack{
                                Text("Trip Length : \(formatDistance(path: recordedPath))")
                                    .font(.title2)
                                    .padding()
                                    .cornerRadius(10)
                                    .font(.headline)
                                Image(systemName: "map")
                                    .font(.title2)
                            }
                            
                            if let mainBehavior = getMainBehavior(recordedPath.behaviorTimes) {
                                HStack {
                                    Text("Main Behavior: \(mainBehavior)")
                                        .font(.title2)
                                        .padding()
                                        .cornerRadius(10)
                                        .font(.headline)
                                        .foregroundColor(behaviorColor(for: mainBehavior))
                                    Text("\(emoji(for: mainBehavior))")
                                        .font(.title2)
                                }
                            }
                        }
                            .padding()
                        
                        Spacer()

                        Button(action: {
                            presentationMode.wrappedValue.dismiss()
                        }) {
                            Text("Back")
                                .font(.title)
                                .padding()
                                .background(Color.blue)
                                .cornerRadius(10)
                                .foregroundColor(.white)
                                .padding(.bottom, 20)
                        }
                    }
                }
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Menu {
                            Button(action: deletePath) {
                                Label {
                                    Text("Delete Path")
                                        .foregroundColor(.red)
                                } icon: {
                                    Image(systemName: "trash")
                                }
                            }
                        } label: {
                            Image(systemName: "ellipsis")
                        }
                    }
                }
            }
            .navigationBarBackButtonHidden(true)
        }
    
    private func deletePath() {
            // Fetch the specific RecordedPathEntity
            let fetchRequest = NSFetchRequest<RecordedPathEntity>(entityName: "RecordedPathEntity")
            fetchRequest.predicate = NSPredicate(format: "id == %@", recordedPath.id as CVarArg)
            
            do {
                let paths = try context.fetch(fetchRequest)
                if let pathEntity = paths.first {
                    context.delete(pathEntity)
                    try context.save()
                    presentationMode.wrappedValue.dismiss()
                }
            } catch {
                print("Failed to delete path: \(error)")
            }
        }

        private func formatTime(_ timeInterval: TimeInterval) -> String {
            let formatter = DateComponentsFormatter()
            formatter.allowedUnits = [.hour, .minute, .second]
            formatter.unitsStyle = .positional
            formatter.zeroFormattingBehavior = .pad
            return formatter.string(from: timeInterval) ?? "00:00:00"
        }

        private let dateFormatter: DateFormatter = {
            let formatter = DateFormatter()
            formatter.dateStyle = .short
            formatter.timeStyle = .medium
            return formatter
        }()
    
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
            return Color.blue
        default:
            return Color.black
        }
    }

    private func emoji(for behavior: String) -> String {
        switch behavior {
        case "cruise":
            return "🚗"
        case "fun":
            return "🎉"
        case "overtake":
            return "🚀"
        case "traffic":
            return "🚦"
        case "wait":
            return "⏳"
        default:
            return "❓"
        }
    }
}


