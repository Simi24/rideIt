//
//  Log.swift
//  ApplicazioniMobiliProgetto
//
//  Created by Simone Paolo Petta on 29/06/24.
//

import Foundation

class Log {
    static private func getLogFilePath() -> URL? {
        let fileManager = FileManager.default
        guard let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return nil
        }
        return documentsURL.appendingPathComponent("log.txt")
    }

    static func logToFile(_ message: String) {
        guard let logFilePath = getLogFilePath() else {
            print("Failed to get log file path")
            return
        }
        let logMessage = "\(Date()): \(message)\n"
        if FileManager.default.fileExists(atPath: logFilePath.path) {
            if let fileHandle = try? FileHandle(forWritingTo: logFilePath) {
                fileHandle.seekToEndOfFile()
                if let data = logMessage.data(using: .utf8) {
                    fileHandle.write(data)
                    fileHandle.closeFile()
                }
            }
        } else {
            try? logMessage.write(to: logFilePath, atomically: true, encoding: .utf8)
        }
    }

    static func printAndLog(_ message: String) {
        print(message)
        logToFile(message)
    }

    static func getLogContents() -> String? {
        guard let logFilePath = getLogFilePath() else {
            print("Failed to get log file path")
            return nil
        }
        return try? String(contentsOf: logFilePath, encoding: .utf8)
    }
}
