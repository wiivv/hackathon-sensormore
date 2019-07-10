//
//  CoreMotionManager.swift
//  sensormore
//
//  Created by Adrian Wong on 2019-07-09.
//  Copyright © 2019 Wiivv. All rights reserved.
//

import Foundation
import CoreMotion
import CoreLocation
import UIKit
import os.log

extension OSLog {
    private static var subsystem = Bundle.main.bundleIdentifier!

    /// Logs the view cycles like viewDidLoad.
    static let coreMotionManagerCatagory = OSLog(subsystem: subsystem, category: "CoreMotionManager")
}

protocol CoreMotionManagerCallback : class {
    func onAccelerometerUpdate(_ data: CMAcceleration, foreground: Bool)
    func onGyroUpdate(_ data: CMRotationRate)
    func onMagnetometerUpdate(_ data: CMMagneticField)
    func onDeviceMotionUpdate(_ attitude: CMAttitude, heading: Double)
}

extension CoreMotionManagerCallback {
    func onAccelerometerUpdate(_ data: CMAcceleration, foreground: Bool) {}
    func onGyroUpdate(_ data: CMRotationRate) {}
    func onMagnetometerUpdate(_ data: CMMagneticField) {}
    func onDeviceMotionUpdate(_ attitude: CMAttitude, heading: Double) {}
}

class CoreMotionManager : NSObject, CLLocationManagerDelegate {

    weak var manCallBack : CoreMotionManagerCallback?
    
    private let motionManager = CMMotionManager()
    private let locationManager = CLLocationManager()
    private let opQueue: OperationQueue = {
        let o = OperationQueue()
        o.name = "core-motion-updates"
        return o
    }()
    private var shouldRestartMotionUpdates = false
    private var inForeground = false

    var timer: Timer!
    
    override init(){
        super.init()
//        motionManager.startAccelerometerUpdates()
//        motionManager.startGyroUpdates()
//        motionManager.startMagnetometerUpdates()
//        motionManager.startDeviceMotionUpdates()
//
//        timer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(CoreMotionManager.update), userInfo: nil, repeats: true)
        
        self.shouldRestartMotionUpdates = true
        self.restartMotionUpdates()
        
        locationManager.stopUpdatingLocation()
        locationManager.requestAlwaysAuthorization()
        locationManager.startUpdatingLocation()
        locationManager.allowsBackgroundLocationUpdates = true
        locationManager.delegate = self
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(appDidEnterBackground),
                                               name: UIApplication.didEnterBackgroundNotification,
                                               object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(appDidBecomeActive),
                                               name: UIApplication.didBecomeActiveNotification,
                                               object: nil)
        
        inForeground = true
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self,
                                                  name: UIApplication.didEnterBackgroundNotification,
                                                  object: nil)
        NotificationCenter.default.removeObserver(self,
                                                  name: UIApplication.didBecomeActiveNotification,
                                                  object: nil)
    }
    
    func locationManager(_ manager: CLLocationManager,
                     didUpdateLocations locations: [CLLocation]) {
        let latestLocation: CLLocation = locations[locations.count - 1]
        os_log("Location Updates! %f %f", log: OSLog.coreMotionManagerCatagory, type: .info,
            latestLocation.coordinate.latitude,
            latestLocation.coordinate.longitude)
    }
    
    func locationManager(_ manager: CLLocationManager,
                     didFailWithError error: Error) {
        os_log("Location Updates Failed! %@", log: OSLog.coreMotionManagerCatagory, type: .info, error.localizedDescription)
    }
    
    @objc private func appDidEnterBackground() {
        self.restartMotionUpdates()
        inForeground = false
    }

    @objc private func appDidBecomeActive() {
        self.restartMotionUpdates()
        inForeground = true
    }
    
    private var ACC_LOG_COUNTER = 0
    private func restartMotionUpdates() {
        guard self.shouldRestartMotionUpdates else { return }

//        self.motionManager.stopDeviceMotionUpdates()
//        self.motionManager.startDeviceMotionUpdates(using: .xArbitraryZVertical, to: self.opQueue) { deviceMotion, error in
//            guard let deviceMotion = deviceMotion else { return }
//            print(deviceMotion)
//        }
        
        motionManager.stopAccelerometerUpdates()
        motionManager.startAccelerometerUpdates(to: self.opQueue, withHandler: {
            [weak self] (data, error) -> Void in
            
            DispatchQueue.main.async { [weak self] in
                guard let accel = data?.acceleration else {
                    return
                }
                
                self?.ACC_LOG_COUNTER += 1
                if ((self?.ACC_LOG_COUNTER ?? 1) % 10 == 0) {
                    os_log("Accelerometer Updates! %f %f %f", log: OSLog.coreMotionManagerCatagory, type: .info, accel.x, accel.y, accel.z)
                }
                
                self?.manCallBack?.onAccelerometerUpdate(accel, foreground: self!.inForeground)
            }
        })
    }
    
    @objc func update() {
        if let accelerometerData = motionManager.accelerometerData {
            manCallBack?.onAccelerometerUpdate(accelerometerData.acceleration, foreground: self.inForeground)
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
