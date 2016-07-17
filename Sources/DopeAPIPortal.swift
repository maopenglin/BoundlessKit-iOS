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

public class DopeAPIPortal : NSObject{
    static let instance: DopeAPIPortal = DopeAPIPortal()
    private override init() {
        super.init()
    }
    
    private let dopamineAPIURL = "https://api.usedopamine.com/v3/app/"
    
    static func track(events: DopeEvent...){    // Enter one or more as parameters, or in an array
        return track(events)
    }
    
    var trackCartridge = Cartridge()
    
    static func track(events: [DopeEvent]){
        for event in events{
            instance.trackCartridge.push(event)
        }
        
        // Post once near capacity
        let max = Double(instance.reportCartridge.max)
        let end = Double(instance.reportCartridge.end)
        let nearCapacity = 0.0
        if(end/max >= nearCapacity){
            // create dict with credentials
            var payload = instance.configurationData
            
            // add tracked events to payload
            payload.update(["events":instance.trackCartridge.toJsonable()])
            payload.update(events.first!.toJsonable())  // debug. v3 adaptation
            
            // sendRequest()
            instance.send(.Track, payload: payload, completion: {response in
                // check for bad statusCode
                NSLog("report response:\(response)")
            })
            
            
            // sqldelete all events that were sent
            
            // empty the cartridge
        }
        
    }
    
    
    
    
    var reportCartridge = Cartridge()
    
    static func report(events: [DopeEvent]){
        // add all events and also their feedbacks. feedbacks were added during dkit.reinforce()
        for event in events{
            instance.reportCartridge.push(event)
        }
        
        
        // Post once near capacity
        let max = Double(instance.reportCartridge.max)
        let end = Double(instance.reportCartridge.end)
        let nearCapacity = 0.75
        if(end/max >= nearCapacity){
            // create dict with credentials
            var payload = instance.configurationData
            
            // add reinforcement events to payload
            while let event = instance.reportCartridge.pop(){
                let reinforcementEvent :[String:AnyObject] = ["actionID":event.actionID!, "reinforcement":event.reinforcement!]
                payload.update(["events":reinforcementEvent])
            }
            
            
            // sendRequest()
            instance.send(.Report, payload: payload, completion: {response in
                // check for bad statusCode
                NSLog("report response:\(response)")
            })
            
            
            // sqldelete all events that were sent
            
            // refresh the cartridge
        }
        
        
        
        
        
    }
    
    // Enter one or more as parameters, or in an array
    static func report(events: DopeEvent...){ return report(events) }
    
    public static func refresh(actionID: String) -> Cartridge{
        
        // sendRequest()
        var payload = instance.configurationData
        payload["actionID"] = actionID
        instance.send(.Refresh, payload: payload, completion: {
            response in
            DopamineKit.DebugLog("refresh for \(actionID) resulted in:\(response)")
            
            // check for bad statusCode
            
            // Turn data into DopeEvent
            
            // Load into cartridge
        })
        
        return Cartridge()
    }
    
    private enum CallType{
        case Track, Report, Refresh
        var str:String{ switch self{
            case .Track: return "track"
            case .Report: return "report"
            case .Refresh: return "track"
            }
        }
    }
    
    
    lazy var session = NSURLSession.sharedSession()
    
    /// This function sends a request to the DopamineAPI
    ///
    /// - parameters:
    ///     - callType: "track" or "reinforce".
    ///     - actionID: Descriptive name of the action.
    ///     - metaData?: Event info as a set of key-value pairs that can be sent with a tracking call. The value should JSON formattable like an NSNumber or NSString. Defaults to `nil`.
    ///     - secondaryIdentity?: An additional idetification string. Defaults to `nil`.
    ///     - completion: A closure with the reinforcement response passed in as a `String`.
    private func send(type: CallType, payload: [String:AnyObject], timeout:NSTimeInterval = 3, completion: [String: AnyObject] -> Void) {
        
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
        
        var dict: [String: AnyObject] = [ "clientOS": "iOS-Swift",
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