//
//  DopeLocation.swift
//  DopamineKit
//
//  Created by Akash Desai on 11/9/17.
//

import Foundation
import CoreLocation

class DopeLocation : NSObject, CLLocationManagerDelegate {
    
    fileprivate static var _shared: DopeLocation?
    @objc public static var shared: DopeLocation {
        get {
            if let _shared = _shared {
                return _shared
            } else {
                _shared = DopeLocation()
                return _shared!
            }
        }
    }
    
    public var locationManager: CLLocationManager?
    public var canGetLocation: Bool = true
    fileprivate var lastLocation: CLLocation?
    fileprivate var expiresAt = Date()
    fileprivate var timeAccuracy: TimeInterval = 60 //seconds
    
    fileprivate var queue = OperationQueue()
    
    fileprivate override init() {
        super.init()
        DispatchQueue.main.async {
            self.locationManager = CLLocationManager()
            self.locationManager?.delegate = self
        }
    }
    
    public func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if status == .authorizedAlways || status == .authorizedWhenInUse {
            canGetLocation = true
        } else {
            canGetLocation = false
        }
    }
    
    public func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        locationManager?.stopUpdatingLocation()
        expiresAt = Date().addingTimeInterval(timeAccuracy)
        if let location = locations.last {
            lastLocation = location
        }
        queue.isSuspended = false
    }
    
    public func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        canGetLocation = false
        queue.isSuspended = false
    }
    
    public func getLocation(callback: @escaping ([String: Any]?)->()) {
        guard DopamineConfiguration.current.locationObservations else {
            callback(nil)
            return
        }
        
        if !canGetLocation {
            callback(nil)
        } else if Date() < expiresAt {
            callback(locationInfo)
        } else {
            forceUpdate() {
                callback(self.locationInfo)
            }
        }
    }
    
    func forceUpdate(completion: @escaping ()->()) {
        DispatchQueue.global().async {
            defer {
                self.queue.addOperation(completion)
            }
            
            if self.queue.isSuspended {
                return
            }
            self.queue.isSuspended = true
            
            DispatchQueue.main.async {
                self.locationManager?.startUpdatingLocation()
            }
            // If no location after 3 seconds unsuspend the queue
            DispatchQueue.global().asyncAfter(deadline: .now() + 3) {
                if self.queue.isSuspended {
                    self.queue.isSuspended = false
                }
            }
        }
    }
    
    fileprivate var locationInfo: [String: Any]? {
        get {
            if let lastLocation = self.lastLocation {
                let utc = Int64(1000*lastLocation.timestamp.timeIntervalSince1970)
                let timezoneOffset = Int64(1000*NSTimeZone.default.secondsFromGMT())
                let localTime = utc + timezoneOffset
                var locationInfo: [String: Any] = ["utc": utc,
                                                   "timezoneOffset": timezoneOffset,
                                                   "localTime": localTime,
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
