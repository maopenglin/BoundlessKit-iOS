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
        case track, report, refresh, sync
        var pathExtenstion:String{ switch self{
        case .track: return "app/track/"
        case .report: return "app/report/"
        case .refresh: return "app/refresh/"
        case .sync: return "telemetry/sync/"
            }
        }
    }
    
    internal static let sharedInstance: DopamineAPI = DopamineAPI()
    
    private static let dopamineAPIURL = "https://api.usedopamine.com/v4/"
    private static let clientSDKVersion = Bundle(for: DopamineAPI.self).object(forInfoDictionaryKey: "CFBundleShortVersionString") as! String
    private static let clientOS = "iOS"
    private static let clientOSVersion = UIDevice.current.systemVersion
    
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
        var payload = sharedInstance.configurationData
        
        // get JSON formatted actions
        var trackedActionsJSONArray = Array<Any>()
        for action in actions{
            trackedActionsJSONArray.append(action.toJSONType())
        }
        
        payload["actions"] = trackedActionsJSONArray
        payload["utc"] = NSNumber(value: Int64(Date().timeIntervalSince1970) * 1000)
        payload["timezoneOffset"] = NSNumber(value: Int64(NSTimeZone.default.secondsFromGMT()) * 1000)
        
        sharedInstance.send(call: .track, with: payload, completion: completion)
    }

    /// Send an array of actions to the DopamineAPI's `/report` path
    ///
    /// - parameters:
    ///     - actions: An array of actions to send.
    ///     - completion: A closure to handle the JSON formatted response.
    ///
    internal static func report(_ actions: [DopeAction], completion: @escaping ([String:Any]) -> ()){
        var payload = sharedInstance.configurationData
        
        var reinforcedActionsArray = Array<Any>()
        for action in actions{
            reinforcedActionsArray.append(action.toJSONType())
        }
        
        payload["actions"] = reinforcedActionsArray
        payload["utc"] = NSNumber(value: Int64(Date().timeIntervalSince1970) * 1000)
        payload["timezoneOffset"] = NSNumber(value: Int64(NSTimeZone.default.secondsFromGMT()) * 1000)
        
        sharedInstance.send(call: .report, with: payload, completion: completion)
    }
    
    /// Send an actionID to the DopamineAPI's `/refresh` path to generate a new cartridge of reinforcement decisions
    ///
    /// - parameters:
    ///     - actionID: The actionID that needs reinforcement decisions.
    ///     - completion: A closure to handle the JSON formatted response.
    ///
    internal static func refresh(_ actionID: String, completion: @escaping ([String:Any]) -> ()){
        var payload = sharedInstance.configurationData
        
        payload["actionID"] = actionID
        payload["utc"] = NSNumber(value: Int64(Date().timeIntervalSince1970) * 1000)
        payload["timezoneOffset"] = NSNumber(value: Int64(NSTimeZone.default.secondsFromGMT()) * 1000)
        
        DopamineKit.debugLog("Refreshing \(actionID)...")
        sharedInstance.send(call: .refresh, with: payload, completion: completion)
    }
    
    /// Send sync overviews and raised exceptions to the DopamineAPI's `/sync` path to increase service quality
    ///
    /// - parameters:
    ///     - syncOverviews: The array of SyncOverviews to send
    ///     - exceptions: The array of DopeExceptions to send
    ///     - completion: A closure to handle the JSON formatted response.
    ///
    internal static func sync( syncOverviews: [SyncOverview], dopeExceptions: [DopeException], completion: @escaping ([String:Any]) -> ()){
        var payload = sharedInstance.configurationData
        
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
        payload["utc"] = NSNumber(value: Int64(Date().timeIntervalSince1970) * 1000)
        payload["timezoneOffset"] = NSNumber(value: Int64(NSTimeZone.default.secondsFromGMT()) * 1000)
        
        sharedInstance.send(call: .sync, with: payload, completion: completion)
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
        let baseURL = URL(string: DopamineAPI.dopamineAPIURL)!
        guard let url = URL(string: type.pathExtenstion, relativeTo: baseURL) else {
            DopamineKit.debugLog("Could not construct for \(type.pathExtenstion)")
            return
        }
        
        DopamineKit.debugLog("Preparing \(type.pathExtenstion) api call to \(url.absoluteString)...")
        do {
            var request = URLRequest(url: url)
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpMethod = "POST"
            request.timeoutInterval = timeout
            let jsonPayload = try JSONSerialization.data(withJSONObject: payload, options: JSONSerialization.WritingOptions())
//            DopamineKit.debugLog("sending raw payload:\(jsonPayload.debugDescription)")   // hex 16 chars
            request.httpBody = jsonPayload
            
            let callStartTime = Int64( 1000*NSDate().timeIntervalSince1970 )
            let task = session.dataTask(with: request, completionHandler: { responseData, responseURL, error in
                var responseDict: [String : Any] = [:]
                defer { completion(responseDict) }
                
                if responseURL == nil {
                    DopamineKit.debugLog("❌ invalid response:\(String(describing: error?.localizedDescription))")
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
                    case .sync:
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
                        let message = "❌ Error reading \(type.pathExtenstion) response data, not a dictionary: \(json)"
                        DopamineKit.debugLog(message)
                        Telemetry.storeException(className: "JSONSerialization", message: message)
                        return
                    }
                    responseDict = dict
                    DopamineKit.debugLog("✅\(type.pathExtenstion) call got response:\(responseDict.debugDescription)")
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
                    case .sync:
                        break
                    }
                    
                } catch {
                    let message = "❌ Error reading \(type.pathExtenstion) response data: \(responseData.debugDescription)"
                    DopamineKit.debugLog(message)
                    Telemetry.storeException(className: "JSONSerialization", message: message)
                    return
                }
                
            })
            
            // send request
