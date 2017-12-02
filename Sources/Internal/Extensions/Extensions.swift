//
//  Extensions.swift
//  DopamineKit
//
//  Created by Akash Desai on 11/27/17.
//

import Foundation

internal extension DopamineKit {
    class var frameworkBundle: Bundle? {
        if let bundleURL = Bundle(for: DopamineKit.classForCoder()).url(forResource: "DopamineKit", withExtension: "bundle") {
            return Bundle(url: bundleURL)
        } else {
            DopeLog.debug("The DopamineKit framework bundle cannot be found")
            return nil
        }
    }
}













