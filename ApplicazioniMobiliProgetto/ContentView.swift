//
//  ContentView.swift
//  ApplicazioniMobiliProgetto
//
//  Created by Simone Paolo Petta on 20/06/24.
//

import SwiftUI

struct ContentView: View {
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
}
