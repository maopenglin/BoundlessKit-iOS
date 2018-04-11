//
//  BoundlessLocation.swift
//  BoundlessKit
//
//  Created by Akash Desai on 4/11/18.
//

import Foundation
import CoreLocation

class BoundlessLocation : NSObject, CLLocationManagerDelegate {
    
    static let shared = BoundlessLocation()
    
    public var locationManager: CLLocationManager?
    public var enabled: Bool = false
    fileprivate var current: CLLocation?
    fileprivate var expiresAt = Date()
    fileprivate var timeAccuracy: TimeInterval = 60 //seconds
    
    fileprivate var queue = OperationQueue()
    
    fileprivate override init() {
        super.init()
        guard let infoPlist = Bundle.main.infoDictionary,
            infoPlist["NSLocationWhenInUseUsageDescription"] != nil || infoPlist["NSLocationAlwaysAndWhenInUseUsageDescription"] != nil || infoPlist["NSLocationAlwaysUsageDescription"] != nil else {
                return
        }
        enabled = true
        DispatchQueue.main.async {
            self.locationManager = CLLocationManager()
            self.locationManager?.delegate = self
        }
    }
    
    public func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        enabled = status == .authorizedAlways || status == .authorizedWhenInUse
    }
    
    public func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        locationManager?.stopUpdatingLocation()
        expiresAt = Date().addingTimeInterval(timeAccuracy)
        if let location = locations.last {
            current = location
        }
        queue.isSuspended = false
    }
    
    public func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        enabled = false
        queue.isSuspended = false
    }
    
    public func getLocation(callback: @escaping ([String: Any]?)->()) {
//        guard DopamineConfiguration.current.locationObservations else {
//            callback(nil)
//            return
//        }
        
        if !enabled {
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
        if !self.queue.isSuspended {
            self.queue.isSuspended = true
            DispatchQueue.main.async {
                self.locationManager?.startUpdatingLocation()
            }
        }
        self.queue.addOperation(completion)
    }
    
    fileprivate var locationInfo: [String: Any]? {
        get {
            if let lastLocation = self.current {
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
