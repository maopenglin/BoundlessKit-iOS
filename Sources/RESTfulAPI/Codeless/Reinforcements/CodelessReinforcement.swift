//
//  Reinforcement.swift
//  DopamineKit
//
//  Created by Akash Desai on 12/1/17.
//

import Foundation

public class CodelessReinforcement : NSObject {
    
//    internal static var needsLastTouchLocation = false
    internal static var lastTouchLocationInUIWindow: CGPoint = .zero
    @objc public class func setLastTouch(_ touch: UITouch?) {
        if let touch = touch,
            touch.phase == .ended,
            let view = touch.view {
            DispatchQueue.main.async {
                UIWindow.lastTouchPoint = view.convert(touch.location(in: view), to: nil)
            }
        }
    }
    
    internal static func reinforcementsIDs(in actionMapping: [String: Any]) -> [String]? {
        if let codeless = actionMapping["codeless"] as? [String: Any],
            let reinforcements = codeless["reinforcements"] as? [[String: Any]],
            !reinforcements.isEmpty {
            var reinforcementIDs = [String]()
            for reinforcement in reinforcements {
                if let primitive = reinforcement["primitive"] as? String {
                    reinforcementIDs.append(primitive)
                } else {
                    DopeLog.error("Expected 'primitive' key with string value for codeless reinforcement")
                }
            }
            if !reinforcementIDs.isEmpty { return reinforcementIDs }
        }
        return nil
    }
    
    internal static func show(actionID: String, reinforcementDecision: String, senderInstance: AnyObject?, targetInstance: NSObject, completion: @escaping ()->Void = {}) {
        guard reinforcementDecision != Cartridge.defaultReinforcementDecision else {
            completion()
            return
        }
        
        var reinforcement: [String: Any]?
        if let actionMapping = DopamineVersion.current.actionMapping(for: actionID),
            let codeless = actionMapping["codeless"] as? [String: Any],
            let reinforcements = codeless["reinforcements"] as? [[String: Any]] {
            for aReinforcement in reinforcements {
                if aReinforcement["primitive"] as? String == reinforcementDecision {
                    reinforcement = aReinforcement
                    break
                }
            }
        }
        if let reinforcement = reinforcement {
            show(reinforcement: reinforcement, senderInstance: senderInstance, targetInstance: targetInstance) {
                completion()
            }
        } else {
            DopeLog.error("No reinforcement found for actionID:\(actionID)")
        }
    }
    
