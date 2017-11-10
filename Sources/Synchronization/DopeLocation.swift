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
    fileprivate var timeAccuracy: TimeInterval = 3
    
    fileprivate var queue = OperationQueue()
    
    fileprivate override init() {
        super.init()
        locationManager = CLLocationManager()
        locationManager.delegate = self
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
    }
    
    public func getLocation(callback: @escaping ([String: Any]?)->()) {
        if !canGetLocation {
            DopeLog.debug("Cannnot get location")
            callback(nil)
        } else if let lastLocation = lastLocation, Date() < expiresAt {
            DopeLog.debug("Last location available")
            callback(["lat": lastLocation.coordinate.latitude, "long": lastLocation.coordinate.longitude])
        } else {
            DopeLog.debug("Getting location...")
            self.queue.isSuspended = true
            self.queue.addOperation {
                if let lastLocation = self.lastLocation {
                    callback(["lat": lastLocation.coordinate.latitude, "long": lastLocation.coordinate.longitude])
                } else {
                    callback(nil)
                }
            }
            DispatchQueue.global(qos: .userInitiated).async {
                self.locationManager.startUpdatingLocation()
                DopeLog.debug("Started locationmanager")
            }
            // Stop waiting for location after 3 seconds
            DispatchQueue.global().asyncAfter(deadline: .now() + 3) {
                if self.queue.isSuspended {
                    DopeLog.debug("getLocation() timed out")
                    self.canGetLocation = false
                    self.queue.isSuspended = false
                }
            }
        }
    }
}
