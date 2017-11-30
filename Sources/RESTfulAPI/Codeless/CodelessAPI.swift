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
    
    static var connectionID: String? { didSet { DopeLog.debug("🔍 \(connectionID != nil ? "C" : "Disc")onnected to visualizer") } }
    private let tracesQueue = OperationQueue()
    
    private override init() {
        super.init()
        tracesQueue.maxConcurrentOperationCount = 1
    }
    
    @objc
    public static func boot() {
        var payload = DopamineProperties.current.apiCredentials
        payload["inProduction"] = DopamineProperties.current.inProduction
        payload["currentVersion"] = DopamineVersion.current.versionID ?? "nil"
        payload["currentConfig"] = DopamineConfiguration.current.configID ?? "nil"
        payload["initialBoot"] = (UserDefaults.initialBootDate == nil)
        shared.send(call: .boot, with: payload){ response in
            if let status = response["status"] as? Int {
                DopeLog.debug("Codeless Boot:\(response as AnyObject)")
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
            
            // display reinforcement if reinforcement is set for this event
            DopamineVersion.current.codelessReinforcementFor(sender: "customEvent", target: "ApplicationEvent", selector: key) { reinforcement in
            
                DopeLog.debug("Found application mapping with params:\(reinforcement as AnyObject)")
                guard let delay = reinforcement["Delay"] as? Double else { DopeLog.error("❌ Bad param"); return }
                guard let viewOption = reinforcement["ViewOption"] as? String else { DopeLog.error("❌ Bad param"); return }
                guard let viewCustom = reinforcement["ViewCustom"] as? String else { DopeLog.error("❌ Bad param"); return }
                guard let viewMarginX = reinforcement["ViewMarginX"] as? CGFloat else { DopeLog.error("❌ Bad param"); return }
                guard let viewMarginY = reinforcement["ViewMarginY"] as? CGFloat else { DopeLog.error("❌ Bad param"); return }
                guard let reinforcementType = reinforcement["primitive"] as? String else { DopeLog.error("❌ Bad param"); return }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                    prepareShowReinforcement: do {
                        let viewsAndLocations: [(UIView, CGPoint)]
                        
                        switch viewOption {
                        case "fixed":
                            let view = UIWindow.topWindow!
                            let xMargin = viewMarginX <= 1.0 && viewMarginX > 0 ? viewMarginX * view.bounds.width : viewMarginX
                            let yMargin = viewMarginY <= 1.0 && viewMarginY > 0 ? viewMarginY * view.bounds.height : viewMarginY
                            viewsAndLocations = [(view, CGPoint(x: xMargin, y: yMargin))]
                            
                        case "custom":
                            if viewCustom != "" {
                                viewsAndLocations = UIView.find(viewCustom, { (view) -> CGPoint in
                                    return CGPoint(x: view.bounds.width / 2, y: view.bounds.height / 2)
                                })
                            } else {
                                DopeLog.debug("Oh no. No CustomView <\(viewCustom)> exists. No reinforcement for you.")
                                break prepareShowReinforcement
                            }
                            
                        default:
//                            DopeLog.debug("Oh no. Unknown reinforcement type primitive. No reinforcement for you.")
                            break prepareShowReinforcement
                        }
//                        DopeLog.debug("About to show application event reinforcement")
                        showReinforcement(on: viewsAndLocations, of: reinforcementType, withParameters: reinforcement)
                    }
                }
            }
            
            var payload = DopamineProperties.current.apiCredentials
            payload["customEvent"] = ["ApplicationEvent": key]
            payload["actionID"] = key
            payload["senderImage"] = ""
            let submitPayload = {
                // send event to visualizer if connected
                if let connectionID = connectionID {
                    payload["connectionUUID"] = connectionID
                    submit(payload)
                }
            }
            if key == "appLaunch" {
                DispatchQueue.global().asyncAfter(deadline: .now() + 3) {
                    submitPayload()
                }
            } else {
                submitPayload()
            }
            
        }
    }
    
    @objc
    public static var lastTouchLocationInUIWindow: CGPoint = CGPoint.zero
    
    @objc
    public static func recordEvent(touch: UITouch) {
        DispatchQueue.global().async {
            if let touchView = touch.view,
                touch.phase == .ended {
                
                let senderClassname = NSStringFromClass(type(of: touch))
                let targetName = touchView.getParentResponders().joined(separator: ",")
                let selectorName = "ended"
                
                // display reinforcement if reinforcement is set for this event
                DopamineVersion.current.codelessReinforcementFor(sender: senderClassname, target: targetName, selector: selectorName) { reinforcement in
                    
                    guard let delay = reinforcement["Delay"] as? Double else { DopeLog.error("❌ Bad param"); return }
                    guard let viewOption = reinforcement["ViewOption"] as? String else { DopeLog.error("❌ Bad param"); return }
                    guard let viewCustom = reinforcement["ViewCustom"] as? String else { DopeLog.error("❌ Bad param"); return }
                    guard let viewMarginX = reinforcement["ViewMarginX"] as? CGFloat else { DopeLog.error("❌ Bad param"); return }
                    guard let viewMarginY = reinforcement["ViewMarginY"] as? CGFloat else { DopeLog.error("❌ Bad param"); return }
                    guard let reinforcementType = reinforcement["primitive"] as? String else { DopeLog.error("❌ Bad param"); return }
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                        prepareShowReinforcement: do {
                            let viewsAndLocations: [(UIView, CGPoint)]
                            
                            switch viewOption {
                            case "fixed":
                                let view = UIWindow.topWindow!
                                let xMargin = viewMarginX <= 1.0 && viewMarginX > 0 ? viewMarginX * view.bounds.width : viewMarginX
                                let yMargin = viewMarginY <= 1.0 && viewMarginY > 0 ? viewMarginY * view.bounds.height : viewMarginY
                                viewsAndLocations = [(view, CGPoint(x: xMargin, y: yMargin))]
                                
                            case "touch":
                                viewsAndLocations = [(UIWindow.topWindow!, Helper.lastTouchLocationInUIWindow)]
                                
                            case "sender":
                                viewsAndLocations = [(UIWindow.topWindow!, Helper.lastTouchLocationInUIWindow)]
                                
                            case "superview":
                                if let superview = touchView.superview {
                                    viewsAndLocations = [(superview, CGPoint(x: superview.bounds.width / 2, y: superview.bounds.height / 2))]
                                } else {
                                    DopeLog.debug("Oh no. TouchView has no superview. No reinforcement for you.")
                                    break prepareShowReinforcement
                                }
                                
                            case "target":
                                viewsAndLocations = [(touchView, CGPoint(x: touchView.bounds.width / 2, y: touchView.bounds.height / 2))]
                                
                            case "custom":
                                if viewCustom != "" {
                                    viewsAndLocations = UIView.find(viewCustom, { (view) -> CGPoint in
                                        return CGPoint(x: view.bounds.width / 2, y: view.bounds.height / 2)
                                    })
                                } else {
                                    DopeLog.debug("Oh no. No CustomView <\(viewCustom)> exists. No reinforcement for you.")
                                    break prepareShowReinforcement
                                }
                                
                            default:
                                DopeLog.debug("Oh no. Unknown reinforcement type primitive. No reinforcement for you.")
                                break prepareShowReinforcement
                            }
                            
                            showReinforcement(on: viewsAndLocations, of: reinforcementType, withParameters: reinforcement)
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
                    payload["actionID"] = [senderClassname, targetName, selectorName].joined(separator: "-")
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
            
            // display reinforcement if reinforcement is set for this event
            DopamineVersion.current.codelessReinforcementFor(sender: senderClassname, target: targetClassname, selector: selectorName) { reinforcement in
                
                guard let delay = reinforcement["Delay"] as? Double else { DopeLog.error("❌ Bad param"); return }
                guard let viewOption = reinforcement["ViewOption"] as? String else { DopeLog.error("❌ Bad param"); return }
                guard let viewCustom = reinforcement["ViewCustom"] as? String else { DopeLog.error("❌ Bad param"); return }
                guard let viewMarginX = reinforcement["ViewMarginX"] as? CGFloat else { DopeLog.error("❌ Bad param"); return }
                guard let viewMarginY = reinforcement["ViewMarginY"] as? CGFloat else { DopeLog.error("❌ Bad param"); return }
                guard let reinforcementType = reinforcement["primitive"] as? String else { DopeLog.error("❌ Bad param"); return }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                    prepareShowReinforcement: do {
                        let viewsAndLocations: [(UIView, CGPoint)]
                        
                        switch viewOption {
                        case "fixed":
                            let view = UIWindow.topWindow!
                            let xMargin = viewMarginX <= 1.0 && viewMarginX > 0 ? viewMarginX * view.bounds.width : viewMarginX
                            let yMargin = viewMarginY <= 1.0 && viewMarginY > 0 ? viewMarginY * view.bounds.height : viewMarginY
                            viewsAndLocations = [(view, CGPoint(x: xMargin, y: yMargin))]
                            
                        case "touch":
                            viewsAndLocations = [(UIWindow.topWindow!, Helper.lastTouchLocationInUIWindow)]
                            
                        case "sender":
                            if let view = senderInstance as? UIView {
                                viewsAndLocations = [(view, CGPoint(x: view.bounds.width / 2, y: view.bounds.height / 2))]
                            } else if senderInstance.responds(to: NSSelectorFromString("view")),
                                let view = senderInstance.value(forKey: "view") as? UIView {
                                viewsAndLocations = [(view, CGPoint(x: view.bounds.width / 2, y: view.bounds.height / 2))]
                            } else {
                                DopeLog.debug("Oh no. Sender is not a UIView or has no view property. No reinforcement for you.")
                                break prepareShowReinforcement
                            }
                            
                        case "superview":
                            if let senderInstance = senderInstance as? UIView,
                                let superview = senderInstance.superview {
                                viewsAndLocations = [(superview, CGPoint(x: superview.bounds.width / 2, y: superview.bounds.height / 2))]
                            } else if senderInstance.responds(to: NSSelectorFromString("view")),
                                let view = senderInstance.value(forKey: "view") as? UIView,
                                let superview = view.superview {
                                viewsAndLocations = [(superview, CGPoint(x: superview.bounds.width / 2, y: superview.bounds.height / 2))]
                            } else {
                                DopeLog.debug("Oh no. Sender is not a UIView or has no superview. No reinforcement for you.")
                                break prepareShowReinforcement
                            }
                            
                        case "target":
                            if let view = targetInstance as? UIView {
                                viewsAndLocations = [(view, CGPoint(x: view.bounds.width / 2, y: view.bounds.height / 2))]
                            } else if targetInstance.responds(to: NSSelectorFromString("view")),
                                let view = targetInstance.value(forKey: "view") as? UIView {
                                viewsAndLocations = [(view, CGPoint(x: view.bounds.width / 2, y: view.bounds.height / 2))]
                            } else {
                                DopeLog.debug("Oh no. Target is not a UIView and has no view property. Doing touch")
                                viewsAndLocations = [(UIWindow.topWindow!, Helper.lastTouchLocationInUIWindow)]
                            }
                            
                        case "custom":
                            if viewCustom != "" {
                                viewsAndLocations = UIView.find(viewCustom, { (view) -> CGPoint in
                                    return CGPoint(x: view.bounds.width / 2, y: view.bounds.height / 2)
                                })
                            } else {
                                DopeLog.debug("Oh no. No CustomView <\(viewCustom)> exists. No reinforcement for you.")
                                break prepareShowReinforcement
                            }
                            
                        default:
                            DopeLog.debug("Oh no. Unknown view type. No reinforcement for you.")
                            break prepareShowReinforcement
                        }
                        
                        showReinforcement(on: viewsAndLocations, of: reinforcementType, withParameters: reinforcement)
                    }
                }
            }
            
            
            // send event to visualizer if connected
            if let connectionID = connectionID {
                var payload = DopamineProperties.current.apiCredentials
                payload["connectionUUID"] = connectionID
                payload["sender"] = senderClassname
                payload["target"] = targetClassname
                payload["selector"] = selectorName
                payload["actionID"] = [senderClassname, targetClassname, selectorName].joined(separator: "-")
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
    
//    static var submitted = Set<String>()
    fileprivate static func submit(_ payload: [String: Any]) {
//        guard !submitted.contains(payload["actionID"] as! String) else {
//            return
//        }
//        submitted.insert(payload["actionID"] as! String)
        shared.send(call: .submit, with: payload){ response in
            if response["status"] as? Int != 200 {
                CodelessAPI.connectionID = nil
                DopamineVersion.current.updateVisualizerMappings([:])
            } else if shared.tracesQueue.operationCount <= 1 {
                if let visualizerMappings = response["mappings"] as? [String:Any] {
                    DopamineVersion.current.updateVisualizerMappings(visualizerMappings)
                } else {
                    DopeLog.debug("Invalid mappings")
                }
            }
        }
    }
    
    fileprivate static func showReinforcement(on viewAndLocation: [(UIView, CGPoint)], of type: String, withParameters reinforcement: [String: Any]) {
        switch type {
            
        case "Emojisplosion":
            guard let content = reinforcement["Content"] as? String else { DopeLog.error("❌ Bad param"); break }
            guard let xAcceleration = reinforcement["AccelX"] as? CGFloat else { DopeLog.error("❌  Bad param"); break }
            guard let yAcceleration = reinforcement["AccelY"] as? CGFloat  else { DopeLog.error("❌  Bad param"); break }
            guard let bursts = reinforcement["Bursts"] as? Double  else { DopeLog.error("❌  Bad param"); break }
            guard let angle = reinforcement["EmissionAngle"] as? CGFloat  else { DopeLog.error("❌  Bad param"); break }
            guard let range = reinforcement["EmissionRange"] as? CGFloat  else { DopeLog.error("❌  Bad param"); break }
            guard let fadeout = reinforcement["FadeOut"] as? Float  else { DopeLog.error("❌  Bad param"); break }
            guard let lifetime = reinforcement["Lifetime"] as? Float  else { DopeLog.error("❌  Bad param"); break }
            guard let lifetimeRange = reinforcement["LifetimeRange"] as? Float  else { DopeLog.error("❌  Bad param"); break }
            guard let quantity = reinforcement["Quantity"] as? Float  else { DopeLog.error("❌  Bad param"); break }
            guard let scale = reinforcement["Scale"] as? CGFloat  else { DopeLog.error("❌  Bad param"); break }
            guard let scaleRange = reinforcement["ScaleRange"] as? CGFloat  else { DopeLog.error("❌  Bad param"); break }
            guard let scaleSpeed = reinforcement["ScaleSpeed"] as? CGFloat  else { DopeLog.error("❌  Bad param"); break }
            guard let spin = reinforcement["Spin"] as? CGFloat  else { DopeLog.error("❌  Bad param"); break }
            guard let velocity = reinforcement["Velocity"] as? CGFloat  else { DopeLog.error("❌  Bad param"); break }
            let image = content.decode().image().cgImage
            for (view, location) in viewAndLocation {
                view.showEmojiSplosion(at: location, content: image, scale: scale, scaleSpeed: scaleSpeed, scaleRange: scaleRange, lifetime: lifetime, lifetimeRange: lifetimeRange, fadeout: fadeout, birthRate: quantity, birthCycles: bursts, velocity: velocity, xAcceleration: xAcceleration, yAcceleration: yAcceleration, angle: angle, range: range, spin: spin)
            }
            return
            
        case "Gifsplosion":
            guard let contentString = reinforcement["Content"] as? String  else { DopeLog.error("❌  Bad param"); break }
            guard let xAcceleration = reinforcement["AccelX"] as? CGFloat  else { DopeLog.error("❌  Bad param"); break }
            guard let yAcceleration = reinforcement["AccelY"] as? CGFloat  else { DopeLog.error("❌  Bad param"); break }
            guard let bursts = reinforcement["Bursts"] as? Double  else { DopeLog.error("❌  Bad param"); break }
            guard let angle = reinforcement["EmissionAngle"] as? CGFloat  else { DopeLog.error("❌  Bad param"); break }
            guard let range = reinforcement["EmissionRange"] as? CGFloat  else { DopeLog.error("❌  Bad param"); break }
            guard let fadeout = reinforcement["FadeOut"] as? Float  else { DopeLog.error("❌  Bad param"); break }
            guard let lifetime = reinforcement["Lifetime"] as? Float  else { DopeLog.error("❌  Bad param"); break }
            guard let lifetimeRange = reinforcement["LifetimeRange"] as? Float  else { DopeLog.error("❌  Bad param"); break }
            guard let quantity = reinforcement["Quantity"] as? Float  else { DopeLog.error("❌  Bad param"); break }
            guard let scale = reinforcement["Scale"] as? CGFloat  else { DopeLog.error("❌  Bad param"); break }
            guard let scaleRange = reinforcement["ScaleRange"] as? CGFloat  else { DopeLog.error("❌  Bad param"); break }
            guard let scaleSpeed = reinforcement["ScaleSpeed"] as? CGFloat  else { DopeLog.error("❌  Bad param"); break }
            guard let spin = reinforcement["Spin"] as? CGFloat  else { DopeLog.error("❌  Bad param"); break }
            guard let velocity = reinforcement["Velocity"] as? CGFloat  else { DopeLog.error("❌  Bad param"); break }
            guard let backgroundColorString = reinforcement["BackgroundColor"] as? String  else { DopeLog.error("❌  Bad param"); break }
            guard let backgroundAlpha = reinforcement["BackgroundAlpha"] as? CGFloat  else { DopeLog.error("❌  Bad param"); break }
            for (view, location) in viewAndLocation {
                view.showGifSplosion(at: location, contentString: contentString, scale: scale, scaleSpeed: scaleSpeed, scaleRange: scaleRange, lifetime: lifetime, lifetimeRange: lifetimeRange, fadeout: fadeout, quantity: quantity, bursts: bursts, velocity: velocity, xAcceleration: xAcceleration, yAcceleration: yAcceleration, angle: angle, range: range, spin: spin, backgroundColor: UIColor.from(rgb: backgroundColorString), backgroundAlpha: backgroundAlpha)
            }
            return
            
        case "Glow":
            guard let duration = reinforcement["Duration"] as? Double  else { DopeLog.error("❌  Bad param"); break }
            guard let colorString = reinforcement["Color"] as? String  else { DopeLog.error("❌  Bad param"); break }
            guard let alpha = reinforcement["Alpha"] as? CGFloat  else { DopeLog.error("❌  Bad param"); break }
            guard let count = reinforcement["Count"] as? Float  else { DopeLog.error("❌  Bad param"); break }
            guard let radius = reinforcement["Radius"] as? CGFloat  else { DopeLog.error("❌  Bad param"); break }
            let color = UIColor.from(rgb: colorString)
            for (view, _) in viewAndLocation {
                view.showGlow(duration: duration, color: color, alpha: alpha, radius: radius, count: count)
            }
            return
            
        case "Sheen":
            guard let duration = reinforcement["Duration"] as? Double  else { DopeLog.error("❌  Bad param"); break }
            for (view, _) in viewAndLocation {
                view.showSheen(duration: duration)
            }
            return
            
        case "Pulse":
            guard let count = reinforcement["Count"] as? Float  else { DopeLog.error("❌  Bad param"); break }
            guard let duration = reinforcement["Duration"] as? Double  else { DopeLog.error("❌  Bad param"); break }
            guard let scale = reinforcement["Scale"] as? CGFloat  else { DopeLog.error("❌  Bad param"); break }
            guard let velocity = reinforcement["Velocity"] as? CGFloat  else { DopeLog.error("❌  Bad param"); break }
            guard let damping = reinforcement["Damping"] as? CGFloat  else { DopeLog.error("❌  Bad param"); break }
            for (view, _) in viewAndLocation {
                view.showPulse(count: count, duration: duration, scale: scale, velocity: velocity, damping: damping)
            }
            return
            
        case "Shimmy":
            guard let count = reinforcement["Count"] as? Int  else { DopeLog.error("❌  Bad param"); break }
            guard let duration = reinforcement["Duration"] as? Double  else { DopeLog.error("❌  Bad param"); break }
            guard let translation = reinforcement["Translation"] as? Int  else { DopeLog.error("❌  Bad param"); break }
            for (view, _) in viewAndLocation {
                view.showShimmy(count: count, duration: duration, translation: translation)
            }
            return
            
        case "Vibrate":
            guard let duration = reinforcement["Duration"] as? Double  else { DopeLog.error("❌  Bad param"); break }
            guard let vibrateCount = reinforcement["Count"] as? Int  else { DopeLog.error("❌  Bad param"); break }
            guard let vibrateTranslation = reinforcement["Translation"] as? Int  else { DopeLog.error("❌  Bad param"); break }
            guard let vibrateSpeed = reinforcement["Speed"] as? Float  else { DopeLog.error("❌  Bad param"); break }
            guard let scale = reinforcement["Scale"] as? CGFloat  else { DopeLog.error("❌  Bad param"); break }
            guard let scaleVelocity = reinforcement["ScaleVelocity"] as? CGFloat  else { DopeLog.error("❌  Bad param"); break }
            guard let scaleDamping = reinforcement["ScaleDamping"] as? CGFloat  else { DopeLog.error("❌  Bad param"); break }
            for (view, _) in viewAndLocation {
                view.showVibrate(vibrateCount: vibrateCount, vibrateDuration: duration, vibrateTranslation: vibrateTranslation, vibrateSpeed: vibrateSpeed, scale: scale, scaleCount: 1, scaleDuration: 0.3, scaleVelocity: scaleVelocity, scaleDamping: scaleDamping)
            }
            return
            
        default:
            // TODO: implement delegate callback for dev defined reinforcements
            DopeLog.debug("Unknown reinforcement type:\(String(describing: reinforcement))")
            return
        }
        
        // function should have returned if successful
        DopeLog.error("Invalid animation parameters for reinforcement type:\(String(describing: reinforcement))")
        print("reinforcement objcect:\(reinforcement as AnyObject)")
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
                        CodelessAPI.connectionID = connectionID
                        print("Reconnected")
//                        DispatchQueue.main.async {
//                            CandyBar(title: "Connection Restored", subtitle: "DopamineKit Visualizer").show(duration: 1.2)
//                        }
                    }
                    
                case 204:
                    if DopamineVersion.current.visualizerMappings.count != 0 {
                        DopamineVersion.current.updateVisualizerMappings([:])
                    }
                    break
                    
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
                        DopeLog.debug("✅\(type.path) call got response:\(responseDict as AnyObject)")
                        
                    } catch {
                        let message = "❌ Error reading \(type.path) response data: " + String(describing: (responseData != nil) ? String(data: responseData!, encoding: .utf8) : String(describing: responseData.debugDescription))
                        DopeLog.debug(message)
                        return
                    }
                    
                })
                
                // send request
                DopeLog.debug("Sending \(type.path) api call with payload: \(payload as AnyObject)")
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
    
    static func find(_ viewCustom: String, _ locationFunction: (UIView) -> CGPoint ) -> [(UIView, CGPoint)] {
        var values: [(UIView, CGPoint)] = []
        for view in find(viewCustom) {
            values.append((view, locationFunction(view)))
        }
        return values
    }
    
    static func find(_ viewCustom: String) -> [UIView] {
        let viewCustomParams = viewCustom.components(separatedBy: "$")
        let classname: String
        let index: Int?
        if viewCustomParams.count == 2 {
            classname = viewCustomParams[0]
            index = Int(viewCustomParams[1])
        } else if viewCustomParams.count == 1 {
            classname = viewCustomParams[0]
            index = nil
        } else {
            DopeLog.error("Invalid params for customView. Should be in the format \"ViewClassname$0\"")
            return []
        }
        let possibleViews = UIApplication.shared.keyWindow!.getSubviewsWithClassname(classname: classname)
        
        if let index = index {
            if index >= 0 {
                if index < possibleViews.count {
                    return [possibleViews[index]]
                } else if let view = possibleViews.last {
                    return [view]
                }
            } else { // negative index counts backwards
                if -index <= possibleViews.count {
                    return [possibleViews[possibleViews.count + index]]
                } else if let view = possibleViews.first {
                    return [view]
                }
            }
        }
        
        return possibleViews
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
