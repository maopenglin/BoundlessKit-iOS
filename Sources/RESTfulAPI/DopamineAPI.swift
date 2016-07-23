//
//  DopeAPIPortal.swift
//  Pods
//
//  Created by Akash Desai on 7/16/16.
//
//

import Foundation

let clientOSVersion = UIDevice.currentDevice().systemVersion
let clientSDKVersion = "4.0.0.beta"
let clientOS = "iOS"

public class DopamineAPI : NSObject{
    
    private let dopamineAPIURL = "https://api.usedopamine.com/v3/app/"
    
    static let instance: DopamineAPI = DopamineAPI()
    private override init() {
        super.init()
    }
    
    public static func track(actions: [DopeAction], completion: ([String:AnyObject]) -> ()){
        // create dict with credentials
        var payload = instance.configurationData
        
        // add tracked events to payload
        var trackedActionsArray = Array<AnyObject>()
        for action in actions{
            trackedActionsArray.append(action.toJSONType())
        }
        payload["actions"] = trackedActionsArray
        
        instance.send(.Track, payload: payload, completion: {response in
            NSLog("track response:\(response)")
            completion(response)
        })
        
    }

    public static func report(actions: [DopeAction], completion: ([String:AnyObject]) -> ()){
        var payload = instance.configurationData
        
        var reinforcedActionsArray = Array<AnyObject>()
        for action in actions{
            reinforcedActionsArray.append(action.toJSONType())
        }
        payload["actions"] = reinforcedActionsArray
        
        instance.send(.Report, payload: payload, completion: {response in
            NSLog("report response:\(response)")
            completion(response)
        })
    }
    
    
    public static func refresh(actionID: String, completion: ([String:AnyObject]) -> ()){
        var payload = instance.configurationData
        
        payload["actionID"] = actionID
        
        DopamineKit.DebugLog("Refreshing \(actionID)...")
        instance.send(.Refresh, payload: payload, completion:  { response in
            NSLog("refresh response:\(response)")
            completion(response)
        })
    }
    
    
    
    
    
    
    
    
    
    lazy var session = NSURLSession.sharedSession()
    private enum CallType{
        case Track, Report, Refresh
        var str:String{ switch self{
        case .Track: return "track"
        case .Report: return "report"
        case .Refresh: return "refresh"
            }
        }
    }
    
