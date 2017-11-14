//
//  DopeLocation.swift
//  DopamineKit
//
//  Created by Akash Desai on 11/9/17.
//

import Foundation
import CoreLocation

class DopeLocation : NSObject, CLLocationManagerDelegate {
    
    @objc public static var shared = DopeLocation()
    public var locationManager: CLLocationManager!
    
    public var canGetLocation: Bool = true
    fileprivate var lastLocation: CLLocation?
    fileprivate var expiresAt = Date()
    fileprivate var timeAccuracy: TimeInterval = 5
    
    fileprivate var queue = OperationQueue()
    
    fileprivate override init() {
        super.init()
        DispatchQueue.main.sync {
            self.locationManager = CLLocationManager()
            self.locationManager.delegate = self
        }
    }
    
    public func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        DopeLog.debug("CLAuthorizationStatus:\(status.rawValue)")
        if status == .authorizedAlways || status == .authorizedWhenInUse {
            canGetLocation = true
        } else {
            canGetLocation = false
        }
    }
    
    public func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        DopeLog.debug("getLocation got location:\(locations.last?.description ?? "nil")")
        
        locationManager.stopUpdatingLocation()
        expiresAt = Date().addingTimeInterval(timeAccuracy)
        if let location = locations.last {
            lastLocation = location
        }
        queue.isSuspended = false
    }
    
    public func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        DopeLog.error("locationManager didFailWithError:\(error)")
        self.canGetLocation = false
    }
    
    public func getLocation(callback: @escaping ([String: Any]?)->()) {
        if !canGetLocation {
//            DopeLog.debug("Cannnot get location")
            callback(nil)
        } else if Date() < expiresAt {
//            DopeLog.debug("Last location available")
            callback(locationInfo)
        } else {
//            DopeLog.debug("Last location old")
            forceUpdate() {
                callback(self.locationInfo)
            }
        }
    }
    
    func forceUpdate(completion: @escaping ()->()) {
        
        if self.queue.isSuspended {
//            DopeLog.debug("Still updating location...")
            self.queue.addOperation(completion)
            return
        }
        
        self.queue.isSuspended = true
        self.queue.addOperation(completion)
        DopeLog.debug("Updating location...")
        DispatchQueue.global(qos: .userInitiated).async {
            self.locationManager.startUpdatingLocation()
            DopeLog.debug("Started locationmanager")
        }
        // If no location after 3 seconds unsuspend the queue
        DispatchQueue.global().asyncAfter(deadline: .now() + 3) {
            if self.queue.isSuspended {
                DopeLog.debug("Location update timed out")
                self.queue.isSuspended = false
            }
        }
    }
    
    fileprivate var locationInfo: [String: Any]? {
        get {
            if let lastLocation = self.lastLocation {
                var locationInfo: [String: Any] = ["timestamp": lastLocation.timestamp.timeIntervalSince1970 * 1000,
                                                   "latitude": lastLocation.coordinate.latitude,
                                                   "horizontalAccuracy": lastLocation.horizontalAccuracy,
                                                   "longitude": lastLocation.coordinate.longitude,
                                                   "verticalAccuracy": lastLocation.verticalAccuracy,
                                                   "altitude": lastLocation.altitude,
                                                   "speed": lastLocation.speed,
                                                   "course": lastLocation.course
                ]
                if let floor = lastLocation.floor?.level {
                    locationInfo["floor"] = floor
                }
                return locationInfo
            } else {
                return nil
            }
        }
    }
}
