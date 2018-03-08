//
//  Extensions.swift
//  BoundlessKit
//
//  Created by Akash Desai on 3/7/18.
//

import Foundation

internal extension Selector {
    func withRandomString(length: Int = 6) -> Selector {
        var components = NSStringFromSelector(self).components(separatedBy: ":")
        components[0] += String.random(length: length)
        return NSSelectorFromString(components.joined(separator: ":"))
    }
}

internal extension NSString {
    static func random(length: Int = 6) -> String {
        let base = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"
        var randomString: String = ""
        
        for _ in 0..<length {
            let randomValue = arc4random_uniform(UInt32(base.count))
            randomString += "\(base[base.index(base.startIndex, offsetBy: Int(randomValue))])"
        }
        return randomString
    }
}
