//
//  CodelessAPI.swift
//  Pods
//
//  Created by Akash Desai on 9/9/17.
//
//

import Foundation

@objc
public class CodelessAPI : NSObject {
    
    /// Valid API actions appeneded to the CodelessAPI URL
    ///
    internal enum CallType{
        case identify, accept, submit, boot
        var path:String{ switch self{
        case .identify: return "https://dashboard-api.usedopamine.com/codeless/pair/customer/identity/"
        case .accept: return "https://dashboard-api.usedopamine.com/codeless/pair/customer/accept/"
        case .submit: return "https://dashboard-api.usedopamine.com/codeless/visualizer/customer/submit/"
        case .boot: return "https://api.usedopamine.com/v5/app/boot"
//        case .boot: return "http://10.0.1.158/v5/app/boot:8008"
            }
        }
    }
    
    @objc
    public static let shared = CodelessAPI()
    
    static var connectionID: String?
    private let tracesQueue = OperationQueue()
    
    private override init() {
        super.init()
        tracesQueue.maxConcurrentOperationCount = 1
    }
    
    @objc
    public static func boot() {
//        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
//            UIApplication.shared.keyWindow!.showConfetti()
//        }
        var payload = DopamineProperties.current.apiCredentials
        payload["utc"] = NSNumber(value: Int64(Date().timeIntervalSince1970) * 1000)
        payload["timezoneOffset"] = NSNumber(value: Int64(NSTimeZone.default.secondsFromGMT()) * 1000)
        payload["inProduction"] = DopamineProperties.current.inProduction
        payload["currentVersion"] = DopamineVersion.current.versionID ?? "nil"
        payload["currentConfig"] = DopamineConfiguration.current.configID ?? "nil"
        payload["initialBoot"] = (Helper.initialBoot == nil)
        shared.send(call: .boot, with: payload){ response in
            if let status = response["status"] as? Int {
                if status == 205 {
                    if let configDict = response["config"] as? [String: Any],
                        let config = DopamineConfiguration.convert(from: configDict) {
                        DopamineProperties.current.configuration = config
                    }
                    if let versionDict = response["version"] as? [String: Any],
                        let version = DopamineVersion.convert(from: versionDict) {
                        DopamineProperties.current.version = version
                    }
                }
            }
            if !DopamineProperties.current.inProduction { promptPairing() }
        }
    }
    
