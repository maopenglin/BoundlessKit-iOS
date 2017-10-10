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
    var miniMapping: [String:[String:Any]]? = nil
    var traces: [Any] = []
    let tracesQueue = OperationQueue()
    
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
        tracesQueue.maxConcurrentOperationCount = 1
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
    
    public static func recordEvent(touch: UITouch) {
        DispatchQueue.global().async {
            if let touchView = touch.view {
                let senderClassname = NSStringFromClass(type(of: touch))
                let targetName = touchView.getParentResponders().joined(separator: ",")
                let selectorName: String
                switch touch.phase {
                case .began:
                    selectorName = "began"
                case .moved:
                    selectorName = "moved"
                case .stationary:
                    selectorName = "stationary"
                case .ended:
                    selectorName = "ended"
                case .cancelled:
                    selectorName = "cancelled"
                }
                
                
                
                // display reward if reward is set for this event
                shared.showRewardFor(sender: senderClassname, target: targetName, selector: selectorName) { rewardParams in
                    showReward: do {
                        if let reinforcements = rewardParams["reinforcements"] as? [[String:Any]] {
                            let reinforcement = reinforcements.randomElement()
                            if let viewOption = reinforcement["ViewOption"] as? String,
                                let viewCustom = reinforcement["ViewCustom"] as? String,
                                let viewMarginX = reinforcement["ViewMarginX"] as? CGFloat,
                                let viewMarginY = reinforcement["ViewMarginY"] as? CGFloat,
                                let reinforcementType = reinforcement["primitive"] as? String
                            {
                                let view: UIView
                                var location: CGPoint
                                switch viewOption {
                                case "fixed":
                                    view = UIApplication.shared.keyWindow!
                                    location = CGPoint(x: viewMarginX, y: viewMarginY)
                                    
                                case "touch":
                                    view = UIApplication.shared.keyWindow!
                                    location = Helper.lastTouchLocationInUIWindow
                                
                                case "sender":
                                    DopamineKit.debugLog("Target not supported for this type of event! No reward for you.")
                                    break showReward
                                    
                                case "superview":
                                    if let superview = touchView.superview {
                                        view = superview
                                        location = CGPoint(x: view.bounds.width / 2, y: view.bounds.height / 2)
                                    } else {
                                        DopamineKit.debugLog("Oh no. Sender is not a UIView or has no superview. No reward for you.")
                                        break showReward
                                    }
                                    
                                case "target":
                                    view = touchView
                                    location = CGPoint(x: view.bounds.width / 2, y: view.bounds.height / 2)
                                    
                                case "custom":
                                    if viewCustom != "" {
                                        let viewCustomParams = viewCustom.components(separatedBy: "$")
                                        DopamineKit.debugLog("ViewCustomParams:\(viewCustomParams)")
                                        if viewCustomParams.count == 2,
                                            let index = Int(viewCustomParams[1]) {
                                            let possibleViews = UIApplication.shared.keyWindow!.getSubviewsWithClassname(classname: viewCustomParams[0])
                                            if index <= possibleViews.count-1 {
                                                view = possibleViews[index]
                                                location = CGPoint(x: view.bounds.width / 2, y: view.bounds.height / 2)
                                            } else {
                                                DopamineKit.debugLog("Oh no. Must select which CustomView with a VALID index. No reward for you.")
                                                break showReward
                                            }
                                        } else {
                                            DopamineKit.debugLog("Oh no. Must select which CustomView with an index. Add '$0' after CustomView classname. No reward for you.")
                                            break showReward
                                        }
                                    } else {
                                        DopamineKit.debugLog("Oh no. No CustomView classname set. No reward for you.")
                                        break showReward
                                    }
                                    
                                    
                                default:
                                    DopamineKit.debugLog("Oh no. Unknown reward type primitive. No reward for you.")
                                    break showReward
                                }
                                
                                switch reinforcementType {
                                    
                                case "Emojisplosion":
                                    if let content = reinforcement["Content"] as? String,
                                        let xAcceleration = reinforcement["AccelX"] as? CGFloat,
                                        let yAcceleration = reinforcement["AccelY"] as? CGFloat,
                                        let bursts = reinforcement["Bursts"] as? Double,
                                        let angle = reinforcement["EmissionAngle"] as? CGFloat,
                                        let range = reinforcement["EmissionRange"] as? CGFloat,
                                        let fadeout = reinforcement["FadeOut"] as? Float,
                                        let lifetime = reinforcement["Lifetime"] as? Float,
                                        let lifetimeRange = reinforcement["LifetimeRange"] as? Float,
                                        let quantity = reinforcement["Quantity"] as? Float,
                                        let scale = reinforcement["Scale"] as? CGFloat,
                                        let scaleRange = reinforcement["ScaleRange"] as? CGFloat,
                                        let scaleSpeed = reinforcement["ScaleSpeed"] as? CGFloat,
                                        let spin = reinforcement["Spin"] as? CGFloat,
                                        let velocity = reinforcement["Velocity"] as? CGFloat
                                    {
                                        // Touch
                                        view.showEmojiSplosion(at: location, content: content.decode().image().cgImage, scale: scale, scaleSpeed: scaleSpeed, scaleRange: scaleRange, lifetime: lifetime, lifetimeRange: lifetimeRange, fadeout: fadeout, birthRate: quantity, birthCycles: bursts, velocity: velocity, xAcceleration: xAcceleration, yAcceleration: yAcceleration, angle: angle, range: range, spin: spin)
                                    }
                                
                                default:
                                    DopamineKit.debugLog("Unknown reward type:\(String(describing: rewardParams["type"]))")
                                    // TODO: implement delegate callback for dev defined rewards
                                }
                            }
                        } else {
                            DopamineKit.debugLog("Invalid visualizer reward parameters.")
                        }
                    }
                }
                
                
                // send event to visualizer if connected
                if let connectionID = connectionID {
                    // send event
                    var payload = shared.configurationData
                    
                    
                    //        payload["officerID"] = officerID
                    payload["connectionUUID"] = connectionID
                    payload["sender"] = senderClassname
                    payload["target"] = targetName
                    payload["selector"] = selectorName
//                    DispatchQueue.main.sync {
//                        //test
//                        if let imageString = touchView.imageAsBase64EncodedString() {
//                            payload["senderImage"] = imageString
//                        } else {
//                            NSLog("Cannot create image for class type:<\(type(of: touchView))>!")
//                        }
//                    }
                    payload["senderImage"] = ""
                    payload["utc"] = NSNumber(value: Int64(Date().timeIntervalSince1970) * 1000)
                    payload["timezoneOffset"] = NSNumber(value: Int64(NSTimeZone.default.secondsFromGMT()) * 1000)
                    shared.send(call: .submit, with: payload){ response in
                    }
                    
                    // update rewards
                    shared.retrieveRewards()
                }
                
            }
        }
    }
    
    public static func recordAction(senderInstance: AnyObject, targetInstance: AnyObject, selectorObj: Selector, event: UIEvent) {
        DispatchQueue.global().async {
            let senderClassname = NSStringFromClass(type(of: senderInstance))
            let targetClassname = NSStringFromClass(type(of: targetInstance))
            let selectorName = NSStringFromSelector(selectorObj)
            
            // display reward if reward is set for this event
            shared.showRewardFor(sender: senderClassname, target: targetClassname, selector: selectorName) { rewardParams in
                showReward: do {
                    if let reinforcements = rewardParams["reinforcements"] as? [[String:Any]] {
                        let reinforcement = reinforcements.randomElement()
                        if let viewOption = reinforcement["ViewOption"] as? String,
                            let viewCustom = reinforcement["ViewCustom"] as? String,
                            let viewMarginX = reinforcement["ViewMarginX"] as? CGFloat,
                            let viewMarginY = reinforcement["ViewMarginY"] as? CGFloat,
                            let reinforcementType = reinforcement["primitive"] as? String
                        {
                            let view: UIView
                            var location: CGPoint
                            switch viewOption {
                            case "fixed":
                                view = UIApplication.shared.keyWindow!
                                location = CGPoint(x: viewMarginX, y: viewMarginY)
                                
                            case "touch":
                                view = UIApplication.shared.keyWindow!
                                location = Helper.lastTouchLocationInUIWindow
                                
                            case "sender":
                                if let senderInstance = senderInstance as? UIView {
                                    view = senderInstance
                                    location = CGPoint(x: view.bounds.width / 2, y: view.bounds.height / 2)
                                } else if senderInstance.responds(to: Selector("view")),
                                    let sv = senderInstance.value(forKey: "view") as? UIView {
                                    view = sv
                                    location = CGPoint(x: view.bounds.width / 2, y: view.bounds.height / 2)
                                } else {
                                    DopamineKit.debugLog("Oh no. Sender is not a UIView or has no view property.")
                                    break showReward
                                }
                                
                            case "superview":
                                if let senderInstance = senderInstance as? UIView,
                                    let superview = senderInstance.superview {
                                    view = superview
                                    location = CGPoint(x: view.bounds.width / 2, y: view.bounds.height / 2)
                                } else {
                                    DopamineKit.debugLog("Oh no. Sender is not a UIView or has no superview. Doing touch")
                                    view = UIApplication.shared.keyWindow!
                                    location = Helper.lastTouchLocationInUIWindow
                                }
                                
                            case "target":
                                if let targetInstance = targetInstance as? UIView {
                                    view = targetInstance
                                    location = CGPoint(x: view.bounds.width / 2, y: view.bounds.height / 2)
                                } else if targetInstance.responds(to: Selector("view")),
                                    let tv = targetInstance.value(forKey: "view") as? UIView {
                                    view = tv
                                    location = CGPoint(x: view.bounds.width / 2, y: view.bounds.height / 2)
                                } else {
                                    DopamineKit.debugLog("Oh no. Target is not a UIView and has no view property. Doing touch")
                                    view = UIApplication.shared.keyWindow!
                                    location = Helper.lastTouchLocationInUIWindow
                                }
                                
                            case "custom":
                                if viewCustom != "" {
                                    let viewCustomParams = viewCustom.components(separatedBy: "$")
                                    DopamineKit.debugLog("ViewCustomParams:\(viewCustomParams)")
                                    if viewCustomParams.count == 2,
                                        let index = Int(viewCustomParams[1]) {
                                        let possibleViews = UIApplication.shared.keyWindow!.getSubviewsWithClassname(classname: viewCustomParams[0])
                                        if index <= possibleViews.count-1 {
                                            view = possibleViews[index]
                                            location = CGPoint(x: view.bounds.width / 2, y: view.bounds.height / 2)
                                        } else {
                                            DopamineKit.debugLog("Oh no. Must select which CustomView with a VALID index. No reward for you.")
                                            break showReward
                                        }
                                    } else {
                                        DopamineKit.debugLog("Oh no. Must select which CustomView with an index. Add '$0' after CustomView classname. No reward for you.")
                                        break showReward
                                    }
                                } else {
                                    DopamineKit.debugLog("Oh no. No CustomView classname set. No reward for you.")
                                    break showReward
                                }
                                
                                
                            default:
                                DopamineKit.debugLog("Oh no. Unknown reward type primitive. No reward for you.")
                                break showReward
                            }
                            
                            switch reinforcementType {
                                
                            case "Emojisplosion":
                                if let content = reinforcement["Content"] as? String,
                                    let xAcceleration = reinforcement["AccelX"] as? CGFloat,
                                    let yAcceleration = reinforcement["AccelY"] as? CGFloat,
                                    let bursts = reinforcement["Bursts"] as? Double,
                                    let angle = reinforcement["EmissionAngle"] as? CGFloat,
                                    let range = reinforcement["EmissionRange"] as? CGFloat,
                                    let fadeout = reinforcement["FadeOut"] as? Float,
                                    let lifetime = reinforcement["Lifetime"] as? Float,
                                    let lifetimeRange = reinforcement["LifetimeRange"] as? Float,
                                    let quantity = reinforcement["Quantity"] as? Float,
                                    let scale = reinforcement["Scale"] as? CGFloat,
                                    let scaleRange = reinforcement["ScaleRange"] as? CGFloat,
                                    let scaleSpeed = reinforcement["ScaleSpeed"] as? CGFloat,
                                    let spin = reinforcement["Spin"] as? CGFloat,
                                    let velocity = reinforcement["Velocity"] as? CGFloat
                                {
                                    // Touch
                                    view.showEmojiSplosion(at: location, content: content.decode().image().cgImage, scale: scale, scaleSpeed: scaleSpeed, scaleRange: scaleRange, lifetime: lifetime, lifetimeRange: lifetimeRange, fadeout: fadeout, birthRate: quantity, birthCycles: bursts, velocity: velocity, xAcceleration: xAcceleration, yAcceleration: yAcceleration, angle: angle, range: range, spin: spin)
                                }
                            
                            default:
                                DopamineKit.debugLog("Unknown reward type:\(String(describing: rewardParams["type"]))")
                                // TODO: implement delegate callback for dev defined rewards
                            }
                        }
                    } else {
                        DopamineKit.debugLog("Invalid visualizer reward parameters.")
                    }
                }
            }
            
            
            // send event to visualizer if connected
            if let connectionID = connectionID {
                // send event
                var payload = shared.configurationData
                
                
                //        payload["officerID"] = officerID
                payload["connectionUUID"] = connectionID
                payload["sender"] = senderClassname
                payload["target"] = targetClassname
                payload["selector"] = selectorName
                DispatchQueue.main.sync {
                    //test
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
//                payload["senderImage"] = ""
                payload["utc"] = NSNumber(value: Int64(Date().timeIntervalSince1970) * 1000)
                payload["timezoneOffset"] = NSNumber(value: Int64(NSTimeZone.default.secondsFromGMT()) * 1000)
                shared.send(call: .submit, with: payload){ response in
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
//                    DopamineKit.debugLog("✅\(type.pathExtenstion) call got response:\(responseDict.debugDescription)")
                    
                    if type == .submit  && self.tracesQueue.operationCount <= 1 {
                        if responseDict["status"] as? Int == 200 {
                            if let temporaryMappings = responseDict["mappings"] as? [[String:Any]] {
                                var miniMapping = [String : [String : Any]]()
                                for mapping in temporaryMappings {
                                    if let sender = mapping["sender"],
                                        let target = mapping["target"],
                                        let selector = mapping["selector"]
                                    {
                                        miniMapping["\(sender)-\(target)-\(selector)"] = mapping
                                    }
                                }
                                VisualizerAPI.shared.miniMapping = miniMapping
                                print("Minimapping:\(VisualizerAPI.shared.miniMapping)")
                            }
                        } else {
                            VisualizerAPI.connectionID = nil
                        }
                    }
                    
                } catch {
                    let message = "❌ Error reading \(type.pathExtenstion) response data: " + String(describing: (responseData != nil) ? String(data: responseData!, encoding: .utf8) : String(describing: responseData.debugDescription))
                    DopamineKit.debugLog(message)
                    return
                }
                
            })
            
            // send request
//            DopamineKit.debugLog("Sending \(type.pathExtenstion) api call with payload: \(payload.description)")
            //test
            tracesQueue.addOperation {
                task.resume()
            }
            DopamineKit.debugLog("Traces queued:\(tracesQueue.operationCount)")
            
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

fileprivate extension UIResponder {
    func getParentResponders() -> [String]{
        var parentResponders: [String] = []
        getParentResponders(responders: &parentResponders)
        return parentResponders
    }
    
    func getParentResponders(responders: inout [String]) {
        responders.append(NSStringFromClass(type(of:self)))
        if let next = self.next {
            next.getParentResponders(responders: &responders)
        }
    }
}

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
    
    func getSubviewsWithClassname(classname: String) -> [UIView] {
        var views = [UIView]()
        
        for subview in self.subviews {
            views += subview.getSubviewsWithClassname(classname: classname)

            if classname == String(describing: type(of: subview)) {
                views.append(subview)
            }
        }
        
        return views
    }
}

fileprivate extension UIImage {
    func base64EncodedPNGString() -> String? {
        if let imageData = UIImagePNGRepresentation(self) {
            return imageData.base64EncodedString()
        } else {
            NSLog("Could not create PNG representation of UIImage...")
            return nil
        }
    }
}

fileprivate extension Array {
    func randomElement() -> Element {
        return self[Int(arc4random_uniform(UInt32(self.count)))]
    }
}

fileprivate extension String {
    func decode() -> String {
        if let data = self.data(using: .utf8),
            let str = String(data: data, encoding: .nonLossyASCII) {
            return str
        } else {
            return self
        }
    }
}
