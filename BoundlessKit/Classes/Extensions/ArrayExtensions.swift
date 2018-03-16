//
//  ArrayExtensions.swift
//  BoundlessKit
//
//  Created by Akash Desai on 12/1/17.
//

import Foundation

extension Array {
    func selectRandom() -> Element? {
        guard !isEmpty else { return nil }
        return self[Int(arc4random_uniform(UInt32(self.count)))]
    }
}

internal class WeakObject {
    weak var value: AnyObject?
    init (value: AnyObject) {
        self.value = value
    }
}

extension Array where Element:WeakObject {
    mutating func compact() {
        self = self.filter { $0.value != nil }
    }
}
