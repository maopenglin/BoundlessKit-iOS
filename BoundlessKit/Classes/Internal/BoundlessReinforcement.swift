//
//  BoundlessReinforcement.swift
//  BoundlessKit
//
//  Created by Akash Desai on 3/6/18.
//

import Foundation

internal class BoundlessReinforcement : NSObject {
    
    let name: String
    let actionID: String
    var metadata: [String: Any]
    let utc:Int64
    let timezoneOffset:Int64
    
    
    init(_ name: String,
         _ actionID: String,
         _ metadata: [String:Any] = [:],
         _ utc:Int64 = Int64( 1000*Date().timeIntervalSince1970 ),
         _ timezoneOffset: Int64 = Int64( 1000*NSTimeZone.default.secondsFromGMT() )) {
        self.name = name
        self.actionID = actionID
        self.utc = utc
        self.metadata = metadata
        self.timezoneOffset = timezoneOffset
    }
}


extension BoundlessReinforcement {
    func toJSONType() -> [String : Any] {
        var jsonObject: [String:Any] = [:]
        
        jsonObject["actionID"] = actionID
        jsonObject["reinforcementDecision"] = name
        jsonObject["metadata"] = metadata
        jsonObject["time"] = [
            ["timeType":"utc", "value": NSNumber(value: utc)],
            ["timeType":"deviceTimezoneOffset", "value": NSNumber(value: timezoneOffset)]
        ]
        
        return jsonObject
    }
}
