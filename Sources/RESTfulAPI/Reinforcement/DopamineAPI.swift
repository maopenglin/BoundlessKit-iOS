//
//  DopeAPIPortal.swift
//  Pods
//
//  Created by Akash Desai on 7/16/16.
//
//

import Foundation
import AdSupport

internal class DopamineAPI : NSObject{
    
    enum APICallTypes {
        case track, report, refresh, telemetry
        
        var clientType: HTTPClient.CallType {
            switch self {
            case .track: return .track
            case .report: return .report
            case .refresh: return .refresh
            case .telemetry: return .telemetry
            }
        }
    }
    
    static var logCalls = false
    
    internal static let shared: DopamineAPI = DopamineAPI()
    
    private override init() {
        super.init()
    }
    
    /// Send an array of actions to the DopamineAPI's `/track` path
    ///
    /// - parameters:
    ///     - actions: An array of actions to send.
    ///     - completion: A closure to handle the JSON formatted response.
    ///
    internal static func track(_ actions: [DopeAction], completion: @escaping ([String:Any]) -> ()){
        // create dict with credentials
        guard var payload = DopamineProperties.current?.apiCredentials else { return }
        
        // get JSON formatted actions
        var trackedActionsJSONArray = Array<Any>()
        for action in actions{
            trackedActionsJSONArray.append(action.toJSONType())
        }
        
        payload["actions"] = trackedActionsJSONArray
        
        shared.send(call: .track, with: payload, completion: completion)
    }

    /// Send an array of actions to the DopamineAPI's `/report` path
    ///
    /// - parameters:
    ///     - actions: An array of actions to send.
    ///     - completion: A closure to handle the JSON formatted response.
    ///
    internal static func report(_ actions: [DopeAction], completion: @escaping ([String:Any]) -> ()){
        guard var payload = DopamineProperties.current?.apiCredentials else { return }
        
        var reinforcedActionsArray = Array<Any>()
        for action in actions{
            reinforcedActionsArray.append(action.toJSONType())
        }
        
        payload["actions"] = reinforcedActionsArray
        
        shared.send(call: .report, with: payload, completion: completion)
    }
    
    /// Send an actionID to the DopamineAPI's `/refresh` path to generate a new cartridge of reinforcement decisions
    ///
    /// - parameters:
    ///     - actionID: The actionID that needs reinforcement decisions.
    ///     - completion: A closure to handle the JSON formatted response.
    ///
    internal static func refresh(_ actionID: String, completion: @escaping ([String:Any]) -> ()){
        guard var payload = DopamineProperties.current?.apiCredentials else { return }
        payload["actionID"] = actionID
        
        DopeLog.debug("Refreshing \(actionID)...")
        shared.send(call: .refresh, with: payload, completion: completion)
    }
    
    /// Send sync overviews and raised exceptions to the DopamineAPI's `/sync` path to increase service quality
    ///
    /// - parameters:
    ///     - syncOverviews: The array of SyncOverviews to send
    ///     - exceptions: The array of DopeExceptions to send
    ///     - completion: A closure to handle the JSON formatted response.
    ///
    internal static func sync( syncOverviews: [SyncOverview], dopeExceptions: [DopeException], completion: @escaping ([String:Any]) -> ()){
        guard var payload = DopamineProperties.current?.apiCredentials else { return }
        
        var syncOverviewJSONArray: [Any] = []
        for syncOverview in syncOverviews {
            syncOverviewJSONArray.append(syncOverview.toJSONType())
        }
        
        var exceptionsJSONArray: [Any] = []
        for exception in dopeExceptions {
            exceptionsJSONArray.append(exception.toJSONType())
        }
        
        payload["syncOverviews"] = syncOverviewJSONArray
        payload["exceptions"] = exceptionsJSONArray
        
        shared.send(call: .telemetry, with: payload, completion: completion)
    }
    
    internal var httpClient = HTTPClient() {
        didSet {
            print("Set httpclient")
        }
    }
    
    /// This function sends a request to the DopamineAPI
    ///
    /// - parameters:
    ///     - callType: The type of call to send.
    ///     - payload: A JSON compatible dictionary to send.
    ///     - timeout: A timeout, in seconds, for the request. Defaults to 3 seconds.
    ///     - completion: A closure with a JSON formatted dictionary.
    ///
    private func send(call type: APICallTypes, with payload: [String:Any], completion: @escaping ([String: Any]) -> Void) {
        
        let callStartTime = Int64( 1000*NSDate().timeIntervalSince1970 )
        let task = httpClient.post(type: type.clientType, jsonObject: payload) { response in
            
            completion(response ?? [:])
            
            let statusCode: Int = response?["status"] as? Int ?? -2
            switch type {
            case .track:
                Telemetry.setResponseForTrackSync(statusCode, whichStartedAt: callStartTime)
            case .report:
                Telemetry.setResponseForReportSync(statusCode, whichStartedAt: callStartTime)
            case .refresh:
                if let actionID = payload["actionID"] as? String {
                    Telemetry.setResponseForCartridgeSync(forAction: actionID, statusCode, whichStartedAt: callStartTime)
                }
            case .telemetry:
                break
            }
            
            if DopamineAPI.logCalls { DopeLog.debug("got response:\(response as AnyObject)") }
        }
        
        // send request
        if DopamineAPI.logCalls { DopeLog.debug("with payload: \(payload as AnyObject)") }
        task.start()
        
    }
    
}

