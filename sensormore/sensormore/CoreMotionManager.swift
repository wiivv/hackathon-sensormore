//
//  CoreMotionManager.swift
//  sensormore
//
//  Created by Adrian Wong on 2019-07-09.
//  Copyright © 2019 Wiivv. All rights reserved.
//

import Foundation
import CoreMotion

protocol CoreMotionManagerCallback : class {
    func onAccelerometerUpdate(_ data: CMAcceleration)
    func onGyroUpdate(_ data: CMRotationRate)
    func onMagnetometerUpdate(_ data: CMMagneticField)
    func onDeviceMotionUpdate(_ attitude: CMAttitude, heading: Double)
}

extension CoreMotionManagerCallback {
    func onAccelerometerUpdate(_ data: CMAcceleration) {}
    func onGyroUpdate(_ data: CMRotationRate) {}
    func onMagnetometerUpdate(_ data: CMMagneticField) {}
    func onDeviceMotionUpdate(_ attitude: CMAttitude, heading: Double) {}
}

class CoreMotionManager {

    weak var manCallBack : CoreMotionManagerCallback?
    
    let motionManager = CMMotionManager()
    var timer: Timer!
    
    init(){
        motionManager.startAccelerometerUpdates()
        motionManager.startGyroUpdates()
        motionManager.startMagnetometerUpdates()
        motionManager.startDeviceMotionUpdates()
        
        timer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(CoreMotionManager.update), userInfo: nil, repeats: true)
    }
    
    @objc func update() {
        if let accelerometerData = motionManager.accelerometerData {
            manCallBack?.onAccelerometerUpdate(accelerometerData.acceleration)
        }
        if let gyroData = motionManager.gyroData {
            manCallBack?.onGyroUpdate(gyroData.rotationRate)
        }
        if let magnetometerData = motionManager.magnetometerData {
            manCallBack?.onMagnetometerUpdate(magnetometerData.magneticField)
        }
        if let deviceMotion = motionManager.deviceMotion {
            manCallBack?.onDeviceMotionUpdate(deviceMotion.attitude, heading: deviceMotion.heading)
        }
    }
}
