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

internal extension Method {
    func returnType() -> String {
        let bufferSize = 4
        let buffer = UnsafeMutablePointer<Int8>.allocate(capacity: bufferSize)
        method_getReturnType(self, buffer, bufferSize)
        let str = String(cString: buffer)
        buffer.deallocate(capacity: bufferSize)
        return str
    }
    
    func argTypes() -> String {
        let bufferSize = 4
        var index: UInt32 = 0
        let numArgs = method_getNumberOfArguments(self)
        var types = ""
        while (index < numArgs) {
            let buffer = UnsafeMutablePointer<Int8>.allocate(capacity: bufferSize)
            method_getArgumentType(self, index, buffer, bufferSize)
            let argType = String(cString: buffer)
            buffer.deallocate(capacity: bufferSize)
            types += argType
            index += 1
        }
        
        return types
    }
    
    func types() -> String {
        return returnType() + argTypes()
    }
}
