//
//  MotionManager.swift
//  ApplicazioniMobiliProgetto
//
//  Created by Simone Paolo Petta on 20/06/24.
//

import SwiftUI
import CoreMotion
import CoreML

class MotionManager: ObservableObject {
    internal var motionManager = CMMotionManager()
    private var timer: Timer?
    
    @Published var accX: [Double] = []
    @Published var accY: [Double] = []
    @Published var accZ: [Double] = []
    @Published var gyrX: [Double] = []
    @Published var gyrY: [Double] = []
    @Published var gyrZ: [Double] = []
    @Published var magX: [Double] = []
    @Published var magY: [Double] = []
    @Published var magZ: [Double] = []
    
    @Published var predictedBehavior: String = "Unknown"
    
    // Buffer per i dati
    private var bufferAccX: [Double] = []
    private var bufferAccY: [Double] = []
    private var bufferAccZ: [Double] = []
    private var bufferGyrX: [Double] = []
    private var bufferGyrY: [Double] = []
    private var bufferGyrZ: [Double] = []
    private var bufferMagX: [Double] = []
    private var bufferMagY: [Double] = []
    private var bufferMagZ: [Double] = []

    func startUpdates() {
        print("Starting update")
        
        if motionManager.isAccelerometerAvailable {
            motionManager.accelerometerUpdateInterval = 1.0 / 40.0 // 40 Hz
            motionManager.startAccelerometerUpdates(to: OperationQueue.current!) { (data, error) in
                if let trueData = data {
                    self.bufferAccX.append(trueData.acceleration.x)
                    self.bufferAccY.append(trueData.acceleration.y)
                    self.bufferAccZ.append(trueData.acceleration.z)
                    //print(trueData.acceleration.x, " ", trueData.acceleration.y, " ", trueData.acceleration.z)
                }
            }
        }
        
        if motionManager.isGyroAvailable {
            motionManager.gyroUpdateInterval = 1.0 / 40.0 // 40 Hz
            motionManager.startGyroUpdates(to: OperationQueue.current!) { (data, error) in
                if let trueData = data {
                    self.bufferGyrX.append(trueData.rotationRate.x)
                    self.bufferGyrY.append(trueData.rotationRate.y)
                    self.bufferGyrZ.append(trueData.rotationRate.z)
                    //print(trueData.rotationRate.x, " ", trueData.rotationRate.y, " ", trueData.rotationRate.z)
                }
            }
        }
        
        if motionManager.isMagnetometerAvailable {
            motionManager.magnetometerUpdateInterval = 1.0 / 40.0 // 40 Hz
            motionManager.startMagnetometerUpdates(to: OperationQueue.current!) { (data, error) in
                if let trueData = data {
                    self.bufferMagX.append(trueData.magneticField.x)
                    self.bufferMagY.append(trueData.magneticField.y)
                    self.bufferMagZ.append(trueData.magneticField.z)
                    //print(trueData.magneticField.x, " ", trueData.magneticField.y, " ", trueData.magneticField.z)
                }
            }
        }
        
        // Start a timer to fetch data every 10 seconds
        timer = Timer.scheduledTimer(withTimeInterval: 10.0, repeats: true) { _ in
            self.processData()
        }
    }
    
    func stopUpdates() {
        print("Stop update")
        motionManager.stopAccelerometerUpdates()
        motionManager.stopGyroUpdates()
        motionManager.stopMagnetometerUpdates()
        timer?.invalidate()
    }
    
    private func updateBuffers() {
        bufferAccX = Array(bufferAccX.suffix(bufferAccX.count / 2))
        bufferAccY = Array(bufferAccY.suffix(bufferAccY.count / 2))
        bufferAccZ = Array(bufferAccZ.suffix(bufferAccZ.count / 2))
        bufferGyrX = Array(bufferGyrX.suffix(bufferGyrX.count / 2))
        bufferGyrY = Array(bufferGyrY.suffix(bufferGyrY.count / 2))
        bufferGyrZ = Array(bufferGyrZ.suffix(bufferGyrZ.count / 2))
        bufferMagX = Array(bufferMagX.suffix(bufferMagX.count / 2))
        bufferMagY = Array(bufferMagY.suffix(bufferMagY.count / 2))
        bufferMagZ = Array(bufferMagZ.suffix(bufferMagZ.count / 2))
    }
    
