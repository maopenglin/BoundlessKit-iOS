//
//  ArrayExtensions.swift
//  DopamineKit
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
