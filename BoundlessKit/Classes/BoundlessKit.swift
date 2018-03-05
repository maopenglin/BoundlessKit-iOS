//
//  BoundlessKit.swift
//  BoundlessKit
//
//  Created by Akash Desai on 4/7/16.
//  Copyright © 2018 Boundless Mind. All rights reserved.
//

import Foundation
import CoreLocation

@objc
open class BoundlessKit : NSObject {
    
    /// A modifiable credentials path used for running tests
    ///
    @objc public static var testCredentials:[String:Any]?
    
    /// A modifiable identity used for running tests
    ///
    @objc public static func setDevelopmentId(_ id:String?, completion: @escaping (String?) -> ()) {
        if BoundlessKit.developmentIdentity != id {
            BoundlessKit.developmentIdentity = id
            BoundlessProperties.resetIdentity(completion: completion)
        }
    }
    @objc internal static var developmentIdentity:String?
    
    /// An optional identity used for production
    ///
    @objc public static func setProductionId(_ id:String?, completion: @escaping (String?) -> ()) {
        if BoundlessKit.productionIdentity != id {
            BoundlessKit.productionIdentity = id
            BoundlessProperties.resetIdentity(completion: completion)
        }
    }
    @objc internal static var productionIdentity:String?
    
    @objc public static let shared: BoundlessKit = BoundlessKit()
    public static let syncCoordinator = SyncCoordinator.shared
    
    private override init() {
        super.init()
    }
    
    /// This function sends an asynchronous tracking call for the specified action
    ///
    /// - parameters:
    ///     - actionID: Descriptive name for the action.
    ///     - metaData: Action details i.e. calories or streak_count.
    ///                  Must be JSON formattable (Number, String, Bool, Array, Object).
    ///                  Defaults to `nil`.
    ///
    @objc open static func track(_ actionID: String, metaData: [String: Any]? = nil) {
        guard BoundlessConfiguration.current.trackingEnabled else {
            return
        }
        // store the action to be synced
        DispatchQueue.global(qos: .background).async {
            let action = BoundlessAction(actionID: actionID, metaData:metaData)
            syncCoordinator.store(track: action)
//            BoundlessLog.debug("tracked:\(actionID) with metadata:\(String(describing: metaData))")
        }
    }
    
    /// This function intelligently chooses whether to reinforce a user action. The reinforcement function, passed as the completion, is run asynchronously on the queue.
    ///
    /// - parameters:
    ///     - actionID: Action name configured on the Boundless Dashboard
    ///     - metaData: Action details i.e. calories or streak_count.
    ///                  Must be JSON formattable (Number, String, Bool, Array, Object).
    ///                  Defaults to `nil`.
    ///     - completion: A closure with the reinforcement decision passed as a `String`.
    ///
    @objc open static func reinforce(_ actionID: String, metaData: [String: Any]? = nil, completion: @escaping (String) -> ()) {
        guard BoundlessConfiguration.current.reinforcementEnabled else {
            completion(Cartridge.defaultReinforcementDecision)
            return
        }
        
        let action = BoundlessAction(actionID: actionID, metaData: metaData)
        action.reinforcementDecision = syncCoordinator.retrieve(cartridgeFor: action.actionID).remove()
        
        DispatchQueue.main.async(execute: {
            completion(action.reinforcementDecision!)
        })
        
        // store the action to be synced
        syncCoordinator.store(report: action)
    }
    
}