    private func processData() {
        guard bufferAccX.count >= 500, bufferAccY.count >= 500, bufferAccZ.count >= 500,
              bufferGyrX.count >= 500, bufferGyrY.count >= 500, bufferGyrZ.count >= 500,
              bufferMagX.count >= 500, bufferMagY.count >= 500, bufferMagZ.count >= 500 else {
            print("Not enough data")
            return
        }
        
        print("Start processing ML")
        
        let statsAccX = calculateStatistics(data: bufferAccX)
        let statsAccY = calculateStatistics(data: bufferAccY)
        let statsAccZ = calculateStatistics(data: bufferAccZ)
        let statsGyrX = calculateStatistics(data: bufferGyrX)
        let statsGyrY = calculateStatistics(data: bufferGyrY)
        let statsGyrZ = calculateStatistics(data: bufferGyrZ)
        let statsMagX = calculateStatistics(data: bufferMagX)
        let statsMagY = calculateStatistics(data: bufferMagY)
        let statsMagZ = calculateStatistics(data: bufferMagZ)
        
        do {
            let model = try DrivingBehaviorClassifier(configuration: MLModelConfiguration())
            let input = DrivingBehaviorClassifierInput(
                Acc_X_mean: statsAccX.mean,
                Acc_X_median: statsAccY.mean,
                Acc_X_std: statsAccZ.mean,
                Acc_X_max: statsAccX.median,
                Acc_X_min: statsAccY.median,
                Acc_Y_mean: statsAccZ.median,
                Acc_Y_median: statsAccX.stddev,
                Acc_Y_std: statsAccY.stddev,
                Acc_Y_max: statsAccZ.stddev,
                Acc_Y_min: statsAccX.max,
                Acc_Z_mean: statsAccY.max,
                Acc_Z_median: statsAccZ.max,
                Acc_Z_std: statsAccX.min,
                Acc_Z_max: statsAccY.min,
                Acc_Z_min: statsAccZ.min,
                Gyr_X_mean: statsGyrX.mean,
                Gyr_X_median: statsGyrX.median,
                Gyr_X_std: statsGyrX.stddev,
                Gyr_X_max: statsGyrX.max,
                Gyr_X_min: statsGyrX.min,
                Gyr_Y_mean: statsGyrY.mean,
                Gyr_Y_median: statsGyrY.median,
                Gyr_Y_std: statsGyrY.stddev,
                Gyr_Y_max: statsGyrY.max,
                Gyr_Y_min: statsGyrY.min,
                Gyr_Z_mean: statsGyrZ.mean,
                Gyr_Z_median: statsGyrZ.median,
                Gyr_Z_std: statsGyrZ.stddev,
                Gyr_Z_max: statsGyrZ.max,
                Gyr_Z_min: statsGyrZ.min,
                Mag_X_mean: statsMagX.mean,
                Mag_X_median: statsMagX.median,
                Mag_X_std: statsMagX.stddev,
                Mag_X_max: statsMagX.max,
                Mag_X_min: statsMagX.min,
                Mag_Y_mean: statsMagY.mean,
                Mag_Y_median: statsMagY.median,
                Mag_Y_std: statsMagY.stddev,
                Mag_Y_max: statsMagY.max,
                Mag_Y_min: statsMagY.min,
                Mag_Z_mean: statsMagZ.mean,
                Mag_Z_median: statsMagZ.median,
                Mag_Z_std: statsMagZ.stddev,
                Mag_Z_max: statsMagZ.max,
                Mag_Z_min: statsMagZ.min
            )
            
            let prediction = try model.prediction(input: input)
            let categories = ["cruise", "fun", "overtake", "traffic", "wait"]
            if let predictedIndex = Int(prediction.classLabel), predictedIndex >= 0 && predictedIndex < categories.count {
                DispatchQueue.main.async {
                    self.predictedBehavior = categories[predictedIndex]
                }
            } else {
                DispatchQueue.main.async {
                    self.predictedBehavior = "Unknown"
                }
            }
            print("Predicted behavior: \(prediction.classLabel)")
            print("Prediction confidence: \(prediction.classProbability)")
        } catch {
            print("Error in prediction: \(error)")
        }
        
        self.updateBuffers()
        
    }
    
    private func calculateStatistics(data: [Double]) -> (mean: Double, median: Double, stddev: Double, max: Double, min: Double) {
            let mean = data.mean()
            let median = data.median()
            let stddev = data.standardDeviation()
            let max = data.max() ?? 0
            let min = data.min() ?? 0
            return (mean, median, stddev, max, min)
        }
}

extension Array where Element == Double {
    func mean() -> Double {
        return self.reduce(0, +) / Double(self.count)
    }
    
    func median() -> Double {
        let sorted = self.sorted()
        if self.count % 2 == 0 {
            return (sorted[self.count / 2] + sorted[self.count / 2 - 1]) / 2
        } else {
            return sorted[self.count / 2]
        }
    }
    
    func standardDeviation() -> Double {
        let mean = self.mean()
        let variance = self.map { pow($0 - mean, 2.0) }.reduce(0, +) / Double(self.count)
        return sqrt(variance)
    }
}

