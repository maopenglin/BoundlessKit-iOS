//
//  DopamineKit.swift
//  Dopamine functionality for swift
//
//  Created by Vince Enachescu on 4/7/16.
//  Copyright © 2016 Dopamine Labs. All rights reserved.
//

import Foundation
import CoreLocation

@objc
open class DopamineKit : NSObject {
    
    /// A modifiable credentials path used for running tests
    ///
    @objc public static var testCredentials:[String:Any]?
    
    /// A modifiable identity used for running tests
    ///
    @objc public static func setDevelopmentId(_ id:String?, completion: @escaping (String?) -> ()) {
        if DopamineKit.developmentIdentity != id {
            DopamineKit.developmentIdentity = id
            DopamineProperties.resetIdentity(completion: completion)
        }
    }
    @objc internal static var developmentIdentity:String?
    
    /// An optional identity used for production
    ///
    @objc public static func setProductionId(_ id:String?, completion: @escaping (String?) -> ()) {
        if DopamineKit.productionIdentity != id {
            DopamineKit.productionIdentity = id
            DopamineProperties.resetIdentity(completion: completion)
        }
    }
    @objc internal static var productionIdentity:String?
    
    @objc public static let shared: DopamineKit = DopamineKit()
    
    public static let syncCoordinator = SyncCoordinator.shared
    fileprivate let queue = OperationQueue()
    
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
        guard DopamineConfiguration.current.trackingEnabled else {
            return
        }
        // store the action to be synced
        shared.queue.addOperation {
            let action = DopeAction(actionID: actionID, metaData:metaData)
            syncCoordinator.store(track: action)
//            DopeLog.debug("tracked:\(actionID) with metadata:\(String(describing: metaData))")
        }
    }
    
    /// This function intelligently chooses whether to reinforce a user action. The reinforcement function, passed as the completion, is run asynchronously on the queue.
    ///
    /// - parameters:
    ///     - actionID: Action name configured on the Dopamine Dashboard
    ///     - metaData: Action details i.e. calories or streak_count.
    ///                  Must be JSON formattable (Number, String, Bool, Array, Object).
    ///                  Defaults to `nil`.
    ///     - completion: A closure with the reinforcement decision passed as a `String`.
    ///
    @objc open static func reinforce(_ actionID: String, metaData: [String: Any]? = nil, completion: @escaping (String) -> ()) {
        guard DopamineConfiguration.current.reinforcementEnabled else {
            return
        }
        shared.queue.addOperation {
            let action = DopeAction(actionID: actionID, metaData: metaData)
            let reinforcementDecision = DopamineConfiguration.current.reinforcementEnabled ? syncCoordinator.retrieve(cartridgeFor: action.actionID).remove() : Cartridge.defaultReinforcementDecision
            
            DispatchQueue.main.async {
                completion(reinforcementDecision)
                DopamineChanges.shared.delegate?.reinforcing?(actionID: actionID, with: reinforcementDecision)
            }
            
            // store the action to be synced
            action.reinforcementDecision = reinforcementDecision
            syncCoordinator.store(report: action)
        }
    }
    
}
