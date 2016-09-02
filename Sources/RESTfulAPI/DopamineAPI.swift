//
//  DopeAPIPortal.swift
//  Pods
//
//  Created by Akash Desai on 7/16/16.
//
//

import Foundation

public class DopamineAPI : NSObject{
    
    static let sharedInstance: DopamineAPI = DopamineAPI()
    
    private static let dopamineAPIURL = "https://api.usedopamine.com/v4/app/"
//    private static let dopamineAPIURL = "https://staging-api.usedopamine.com/v4/app/"
    private static let clientSDKVersion = "4.0.0"
    private static let clientOS = "iOS"
    private static let clientOSVersion = UIDevice.currentDevice().systemVersion
    
    private override init() {
        super.init()
    }
    
    private enum CallType{
        case Track, Report, Refresh
        var str:String{ switch self{
        case .Track: return "track"
        case .Report: return "report"
        case .Refresh: return "refresh"
            }
        }
    }
    
    /// Send an array of actions to the DopamineAPI's `/track` path
    ///
    /// - parameters:
    ///     - actions: An array of actions to send.
    ///     - completion: A closure to handle the JSON formatted response.
    ///
    static func track(actions: [DopeAction], completion: ([String:AnyObject]) -> ()){
        // create dict with credentials
        var payload = sharedInstance.configurationData
        
        // get JSON formatted actions
        var trackedActionsJSONArray = Array<AnyObject>()
        for action in actions{
            trackedActionsJSONArray.append(action.toJSONType())
        }
        
        payload["actions"] = trackedActionsJSONArray
        payload["utc"] = 1000*NSDate().timeIntervalSince1970
        payload["timezoneOffset"] = 1000*NSTimeZone.defaultTimeZone().secondsFromGMT
        
        sharedInstance.send(.Track, payload: payload, completion: {response in
            completion(response)
        })
    }

    /// Send an array of actions to the DopamineAPI's `/report` path
    ///
    /// - parameters:
    ///     - actions: An array of actions to send.
    ///     - completion: A closure to handle the JSON formatted response.
    ///
    static func report(actions: [DopeAction], completion: ([String:AnyObject]) -> ()){
        var payload = sharedInstance.configurationData
        
        var reinforcedActionsArray = Array<AnyObject>()
        for action in actions{
            reinforcedActionsArray.append(action.toJSONType())
        }
        
        payload["actions"] = reinforcedActionsArray
        payload["utc"] = 1000*NSDate().timeIntervalSince1970
        payload["timezoneOffset"] = 1000*NSTimeZone.defaultTimeZone().secondsFromGMT
        
        sharedInstance.send(.Report, payload: payload, completion: {response in
            completion(response)
        })
    }
    
    /// Send an actionID to the DopamineAPI's `/refresh` path to generate a new cartridge of reinforcement decisions
    ///
    /// - parameters:
    ///     - actionID: The actionID that needs reinforcement decisions.
    ///     - completion: A closure to handle the JSON formatted response.
    ///
    static func refresh(actionID: String, completion: ([String:AnyObject]) -> ()){
        var payload = sharedInstance.configurationData
        
        payload["actionID"] = actionID
        payload["utc"] = 1000*NSDate().timeIntervalSince1970
        payload["timezoneOffset"] = 1000*NSTimeZone.defaultTimeZone().secondsFromGMT
        
        DopamineKit.DebugLog("Refreshing \(actionID)...")
        sharedInstance.send(.Refresh, payload: payload, completion:  { response in
            completion(response)
        })
    }
    
    private lazy var session = NSURLSession.sharedSession()
    
