//
//  DopeTimer.swift
//  DopamineKit
//
//  Created by Akash Desai on 11/9/17.
//

import Foundation
import SystemConfiguration.CaptiveNetwork
import CoreBluetooth

internal class DopeInfo : NSObject {
    
    static let shared = DopeInfo()
    
    fileprivate static var timeMarkers = NSMutableDictionary()
    
    static func trackStartTime(for id: String) -> NSDictionary {
        let start = Date()
        timeMarkers.setValue(start, forKey: id)
        return ["start": Int64(1000*start.timeIntervalSince1970)]
    }
    
    static func timeTracked(for id: String) -> NSDictionary {
        defer {
            timeMarkers.removeObject(forKey: id)
        }
        let result = NSMutableDictionary()
        let end = Date()
        result["end"] = Int64(1000*end.timeIntervalSince1970)
        if let start = timeMarkers.value(forKey: id) as? Date {
            result["start"] = Int64(1000*start.timeIntervalSince1970)
            result["spent"] = Int64(1000*end.timeIntervalSince(start))
        }
        return result
    }
    
    
    
    
    static var mySSID: String? {
        if let interfaces = CNCopySupportedInterfaces(),
            let interfacesArray = interfaces as? [String],
            interfacesArray.count > 0,
            let unsafeInterfaceData = CNCopyCurrentNetworkInfo(interfacesArray[0] as CFString),
            let interfaceData = unsafeInterfaceData as? Dictionary <String,AnyObject>,
            let ssid = interfaceData[kCNNetworkInfoKeySSID as String] as? String
            {
            return ssid
        } else {
            return nil
        }
    }
    
}