//            DopamineKit.debugLog("Sending \(type.pathExtenstion) api call with payload: \(payload.description)")
            task.resume()
            
        } catch {
            let message = "Error sending \(type.pathExtenstion) api call with payload:(\(payload.description))"
            DopamineKit.debugLog(message)
            Telemetry.storeException(className: "JSONSerialization", message: message)
        }
    }
    
    /// Computes the basic fields for a request call
    ///
    /// Add this to your payload before calling `send()`
    ///
    private lazy var configurationData: [String: Any] = {
        
        var dict: [String: Any] = [ "clientOS": "iOS",
                                    "clientOSVersion": DopamineAPI.clientOSVersion,
                                    "clientSDKVersion": DopamineAPI.clientSDKVersion,
                                    "primaryIdentity": self.primaryIdentity ]
        
        let credentials: [String: Any]
        if let testCredentials = DopamineKit.testCredentials {
            credentials = testCredentials
            DopamineKit.debugLog("Using test credentials")
        } else {
            guard let credentialsPath = Bundle.main.path(forResource: "DopamineProperties", ofType: "plist"),
                let credentialsPlist = NSDictionary(contentsOfFile: credentialsPath) as? [String: Any] else {
                    DopamineKit.debugLog("[DopamineKit]: Error - cannot find credentials")
                    return dict
            }
            credentials = credentialsPlist
        }
        
        
        guard let appID = credentials["appID"] as? String else{
            DopamineKit.debugLog("<DopamineProperties>: Error no appID key")
            return dict
        }
        dict["appID"] = appID
        
        guard let versionID = credentials["versionID"] as? String else{
            DopamineKit.debugLog("<DopamineProperties>: Error no versionID key")
            return dict
        }
//        if let newVersionID = UserDefaults.standard.string(forKey: "Visualizer.versionID") {
//            dict["versionID"] = newVersionID
//        } else {
            dict["versionID"] = versionID
//        }
        
        if let inProduction = credentials["inProduction"] as? Bool{
            guard let productionSecret = credentials["productionSecret"] as? String else{
                DopamineKit.debugLog("<DopamineProperties>: Error no productionSecret key")
                return dict
            }
            guard let developmentSecret = credentials["developmentSecret"] as? String else{
                DopamineKit.debugLog("<DopamineProperties>: Error no developmentSecret key")
                return dict
            }
            dict["secret"] = inProduction ? productionSecret : developmentSecret
        } else{
            DopamineKit.debugLog("<DopamineProperties>: Error no inProduction key")
            return dict
        }
        
        return dict
    }()
    
    /// Computes a primary identity for the user
    ///
    private lazy var primaryIdentity:String = {
        #if DEBUG
            if let tid = DopamineKit.developmentIdentity {
                DopamineKit.debugLog("Testing with primaryIdentity:(\(tid))")
                return tid
            }
        #endif
        if let aid = ASIdentifierManager.shared().adId()?.uuidString,
            aid != "00000000-0000-0000-0000-000000000000" {
            DopamineKit.debugLog("ASIdentifierManager primaryIdentity:(\(aid))")
            return aid
        } else if let vid = UIDevice.current.identifierForVendor?.uuidString {
            DopamineKit.debugLog("identifierForVendor primaryIdentity:(\(vid))")
            return vid
        } else {
            DopamineKit.debugLog("IDUnavailable for primaryIdentity")
            return "IDUnavailable"
        }
    }()
}
