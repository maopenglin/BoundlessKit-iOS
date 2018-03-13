//
//  BKAction.swift
//  BoundlessKit
//
//  Created by Akash Desai on 3/6/18.
//

import Foundation

public class BKAction : NSObject {
    
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
    
    
    public required convenience init?(coder aDecoder: NSCoder) {
        return nil
    }
}

extension BKAction : NSCoding {
    public func encode(with aCoder: NSCoder) {
        
    }
}

extension BKAction {
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
