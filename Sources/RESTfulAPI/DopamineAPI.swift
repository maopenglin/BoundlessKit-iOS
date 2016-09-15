//
//  DopeAPIPortal.swift
//  Pods
//
//  Created by Akash Desai on 7/16/16.
//
//

import Foundation

open class DopamineAPI : NSObject{
    
    static let sharedInstance: DopamineAPI = DopamineAPI()
    
    fileprivate static let dopamineAPIURL = "https://api.usedopamine.com/v4/app/"
//    private static let dopamineAPIURL = "https://staging-api.usedopamine.com/v4/app/"
    fileprivate static let clientSDKVersion = "4.0.0"
    fileprivate static let clientOS = "iOS"
    fileprivate static let clientOSVersion = UIDevice.current.systemVersion
    
    fileprivate override init() {
        super.init()
    }
    
    fileprivate enum CallType{
        case track, report, refresh
        var str:String{ switch self{
        case .track: return "track"
        case .report: return "report"
        case .refresh: return "refresh"
            }
        }
    }
    
    /// Send an array of actions to the DopamineAPI's `/track` path
    ///
    /// - parameters:
    ///     - actions: An array of actions to send.
    ///     - completion: A closure to handle the JSON formatted response.
    ///
    static func track(_ actions: [DopeAction], completion: @escaping ([String:AnyObject]) -> ()){
        // create dict with credentials
        var payload = sharedInstance.configurationData
        
        // get JSON formatted actions
        var trackedActionsJSONArray = Array<AnyObject>()
        for action in actions{
            trackedActionsJSONArray.append(action.toJSONType())
        }
        
        payload["actions"] = trackedActionsJSONArray as AnyObject?
        payload["utc"] = (1000*Date().timeIntervalSince1970) as AnyObject
        payload["timezoneOffset"] = (1000*NSTimeZone.default.secondsFromGMT()) as AnyObject
        
        sharedInstance.send(.track, payload: payload, completion: {response in
            completion(response)
        })
    }

    /// Send an array of actions to the DopamineAPI's `/report` path
    ///
    /// - parameters:
    ///     - actions: An array of actions to send.
    ///     - completion: A closure to handle the JSON formatted response.
    ///
    static func report(_ actions: [DopeAction], completion: @escaping ([String:AnyObject]) -> ()){
        var payload = sharedInstance.configurationData
        
        var reinforcedActionsArray = Array<AnyObject>()
        for action in actions{
            reinforcedActionsArray.append(action.toJSONType())
        }
        
        payload["actions"] = reinforcedActionsArray as AnyObject?
        payload["utc"] = (1000*Date().timeIntervalSince1970) as AnyObject
        payload["timezoneOffset"] = (1000*NSTimeZone.default.secondsFromGMT()) as AnyObject
        
        sharedInstance.send(.report, payload: payload, completion: {response in
            completion(response)
        })
    }
    
    /// Send an actionID to the DopamineAPI's `/refresh` path to generate a new cartridge of reinforcement decisions
    ///
    /// - parameters:
    ///     - actionID: The actionID that needs reinforcement decisions.
    ///     - completion: A closure to handle the JSON formatted response.
    ///
    static func refresh(_ actionID: String, completion: @escaping ([String:AnyObject]) -> ()){
        var payload = sharedInstance.configurationData
        
        payload["actionID"] = actionID as AnyObject?
        payload["utc"] = (1000*Date().timeIntervalSince1970) as AnyObject
        payload["timezoneOffset"] = (1000*NSTimeZone.default.secondsFromGMT()) as AnyObject
        
        DopamineKit.DebugLog("Refreshing \(actionID)...")
        sharedInstance.send(.refresh, payload: payload, completion:  { response in
            completion(response)
        })
    }
    
    fileprivate lazy var session = URLSession.shared
    
