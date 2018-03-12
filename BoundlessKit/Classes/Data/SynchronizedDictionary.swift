//
//  SynchronizedDictionary.swift
//  BoundlessKit
//
//  Created by Akash Desai on 3/10/18.
//

import Foundation

internal class SynchronizedDictionary<Key, Value> where Key : Hashable {
    fileprivate let queue = DispatchQueue(label: "SynchronizedDictionary", attributes: .concurrent)
    fileprivate var dict = [Key:Value]()
}


extension SynchronizedDictionary {
//    func filter(_ isIncluded: (Key, Value) -> Bool) -> [Key : Value] {
//        var result = [Key:Value]()
//        queue.sync {
//            result = self.dict.filter(isIncluded)
//        }
//        return result
//    }
    func flatMap<ElementOfResult>(_ transform: (Key, Value) -> ElementOfResult?) -> [ElementOfResult] {
        var result = [ElementOfResult]()
        queue.sync { result = self.dict.flatMap(transform) }
        return result
    }
}

// MARK: - Mutable
extension SynchronizedDictionary {
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
    
    func removeValue(forKey key: Key) {
        queue.async(flags: .barrier) {
            self.dict.removeValue(forKey: key)
        }
    }
}

// MARK: - Immutable
extension SynchronizedDictionary {
    
    var count: Int {
        var count = 0
        queue.sync {
            count = dict.count
        }
        return count
    }
    
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
}
