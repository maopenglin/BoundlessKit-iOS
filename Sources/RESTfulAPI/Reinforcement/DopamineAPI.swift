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
    
    static var logCalls = false
    
    /// Valid API actions appeneded to the DopamineAPI URL
    ///
    internal enum CallType{
        case track, report, refresh, telemetry
        var path:String{ switch self{
        case .track: return "https://api.usedopamine.com/v4/app/track/"
        case .report: return "https://api.usedopamine.com/v4/app/report/"
        case .refresh: return "https://api.usedopamine.com/v4/app/refresh/"
        case .telemetry: return "https://api.usedopamine.com/v4/telemetry/sync/"
            }
        }
    }
    
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
    
    internal lazy var httpClient = HTTPClient()
    
    /// This function sends a request to the DopamineAPI
    ///
    /// - parameters:
    ///     - callType: The type of call to send.
    ///     - payload: A JSON compatible dictionary to send.
    ///     - timeout: A timeout, in seconds, for the request. Defaults to 3 seconds.
    ///     - completion: A closure with a JSON formatted dictionary.
    ///
    private func send(call type: CallType, with payload: [String:Any], completion: @escaping ([String: Any]) -> Void) {
//        return
        guard let url = URL(string: type.path) else {
            DopeLog.debug("Invalid url <\(type.path)>")
            return
        }
        
        let callStartTime = Int64( 1000*NSDate().timeIntervalSince1970 )
        let task = httpClient.post(to: url, jsonObject: payload) { responseData, responseURL, error in
            var responseDict: [String : Any] = [:]
            defer { completion(responseDict) }
            
            if responseURL == nil {
                DopeLog.debug("❌ \(type.path) call got invalid response:\(String(describing: error?.localizedDescription))")
                responseDict["error"] = error?.localizedDescription
                switch type {
                case .track:
                    Telemetry.setResponseForTrackSync(-1, error: error?.localizedDescription, whichStartedAt: callStartTime)
                case .report:
                    Telemetry.setResponseForReportSync(-1, error: error?.localizedDescription, whichStartedAt: callStartTime)
                case .refresh:
                    if let actionID = payload["actionID"] as? String {
                        Telemetry.setResponseForCartridgeSync(forAction: actionID, -1, error: error?.localizedDescription, whichStartedAt: callStartTime)
                    }
                case .telemetry:
                    break
                }
                return
            }
            
            do {
                guard let data = responseData,
                    let dict = try JSONSerialization.jsonObject(with: data, options: []) as? [String: AnyObject]
                    else {
                        let json = responseData.flatMap({ NSString(data: $0, encoding: String.Encoding.utf8.rawValue) }) ?? ""
                        let message = "❌ Error reading \(type.path) response data, not a dictionary: \(json)"
                        DopeLog.debug(message)
                        Telemetry.storeException(className: "JSONSerialization", message: message)
                        return
                }
                responseDict = dict
            } catch {
                let message = "❌ Error reading \(type.path) response data: \(responseData.debugDescription)"
                DopeLog.debug(message)
                Telemetry.storeException(className: "JSONSerialization", message: message)
                return
            }
            
            var statusCode: Int = -2
            if let responseStatusCode = responseDict["status"] as? Int {
                statusCode = responseStatusCode
            }
            switch type {
            case .track:
                Telemetry.setResponseForTrackSync(statusCode, error: error?.localizedDescription, whichStartedAt: callStartTime)
            case .report:
                Telemetry.setResponseForReportSync(statusCode, error: error?.localizedDescription, whichStartedAt: callStartTime)
            case .refresh:
                if let actionID = payload["actionID"] as? String {
                    Telemetry.setResponseForCartridgeSync(forAction: actionID, statusCode, error: error?.localizedDescription, whichStartedAt: callStartTime)
                }
            case .telemetry:
                break
            }
            
            DopeLog.debug("✅\(type.path) call")
            if DopamineAPI.logCalls { DopeLog.debug("got response:\(responseDict.debugDescription)") }
        }
        
        // send request
        DopeLog.debug("Sending \(type.path) api call")
        if DopamineAPI.logCalls { DopeLog.debug("with payload: \(payload as AnyObject)") }
        task.resume()
        
    }
    
}