    /// This function sends a request to the DopamineAPI
    ///
    /// - parameters:
    ///     - callType: The type of call to send.
    ///     - payload: A JSON compatible dictionary to send.
    ///     - timeout: A timeout, in seconds, for the request. Defaults to 3 seconds.
    ///     - completion: A closure with a JSON formatted dictionary.
    ///
    fileprivate func send(_ type: CallType, payload: [String:AnyObject], timeout:TimeInterval = 3, completion: @escaping ([String: AnyObject]) -> Void) {
        let baseURL = URL(string: DopamineAPI.dopamineAPIURL)!
        guard let url = URL(string: type.str, relativeTo: baseURL) else {
            DopamineKit.DebugLog("Could not construct url:() with path ()")
            return
        }
        
        DopamineKit.DebugLog("Preparing \(type.str) api call to \(url.absoluteString)...")
        do {
            var request = URLRequest(url: url)
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpMethod = "POST"
            request.timeoutInterval = timeout
            let jsonPayload = try JSONSerialization.data(withJSONObject: payload, options: JSONSerialization.WritingOptions())
//            DopamineKit.DebugLog("sending raw payload:\(jsonPayload.debugDescription)")   // hex 16 chars
            request.httpBody = jsonPayload
            
            let task = session.dataTask(with: request, completionHandler: { responseData, responseURL, error in
                var responseDict: [String : AnyObject] = [:]
                defer { completion(responseDict) }
                
                if responseURL == nil {
                    DopamineKit.DebugLog("❌ invalid response:\(error?.localizedDescription)")
                    responseDict["error"] = error?.localizedDescription as AnyObject?
                    return
                }
                
                do {
                    // turn the response into a json object
                    responseDict = try JSONSerialization.jsonObject(with: responseData!, options: JSONSerialization.ReadingOptions()) as! [String: AnyObject]
                    DopamineKit.DebugLog("✅\(type.str) call got response:\(responseDict.debugDescription)")
                } catch {
                    DopamineKit.DebugLog("❌ Error reading \(type.str) response data: \(responseData.debugDescription)")
                    return
                }
                
            })
            
            // send request
            DopamineKit.DebugLog("Sending \(type.str) api call with payload: \(payload.description)")
            task.resume()
            
        } catch {
            DopamineKit.DebugLog("Error sending \(type.str) api call with payload:(\(payload.description))")
        }
    }
    
    /// A modifiable credentials path used for running tests
    ///
    open static var testCredentialPath:String?
    
    /// Computes the basic fields for a request call
    ///
    /// Add this to your payload before calling `send()`
    ///
    fileprivate lazy var configurationData: [String: AnyObject] = {
        
        var dict: [String: AnyObject] = [ "clientOS": "iOS" as AnyObject,
                                          "clientOSVersion": clientOSVersion as AnyObject,
                                          "clientSDKVersion": clientSDKVersion as AnyObject,
                                          ]
        // add an identity key
        dict["primaryIdentity"] = self.primaryIdentity as AnyObject?
        
        // create a credentials dict from .plist
        let credentialsFilename = "DopamineProperties"
        var path:String
        if let testPath = testCredentialPath {
            path = testPath
        } else {
            guard let credentialsPath = Bundle.main.path(forResource: credentialsFilename, ofType: "plist") else{
                DopamineKit.DebugLog("[DopamineKit]: Error - cannot find credentials in (\(credentialsFilename))")
                return dict
            }
            path = credentialsPath
        }
        
        guard let credentialsPlist = NSDictionary(contentsOfFile: path) as? [String: AnyObject] else{
            DopamineKit.DebugLog("[DopamineKit]: Error - (\(credentialsFilename)) is in the wrong format")
            return dict
        }
        
        guard let appID = credentialsPlist["appID"] as? String else{
            DopamineKit.DebugLog("[DopamineKit]: Error no appID - (\(credentialsFilename)) is in the wrong format")
            return dict
        }
        dict["appID"] = appID as AnyObject?
        
        guard let versionID = credentialsPlist["versionID"] as? String else{
            DopamineKit.DebugLog("[DopamineKit]: Error no versionID - (\(credentialsFilename)) is in the wrong format")
            return dict
        }
        dict["versionID"] = versionID as AnyObject?
        
        if let inProduction = credentialsPlist["inProduction"] as? Bool{
            if(inProduction){
                guard let productionSecret = credentialsPlist["productionSecret"] as? String else{
                    DopamineKit.DebugLog("[DopamineKit]: Error no productionSecret - (\(credentialsFilename)) is in the wrong format")
                    return dict
                }
                dict["secret"] = productionSecret as AnyObject?
            } else{
                guard let developmentSecret = credentialsPlist["developmentSecret"] as? String else{
                    DopamineKit.DebugLog("[DopamineKit]: Error no developmentSecret - (\(credentialsFilename)) is in the wrong format")
                    return dict
                }
                dict["secret"] = developmentSecret as AnyObject?
            }
        } else{
            DopamineKit.DebugLog("[DopamineKit]: Error no inProduction - (\(credentialsFilename)) is in the wrong format")
            return dict
        }
        
        return dict
    }()
    
    /// Computes a primary identity for the user
    ///
    /// This variable computes an identity for the user and saves it to NSUserDefaults for future use.
    ///
    fileprivate lazy var primaryIdentity:String = {
        let key = "DopaminePrimaryIdentity"
        let defaults = UserDefaults.standard
        if let identity = defaults.value(forKey: key) as? String {
            DopamineKit.DebugLog("primaryIdentity:(\(identity))")
            return identity
        } else {
            let defaultIdentity = UIDevice.current.identifierForVendor!.uuidString
            defaults.setValue(defaultIdentity, forKey: key)
            return defaultIdentity
        }
    }()
}
