//
//  ContentView.swift
//  ApplicazioniMobiliProgetto
//
//  Created by Simone Paolo Petta on 20/06/24.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var locationManager = LocationManager()
    @State private var isTracking = false

    var body: some View {
        VStack {
            if locationManager.authorizationStatus == .notDetermined {
                Text("Requesting location access...")
            } else if locationManager.authorizationStatus == .denied {
                Text("Location access denied.")
            } else if locationManager.authorizationStatus == .authorizedWhenInUse || locationManager.authorizationStatus == .authorizedAlways {
                if isTracking {
                    Button("Stop Tracking") {
                        locationManager.stopTracking()
                        isTracking = false
                    }
                    Text("Tracking in progress...")
                } else {
                    Button("Start Tracking") {
                        locationManager.startTracking()
                        isTracking = true
                    }
                    Text("Ready to track your movements.")
                }
            } else {
                Text("Unknown authorization status.")
            }
            
            if let lastLocation = locationManager.lastLocation {
                Text("Last Location: \(lastLocation.coordinate.latitude), \(lastLocation.coordinate.longitude)")
            }
            
            Text("Predicted Behavior: \(locationManager.motionManager.predictedBehavior)")
                .padding()
            
            MapView()
                .edgesIgnoringSafeArea(.all)
                .environmentObject(locationManager)
        }
        .padding()
    }
}


#Preview {
    ContentView()
}


/*struct ContentView: View {
    @ObservedObject var motionManager = MotionManager()
        
        var body: some View {
            VStack {
                Text("Predicted Behavior: \(motionManager.predictedBehavior)")
                    .padding()
                
                Button(action: {
                    self.motionManager.startUpdates()
                    print("Start button")
                }) {
                    Text("Start")
                }
                .padding()
                
                Button(action: {
                    self.motionManager.stopUpdates()
                }) {
                    Text("Stop")
                }
                .padding()
            }
        }
}

#Preview {
    ContentView()
}*/
