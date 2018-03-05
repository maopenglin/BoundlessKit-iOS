//
//  Extensions.swift
//  BoundlessKit
//
//  Created by Akash Desai on 11/27/17.
//

import Foundation

internal extension BoundlessKit {
    class var frameworkBundle: Bundle? {
        if let bundleURL = Bundle(for: BoundlessKit.classForCoder()).url(forResource: "BoundlessKit", withExtension: "bundle") {
            return Bundle(url: bundleURL)
        } else {
            BoundlessLog.debug("The BoundlessKit framework bundle cannot be found")
            return nil
        }
    }
}