    @objc
    public static func recordApplicationEvent(key: String) {
        DispatchQueue.global().async {
            
//            if let mappings = DopamineVersion.current.mappingsForAppEvent(key){
            
            // display reward if reward is set for this event
            DopamineVersion.current.reinforcementFor(sender: "customEvent", target: "ApplicationEvent", selector: key) { reinforcement in
            
                DopeLog.debug("Found application mapping with params:\(dump(reinforcement))")
                if let delay = reinforcement["Delay"] as? Double,
                    let viewOption = reinforcement["ViewOption"] as? String,
                    let viewCustom = reinforcement["ViewCustom"] as? String,
                    let viewMarginX = reinforcement["ViewMarginX"] as? CGFloat,
                    let viewMarginY = reinforcement["ViewMarginY"] as? CGFloat,
                    let reinforcementType = reinforcement["primitive"] as? String
                {
                    DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                        prepareShowReward: do {
                            var view: UIView! = UIApplication.shared.keyWindow! // DLWindow.shared.view
                            var location: CGPoint = CGPoint(x: view.bounds.width / 2, y: view.bounds.height / 2)
                            switch viewOption {
                            case "fixed":
//                                view = UIApplication.shared.keyWindow!
                                let xMargin = viewMarginX <= 1.0 && viewMarginX > 0 ? viewMarginX * view.bounds.width : viewMarginX
                                let yMargin = viewMarginY <= 1.0 && viewMarginY > 0 ? viewMarginY * view.bounds.height : viewMarginY
                                location = CGPoint(x: xMargin, y: yMargin)

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
//                                            DopeLog.debug("Oh no. Must select which CustomView with a VALID index. No reward for you.")
//                                            break prepareShowReward
                                            DopeLog.debug("Forgot to select index. Using 0 by default.")
                                            if let v = possibleViews.first {
                                                view = v
                                            }
                                            location = CGPoint(x: view.bounds.width / 2, y: view.bounds.height / 2)
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
//                                DopeLog.debug("Oh no. Unknown reward type primitive. No reward for you.")
//                                break prepareShowReward
                                break
                            }
                            DopeLog.debug("About to show application event reinforcement")
                            showReward(on: view, at: location, of: reinforcementType, withParameters: reinforcement)
                        }
                    }

                }
            }
            
            var payload = DopamineProperties.current.apiCredentials
            payload["utc"] = NSNumber(value: Int64(Date().timeIntervalSince1970) * 1000)
            payload["timezoneOffset"] = NSNumber(value: Int64(NSTimeZone.default.secondsFromGMT()) * 1000)
            payload["customEvent"] = ["ApplicationEvent": key]
            payload["senderImage"] = ""
            DispatchQueue.global().asyncAfter(deadline: .now() + 3) {
                // send event to visualizer if connected
                if let connectionID = connectionID {
                    payload["connectionUUID"] = connectionID
                    submit(payload)
                }
            }
        }
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
                DopamineVersion.current.reinforcementFor(sender: senderClassname, target: targetName, selector: selectorName) { reinforcement in
                    
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
                    var payload = DopamineProperties.current.apiCredentials
                    payload["connectionUUID"] = connectionID
                    payload["sender"] = senderClassname
                    payload["target"] = targetName
                    payload["selector"] = selectorName
                    payload["senderImage"] = ""
//                    DispatchQueue.main.sync {
//                    payload["senderImage"] = touchView.imageAsBase64EncodedString()
                    
//                        if let view = t as? UIView,
//                            let imageString = view.imageAsBase64EncodedString() {
//                            payload["senderImage"] = imageString
//                        } else if let barItem = senderInstance as? UIBarItem,
//                            let image = barItem.image,
//                            let imageString = image.base64EncodedPNGString() {
//                            payload["senderImage"] = imageString
//                        } else if senderInstance.responds(to: NSSelectorFromString("view")),
//                            let sv = senderInstance.value(forKey: "view") as? UIView,
//                            let imageString = sv.imageAsBase64EncodedString() {
//                            payload["senderImage"] = imageString
//                        } else {
//                            NSLog("Cannot create image, please message team@usedopamine.com to add support for visualizer snapshots of class type:<\(type(of: senderInstance))>!")
//                            payload["senderImage"] = ""
//                        }
//                        
//                    }
                    
                    payload["utc"] = NSNumber(value: Int64(Date().timeIntervalSince1970) * 1000)
                    payload["timezoneOffset"] = NSNumber(value: Int64(NSTimeZone.default.secondsFromGMT()) * 1000)
                    submit(payload)
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
//            print("sender:\(senderClassname) target:\(targetClassname) selector:\(selectorName)")
            
            // display reward if reward is set for this event
            DopamineVersion.current.reinforcementFor(sender: senderClassname, target: targetClassname, selector: selectorName) { reinforcement in
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
                var payload = DopamineProperties.current.apiCredentials
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
                        payload["senderImage"] = ""
                    }
                }
                submit(payload)
            }
        }
    }
    
    fileprivate static func submit(_ payload: [String: Any]) {
        shared.send(call: .submit, with: payload){ response in
            if response["status"] as? Int != 200 {
                CodelessAPI.connectionID = nil
            } else if shared.tracesQueue.operationCount <= 1 {
                if let visualizerMappings = response["mappings"] as? [String:Any] {
                    DopamineVersion.current.updateVisualizerMappings(visualizerMappings)
                } else {
                    DopeLog.debug("Invalid mappings")
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
    private static func promptPairing() {
        var payload = DopamineProperties.current.apiCredentials
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
//                        let connectedRestoredAlert = UIAlertController(title: "Visualizer Pairing", message: "Connection restored", preferredStyle: .alert)
//                        connectedRestoredAlert.addAction( UIAlertAction(title: "Ok", style: .default, handler: { _ in
                            CodelessAPI.connectionID = connectionID
//                        }))
//                        UIWindow.presentTopLevelAlert(alertController: connectedRestoredAlert)
                        CandyBar.init(title: "Connection Restored", subtitle: "DopamineKit Visualizer").show(duration: 1.2)
                    }
                    
                case 204:
                    DopamineVersion.current.updateVisualizerMappings([:])
                    
                case 500:
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
            var payload = DopamineProperties.current.apiCredentials
            payload["deviceName"] = UIDevice.current.name
            payload["connectionUUID"] = connectionID
            shared.send(call: .accept, with: payload) {response in
                if response["status"] as? Int == 200 {
                    CodelessAPI.connectionID = connectionID
                }
            }
        }))
        
        pairingAlert.addAction(UIAlertAction(title: "No", style: .cancel, handler: { _ in
            
        }))
        
        UIWindow.presentTopLevelAlert(alertController: pairingAlert)
        
    }
    
    
    /// This function sends a request to the CodelessAPI
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
                        DopeLog.debug("✅\(type.path) call got empty response.")
                        return
                    }
                    
                    do {
                        // turn the response into a json object
                        guard let data = responseData,
                            let dict = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
                            else {
                                let json = responseData.flatMap({ NSString(data: $0, encoding: String.Encoding.utf8.rawValue) }) ?? ""
                                let message = "❌ Error reading \(type.path) response data, not a dictionary: \(json)"
                                DopeLog.debug(message)
                                Telemetry.storeException(className: "JSONSerialization", message: message)
                                return
                        }
                        responseDict = dict
//                        DopeLog.debug("✅\(type.path) call got response:\(responseDict as AnyObject)")
                        
                    } catch {
                        let message = "❌ Error reading \(type.path) response data: " + String(describing: (responseData != nil) ? String(data: responseData!, encoding: .utf8) : String(describing: responseData.debugDescription))
                        DopeLog.debug(message)
                        return
                    }
                    
                })
                
                // send request
//                DopeLog.debug("Sending \(type.path) api call with payload: \(payload as AnyObject)")
                task.resume()
                
            } catch {
                let message = "Error sending \(type.path) api call with payload:(\(payload as AnyObject))"
                DopeLog.debug(message)
                Telemetry.storeException(className: "JSONSerialization", message: message)
            }
        }
    }
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
