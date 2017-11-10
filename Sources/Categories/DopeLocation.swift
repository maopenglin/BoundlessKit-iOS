//
//  DopeLocation.swift
//  DopamineKit
//
//  Created by Akash Desai on 11/9/17.
//

import Foundation
import CoreLocation

@objc
public class DopeLocation : NSObject, CLLocationManagerDelegate {
    
    @objc public static var shared = DopeLocation()
    public var locationManager: CLLocationManager!
    
    fileprivate var lastLocation: CLLocation?// = CLLocation()
    fileprivate var lastActive: Date?
    fileprivate var expiresIn: Double = 3000
    fileprivate var queue = OperationQueue()
    
    fileprivate override init() {
        super.init()
        locationManager = CLLocationManager()
        locationManager.delegate = self
        locationManager.requestAlwaysAuthorization()
        locationManager.startUpdatingLocation()
    }
    
    public func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        print("In didChangeAuthorizationStatus status:\(status)")
    }
    
    public func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        print("Location:\(locations.last?.description ?? "nil")")
        
        locationManager.stopUpdatingLocation()
        lastActive = Date()
        if let location = locations.last {
            lastLocation = location
        }
        queue.isSuspended = false
    }
    
    public func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print(error)
    }
    
    public func getLocation(callback: @escaping ([String: Any]?)->()) {
        if let lastLocation = lastLocation,
            let lastActive = lastActive,
            Date().timeIntervalSince(lastActive) < expiresIn
        {
            callback(["lat": lastLocation.coordinate.latitude, "long": lastLocation.coordinate.longitude])
        } else {
            DispatchQueue.main.async {
                self.queue.isSuspended = true
                self.queue.addOperation {
                    var dict: [String: Any]?
                    if let lastLocation = self.lastLocation {
                        dict = ["lat": lastLocation.coordinate.latitude, "long": lastLocation.coordinate.longitude]
                    }
                    callback(dict)
                }
                self.locationManager.startUpdatingLocation()
                print("Started locationmanager")
                DispatchQueue.global().asyncAfter(deadline: .now() + 3) {
                    self.queue.isSuspended = false
                }
            }
        }
    }
}
