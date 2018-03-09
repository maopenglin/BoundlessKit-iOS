//
//  BoundlessAction.swift
//  BoundlessKit
//
//  Created by Akash Desai on 3/6/18.
//

import Foundation

internal class BoundlessAction : NSObject {
    
    let name: String
    var metadata: [String: Any]
    let utc:Int64
    let timezoneOffset:Int64
    
    init(_ name: String,
         _ metadata: [String:Any] = [:],
         _ utc: Int64 = Int64( 1000*Date().timeIntervalSince1970 ),
         _ timezoneOffset: Int64 = Int64( 1000*NSTimeZone.default.secondsFromGMT() )) {
        self.name = name
        self.utc = utc
        self.metadata = metadata
        self.timezoneOffset = timezoneOffset
    }
    
}

extension BoundlessAction {
    func toJSONType() -> [String : Any] {
        var jsonObject: [String:Any] = [:]
        
        jsonObject["actionID"] = name
        jsonObject["metadata"] = metadata
        jsonObject["time"] = [
            ["timeType":"utc", "value": NSNumber(value: utc)],
            ["timeType":"deviceTimezoneOffset", "value": NSNumber(value: timezoneOffset)]
        ]
        
        return jsonObject
    }
}
