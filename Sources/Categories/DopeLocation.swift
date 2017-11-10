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
    
    public func getLocation(callback: @escaping (CLLocation?)->()) {
        if let lastActive = lastActive,
            Date().timeIntervalSince(lastActive) < expiresIn
        {
            callback(lastLocation)
        }
        
        else {
            queue.isSuspended = true
            queue.addOperation({
                callback(self.lastLocation)
            })
            DispatchQueue.main.async {
                self.locationManager.startUpdatingLocation()
                print("Started locationmanager")
            }
        }
    }
}