    /// This function sends a request to the DopamineAPI
    ///
    /// - parameters:
    ///     - callType: The type of call to send.
    ///     - payload: A JSON compatible dictionary to send.
    ///     - timeout: A timeout, in seconds, for the request. Defaults to 3 seconds.
    ///     - completion: A closure with a JSON formatted dictionary.
    ///
    private func send(type: CallType, payload: [String:AnyObject], timeout:NSTimeInterval = 3, completion: [String: AnyObject] -> Void) {
        let baseURL = NSURL(string: DopamineAPI.dopamineAPIURL)!
        guard let url = NSURL(string: type.str, relativeToURL: baseURL) else {
            DopamineKit.DebugLog("Could not construct url:() with path ()")
            return
        }
        
        DopamineKit.DebugLog("Preparing \(type.str) api call to \(url.absoluteString)...")
        do {
            let request = NSMutableURLRequest(URL: url)
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.HTTPMethod = "POST"
            request.timeoutInterval = timeout
            let jsonPayload = try NSJSONSerialization.dataWithJSONObject(payload, options: NSJSONWritingOptions())
//            DopamineKit.DebugLog("sending raw payload:\(jsonPayload.debugDescription)")   // hex 16 chars
            request.HTTPBody = jsonPayload
            
            // request handler
            let task = session.dataTaskWithRequest(request) { responseData, responseURL, error in
                var responseDict: [String : AnyObject] = [:]
                defer { completion(responseDict) }
                
                if responseURL == nil {
                    DopamineKit.DebugLog("❌ invalid response:\(error?.localizedDescription)")
                    responseDict["error"] = error?.localizedDescription
                    return
                }
                
                do {
                    // turn the response into a json object
                    responseDict = try NSJSONSerialization.JSONObjectWithData(responseData!, options: NSJSONReadingOptions()) as! [String: AnyObject]
                    DopamineKit.DebugLog("✅\(type.str) call got response:\(responseDict.debugDescription)")
                } catch {
                    DopamineKit.DebugLog("❌ Error reading \(type.str) response data: \(responseData.debugDescription)")
                    return
                }
                
            }
            
            // send request
            DopamineKit.DebugLog("Sending \(type.str) api call with payload: \(payload.description)")
            task.resume()
            
        } catch {
            DopamineKit.DebugLog("Error sending \(type.str) api call with payload:(\(payload.description))")
        }
    }
    
    /// A modifiable credentials path used for running tests
    ///
    public static var testCredentialPath:String?
    
    /// Computes the basic fields for a request call
    ///
    /// Add this to your payload before calling `send()`
    ///
    private lazy var configurationData: [String: AnyObject] = {
        
        var dict: [String: AnyObject] = [ "clientOS": "iOS",
                                          "clientOSVersion": clientOSVersion,
                                          "clientSDKVersion": clientSDKVersion,
                                          ]
        // add an identity key
        dict["primaryIdentity"] = self.primaryIdentity
        
        // create a credentials dict from .plist
        let credentialsFilename = "DopamineProperties"
        var path:String
        if let testPath = testCredentialPath {
            path = testPath
        } else {
            guard let credentialsPath = NSBundle.mainBundle().pathForResource(credentialsFilename, ofType: "plist") else{
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
        dict["appID"] = appID
        
        guard let versionID = credentialsPlist["versionID"] as? String else{
            DopamineKit.DebugLog("[DopamineKit]: Error no versionID - (\(credentialsFilename)) is in the wrong format")
            return dict
        }
        dict["versionID"] = versionID
        
        if let inProduction = credentialsPlist["inProduction"] as? Bool{
            if(inProduction){
                guard let productionSecret = credentialsPlist["productionSecret"] as? String else{
                    DopamineKit.DebugLog("[DopamineKit]: Error no productionSecret - (\(credentialsFilename)) is in the wrong format")
                    return dict
                }
                dict["secret"] = productionSecret
            } else{
                guard let developmentSecret = credentialsPlist["developmentSecret"] as? String else{
                    DopamineKit.DebugLog("[DopamineKit]: Error no developmentSecret - (\(credentialsFilename)) is in the wrong format")
                    return dict
                }
                dict["secret"] = developmentSecret
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
    private lazy var primaryIdentity:String = {
        let key = "DopaminePrimaryIdentity"
        let defaults = NSUserDefaults.standardUserDefaults()
        if let identity = defaults.valueForKey(key) as? String {
            DopamineKit.DebugLog("primaryIdentity:(\(identity))")
            return identity
        } else {
            let defaultIdentity = UIDevice.currentDevice().identifierForVendor!.UUIDString
            defaults.setValue(defaultIdentity, forKey: key)
            return defaultIdentity
        }
    }()
}
