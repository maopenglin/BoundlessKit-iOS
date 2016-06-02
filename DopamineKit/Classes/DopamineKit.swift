//
//  DopamineKit.swift
//  Dopamine functionality for swift
//
//  Created by Vince Enachescu on 4/7/16.
//  Copyright © 2016 Dopamine Labs. All rights reserved.
//

import Foundation

// constants
let DopamineDefaultsKey = "DopaminePrimaryIdentity"
let DopaminePlistFile = "DopamineProperties"
let DopamineAPIURL = "https://api.usedopamine.com/v3/app/"

public class DopamineKit : NSObject{
    // Singleton configuration
    static let instance: DopamineKit = DopamineKit()
    private let baseURL = NSURL(string: DopamineAPIURL)!
    private let session = NSURLSession.sharedSession()
    
    private static var requestContainedMetadata = false
    private static var requestContainedSecondaryID = false
    
    
    /// This function sends an asynchronous tracking call for the specified actionID
    /// - parameters:
    ///     - actionID: the name of the action
    ///     - metaData: Default `nil` - metadata as a set of key-value pairs that can be sent with a tracking call. The value should be JSON formattable.
    ///     - secondaryIdentity: Default `nil` - an additional idetification string
    ///     - callback: Optional - A callback function with the track HTTP response code passed in as a String
    public static func track(actionID: String, metaData: [String: AnyObject]? = nil, secondaryIdentity: String? = nil, callback: (String? -> ()) = {_ in} ){
        self.instance.sendRequestFor("track", actionID: actionID, metaData: metaData, secondaryIdentity: secondaryIdentity, callback: callback)
    }
    
    /// This function sends an asynchronous reinforcement call for the specified actionID
    /// - parameters:
    ///     - actionID: the name of the action
    ///     - metaData: Default `nil` - metadata as a set of key-value pairs that can be sent with a tracking call. The value should be JSON formattable.
    ///     - secondaryIdentity: Default `nil` - an additional idetification string
    ///     - callback: A callback function with the reinforcement response passed in as a String
    public static func reinforce(actionID: String, metaData: [String: AnyObject]? = nil, secondaryIdentity: String? = nil, timeoutSeconds: Float = 2.0, callback: String? -> ()) {
        self.instance.sendRequestFor("reinforce", actionID: actionID, metaData: metaData, secondaryIdentity: secondaryIdentity, callback: callback)
        
        // Set variables for Tutorial reinforcements
        self.requestContainedMetadata = !(metaData==nil)
        self.requestContainedSecondaryID = !(secondaryIdentity==nil)
        
    }
    
    
    var plistPath: String
    private override init() {
        self.plistPath = ""
        super.init()
    }
    
    private func sendRequestFor(callType: String, actionID: String, metaData: [String: AnyObject]? = nil, secondaryIdentity: String? = nil, callback: String? -> ()) {
        // create dictionary container for api call data
        var data = self.requestData
        var jsonData: NSData
        
        data["actionID"] = actionID
        data["UTC"] = NSDate().timeIntervalSince1970 * 1000
        data["localTime"] = Double(NSTimeZone.defaultTimeZone().secondsFromGMT) +
            NSDate().timeIntervalSince1970 * 1000
        
        // optional metadata and secondary indentity
        if metaData != nil {
            data["metaData"] = metaData as [String: AnyObject]!
        }
        
        if secondaryIdentity != nil {
            data["secondaryIdentity"] = secondaryIdentity!
        }
        
        do {
            jsonData = try NSJSONSerialization.dataWithJSONObject(data, options: .PrettyPrinted) 
        } catch {
            NSLog("DopamineKit: Error composing api request type:(\(callType)) with data:(\(data))")
            return
        }

        let url = NSURL(string: callType, relativeToURL: baseURL)!
        let request = NSMutableURLRequest(URL: url)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.HTTPMethod = "POST"
        request.HTTPBody = jsonData

        // set up request handler
        let task = session.dataTaskWithRequest(request) { data, response, error in
            
            // check if request failed locally
            if let httpError = error as NSError! {
                NSLog("DopamineKit: Error while sending request - \(httpError.localizedDescription)")
            } else {
                self.handleResponse(callType, data: data, response: response, callback: callback)
            }
        }
        
        // send request
        NSLog("DopamineKit: sending request \(data.description)")
        task.resume()
        
    }
    
    private func handleResponse(callType: String, data: NSData?, response: NSURLResponse?, callback: String? -> ()) {
        
        // check for server's http response
        if let httpResponse = response as? NSHTTPURLResponse where httpResponse.statusCode != 200 {
            NSLog("DopamineKit: Error - request failed (Status Code:\(httpResponse.statusCode))")
            callback(nil)
        }
        
        // parse the json response
        let jsonOptions = NSJSONReadingOptions()
        var dict: [String: AnyObject] = [:]
        do {
            dict = try NSJSONSerialization.JSONObjectWithData(data!, options: jsonOptions) as! [String: AnyObject]
        } catch {
            NSLog("DopamineKit: Error reading dopamine response data: \(data)")
            callback(nil)
        }
        
        // return the reinforcement decision as a string for reinforcement calls, status for track calls
        switch (callType){
            case "reinforce":
                NSLog("DopamineKit reinforce response:\(dict)")
                let reinforcer = dict["reinforcementDecision"] as? String
                callback(reinforcer)
            break
            
            case "track":
                NSLog("DopamineKit track response:\(dict)")
                let status = dict["status"] as? Int
                NSLog("\(status)")
                callback(status?.description)
            break
            
            default:
                NSLog("DopamineKit: Error - unhandled response for \(callType): \(dict)")
                callback(nil)
            break
        }
        
        
    }
    