    fileprivate static func show(reinforcement: [String:Any], senderInstance: AnyObject?, targetInstance: NSObject, completion: @escaping ()->Void = {}) {
        guard let delay = reinforcement["Delay"] as? Double else { DopeLog.error("Missing parameter", visual: true); return }
        guard let reinforcementType = reinforcement["primitive"] as? String else { DopeLog.error("Missing parameter", visual: true); return }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            if let viewAndLocation = reinforcementViews(senderInstance: senderInstance, targetInstance: targetInstance, options: reinforcement) {
                switch reinforcementType {
                    
                case "Confetti":
                    guard let duration = reinforcement["Duration"] as? Double else { DopeLog.error("Missing parameter", visual: true); break }
                    guard let hapticFeedback = reinforcement["HapticFeedback"] as? Bool  else { DopeLog.error("Missing parameter", visual: true); break }
                    guard let systemSound = reinforcement["SystemSound"] as? UInt32  else { DopeLog.error("Missing parameter", visual: true); break }
                    for (view, _) in viewAndLocation {
                        view.showConfetti(duration: duration, hapticFeedback: hapticFeedback, systemSound: systemSound, completion: completion)
                    }
                    return
                    
                case "Emojisplosion":
                    guard let content = reinforcement["Content"] as? String else { DopeLog.error("Missing parameter", visual: true); break }
                    guard let xAcceleration = reinforcement["AccelX"] as? CGFloat else { DopeLog.error("Missing parameter", visual: true); break }
                    guard let yAcceleration = reinforcement["AccelY"] as? CGFloat  else { DopeLog.error("Missing parameter", visual: true); break }
                    guard let bursts = reinforcement["Bursts"] as? Double  else { DopeLog.error("Missing parameter", visual: true); break }
                    guard let angle = reinforcement["EmissionAngle"] as? CGFloat  else { DopeLog.error("Missing parameter", visual: true); break }
                    guard let range = reinforcement["EmissionRange"] as? CGFloat  else { DopeLog.error("Missing parameter", visual: true); break }
                    guard let fadeout = reinforcement["FadeOut"] as? Float  else { DopeLog.error("Missing parameter", visual: true); break }
                    guard let lifetime = reinforcement["Lifetime"] as? Float  else { DopeLog.error("Missing parameter", visual: true); break }
                    guard let lifetimeRange = reinforcement["LifetimeRange"] as? Float  else { DopeLog.error("Missing parameter", visual: true); break }
                    guard let quantity = reinforcement["Quantity"] as? Float  else { DopeLog.error("Missing parameter", visual: true); break }
                    guard let scale = reinforcement["Scale"] as? CGFloat  else { DopeLog.error("Missing parameter", visual: true); break }
                    guard let scaleRange = reinforcement["ScaleRange"] as? CGFloat  else { DopeLog.error("Missing parameter", visual: true); break }
                    guard let scaleSpeed = reinforcement["ScaleSpeed"] as? CGFloat  else { DopeLog.error("Missing parameter", visual: true); break }
                    guard let spin = reinforcement["Spin"] as? CGFloat  else { DopeLog.error("Missing parameter", visual: true); break }
                    guard let velocity = reinforcement["Velocity"] as? CGFloat  else { DopeLog.error("Missing parameter", visual: true); break }
                    guard let hapticFeedback = reinforcement["HapticFeedback"] as? Bool  else { DopeLog.error("Missing parameter", visual: true); break }
                    guard let systemSound = reinforcement["SystemSound"] as? UInt32  else { DopeLog.error("Missing parameter", visual: true); break }
                    let image = content.decode().image().cgImage
                    for (view, location) in viewAndLocation {
                        view.showEmojiSplosion(at: location, content: image, scale: scale, scaleSpeed: scaleSpeed, scaleRange: scaleRange, lifetime: lifetime, lifetimeRange: lifetimeRange, fadeout: fadeout, quantity: quantity, bursts: bursts, velocity: velocity, xAcceleration: xAcceleration, yAcceleration: yAcceleration, angle: angle, range: range, spin: spin, hapticFeedback: hapticFeedback, systemSound: systemSound, completion: completion)
                    }
                    return
                    
                case "Glow":
                    guard let duration = reinforcement["Duration"] as? Double  else { DopeLog.error("Missing parameter", visual: true); break }
                    guard let colorString = reinforcement["Color"] as? String  else { DopeLog.error("Missing parameter", visual: true); break }
                    guard let alpha = reinforcement["Alpha"] as? CGFloat  else { DopeLog.error("Missing parameter", visual: true); break }
                    guard let count = reinforcement["Count"] as? Float  else { DopeLog.error("Missing parameter", visual: true); break }
                    guard let radius = reinforcement["Radius"] as? CGFloat  else { DopeLog.error("Missing parameter", visual: true); break }
                    guard let hapticFeedback = reinforcement["HapticFeedback"] as? Bool  else { DopeLog.error("Missing parameter", visual: true); break }
                    guard let systemSound = reinforcement["SystemSound"] as? UInt32  else { DopeLog.error("Missing parameter", visual: true); break }
                    let color = UIColor.from(rgb: colorString)
                    for (view, _) in viewAndLocation {
                        view.showGlow(duration: duration, color: color, alpha: alpha, radius: radius, count: count, hapticFeedback: hapticFeedback, systemSound: systemSound, completion: completion)
                    }
                    return
                    
                case "Sheen":
                    guard let duration = reinforcement["Duration"] as? Double  else { DopeLog.error("Missing parameter", visual: true); break }
                    guard let hapticFeedback = reinforcement["HapticFeedback"] as? Bool  else { DopeLog.error("Missing parameter", visual: true); break }
                    guard let systemSound = reinforcement["SystemSound"] as? UInt32  else { DopeLog.error("Missing parameter", visual: true); break }
                    for (view, _) in viewAndLocation {
                        view.showSheen(duration: duration, hapticFeedback: hapticFeedback, systemSound: systemSound, completion: completion)
                    }
                    return
                    
                case "Pulse":
                    guard let count = reinforcement["Count"] as? Float  else { DopeLog.error("Missing parameter", visual: true); break }
                    guard let duration = reinforcement["Duration"] as? Double  else { DopeLog.error("Missing parameter", visual: true); break }
                    guard let scale = reinforcement["Scale"] as? CGFloat  else { DopeLog.error("Missing parameter", visual: true); break }
                    guard let velocity = reinforcement["Velocity"] as? CGFloat  else { DopeLog.error("Missing parameter", visual: true); break }
                    guard let damping = reinforcement["Damping"] as? CGFloat  else { DopeLog.error("Missing parameter", visual: true); break }
                    guard let hapticFeedback = reinforcement["HapticFeedback"] as? Bool  else { DopeLog.error("Missing parameter", visual: true); break }
                    guard let systemSound = reinforcement["SystemSound"] as? UInt32  else { DopeLog.error("Missing parameter", visual: true); break }
                    for (view, _) in viewAndLocation {
                        view.showPulse(count: count, duration: duration, scale: scale, velocity: velocity, damping: damping, hapticFeedback: hapticFeedback, systemSound: systemSound, completion: completion)
                    }
                    return
                    
                case "Shimmy":
                    guard let count = reinforcement["Count"] as? Int  else { DopeLog.error("Missing parameter", visual: true); break }
                    guard let duration = reinforcement["Duration"] as? Double  else { DopeLog.error("Missing parameter", visual: true); break }
                    guard let translation = reinforcement["Translation"] as? Int  else { DopeLog.error("Missing parameter", visual: true); break }
                    guard let hapticFeedback = reinforcement["HapticFeedback"] as? Bool  else { DopeLog.error("Missing parameter", visual: true); break }
                    guard let systemSound = reinforcement["SystemSound"] as? UInt32  else { DopeLog.error("Missing parameter", visual: true); break }
                    for (view, _) in viewAndLocation {
                        view.showShimmy(count: count, duration: duration, translation: translation, hapticFeedback: hapticFeedback, systemSound: systemSound, completion: completion)
                    }
                    return
                    
                case "Vibrate":
                    guard let vibrateDuration = reinforcement["VibrateDuration"] as? Double  else { DopeLog.error("Missing parameter", visual: true); break }
                    guard let vibrateCount = reinforcement["VibrateCount"] as? Int  else { DopeLog.error("Missing parameter", visual: true); break }
                    guard let vibrateTranslation = reinforcement["VibrateTranslation"] as? Int  else { DopeLog.error("Missing parameter", visual: true); break }
                    guard let vibrateSpeed = reinforcement["VibrateSpeed"] as? Float  else { DopeLog.error("Missing parameter", visual: true); break }
                    guard let scale = reinforcement["Scale"] as? CGFloat  else { DopeLog.error("Missing parameter", visual: true); break }
                    guard let scaleDuration = reinforcement["ScaleDuration"] as? Double  else { DopeLog.error("Missing parameter", visual: true); break }
                    guard let scaleCount = reinforcement["ScaleCount"] as? Float  else { DopeLog.error("Missing parameter", visual: true); break }
                    guard let scaleVelocity = reinforcement["ScaleVelocity"] as? CGFloat  else { DopeLog.error("Missing parameter", visual: true); break }
                    guard let scaleDamping = reinforcement["ScaleDamping"] as? CGFloat  else { DopeLog.error("Missing parameter", visual: true); break }
                    guard let hapticFeedback = reinforcement["HapticFeedback"] as? Bool  else { DopeLog.error("Missing parameter", visual: true); break }
                    guard let systemSound = reinforcement["SystemSound"] as? UInt32  else { DopeLog.error("Missing parameter", visual: true); break }
                    for (view, _) in viewAndLocation {
                        view.showVibrate(vibrateCount: vibrateCount, vibrateDuration: vibrateDuration, vibrateTranslation: vibrateTranslation, vibrateSpeed: vibrateSpeed, scale: scale, scaleCount: scaleCount, scaleDuration: scaleDuration, scaleVelocity: scaleVelocity, scaleDamping: scaleDamping, hapticFeedback: hapticFeedback, systemSound: systemSound, completion: completion)
                    }
                    return
                    
                default:
                    // TODO: implement delegate callback for dev defined reinforcements
                    DopeLog.error("Unknown reinforcement type:\(String(describing: reinforcement))", visual: true)
                    return
                }
            }
        }
    }
    
    fileprivate static func reinforcementViews(senderInstance: AnyObject?, targetInstance: NSObject, options: [String: Any]) -> [(UIView, CGPoint)]? {
        guard let viewOption = options["ViewOption"] as? String else { DopeLog.error("Missing parameter", visual: true); return nil }
        guard let viewCustom = options["ViewCustom"] as? String else { DopeLog.error("Missing parameter", visual: true); return nil }
        guard let viewMarginX = options["ViewMarginX"] as? CGFloat else { DopeLog.error("Missing parameter", visual: true); return nil }
        guard let viewMarginY = options["ViewMarginY"] as? CGFloat else { DopeLog.error("Missing parameter", visual: true); return nil }
        
        let viewsAndLocations: [(UIView, CGPoint)]?
        
        switch viewOption {
        case "fixed":
            let view = UIWindow.topWindow!
            viewsAndLocations = [(view, view.pointWithMargins(x: viewMarginX, y: viewMarginY))]
            
        case "touch":
            viewsAndLocations = [(UIWindow.topWindow!, UIWindow.lastTouchPoint.withMargins(marginX: viewMarginX, marginY: viewMarginY))]
            
        case "custom":
            var parts = viewCustom.components(separatedBy: "-")
            if parts.count > 0 {
                let vcClass = parts[0]
                var parent: NSObject
                if vcClass == "self" {
                    parent = targetInstance
                } else if
                    let keyWindow = UIApplication.shared.keyWindow,
                    let vc = keyWindow.getViewControllersWithClassname(classname: vcClass).first {
                    parent = vc
                } else {
                    DopeLog.error("Could not find CustomView <\(viewCustom)>", visual: true)
                    return nil
                }
                
                parts.removeFirst()
                for childName in parts {
                    if parent.responds(to: NSSelectorFromString(childName)),
                        let obj = parent.value(forKey: childName) as? NSObject {
                        parent = obj
                    }
                }
                
                if let view = parent as? UIView {
                    viewsAndLocations = [(view, view.pointWithMargins(x: viewMarginX, y: viewMarginY))]
                } else {
                    DopeLog.error("Could not find CustomView <\(viewCustom)>", visual: true)
                    return nil
                }
                
            } else if viewCustom == "self", let view = targetInstance as? UIView {
                viewsAndLocations = [(view, view.pointWithMargins(x: viewMarginX, y: viewMarginY))]
            } else {
                viewsAndLocations = UIView.find(viewCustom, { (view) -> CGPoint in
                    return view.pointWithMargins(x: viewMarginX, y: viewMarginY)
                })
                if viewsAndLocations?.count == 0 {
                    DopeLog.error("Could not find CustomView <\(viewCustom)>", visual: true)
                    return nil
                }
            }
            
        case "sender":
            if let senderInstance = senderInstance {
                if let view = senderInstance as? UIView {
                    viewsAndLocations = [(view, view.pointWithMargins(x: viewMarginX, y: viewMarginY))]
                } else if senderInstance.responds(to: NSSelectorFromString("view")),
                    let view = senderInstance.value(forKey: "view") as? UIView {
                    viewsAndLocations = [(view, view.pointWithMargins(x: viewMarginX, y: viewMarginY))]
                } else if senderInstance.responds(to: NSSelectorFromString("imageView")),
                    let view = senderInstance.value(forKey: "imageView") as? UIImageView {
                    viewsAndLocations = [(view, view.pointWithMargins(x: viewMarginX, y: viewMarginY))]
                } else {
                    DopeLog.error("Could not find sender view for \(type(of: senderInstance))", visual: true)
                    return nil
                }
            } else {
                DopeLog.error("No sender object", visual: true)
                return nil
            }
            
        case "target":
            if let viewController = targetInstance as? UIViewController,
                let view = viewController.view {
                viewsAndLocations = [(view, view.pointWithMargins(x: viewMarginX, y: viewMarginY))]
            } else if let view = targetInstance as? UIView {
                viewsAndLocations = [(view, view.pointWithMargins(x: viewMarginX, y: viewMarginY))]
            } else {
                DopeLog.error("Could not find viewController view", visual: true)
                return nil
            }
            
        case "superview":
            if let vc = targetInstance as? UIViewController,
                let parentVC = vc.presentingViewController,
                let view = parentVC.view {
                viewsAndLocations = [(view, view.pointWithMargins(x: viewMarginX, y: viewMarginY))]
            } else if let view = targetInstance as? UIView,
                let superview = view.superview {
                viewsAndLocations = [(superview, superview.pointWithMargins(x: viewMarginX, y: viewMarginY))]
            } else {
                DopeLog.error("Could not find superview", visual: true)
                return nil
            }
            
        default:
            DopeLog.error("Unsupported ViewOption <\(viewOption)> for ApplicationEvent", visual: true)
            return nil
        }
        
        return viewsAndLocations
    }
}
