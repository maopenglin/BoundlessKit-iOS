//
//  DopeAPIPortal.swift
//  Pods
//
//  Created by Akash Desai on 7/16/16.
//
//

import Foundation
import AdSupport

@objc
public class DopamineAPI : NSObject{
    
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
        var payload = DopamineProperties.current.apiCredentials
        
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
        var payload = DopamineProperties.current.apiCredentials
        
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
        var payload = DopamineProperties.current.apiCredentials
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
        var payload = DopamineProperties.current.apiCredentials
        
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
    
    private lazy var session = URLSession.shared
    
    /// This function sends a request to the DopamineAPI
    ///
    /// - parameters:
    ///     - callType: The type of call to send.
    ///     - payload: A JSON compatible dictionary to send.
    ///     - timeout: A timeout, in seconds, for the request. Defaults to 3 seconds.
    ///     - completion: A closure with a JSON formatted dictionary.
    ///
    private func send(call type: CallType, with payload: [String:Any], timeout:TimeInterval = 3.0, completion: @escaping ([String: Any]) -> Void) {
//        if true {
//            return
//        }
        guard let url = URL(string: type.path) else {
            DopeLog.debug("Invalid url <\(type.path)>")
            return
        }
        
        DopeLog.debug("Preparing \(type) api call to \(url.absoluteString)...")
        do {
            var request = URLRequest(url: url)
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpMethod = "POST"
            request.timeoutInterval = timeout
            let jsonPayload = try JSONSerialization.data(withJSONObject: payload, options: JSONSerialization.WritingOptions())
//            DopeLog.debugLog("sending raw payload:\(jsonPayload.debugDescription)")   // hex 16 chars
            request.httpBody = jsonPayload
            
            let callStartTime = Int64( 1000*NSDate().timeIntervalSince1970 )
            let task = session.dataTask(with: request, completionHandler: { responseData, responseURL, error in
                var responseDict: [String : Any] = [:]
                defer { completion(responseDict) }
                
                if responseURL == nil {
                    DopeLog.debug("❌ invalid response:\(String(describing: error?.localizedDescription))")
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
                    // turn the response into a json object
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
//                    DopeLog.debug("✅\(type.path) call got response:\(responseDict.debugDescription)")
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
                    
                } catch {
                    let message = "❌ Error reading \(type.path) response data: \(responseData.debugDescription)"
                    DopeLog.debug(message)
                    Telemetry.storeException(className: "JSONSerialization", message: message)
                    return
                }
                
            })
            
            // send request
//            DopeLog.debug("Sending \(type.path) api call with payload: \(payload as AnyObject)")
            task.resume()
            
        } catch {
            let message = "Error sending \(type.path) api call with payload:(\(payload as AnyObject))"
            DopeLog.debug(message)
            Telemetry.storeException(className: "JSONSerialization", message: message)
        }
    }
    
}
