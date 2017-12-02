//
//  ArrayExtensions.swift
//  DopamineKit
//
//  Created by Akash Desai on 12/1/17.
//

import Foundation

extension Array {
    func selectRandom() -> Element? {
        if self.count == 0 { return nil }
        return self[Int(arc4random_uniform(UInt32(self.count)))]
    }
}
