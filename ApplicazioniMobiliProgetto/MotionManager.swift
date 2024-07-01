//
//  MotionManager.swift
//  ApplicazioniMobiliProgetto
//
//  Created by Simone Paolo Petta on 20/06/24.
//

import SwiftUI
import CoreMotion
import CoreML
import simd

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
    @Published var bufferPitch: [Double] = []
    @Published var bufferRoll: [Double] = []
    @Published var bufferYaw: [Double] = []

    func startUpdates() {
        print("Starting update")
        
        if motionManager.isDeviceMotionAvailable {
                    motionManager.deviceMotionUpdateInterval = 1.0 / 40.0 // 40 Hz
                    
                    // Set correct frame
                    motionManager.startDeviceMotionUpdates(using: .xMagneticNorthZVertical, to: OperationQueue.current!) { (motion, error) in
                        if let motion = motion {
                            let pitch = self.radiansToDegrees(motion.attitude.pitch)
                            let roll = self.radiansToDegrees(motion.attitude.roll)
                            let yaw = self.radiansToDegrees(motion.attitude.yaw)
                            
                            // Change value for ENU with monitor up
                            let adjustedRoll = -pitch
                            let adjustedPitch = roll
                            let adjustedYaw = (450 - yaw).truncatingRemainder(dividingBy: 360) // Value between 0 and 360
                            //print(adjustedPitch, adjustedRoll, adjustedYaw)
                            
                            DispatchQueue.main.async {
                                self.bufferRoll.append(adjustedRoll)
                                self.bufferPitch.append(adjustedPitch)
                                self.bufferYaw.append(adjustedYaw)
                            }
                        }
                    }
                }
        
        if motionManager.isAccelerometerAvailable {
            motionManager.accelerometerUpdateInterval = 1.0 / 40.0 // 40 Hz
            motionManager.startAccelerometerUpdates(to: OperationQueue.current!) { (data, error) in
                if let trueData = data {
                    self.bufferAccX.append(trueData.acceleration.x * 9.81)
                    self.bufferAccY.append(trueData.acceleration.y * 9.81)
                    self.bufferAccZ.append(-trueData.acceleration.z * 9.81)
                    //print(trueData.acceleration.x * 10, " ", trueData.acceleration.y * 10, " ", trueData.acceleration.z * 10)
                }
            }
        }
        
        if motionManager.isGyroAvailable {
            motionManager.gyroUpdateInterval = 1.0 / 40.0 // 40 Hz
            motionManager.startGyroUpdates(to: OperationQueue.current!) { (data, error) in
                if let trueData = data {
                    self.bufferGyrX.append(trueData.rotationRate.x * 9.81)
                    self.bufferGyrY.append(trueData.rotationRate.y * 9.81)
                    self.bufferGyrZ.append(trueData.rotationRate.z * 9.81)
                    //print(trueData.rotationRate.x, " ", trueData.rotationRate.y, " ", trueData.rotationRate.z)
                }
            }
        }
        
        if motionManager.isMagnetometerAvailable {
            motionManager.magnetometerUpdateInterval = 1.0 / 40.0 // 40 Hz
            motionManager.startMagnetometerUpdates(to: OperationQueue.current!) { (data, error) in
                if let trueData = data {
                    self.bufferMagX.append(trueData.magneticField.x / 1000.0 )
                    self.bufferMagY.append(trueData.magneticField.y / 1000.0)
                    self.bufferMagZ.append(trueData.magneticField.z / 1000.0)
                    //print(trueData.magneticField.x / 1000.0, " ", trueData.magneticField.y / 1000.0, " ", trueData.magneticField.z / 1000.0)
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
        resetAllData()
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
        
        let statsPitch = calculateStatistics(data: bufferPitch)
        let statsRoll = calculateStatistics(data: bufferRoll)
        let statsYaw = calculateStatistics(data: bufferYaw)
        
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
                let model = try DrivingClassifierCreateMLEuler(configuration: MLModelConfiguration())
                let input = DrivingClassifierCreateMLEulerInput(
                    Acc_X_mean: statsAccX.mean,
                    Acc_X_median: statsAccX.median,
                    Acc_X_std: statsAccX.stddev,
                    Acc_X_max: statsAccX.max,
                    Acc_X_min: statsAccX.min,
                    Acc_Y_mean: statsAccY.mean,
                    Acc_Y_median: statsAccY.median,
                    Acc_Y_std: statsAccY.stddev,
                    Acc_Y_max: statsAccY.max,
                    Acc_Y_min: statsAccY.min,
                    Acc_Z_mean: statsAccZ.mean,
                    Acc_Z_median: statsAccZ.median,
                    Acc_Z_std: statsAccZ.stddev,
                    Acc_Z_max: statsAccZ.max,
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
                    Mag_Z_min: statsMagZ.min,
                    Roll_mean: statsRoll.mean,
                    Roll_median: statsRoll.median,
                    Roll_std: statsRoll.stddev,
                    Roll_max: statsRoll.max,
                    Roll_min: statsRoll.min,
                    Pitch_mean: statsYaw.mean,
                    Pitch_median: statsYaw.median,
                    Pitch_std: statsYaw.stddev,
                    Pitch_max: statsYaw.max,
                    Pitch_min: statsYaw.min,
                    Yaw_mean: statsPitch.mean,
                    Yaw_median: statsPitch.median,
                    Yaw_std: statsPitch.stddev,
                    Yaw_max: statsPitch.max,
                    Yaw_min: statsPitch.min
                )
            
            print("------ Start Prediction --------")
            print("Acc_X_mean: \(input.Acc_X_mean)")
                print("Acc_X_median: \(input.Acc_X_median)")
                print("Acc_X_std: \(input.Acc_X_std)")
                print("Acc_X_max: \(input.Acc_X_max)")
                print("Acc_X_min: \(input.Acc_X_min)")
                print("Acc_Y_mean: \(input.Acc_Y_mean)")
                print("Acc_Y_median: \(input.Acc_Y_median)")
                print("Acc_Y_std: \(input.Acc_Y_std)")
                print("Acc_Y_max: \(input.Acc_Y_max)")
                print("Acc_Y_min: \(input.Acc_Y_min)")
                print("Acc_Z_mean: \(input.Acc_Z_mean)")
                print("Acc_Z_median: \(input.Acc_Z_median)")
                print("Acc_Z_std: \(input.Acc_Z_std)")
                print("Acc_Z_max: \(input.Acc_Z_max)")
                print("Acc_Z_min: \(input.Acc_Z_min)")
                print("Gyr_X_mean: \(input.Gyr_X_mean)")
                print("Gyr_X_median: \(input.Gyr_X_median)")
                print("Gyr_X_std: \(input.Gyr_X_std)")
                print("Gyr_X_max: \(input.Gyr_X_max)")
                print("Gyr_X_min: \(input.Gyr_X_min)")
                print("Gyr_Y_mean: \(input.Gyr_Y_mean)")
                print("Gyr_Y_median: \(input.Gyr_Y_median)")
                print("Gyr_Y_std: \(input.Gyr_Y_std)")
                print("Gyr_Y_max: \(input.Gyr_Y_max)")
                print("Gyr_Y_min: \(input.Gyr_Y_min)")
                print("Gyr_Z_mean: \(input.Gyr_Z_mean)")
                print("Gyr_Z_median: \(input.Gyr_Z_median)")
                print("Gyr_Z_std: \(input.Gyr_Z_std)")
                print("Gyr_Z_max: \(input.Gyr_Z_max)")
                print("Gyr_Z_min: \(input.Gyr_Z_min)")
                print("Mag_X_mean: \(input.Mag_X_mean)")
                print("Mag_X_median: \(input.Mag_X_median)")
                print("Mag_X_std: \(input.Mag_X_std)")
                print("Mag_X_max: \(input.Mag_X_max)")
                print("Mag_X_min: \(input.Mag_X_min)")
                print("Mag_Y_mean: \(input.Mag_Y_mean)")
                print("Mag_Y_median: \(input.Mag_Y_median)")
                print("Mag_Y_std: \(input.Mag_Y_std)")
                print("Mag_Y_max: \(input.Mag_Y_max)")
                print("Mag_Y_min: \(input.Mag_Y_min)")
                print("Mag_Z_mean: \(input.Mag_Z_mean)")
                print("Mag_Z_median: \(input.Mag_Z_median)")
                print("Mag_Z_std: \(input.Mag_Z_std)")
                print("Mag_Z_max: \(input.Mag_Z_max)")
                print("Mag_Z_min: \(input.Mag_Z_min)")
            print("Roll_mean: \(input.Roll_mean)")
            print("Roll_median: \(input.Roll_median)")
            print("Roll_std: \(input.Roll_std)")
            print("Roll_max: \(input.Roll_max)")
            print("Roll_min: \(input.Roll_min)")
            print("Pitch_mean: \(input.Pitch_mean)")
            print("Pitch_median: \(input.Pitch_median)")
            print("Pitch_std: \(input.Pitch_std)")
            print("Pitch_max: \(input.Pitch_max)")
            print("Pitch_min: \(input.Pitch_min)")
            print("Yaw_mean: \(input.Yaw_mean)")
            print("Yaw_median: \(input.Yaw_median)")
            print("Yaw_std: \(input.Yaw_std)")
            print("Yaw_max: \(input.Yaw_max)")
            print("Yaw_min: \(input.Yaw_min)")
                
                let prediction = try model.prediction(input: input)
            if prediction.behavior != "" {
                DispatchQueue.main.async {
                    self.predictedBehavior = prediction.behavior
                }
            } else {
                DispatchQueue.main.async {
                    self.predictedBehavior = "Unknown"
                }
            }
            Log.printAndLog("Predicted behavior: \(prediction.behavior), Prediction confidence: \(prediction.behaviorProbability)")
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
    
    func resetAllData() {
            accX.removeAll()
            accY.removeAll()
            accZ.removeAll()
            gyrX.removeAll()
            gyrY.removeAll()
            gyrZ.removeAll()
            magX.removeAll()
            magY.removeAll()
            magZ.removeAll()
            predictedBehavior = "Unknown"
            bufferAccX.removeAll()
            bufferAccY.removeAll()
            bufferAccZ.removeAll()
            bufferGyrX.removeAll()
            bufferGyrY.removeAll()
            bufferGyrZ.removeAll()
            bufferMagX.removeAll()
            bufferMagY.removeAll()
            bufferMagZ.removeAll()
        }
    
    func normalizeData(_ data: [Double]) -> [Double] {
        let mean = data.reduce(0, +) / Double(data.count)
        let std = sqrt(data.map { pow($0 - mean, 2) }.reduce(0, +) / Double(data.count))
        return data.map { ($0 - mean) / std }
    }

    
    func radiansToDegrees(_ radians: Double) -> Double {
        return radians * (180.0 / .pi)
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
        let variance = self.map { pow($0 - mean, 2.0) }.reduce(0, +) / Double(self.count - 1)
        return sqrt(variance)
    }
}

