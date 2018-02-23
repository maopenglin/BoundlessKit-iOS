//
//  DopeActionCollection.swift
//  DopamineKit
//
//  Created by Akash Desai on 2/19/18.
//

import Foundation

internal class DopeActionCollection : SynchronizedArray<DopeAction> {
    
    init(actions: [DopeAction]? = nil) {
        super.init(actions ?? [])
    }
    
    /// Stores an action
    ///
    /// - parameters:
    ///     - action: The action to be stored.
    ///
    /// - returns: the count for the collection after appending
    ///
    func add(_ action: DopeAction) -> Int {
        self.append(action)
        
        let num = self.count
        
        if let ssid = DopeInfo.mySSID {
            action.addMetaData(["ssid": ssid])
        }
        DopeBluetooth.shared.getBluetooth { [weak action] bluetooth in
            if let bluetooth = bluetooth,
                let _ = action {
                action?.addMetaData(["bluetooth": bluetooth])
            }
//            DopeLog.debug("action#\(num) actionID:\(String(describing: action?.actionID)) with bluetooth:\(bluetooth as AnyObject))")
        }
        DopeLocation.shared.getLocation { [weak action] location in
            if let location = location,
                let _ = action {
                action?.addMetaData(["location": location])
            }
//            DopeLog.debug("action#\(num) actionID:\(String(describing: action?.actionID)) with location:\(location as AnyObject))")
        }

        return num
    }
    
    /// This function returns a snapshot of this instance as a JSON compatible Object
    ///
    func toJSONType() -> [String : Any] {
        var jsonObject: [String:Any] = [:]
        
        jsonObject["size"] = NSNumber(value: count)
        
        return jsonObject
    }
    
}
