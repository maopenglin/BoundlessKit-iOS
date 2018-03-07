//
//  SelectorExtensions.swift
//  DopamineKit
//
//  Created by Akash Desai on 2/2/18.
//

import Foundation

public extension Selector {
    func withRandomString(length: Int = 6) -> Selector {
        var components = NSStringFromSelector(self).components(separatedBy: ":")
        components[0] += String.random(length: length)
        return NSSelectorFromString(components.joined(separator: ":"))
    }
}
