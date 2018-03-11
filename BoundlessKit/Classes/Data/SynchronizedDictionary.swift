//
//  SynchronizedDictionary.swift
//  BoundlessKit
//
//  Created by Akash Desai on 3/10/18.
//

import Foundation

public class SynchronizedDictionary<Key, Value> where Key : Hashable {
    fileprivate let queue = DispatchQueue(label: "SynchronizedDictionary", attributes: .concurrent)
    fileprivate var dict = [Key:Value]()
}


public extension SynchronizedDictionary {
//    func filter(_ isIncluded: (Key, Value) -> Bool) -> [Key : Value] {
//        var result = [Key:Value]()
//        queue.sync {
//            result = self.dict.filter(isIncluded)
//        }
//        return result
//    }
    func flatMap<ElementOfResult>(_ transform: ((Key, Value)) -> ElementOfResult?) -> [ElementOfResult] {
        var result = [ElementOfResult]()
        queue.sync { result = self.dict.flatMap(transform) }
        return result
    }
}

public extension SynchronizedDictionary {
    var keys: [Key] {
        var keys: [Key] = []
        queue.sync {
            keys = Array(dict.keys)
        }
        return keys
    }
    
    var values: [Value] {
        var values: [Value] = []
        queue.sync {
            values = Array(dict.values)
        }
        return values
    }

    /// Accesses the element at the specified position if it exists.
    ///
    /// - Parameter index: The position of the element to access.
    /// - Returns: optional element if it exists.
    subscript(key: Key) -> Value? {
        get {
            var value: Value?

            queue.sync {
                value = dict[key]
            }

            return value
        }
        set {
            queue.async(flags: .barrier) {
                self.dict[key] = newValue
            }
        }
    }
}
