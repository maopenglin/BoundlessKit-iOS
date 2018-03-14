//
//  BoundlessContext.swift
//  BoundlessKit
//
//  Created by Akash Desai on 3/8/18.
//

import Foundation

class BoundlessContext : NSObject {
    
    static let queue = DispatchQueue.init(label: NSStringFromClass(BoundlessContext.self), attributes: .concurrent)
    
    static func getContext(completion:@escaping([String:Any]) -> Void) {
        queue.async {
            var context = [String:Any]()
            let group = DispatchGroup.init()
            
            group.enter()
            surroundingBluetooth() { bluetoothInfo in
                if let bluetoothInfo = bluetoothInfo {
                    context["bluetoothInfo"] = bluetoothInfo
                }
                group.leave()
            }
            
            group.enter()
            estimatedLocation() { locationInfo in
                if let locationInfo = locationInfo {
                    context["locationInfo"] = locationInfo
                }
                group.leave()
            }
            
            group.notify(queue: queue) {
                completion(context)
            }
        }
    }
    
    fileprivate static func surroundingBluetooth(completion:@escaping([String:Any]?) -> Void) {
        DispatchQueue.global().async {
            var bluetoothInfo = [String: Any]()
            bluetoothInfo["phone"] = ["signal": 32]
            completion(bluetoothInfo)
        }
    }
    
    fileprivate static func estimatedLocation(completion:@escaping([String:Any]?) -> Void) {
        DispatchQueue.global().async {
            var locationInfo = [String: Any]()
            locationInfo["altitude"] = 3
            completion(locationInfo)
        }
    }
    
}
