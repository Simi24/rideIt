//
//  LogView.swift
//  ApplicazioniMobiliProgetto
//
//  Created by Simone Paolo Petta on 29/06/24.
//

import Foundation
import SwiftUI

struct LogView: View {
    @State private var logContent: String = ""

    var body: some View {
        VStack {
            Text("Log File")
                .font(.largeTitle)
                .padding()

            ScrollView {
                Text(logContent)
                    .padding()
            }
            .onAppear {
                loadLogContent()
            }
        }
        .padding()
    }

    private func loadLogContent() {
        if let content = Log.getLogContents() {
            logContent = content
        } else {
            logContent = "Failed to load log file."
        }
    }
}
