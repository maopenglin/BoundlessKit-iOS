//
//  VisualizerAPI.swift
//  Pods
//
//  Created by Akash Desai on 9/9/17.
//
//

import Foundation

@objc
public class VisualizerAPI : NSObject {
    
    /// Valid API actions appeneded to the VisualizerAPI URL
    ///
    internal enum CallType{
        case identify, accept, submit, boot
        var pathExtenstion:String{ switch self{
        case .identify: return "codeless/pair/customer/identity/"
        case .accept: return "codeless/pair/customer/accept/"
        case .submit: return "codeless/visualizer/customer/submit/"
        case .boot: return "https://api.usedopamine.com/v5/app/boot"
            }
        }
    }
    
    @objc
    public static let shared = VisualizerAPI()
    private static let baseURL = "https://dashboard-api.usedopamine.com/"
    
    private static let clientSDKVersion = Bundle(for: DopamineAPI.self).object(forInfoDictionaryKey: "CFBundleShortVersionString") as! String
    private static let clientOS = "iOS"
    private static let clientOSVersion = UIDevice.current.systemVersion
    
    static var connectionID: String?
    private let tracesQueue = OperationQueue()
    private var visualizerMappings: [String:[String:Any]]? = nil
    private var rewardMappings: [String:[String:Any]] = {
        if let rm = UserDefaults.standard.dictionary(forKey: "Visualizer.rewardMappings") as? [String: [String:Any]] { return rm }
        else { return [:] }
    }()
    private func setNewRewardMappings(mappings: [String:[String:Any]], newVersionID: String) {
        let currentVersionID = UserDefaults.standard.string(forKey: "Visualizer.versionID")
        if currentVersionID != nil && newVersionID == currentVersionID {
            return
        } else {
            rewardMappings = mappings
            UserDefaults.standard.set(newVersionID, forKey: "Visualizer.versionID")
            UserDefaults.standard.set(mappings, forKey: "Visualizer.rewardMappings")
            SyncCoordinator.shared.flushVersionedSyncers()
            for actionID in mappings.keys {
                Cartridge(actionID: actionID).sync()
            }
            DopeLog.debug("🆕 Updated reward mapping version!")
        }
    }
    
    public func getMappingFor(sender: String, target: String, selector: String, completion: @escaping ([String:Any]) -> ()) {
        let pairingKey = [sender, target, selector].joined(separator: "-")
        if visualizerMappings != nil,
            let rewardParameters = visualizerMappings![pairingKey] {
            DopeLog.debug("Found real time visualizer reward for <\(pairingKey)>")
            if let reinforcements = rewardParameters["reinforcements"] as? [[String:Any]] {
                let reinforcement = reinforcements.randomElement()
                completion(reinforcement)
            }
        } else if let rewardParameters = rewardMappings[pairingKey] {
            DopeLog.debug("Found reward for <\(pairingKey)>")
            if let actionID = rewardParameters["actionID"] as? String,
                let reinforcements = rewardParameters["reinforcements"] as? [[String:Any]] {
                DopamineKit.reinforce(actionID) { reinforcementType in
                    for reinforcement in reinforcements {
                        if reinforcement["primitive"] as? String == reinforcementType {
                            completion(reinforcement)
                            return
                        }
                    }
                }
            } else {
                DopeLog.debug("Bad reward parameters")
            }
        } else {
//            DopeLog.debugLog("No reward pairing found for <\(pairingKey)>")
        }
    }
    
    private override init() {
        super.init()
        tracesQueue.maxConcurrentOperationCount = 1
    }
    
    @objc
    public func retrieveRewards() {
        var payload = configurationData
        payload["utc"] = NSNumber(value: Int64(Date().timeIntervalSince1970) * 1000)
        payload["timezoneOffset"] = NSNumber(value: Int64(NSTimeZone.default.secondsFromGMT()) * 1000)
        send(call: .boot, with: payload){ _ in }
    }
    
