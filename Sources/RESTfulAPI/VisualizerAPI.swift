//
//  VisualizerAPI.swift
//  Pods
//
//  Created by Akash Desai on 9/9/17.
//
//

import Foundation

public class VisualizerAPI : NSObject {
    
    /// Valid API actions appeneded to the VisualizerAPI URL
    ///
    internal enum CallType{
        case identify, accept, submit
        var pathExtenstion:String{ switch self{
        case .identify: return "codeless/pair/customer/identity/"
        case .accept: return "codeless/pair/customer/accept/"
        case .submit: return "codeless/visualizer/customer/submit/"
            }
        }
    }
    
    public static let shared = VisualizerAPI()
    private static let baseURL = "https://dashboard-api.usedopamine.com/"
    
    static var connectionID: String? //= "test"
//    var eventRewards: [String:[String:Any]] = [:]
    var eventRewards: [String:[String:Any]] = PlaceHolder.rewardPairing
    var miniMapping: [String:[String:Any]]?
    
    public func showRewardFor(sender: String, target: String, selector: String, rewardFunction: @escaping ([String:Any]) -> Void) {
        let pairingKey = [sender, target, selector].joined(separator: "-")
        if miniMapping != nil,
            let rewardParameters = miniMapping![pairingKey] {
            DopamineKit.debugLog("Found real time rewarded event <\(pairingKey)> with parameters:<\(rewardParameters)>")
            DispatchQueue.main.async {
                rewardFunction(rewardParameters)
            }
            return
        }
        if let rewardParameters = eventRewards[pairingKey] {
            DopamineKit.debugLog("Found rewarded event <\(pairingKey)> with parameters:<\(rewardParameters)>")
            
            // TODO: enclose in DopamineKit.reinfoce(). temporary inside main dispatch
            DispatchQueue.main.async {
                rewardFunction(rewardParameters)
            }
        } else {
            DopamineKit.debugLog("No reward pairing found for <\(pairingKey)>")
        }
    }
    
    private override init() {
        super.init()
//        retrieveRewards()
    }
    
    public func retrieveRewards() {
        return
//        send(call: .eventrewards, with: configurationData){ response in
//            if let rewards = response["rewards"] as? [String:String] {
//                guard !NSDictionary(dictionary: self.eventRewards).isEqual(to: rewards) else {
//                    return
//                }
//                self.eventRewards = rewards
//                DopamineKit.debugLog("Rewards:\(self.eventRewards)")
//            }
//        }
    }
    
    public static func recordEvent(senderInstance: AnyObject, sender: String, target: String, selector: String, event: UIEvent) {
        DispatchQueue.global().async {
            
            // display reward if reward is set for this event
            shared.showRewardFor(sender: sender, target: target, selector: selector) { rewardParams in
                switch rewardParams["type"] as? String {
                    
                case "burst"?:
                    let content = (rewardParams["content"] as? String)?.image().cgImage
                    
                    switch rewardParams["view"] as? String {
                    case "touch"?:
                        UIApplication.shared.keyWindow!.showEmojiSplosion(at: Helper.lastTouchLocationInUIWindow, content:content)
                        break
                        
                    case "sender"?:
                        if let senderInstance = senderInstance as? UIView {
                            senderInstance.showEmojiSplosion(at:CGPoint(x: senderInstance.bounds.width/2, y: senderInstance.bounds.height/2), content:content)
                        }
                        
                    case "target"?:
                        break
                        
                    case "fixed"?:
                        break
                        
                    default:
                        break
                    }
                    
                case "confetti"?:
                    break
                    
                default:
                    DopamineKit.debugLog("Unknown reward type:\(String(describing: rewardParams["type"]))")
                    // TODO: implement delegate callback for dev defined rewards
                }
            }
            
            
            // send event to visualizer if connected
            if let connectionID = connectionID {
                // send event
                var payload = shared.configurationData
                
                
                //        payload["officerID"] = officerID
                payload["connectionUUID"] = connectionID
                payload["sender"] = sender
                payload["target"] = target
                payload["selector"] = selector
                DispatchQueue.main.sync {
                    if let view = senderInstance as? UIView,
                        let imageString = view.imageAsBase64EncodedString() {
                        payload["senderImage"] = imageString
                    } else if let barItem = senderInstance as? UIBarItem,
                        let image = barItem.image,
                        let imageString = image.base64EncodedPNGString() {
                        payload["senderImage"] = imageString
                    } else {
                        NSLog("Cannot create image, please message team@usedopamine.com to add support for visualizer snapshots of class type:<\(type(of: senderInstance))>!")
                    }
                }
                payload["utc"] = NSNumber(value: Int64(Date().timeIntervalSince1970) * 1000)
                payload["timezoneOffset"] = NSNumber(value: Int64(NSTimeZone.default.secondsFromGMT()) * 1000)
                shared.send(call: .submit, with: payload){ response in
                    if response["status"] as? Int == 200 {
                        if let temporaryMappings = response["mappings"] as? [[String:Any]] {
                            var miniMapping = [String : [String : Any]]()
                            for mapping in temporaryMappings {
                                if let sender = mapping["sender"],
                                    let target = mapping["target"],
                                    let selector = mapping["selector"]
                                {
                                    miniMapping["\(sender)-\(target)-\(selector)"] = mapping
                                }
                            }
                            shared.miniMapping = miniMapping
                        }
                    } else {
                        VisualizerAPI.connectionID = nil
                    }
                }
                
                // update rewards
                shared.retrieveRewards()
            }
        }
    }
    
