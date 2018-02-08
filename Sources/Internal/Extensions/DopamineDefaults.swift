//
//  DopamineDefaults.swift
//  DopamineKit
//
//  Created by Akash Desai on 2/6/18.
//

import Foundation


@objc
open class DopamineDefaults : UserDefaults {
    fileprivate static var disableEnhancementKey = "disableEnhancement"
    
    @objc
    open static var enableEnhancement: Bool {
        get {
            return !UserDefaults.dopamine.bool(forKey: disableEnhancementKey)
        }
        set {
            UserDefaults.dopamine.setValue(!newValue, forKey: disableEnhancementKey)
        }
    }
}
