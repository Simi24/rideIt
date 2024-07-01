//
//  ContentView.swift
//  ApplicazioniMobiliProgetto
//
//  Created by Simone Paolo Petta on 20/06/24.
//

import SwiftUI
import CoreLocation

struct ContentView: View {
    @StateObject private var locationManager = LocationManager()
    @State private var isTracking = false
    @State private var startTime: Date?
    @State private var elapsedTime: TimeInterval = 0
    @State private var timer: Timer?
    @State private var showingSummary = false
    @State private var showingLog = false
    @State private var recordedPath: RecordedPath?

    var body: some View {
        TabView {
            ZStack {
                VStack(alignment: .center, spacing: 20) {
                    Text("Home")
                        .font(.largeTitle)
                        .cornerRadius(10)
                        .padding(.bottom)
                    Spacer()
                    
                    if locationManager.authorizationStatus == .notDetermined {
                        Text("Requesting location access...")
                            .font(.title)
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.black.opacity(0.7))
                            .cornerRadius(10)
                        
                        
                    } else if locationManager.authorizationStatus == .denied {
                        Text("Location access denied.")
                            .font(.title)
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.red.opacity(0.7))
                            .cornerRadius(10)
                        Button(action: {
                            locationManager.requestAuthorization()
                        }) {
                            Text("Please provide permission")
                                .font(.title)
                                .padding()
                                .background(Color.red)
                                .cornerRadius(10)
                                .foregroundColor(.white)
                                .padding(.bottom)
                        }
                    } else if locationManager.authorizationStatus == .authorizedWhenInUse || locationManager.authorizationStatus == .authorizedAlways {
                        VStack(spacing: 20) {
                            if isTracking {
                                VStack(spacing: 20){
                                    Text("Predicted Behavior:")
                                        .font(.largeTitle)
                                        .padding()
                                        .cornerRadius(10)
                                            VStack {
                                                Text("\(emoji(for: locationManager.motionManager.predictedBehavior))")
                                                    .font(.largeTitle)
                                                    .padding()
                                                    .background(behaviorColor(for: locationManager.motionManager.predictedBehavior))
                                                    .cornerRadius(10)
                                                    .foregroundColor(.white)
                                                Text(locationManager.motionManager.predictedBehavior)
                                                    .font(.largeTitle)
                                                    .padding()
                                                    .background(behaviorColor(for: locationManager.motionManager.predictedBehavior))
                                                    .cornerRadius(10)
                                                    .foregroundColor(.white)
                                            
                                        }
                                        .frame(maxWidth: .infinity)
                                        .padding()
                                        .background(behaviorColor(for: locationManager.motionManager.predictedBehavior))
                                        .cornerRadius(10)
                                }
                                
                                Text("Elapsed Time: \(timeString(from: elapsedTime))")
                                    .font(.title2)
                                    .padding()
                                    .background(Color.black.opacity(0.7))
                                    .cornerRadius(10)
                                    .foregroundColor(.white)
                                
                                Spacer()

                                Button(action: {
                                    locationManager.stopTracking()
                                    stopTimer()
                                    showingSummary = true
                                    isTracking = false
                                    recordedPath = locationManager.recordedPath
                                }) {
                                    Text("Stop Tracking")
                                        .font(.title)
                                        .padding()
                                        .background(Color.red)
                                        .cornerRadius(10)
                                        .foregroundColor(.white)
                                        .padding(.bottom)
                                }
                            } else {
                                Text("Place the phone horizontally")
                                    .font(.title2)
                                Image(systemName: "arrow.left")
                                    .font(.title)
                                Spacer()
                                Image("road")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 300, height: 300)
                                    .padding()
                                Spacer()
                                Button(action: {
                                    locationManager.startTracking()
                                    resetTimer()
                                    startTimer()
                                    isTracking = true
                                }) {
                                    Text("Start Tracking")
                                        .font(.title)
                                        .padding()
                                        .background(Color.green)
                                        .cornerRadius(10)
                                        .foregroundColor(.white)
                                        .padding(.bottom)
                                }
                            }
                        }
                    } else {
                        Text("Unknown authorization status.")
                            .font(.title)
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.gray.opacity(0.7))
                            .cornerRadius(10)
                    }
                }
                .padding()
            }
            .tabItem {
                Label("Track", systemImage: "location.fill")
            }
            .sheet(isPresented: $showingSummary) {
                if let path = recordedPath {
                    SummaryView(recordedPath: path)
                        .environmentObject(locationManager)
                } else {
                    Text("No path recorded")
                }
            }
            .sheet(isPresented: $showingLog) {
                LogView()
            }

            PathListView()
                .tabItem {
                    Label("Paths", systemImage: "list.bullet")
                }
                .environmentObject(locationManager)
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

    private func startTimer() {
        startTime = Date()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            if let startTime = self.startTime {
                self.elapsedTime = Date().timeIntervalSince(startTime)
            }
        }
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }

    private func resetTimer() {
        startTime = nil
        elapsedTime = 0
    }

    private func timeString(from timeInterval: TimeInterval) -> String {
        let hours = Int(timeInterval) / 3600
        let minutes = (Int(timeInterval) % 3600) / 60
        let seconds = Int(timeInterval) % 60
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }
}

#Preview {
    ContentView()
}