    /// This function sends a request to the DopamineAPI
    ///
    /// - parameters:
    ///     - callType: "track" or "reinforce".
    ///     - actionID: Descriptive name of the action.
    ///     - metaData?: Event info as a set of key-value pairs that can be sent with a tracking call. The value should JSON formattable like an NSNumber or NSString. Defaults to `nil`.
    ///     - secondaryIdentity?: An additional idetification string. Defaults to `nil`.
    ///     - completion: A closure with the reinforcement response passed in as a `String`.
    private func send(type: CallType, payload: [String:AnyObject], timeout:NSTimeInterval = 3, completion: [String: AnyObject] -> Void) {
        DopamineKit.DebugLog("Payload:\(payload)")
        
        let baseURL = NSURL(string: dopamineAPIURL)!
        
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
//                DopamineKit.DebugLog("sending raw payload:\(jsonPayload.debugDescription)")
                request.HTTPBody = jsonPayload
                
                // request handler
                let task = session.dataTaskWithRequest(request) { responseData, responseURL, error in
                    DopamineKit.DebugLog("request sent")
                    
                    guard let responseURL = responseURL as? NSHTTPURLResponse else{
                        DopamineKit.DebugLog("invalid response")
                        return
                    }
                    
                    // ensure json response object
                    var responseDict: [String : AnyObject]
                    do {
                        // turn the response into a json object
                        responseDict = try NSJSONSerialization.JSONObjectWithData(responseData!, options: NSJSONReadingOptions()) as! [String: AnyObject]
                        DopamineKit.DebugLog("\(type.str) call got response:\(responseDict.debugDescription)")
                    } catch {
                        DopamineKit.DebugLog("Error reading \(type.str) response data: \(responseData.debugDescription)")
                        return
                    }
                    
                    
                    if responseURL.statusCode == 200 {
                        completion(responseDict)
                    } else{
                        DopamineKit.DebugLog("HTTP status code:\(responseURL.statusCode)")
                        completion(responseDict)
                    }
                    
                    
                }
                
                // send request
                DopamineKit.DebugLog("Sending \(type.str) request with payload: \(payload.description)")
                task.resume()
                
            } catch {
                DopamineKit.DebugLog("Error composing \(type.str) request with payload:(\(payload.description))")
            }
        
        
        DopamineKit.DebugLog("Finished \(type.str) api call...")
        }
    
    // compile the static elements of the request call
    lazy var configurationData: [String: AnyObject] = {
        
        var dict: [String: AnyObject] = [ "clientOS": "iOS",
                                          "clientOSVersion": clientOSVersion,
                                          "clientSDKVersion": clientSDKVersion,
                                          ]
        // add an identity key
        dict["primaryIdentity"] = self.primaryIdentity
        
        if(true){
            dict["appID"] = "570ffc491b4c6e9869482fbf"
            dict["versionID"] = "testing"
            dict["secret"] = "d388c7074d8a283bff1f01eb932c1c9e6bec3b10"
            return dict
        }
        
        /* commented out for DEBUG code abouve
        // create a credentials dict from .plist
        let credentialsFilename = "DopamineProperties"
        guard let path = NSBundle.mainBundle().pathForResource(credentialsFilename, ofType: "plist") else{
            DopamineKit.DebugLog("[DopamineKit]: Error - cannot find credentials in (\(credentialsFilename))")
            return dict
        }
        guard let credentialsPlist = NSDictionary(contentsOfFile: credentialsFilename) as? [String: AnyObject] else{
            DopamineKit.DebugLog("[DopamineKit]: Error - (\(credentialsFilename)) is in the wrong format")
            return dict
        }
        
        guard let appID = credentialsPlist["appID"] as? String else{
            DopamineKit.DebugLog("[DopamineKit]: Error - (\(credentialsFilename)) is in the wrong format")
            return dict
        }
        dict["appID"] = appID
        
        guard let versionID = credentialsPlist["versionID"] as? String else{
            DopamineKit.DebugLog("[DopamineKit]: Error - (\(credentialsFilename)) is in the wrong format")
            return dict
        }
        dict["versionID"] = versionID
        
        if let inProduction = credentialsPlist["inProduction"] as? Bool{
            if(inProduction){
                guard let productionSecret = credentialsPlist["productionSecret"] as? String else{
                    DopamineKit.DebugLog("[DopamineKit]: Error - (\(credentialsFilename)) is in the wrong format")
                    return dict
                }
                dict["secret"] = productionSecret
            } else{
                guard let developmentSecret = credentialsPlist["developmentSecret"] as? String else{
                    DopamineKit.DebugLog("[DopamineKit]: Error - (\(credentialsFilename)) is in the wrong format")
                    return dict
                }
                dict["secret"] = developmentSecret
            }
        } else{
            DopamineKit.DebugLog("[DopamineKit]: Error - (\(credentialsFilename)) is in the wrong format")
            return dict
        }
        
        return dict
 
         */
    }()
    
//    static let CartridgeCapacityKey = "DopamineCartridgeCapacities"
//    lazy var cartridgeCapacities:[NSString:NSNumber] = {
//        let defaults = NSUserDefaults.standardUserDefaults()
//        if let capacities = defaults.valueForKey(DopamineAPI.CartridgeCapacityKey) as? [NSString:NSNumber] {
//            return capacities
//        } else {
//            let capacities:[NSString:NSNumber] = [:]
//            defaults.setObject(capacities, forKey: DopamineAPI.CartridgeCapacityKey)
//            return capacities
//        }
//    }()
//    private func updateCartridgeCapacity(actionID: NSString, size: NSNumber){
//        let defaults = NSUserDefaults.standardUserDefaults()
//        cartridgeCapacities[actionID] = size
//        defaults.setObject(cartridgeCapacities, forKey: DopamineAPI.CartridgeCapacityKey)
//    }
    
//    private func cartridgeNeedsReload(actionID: String, left:Int64) -> Bool{
//        if let capacity = cartridgeCapacities[NSString(string: actionID)]{
//            return (Double(left) / Double(capacity)) < DopamineAPI.PreferredMinimumCartridgeCapacity
//        } else {
//            return true
//        }
//    }
    
    // get the primary identity as a lazy computed variable
    lazy var primaryIdentity:String = {
        let key = "DopaminePrimaryIdentity"
        let defaults = NSUserDefaults.standardUserDefaults()
        if let identity = defaults.valueForKey(key) as? String {
            return identity
        } else {
            let defaultIdentity = UIDevice.currentDevice().identifierForVendor!.UUIDString
            defaults.setValue(defaultIdentity, forKey: key)
            return defaultIdentity
        }
    }()
}

extension Dictionary {
    mutating func update(other:Dictionary) {
        for (key,value) in other {
            self.updateValue(value, forKey:key)
        }
    }
}