    @objc
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
                shared.getMappingFor(sender: senderClassname, target: targetName, selector: selectorName) { reinforcement in
                    
                    if let delay = reinforcement["Delay"] as? Double,
                        let viewOption = reinforcement["ViewOption"] as? String,
                        let viewCustom = reinforcement["ViewCustom"] as? String,
                        let viewMarginX = reinforcement["ViewMarginX"] as? CGFloat,
                        let viewMarginY = reinforcement["ViewMarginY"] as? CGFloat,
                        let reinforcementType = reinforcement["primitive"] as? String
                    {
                        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                            prepareShowReward: do {
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
                                    view = UIApplication.shared.keyWindow!
                                    location = Helper.lastTouchLocationInUIWindow
                                    
                                case "superview":
                                    if let superview = touchView.superview {
                                        view = superview
                                        location = CGPoint(x: view.bounds.width / 2, y: view.bounds.height / 2)
                                    } else {
                                        DopeLog.debug("Oh no. TouchView has no superview. No reward for you.")
                                        break prepareShowReward
                                    }
                                    
                                case "target":
                                    view = touchView
                                    location = CGPoint(x: view.bounds.width / 2, y: view.bounds.height / 2)
                                    
                                case "custom":
                                    if viewCustom != "" {
                                        let viewCustomParams = viewCustom.components(separatedBy: "$")
                                        if viewCustomParams.count == 2,
                                            let index = Int(viewCustomParams[1]) {
                                            let possibleViews = UIApplication.shared.keyWindow!.getSubviewsWithClassname(classname: viewCustomParams[0])
                                            if index <= possibleViews.count-1 {
                                                view = possibleViews[index]
                                                location = CGPoint(x: view.bounds.width / 2, y: view.bounds.height / 2)
                                            } else {
                                                DopeLog.debug("Oh no. Must select which CustomView with a VALID index. No reward for you.")
                                                break prepareShowReward
                                            }
                                        } else {
                                            DopeLog.debug("Oh no. Must select which CustomView with an index. Add '$0' after CustomView classname. No reward for you.")
                                            break prepareShowReward
                                        }
                                    } else {
                                        DopeLog.debug("Oh no. No CustomView classname set. No reward for you.")
                                        break prepareShowReward
                                    }
                                    
                                    
                                default:
                                    DopeLog.debug("Oh no. Unknown reward type primitive. No reward for you.")
                                    break prepareShowReward
                                }
                                
                                showReward(on: view, at: location, of: reinforcementType, withParameters: reinforcement)
                            }
                        }
                        
                    }
                }
                
                
                // send event to visualizer if connected
                if let connectionID = connectionID {
                    var payload = shared.configurationData
                    payload["connectionUUID"] = connectionID
                    payload["sender"] = senderClassname
                    payload["target"] = targetName
                    payload["selector"] = selectorName
                    payload["senderImage"] = ""
                    payload["utc"] = NSNumber(value: Int64(Date().timeIntervalSince1970) * 1000)
                    payload["timezoneOffset"] = NSNumber(value: Int64(NSTimeZone.default.secondsFromGMT()) * 1000)
                    shared.send(call: .submit, with: payload){ response in
                        if response["status"] as? Int != 200 {
                            VisualizerAPI.connectionID = nil
                        }
                    }
                }
                
            }
        }
    }
    
    @objc
    public static func recordAction(senderInstance: AnyObject, targetInstance: AnyObject, selectorObj: Selector, event: UIEvent) {
        DispatchQueue.global().async {
            let senderClassname = NSStringFromClass(type(of: senderInstance))
            let targetClassname = NSStringFromClass(type(of: targetInstance))
            let selectorName = NSStringFromSelector(selectorObj)
            
            // display reward if reward is set for this event
            shared.getMappingFor(sender: senderClassname, target: targetClassname, selector: selectorName) { reinforcement in
                if let delay = reinforcement["Delay"] as? Double,
                    let viewOption = reinforcement["ViewOption"] as? String,
                    let viewCustom = reinforcement["ViewCustom"] as? String,
                    let viewMarginX = reinforcement["ViewMarginX"] as? CGFloat,
                    let viewMarginY = reinforcement["ViewMarginY"] as? CGFloat,
                    let reinforcementType = reinforcement["primitive"] as? String
                {
                    DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                        prepareShowReward: do {
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
                                } else if senderInstance.responds(to: NSSelectorFromString("view")),
                                    let sv = senderInstance.value(forKey: "view") as? UIView {
                                    view = sv
                                    location = CGPoint(x: view.bounds.width / 2, y: view.bounds.height / 2)
                                } else {
                                    DopeLog.debug("Oh no. Sender is not a UIView or has no view property. No reward for you.")
                                    break prepareShowReward
                                }
                                
                            case "superview":
                                if let senderInstance = senderInstance as? UIView,
                                    let superview = senderInstance.superview {
                                    view = superview
                                    location = CGPoint(x: view.bounds.width / 2, y: view.bounds.height / 2)
                                } else if senderInstance.responds(to: NSSelectorFromString("view")),
                                    let sv = senderInstance.value(forKey: "view") as? UIView,
                                    let ssv = sv.superview {
                                    view = ssv
                                    location = CGPoint(x: view.bounds.width / 2, y: view.bounds.height / 2)
                                } else {
                                    DopeLog.debug("Oh no. Sender is not a UIView or has no superview. No reward for you.")
                                    break prepareShowReward
                                }
                                
                            case "target":
                                if let targetInstance = targetInstance as? UIView {
                                    view = targetInstance
                                    location = CGPoint(x: view.bounds.width / 2, y: view.bounds.height / 2)
                                } else if targetInstance.responds(to: NSSelectorFromString("view")),
                                    let tv = targetInstance.value(forKey: "view") as? UIView {
                                    view = tv
                                    location = CGPoint(x: view.bounds.width / 2, y: view.bounds.height / 2)
                                } else {
                                    DopeLog.debug("Oh no. Target is not a UIView and has no view property. Doing touch")
                                    view = UIApplication.shared.keyWindow!
                                    location = Helper.lastTouchLocationInUIWindow
                                }
                                
                            case "custom":
                                if viewCustom != "" {
                                    let viewCustomParams = viewCustom.components(separatedBy: "$")
                                    DopeLog.debug("ViewCustomParams:\(viewCustomParams)")
                                    if viewCustomParams.count == 2,
                                        let index = Int(viewCustomParams[1]) {
                                        let possibleViews = UIApplication.shared.keyWindow!.getSubviewsWithClassname(classname: viewCustomParams[0])
                                        if index <= possibleViews.count-1 {
                                            view = possibleViews[index]
                                            location = CGPoint(x: view.bounds.width / 2, y: view.bounds.height / 2)
                                        } else {
                                            DopeLog.debug("Oh no. Must select which CustomView with a VALID index. No reward for you.")
                                            break prepareShowReward
                                        }
                                    } else {
                                        DopeLog.debug("Oh no. Must select which CustomView with an index. Add '$0' after CustomView classname. No reward for you.")
                                        break prepareShowReward
                                    }
                                } else {
                                    DopeLog.debug("Oh no. No CustomView classname set. No reward for you.")
                                    break prepareShowReward
                                }
                                
                                
                            default:
                                DopeLog.debug("Oh no. Unknown view type. No reward for you.")
                                break prepareShowReward
                            }
                            
                            showReward(on: view, at: location, of: reinforcementType, withParameters: reinforcement)
                        }
                    }
                }
                
            }
            
            
            // send event to visualizer if connected
            if let connectionID = connectionID {
                var payload = shared.configurationData
                payload["utc"] = NSNumber(value: Int64(Date().timeIntervalSince1970) * 1000)
                payload["timezoneOffset"] = NSNumber(value: Int64(NSTimeZone.default.secondsFromGMT()) * 1000)
                payload["connectionUUID"] = connectionID
                payload["sender"] = senderClassname
                payload["target"] = targetClassname
                payload["selector"] = selectorName
                DispatchQueue.main.sync {
                    if let view = senderInstance as? UIView,
                        let imageString = view.imageAsBase64EncodedString() {
                        payload["senderImage"] = imageString
                    } else if let barItem = senderInstance as? UIBarItem,
                        let image = barItem.image,
                        let imageString = image.base64EncodedPNGString() {
                        payload["senderImage"] = imageString
                    } else if senderInstance.responds(to: NSSelectorFromString("view")),
                        let sv = senderInstance.value(forKey: "view") as? UIView,
                        let imageString = sv.imageAsBase64EncodedString() {
                        payload["senderImage"] = imageString
                    } else {
                        NSLog("Cannot create image, please message team@usedopamine.com to add support for visualizer snapshots of class type:<\(type(of: senderInstance))>!")
                    }
                }
//                payload["senderImage"] = ""
                shared.send(call: .submit, with: payload){ response in
                    if response["status"] as? Int != 200 {
                        VisualizerAPI.connectionID = nil
                    }
                }
            }
        }
    }
    
    fileprivate static func showReward(on view: UIView, at location: CGPoint, of type: String, withParameters reinforcement: [String: Any]) {
        switch type {
            
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
                view.showEmojiSplosion(at: location, content: content.decode().image().cgImage, scale: scale, scaleSpeed: scaleSpeed, scaleRange: scaleRange, lifetime: lifetime, lifetimeRange: lifetimeRange, fadeout: fadeout, birthRate: quantity, birthCycles: bursts, velocity: velocity, xAcceleration: xAcceleration, yAcceleration: yAcceleration, angle: angle, range: range, spin: spin)
            }
            
        case "Glow":
            if let duration = reinforcement["Duration"] as? Double,
                let color = reinforcement["Color"] as? String,
                let alpha = reinforcement["Alpha"] as? CGFloat,
                let count = reinforcement["Count"] as? Float,
                let radius = reinforcement["Radius"] as? CGFloat
            {
                view.showGlow(duration: duration, color: UIColor.from(hex: color), alpha: alpha, radius: radius, count: count)
            }
            
        case "Sheen":
            if let duration = reinforcement["Duration"] as? Double {
                view.showSheen(duration: duration)
            }
            
        case "Pulse":
            if let count = reinforcement["Count"] as? Float,
                let duration = reinforcement["Duration"] as? Double,
                let scale = reinforcement["Scale"] as? CGFloat,
                let velocity = reinforcement["Velocity"] as? CGFloat,
                let damping = reinforcement["Damping"] as? CGFloat {
                print("Here!")
                view.showPulse(count: count, duration: duration, scale: scale, velocity: velocity, damping: damping)
            }
            
        case "Shimmy":
            if let count = reinforcement["Count"] as? Int,
                let duration = reinforcement["Duration"] as? Double,
                let translation = reinforcement["Translation"] as? Int {
                view.showShimmy(count: count, duration: duration, translation: translation)
            }
            
        default:
            DopeLog.debug("Unknown reinforcement reward type:\(String(describing: reinforcement))")
            // TODO: implement delegate callback for dev defined rewards
        }
    }
    
    @objc
    public static func promptPairing() {
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
        let url: URL
        if type == .boot,
            let bootURL = URL(string: type.pathExtenstion) {
            url = bootURL
        } else if let baseURL = URL(string: VisualizerAPI.baseURL),
            let visualizerUrl = URL(string: type.pathExtenstion, relativeTo: baseURL) {
            url = visualizerUrl
        } else {
            DopeLog.debug("Could not construct for \(type.pathExtenstion)")
            return
        }
        tracesQueue.addOperation {
//            DopeLog.debugLog("Preparing \(type.pathExtenstion) api call to \(url.absoluteString)...")
            do {
                var request = URLRequest(url: url)
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                request.httpMethod = "POST"
                request.timeoutInterval = timeout
                let jsonPayload = try JSONSerialization.data(withJSONObject: payload, options: JSONSerialization.WritingOptions())
                request.httpBody = jsonPayload
                
                let callStartTime = Int64( 1000*NSDate().timeIntervalSince1970 )
                let task = URLSession.shared.dataTask(with: request, completionHandler: { responseData, responseURL, error in
                    var responseDict: [String : Any] = [:]
                    defer { completion(responseDict) }
                    
                    if responseURL == nil {
                        DopeLog.debug("❌ invalid response:\(String(describing: error?.localizedDescription))")
                        responseDict["error"] = error?.localizedDescription
                        return
                    }
                    
                    if let responseData = responseData,
                        responseData.isEmpty {
                        DopeLog.debug("✅\(type.pathExtenstion) call got empty response.")
                        return
                    }
                    
                    do {
                        // turn the response into a json object
                        guard let data = responseData,
                            let dict = try JSONSerialization.jsonObject(with: data, options: []) as? [String: AnyObject]
                            else {
                                let json = responseData.flatMap({ NSString(data: $0, encoding: String.Encoding.utf8.rawValue) }) ?? ""
                                let message = "❌ Error reading \(type.pathExtenstion) response data, not a dictionary: \(json)"
                                DopeLog.debug(message)
                                Telemetry.storeException(className: "JSONSerialization", message: message)
                                return
                        }
                        responseDict = dict
                        //                    DopeLog.debugLog("✅\(type.pathExtenstion) call got response:\(responseDict.debugDescription)")
                        DopeLog.debug("✅\(type.pathExtenstion) call got response with status:\(responseDict["status"] ?? "unknown")")
                        
                        if (type == .boot) || (type == .submit  && self.tracesQueue.operationCount <= 1) {
                            if (type == .boot && responseDict["status"] as? Int == 205) || (type == .submit && responseDict["status"] as? Int == 200) {
                                if let apiMappings = responseDict["mappings"] as? [[String:Any]] {
                                    var tempDict = [String : [String : Any]]()
                                    for mappings in apiMappings {
                                        if let sender = mappings["sender"],
                                            let target = mappings["target"],
                                            let selector = mappings["selector"]
                                        {
                                            tempDict["\(sender)-\(target)-\(selector)"] = mappings
                                        } else if let actionID = mappings["actionID"] as? String,
                                            let reinforcements = mappings["reinforcements"] as? [[String: Any]] {
                                            tempDict[actionID] = ["actionID":actionID, "reinforcements":reinforcements]
                                        } else {
                                            DopeLog.debug("Invalid mapping")
                                        }
                                    }
                                    if type == .submit {
                                        VisualizerAPI.shared.visualizerMappings = tempDict
                                    } else { // .boot
                                        if let newVersionID = responseDict["newVersionID"] as? String {
                                            VisualizerAPI.shared.setNewRewardMappings(mappings: tempDict, newVersionID: newVersionID)
                                        } else {
                                            DopeLog.debug("Missing 'newVersionID'")
                                        }
                                    }
                                }
                            }
                        }
                        
                    } catch {
                        let message = "❌ Error reading \(type.pathExtenstion) response data: " + String(describing: (responseData != nil) ? String(data: responseData!, encoding: .utf8) : String(describing: responseData.debugDescription))
                        DopeLog.debug(message)
                        return
                    }
                    
                })
                
                // send request
//                DopeLog.debugLog("Sending \(type.pathExtenstion) api call with payload: \(payload.description)")
                task.resume()
                
            } catch {
                let message = "Error sending \(type.pathExtenstion) api call with payload:(\(payload.description))"
                DopeLog.debug(message)
                Telemetry.storeException(className: "JSONSerialization", message: message)
            }
        }
    }
    
    
    
    
    /// Computes the basic fields for a request call
    ///
    /// Add this to your payload before calling `send()`
    ///
    private lazy var configurationData: [String: Any] = {
        
        var dict: [String: Any] = [ "clientOS": "iOS",
                                    "clientOSVersion": VisualizerAPI.clientOSVersion,
                                    "clientSDKVersion": VisualizerAPI.clientSDKVersion,
                                    "primaryIdentity" : self.primaryIdentity ]
        
        // create a credentials dict from .plist
        let credentialsFilename = "DopamineProperties"
        var path:String
        guard let credentialsPath = Bundle.main.path(forResource: credentialsFilename, ofType: "plist") else{
            DopeLog.debug("[DopamineKit]: Error - cannot find credentials in (\(credentialsFilename))")
            return dict
        }
        path = credentialsPath
        
        guard let credentialsPlist = NSDictionary(contentsOfFile: path) as? [String: Any] else{
            DopeLog.debug("[DopamineKit]: Error - (\(credentialsFilename)) is in the wrong format")
            return dict
        }
        
        guard let appID = credentialsPlist["appID"] as? String else{
            DopeLog.debug("[DopamineKit]: Error no appID - (\(credentialsFilename)) is in the wrong format")
            return dict
        }
        dict["appID"] = appID
        
        guard let versionID = credentialsPlist["versionID"] as? String else{
            DopeLog.debug("[DopamineKit]: Error no versionID - (\(credentialsFilename)) is in the wrong format")
            return dict
        }
        dict["versionID"] = versionID
        
        if let inProduction = credentialsPlist["inProduction"] as? Bool{
            if(inProduction){
                guard let productionSecret = credentialsPlist["productionSecret"] as? String else{
                    DopeLog.debug("[DopamineKit]: Error no productionSecret - (\(credentialsFilename)) is in the wrong format")
                    return dict
                }
                dict["secret"] = productionSecret
            } else{
                guard let developmentSecret = credentialsPlist["developmentSecret"] as? String else{
                    DopeLog.debug("[DopamineKit]: Error no developmentSecret - (\(credentialsFilename)) is in the wrong format")
                    return dict
                }
                dict["secret"] = developmentSecret
            }
        } else{
            DopeLog.debug("[DopamineKit]: Error no inProduction - (\(credentialsFilename)) is in the wrong format")
            return dict
        }
        
        return dict
    }()
    
    /// Computes a primary identity for the user
    ///
    /// This variable computes an identity for the user and saves it to NSUserDefaults for future use.
    ///
    private lazy var primaryIdentity:String = {
        #if DEBUG
            if let tid = DopamineKit.developmentIdentity {
                DopeLog.debug("Testing with primaryIdentity:(\(tid))")
                return tid
            }
        #endif
        if let aid = ASIdentifierManager.shared().adId()?.uuidString,
            aid != "00000000-0000-0000-0000-000000000000" {
            DopeLog.debug("ASIdentifierManager primaryIdentity:(\(aid))")
            return aid
        } else if let vid = UIDevice.current.identifierForVendor?.uuidString {
            DopeLog.debug("identifierForVendor primaryIdentity:(\(vid))")
            return vid
        } else {
            DopeLog.debug("IDUnavailable for primaryIdentity")
            return "IDUnavailable"
        }
    }()

}

fileprivate extension UIResponder {
    func getParentResponders() -> [String]{
        var responders: [String] = []
        DispatchQueue.main.sync {
            parentResponders(responders: &responders)
        }
        return responders
    }
    
    private func parentResponders(responders: inout [String]) {
        responders.append(NSStringFromClass(type(of:self)))
        if let next = self.next {
            next.parentResponders(responders: &responders)
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