    // compile the static elements of the request call
    
    lazy var requestData: [String: AnyObject] = {
        
        var dict: [String: AnyObject] = [
            "clientOS": "iOS-Swift",
            "clientOSVersion": clientOSVersion,
            "clientSDKVersion": "1.0.1",
        ]
        
        // load configuration details from bundled plist file
        if (self.plistPath == ""){
            // set the plist path to the default (main bundle)
            if let path = NSBundle.mainBundle().pathForResource(DopaminePlistFile, ofType: "plist") {
                self.plistPath = path
            } else {
                self.plistPath = ""
            }
            
        }
        
        // save values
        if let config = NSDictionary(contentsOfFile: self.plistPath) as? [String: AnyObject] {
            for key in ["appID", "versionID"] {
                if let value = config[key] {
                    dict[key] = value
                } else {
                    NSLog("DopamineKit: Error - bad appID or versionID in 'DopamineProperties.plist'")
                }
            }
            
            NSLog("DopamineKit credentials:\(dict)")
            
            // set the development/production secret key
            if config["inProduction"] as! Bool {
                dict["secret"] = config["productionSecret"] as! String
            } else {
                dict["secret"] = config["developmentSecret"] as! String
            }
            
            dict["primaryIdentity"] = self.getPrimaryIdentity()
            
        } else {
            NSLog("DopamineKit: Error - bad configuration in 'DopamineProperties.plist'")
        }
        
        return dict
    }()
    
    // get the primary identity as a lazy computed variable
    private func getPrimaryIdentity() -> String! {
        
        // check if a current primary identity is set in user defaults
        let defaults = NSUserDefaults.standardUserDefaults()
        if let identity = defaults.valueForKey(DopamineDefaultsKey) as? String {
            return identity
        } else {
            // if not, generate the unique identifier and save it to defaults
            let defaultIdentity = deviceUUID
            defaults.setValue(defaultIdentity, forKey: DopamineDefaultsKey)
            return defaultIdentity
        }
    }
    
    
    /// This function creates a simple reinforcement using DesignerReinforcementView that is displayed over the current view. The reinforcement can be displayed with an optional dimmed background, and also comes with a close button
    /// - parameters:
    ///     - reinforcementViewType: the type of reinforcement selected from DopamineKit templates
    ///     - reinforcementTitle: Default "Great job!" - the title or primary text for the reinforcement
    ///     - reinforcementSubtitle: Default "Keep doing you" - the subtitle or secondary text for the reinforcement
    ///     - dismissMessage: Default "close" - the message displayed on the DesignerReinforcementView's `closeButton` if text can be displayed on the template type
    public static func createReinforcement(reinforcementViewType: DesignerReinforcementType,
                                           reinforcementTitle: String = "Great job!",
                                           reinforcementSubtitle: String = "Keep doing you",
                                           dismissMessage: String = "Close")
        -> ReinforcementModalPresenter{
            
            // Step through guide for Hello Dopamine
            var primaryText = reinforcementTitle
            
            let isDummyApp = (self.instance.requestData["appID"] as! String) == "570ffc491b4c6e9869482fbf"
            let inDevelopment = (self.instance.requestData["secret"] as! String) == "d388c7074d8a283bff1f01eb932c1c9e6bec3b10"
            if(isDummyApp && inDevelopment  ){   // Is the dummy app
                if(self.requestContainedMetadata && self.requestContainedSecondaryID){
                    primaryText = "Congrats! You're now certified to be Dope"
                } else if(!self.requestContainedMetadata){
                    primaryText = "Add metadata yo"
                } else if(!self.requestContainedSecondaryID){
                    primaryText = "Add custom identification next!"
                }
                
            }
            else{
                // Normal text for normal applications
                primaryText = reinforcementTitle
            }
            
            
            
            let reinforcementView = DesignerReinforcementView(frame: UIScreen.mainScreen().bounds,
                                                              type: reinforcementViewType,
                                                              primaryText: primaryText,
                                                              secondaryText: reinforcementSubtitle,
                                                              closeText: dismissMessage)
            
            let vc = ReinforcementModalPresenter(view: reinforcementView)
            reinforcementView.closeButton.addTarget(vc, action:  #selector(ReinforcementModalPresenter.dismissSelf), forControlEvents: UIControlEvents.TouchUpInside)
//            reinforcementView.didSwipe(reco)
            vc.view.layer.masksToBounds = true
            return vc
            
    }
    
}

#if os(iOS)
    
    import UIKit
    
let deviceUUID = UIDevice.currentDevice().identifierForVendor!.UUIDString
let clientOSVersion = UIDevice.currentDevice().systemVersion
    
#elseif os(OSX)
    
    import AppKit
     
let deviceUUID = NSProcessInfo().globallyUniqueString
let clientOSVersion = NSProcessInfo().operatingSystemVersionString
    
#endif