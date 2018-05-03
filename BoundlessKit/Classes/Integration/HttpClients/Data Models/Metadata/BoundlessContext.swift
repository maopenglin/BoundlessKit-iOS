//
//  BoundlessContext.swift
//  BoundlessKit
//
//  Created by Akash Desai on 3/8/18.
//

import Foundation

class BoundlessContext : NSObject {
    static var locationEnabled = false
    
    static let queue = DispatchQueue.init(label: NSStringFromClass(BoundlessContext.self), attributes: .concurrent)
    
    class func getContext(completion:@escaping([String:Any]) -> Void) {
        queue.async {
            var context = [String:Any]()
            let group = DispatchGroup()
            
            group.enter()
            BoundlessBluetooth.shared.getBluetooth { bluetoothInfo in
                //                BKLog.debug("Bluetoothinfo:\(bluetoothInfo as AnyObject)")
                if let bluetoothInfo = bluetoothInfo {
                    context["bluetoothInfo"] = bluetoothInfo
                }
                group.leave()
            }
            
            if locationEnabled {
                group.enter()
                BoundlessLocation.shared.getLocation { locationInfo in
                    if let locationInfo = locationInfo {
                        context["locationInfo"] = locationInfo
                    }
                    group.leave()
                }
            }
            
            group.notify(queue: DispatchQueue.global()) {
                completion(context)
            }
        }
    }
}