    public static func promptPairing() {
//        return
        var payload = shared.configurationData
        payload["deviceName"] = UIDevice.current.name
        
        shared.send(call: .identify, with: payload){ response in
            if let status = response["status"] as? Int {
                switch status {
                case 202:
                    DispatchQueue.global().asyncAfter(deadline: .now() + 5) {
                        promptPairing()
                    }
                    break
                    
                case 200:
                    if let adminName = response["adminName"] as? String,
                        let connectionID = response["connectionUUID"] as? String {
                        presentPairingAlert(from: adminName, connectionID: connectionID)
                    }
                    
                case 208:
                    if let connectionID = response["connectionUUID"] as? String {
                        let connectedRestoredAlert = UIAlertController(title: "Visualizer Pairing", message: "Connection restored", preferredStyle: .alert)
                        connectedRestoredAlert.addAction( UIAlertAction(title: "Ok", style: .default, handler: { _ in
                            VisualizerAPI.connectionID = connectionID
                        }))
                        UIWindow.presentTopLevelAlert(alertController: connectedRestoredAlert)
                    }
                    
                case 500, 204, 201:
                    break
                    
                default:
                    break
                }
            }
        }
    }
    
    private static func presentPairingAlert(from adminName: String, connectionID: String) {
        
        let pairingAlert = UIAlertController(title: "Visualizer Pairing", message: "Accept pairing request from \(adminName)?", preferredStyle: UIAlertControllerStyle.alert)
        
        pairingAlert.addAction( UIAlertAction( title: "Yes", style: .default, handler: { _ in
            var payload = shared.configurationData
            payload["deviceName"] = UIDevice.current.name
            payload["connectionUUID"] = connectionID
            shared.send(call: .accept, with: payload) {response in
                if response["status"] as? Int == 200 {
                    VisualizerAPI.connectionID = connectionID
                }
            }
        }))
        
        pairingAlert.addAction(UIAlertAction(title: "No", style: .cancel, handler: { _ in
            
        }))
        
        UIWindow.presentTopLevelAlert(alertController: pairingAlert)
        
    }
    
    
    /// This function sends a request to the VisualizerAPI
    ///
    /// - parameters:
    ///     - callType: The type of call to send.
    ///     - payload: A JSON compatible dictionary to send.
    ///     - timeout: A timeout, in seconds, for the request. Defaults to 3 seconds.
    ///     - completion: A closure with a JSON formatted dictionary.
    ///
    private func send(call type: CallType, with payload: [String:Any], timeout:TimeInterval = 3.0, completion: @escaping ([String: Any]) -> Void) {
        let baseURL = URL(string: VisualizerAPI.baseURL)!
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
            let task = URLSession.shared.dataTask(with: request, completionHandler: { responseData, responseURL, error in
                var responseDict: [String : Any] = [:]
                defer { completion(responseDict) }
                
                if responseURL == nil {
                    DopamineKit.debugLog("❌ invalid response:\(String(describing: error?.localizedDescription))")
                    responseDict["error"] = error?.localizedDescription
                    return
                }
                
                if let responseData = responseData,
                    responseData.isEmpty {
                    DopamineKit.debugLog("✅\(type.pathExtenstion) call got empty response.")
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
                    
                } catch {
                    let message = "❌ Error reading \(type.pathExtenstion) response data: " + String(describing: (responseData != nil) ? String(data: responseData!, encoding: .utf8) : String(describing: responseData.debugDescription))
                    DopamineKit.debugLog(message)
                    return
                }
                
            })
            
            // send request
            DopamineKit.debugLog("Sending \(type.pathExtenstion) api call with payload: \(payload.description)")
            //test
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
        
        var dict: [String: Any] = [ "primaryIdentity" : self.primaryIdentity ]
        
        // create a credentials dict from .plist
        let credentialsFilename = "DopamineProperties"
        var path:String
        guard let credentialsPath = Bundle.main.path(forResource: credentialsFilename, ofType: "plist") else{
            DopamineKit.debugLog("[DopamineKit]: Error - cannot find credentials in (\(credentialsFilename))")
            return dict
        }
        path = credentialsPath
        
        guard let credentialsPlist = NSDictionary(contentsOfFile: path) as? [String: Any] else{
            DopamineKit.debugLog("[DopamineKit]: Error - (\(credentialsFilename)) is in the wrong format")
            return dict
        }
        
        guard let appID = credentialsPlist["appID"] as? String else{
            DopamineKit.debugLog("[DopamineKit]: Error no appID - (\(credentialsFilename)) is in the wrong format")
            return dict
        }
        dict["appID"] = appID
        
        guard let versionID = credentialsPlist["versionID"] as? String else{
            DopamineKit.debugLog("[DopamineKit]: Error no versionID - (\(credentialsFilename)) is in the wrong format")
            return dict
        }
        dict["versionID"] = versionID
        
        if let inProduction = credentialsPlist["inProduction"] as? Bool{
            if(inProduction){
                guard let productionSecret = credentialsPlist["productionSecret"] as? String else{
                    DopamineKit.debugLog("[DopamineKit]: Error no productionSecret - (\(credentialsFilename)) is in the wrong format")
                    return dict
                }
                dict["secret"] = productionSecret
            } else{
                guard let developmentSecret = credentialsPlist["developmentSecret"] as? String else{
                    DopamineKit.debugLog("[DopamineKit]: Error no developmentSecret - (\(credentialsFilename)) is in the wrong format")
                    return dict
                }
                dict["secret"] = developmentSecret
            }
        } else{
            DopamineKit.debugLog("[DopamineKit]: Error no inProduction - (\(credentialsFilename)) is in the wrong format")
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
        let defaults = UserDefaults.standard
        if let identity = defaults.value(forKey: key) as? String {
            DopamineKit.debugLog("primaryIdentity:(\(identity))")
            return identity
        } else {
            let defaultIdentity = UIDevice.current.identifierForVendor!.uuidString
            defaults.setValue(defaultIdentity, forKey: key)
            return defaultIdentity
        }
    }()

}

//fileprivate func snapshotAsBase64EncodedString(object: AnyObject) -> String? {
//    if let object = object as? NSObject {
//        if let view = object.value(forKey: "view") as? UIView,
//            let imageString = view.imageAsBase64EncodedString() {
//            return imageString
//        } else if let image = object.value(forKey: "image") as? UIImage,
//            let imageString = image.base64EncodedPNGString() {
//            return imageString
//        }
//        
//        NSLog("Cannot create image, please message team@usedopamine.com to add support for visualizer snapshots of class type:<\(type(of: object))>!")
//    }
//    
//    return nil
//}

fileprivate extension UIWindow {
    static func presentTopLevelAlert(alertController:UIAlertController, completion:(() -> Void)? = nil) {
        DispatchQueue.main.async {
            let alertWindow = UIWindow(frame: UIScreen.main.bounds)
            alertWindow.rootViewController = UIViewController()
            alertWindow.windowLevel = UIWindowLevelAlert + 1;
            alertWindow.makeKeyAndVisible()
            alertWindow.rootViewController?.present(alertController, animated: true, completion: completion)
        }
    }
}

fileprivate extension UIView {
    func imageAsBase64EncodedString() -> String? {
        UIGraphicsBeginImageContextWithOptions(bounds.size, false, 0)
        drawHierarchy(in: self.bounds, afterScreenUpdates: true)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        if let image = image,
            let imageString = image.base64EncodedPNGString() {
            return imageString
        } else {
            NSLog("Could not create snapshot of UIView...")
            return nil
        }
    }
}

fileprivate extension UIImage {
    func base64EncodedPNGString() -> String? {
        if let imageData = UIImagePNGRepresentation(self) {
            print(imageData.base64EncodedString())
            return imageData.base64EncodedString()
        } else {
            NSLog("Could not create PNG representation of UIImage...")
            return nil
        }
    }
}
