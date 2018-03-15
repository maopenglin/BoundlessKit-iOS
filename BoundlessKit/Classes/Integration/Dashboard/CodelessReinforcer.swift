//
//  CodelessReinforcer.swift
//  BoundlessKit
//
//  Created by Akash Desai on 3/6/18.
//

import Foundation

internal class CodelessReinforcer : NSObject {
    
    let actionID: String
    var reinforcements = [String: CodelessReinforcement]()
    
    init(forActionID actionID: String) {
        self.actionID = actionID
    }
    
//    @objc
//    func show(sender: AnyObject?, target: NSObject, selector: Selector) {
//
//    }
    @objc
    func receive(notification: Notification) {
        print("Got notification:\(notification.debugDescription)")
    }
    
}

struct CodelessReinforcement {
    let primitive: String
    let parameters: [String: Any]
    
    init?(from dict: [String: Any]) {
        if let primitive = dict["primitive"] as? String {
            self.primitive = primitive
            self.parameters = dict
        } else {
            return nil
        }
    }
    
    
    fileprivate static func show(reinforcement: [String:Any], senderInstance: AnyObject?, targetInstance: NSObject, completion: @escaping ()->Void = {}) {
        guard let delay = reinforcement["Delay"] as? Double else { BKLog.error("Missing parameter", visual: true); return }
        guard let reinforcementType = reinforcement["primitive"] as? String else { BKLog.error("Missing parameter", visual: true); return }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            if let viewAndLocation = reinforcementViews(senderInstance: senderInstance, targetInstance: targetInstance, options: reinforcement) {
                switch reinforcementType {
                    
                case "Confetti":
                    guard let duration = reinforcement["Duration"] as? Double else { BKLog.error("Missing parameter", visual: true); break }
                    guard let hapticFeedback = reinforcement["HapticFeedback"] as? Bool  else { BKLog.error("Missing parameter", visual: true); break }
                    guard let systemSound = reinforcement["SystemSound"] as? UInt32  else { BKLog.error("Missing parameter", visual: true); break }
                    for (view, _) in viewAndLocation {
                        view.showConfetti(duration: duration, hapticFeedback: hapticFeedback, systemSound: systemSound, completion: completion)
                    }
                    return
                    
                case "Emojisplosion":
                    guard let content = reinforcement["Content"] as? String else { BKLog.error("Missing parameter", visual: true); break }
                    guard let xAcceleration = reinforcement["AccelX"] as? CGFloat else { BKLog.error("Missing parameter", visual: true); break }
                    guard let yAcceleration = reinforcement["AccelY"] as? CGFloat  else { BKLog.error("Missing parameter", visual: true); break }
                    guard let bursts = reinforcement["Bursts"] as? Double  else { BKLog.error("Missing parameter", visual: true); break }
                    guard let angle = reinforcement["EmissionAngle"] as? CGFloat  else { BKLog.error("Missing parameter", visual: true); break }
                    guard let range = reinforcement["EmissionRange"] as? CGFloat  else { BKLog.error("Missing parameter", visual: true); break }
                    guard let fadeout = reinforcement["FadeOut"] as? Float  else { BKLog.error("Missing parameter", visual: true); break }
                    guard let lifetime = reinforcement["Lifetime"] as? Float  else { BKLog.error("Missing parameter", visual: true); break }
                    guard let lifetimeRange = reinforcement["LifetimeRange"] as? Float  else { BKLog.error("Missing parameter", visual: true); break }
                    guard let quantity = reinforcement["Quantity"] as? Float  else { BKLog.error("Missing parameter", visual: true); break }
                    guard let scale = reinforcement["Scale"] as? CGFloat  else { BKLog.error("Missing parameter", visual: true); break }
                    guard let scaleRange = reinforcement["ScaleRange"] as? CGFloat  else { BKLog.error("Missing parameter", visual: true); break }
                    guard let scaleSpeed = reinforcement["ScaleSpeed"] as? CGFloat  else { BKLog.error("Missing parameter", visual: true); break }
                    guard let spin = reinforcement["Spin"] as? CGFloat  else { BKLog.error("Missing parameter", visual: true); break }
                    guard let velocity = reinforcement["Velocity"] as? CGFloat  else { BKLog.error("Missing parameter", visual: true); break }
                    guard let hapticFeedback = reinforcement["HapticFeedback"] as? Bool  else { BKLog.error("Missing parameter", visual: true); break }
                    guard let systemSound = reinforcement["SystemSound"] as? UInt32  else { BKLog.error("Missing parameter", visual: true); break }
                    let image = content.decode().image().cgImage
                    for (view, location) in viewAndLocation {
                        view.showEmojiSplosion(at: location, content: image, scale: scale, scaleSpeed: scaleSpeed, scaleRange: scaleRange, lifetime: lifetime, lifetimeRange: lifetimeRange, fadeout: fadeout, quantity: quantity, bursts: bursts, velocity: velocity, xAcceleration: xAcceleration, yAcceleration: yAcceleration, angle: angle, range: range, spin: spin, hapticFeedback: hapticFeedback, systemSound: systemSound, completion: completion)
                    }
                    return
                    
                case "Glow":
                    guard let duration = reinforcement["Duration"] as? Double  else { BKLog.error("Missing parameter", visual: true); break }
                    guard let colorString = reinforcement["Color"] as? String  else { BKLog.error("Missing parameter", visual: true); break }
                    guard let alpha = reinforcement["Alpha"] as? CGFloat  else { BKLog.error("Missing parameter", visual: true); break }
                    guard let count = reinforcement["Count"] as? Float  else { BKLog.error("Missing parameter", visual: true); break }
                    guard let radius = reinforcement["Radius"] as? CGFloat  else { BKLog.error("Missing parameter", visual: true); break }
                    guard let hapticFeedback = reinforcement["HapticFeedback"] as? Bool  else { BKLog.error("Missing parameter", visual: true); break }
                    guard let systemSound = reinforcement["SystemSound"] as? UInt32  else { BKLog.error("Missing parameter", visual: true); break }
                    let color = UIColor.from(rgb: colorString)
                    for (view, _) in viewAndLocation {
                        view.showGlow(duration: duration, color: color, alpha: alpha, radius: radius, count: count, hapticFeedback: hapticFeedback, systemSound: systemSound, completion: completion)
                    }
                    return
                    
                case "Sheen":
                    guard let duration = reinforcement["Duration"] as? Double  else { BKLog.error("Missing parameter", visual: true); break }
                    guard let hapticFeedback = reinforcement["HapticFeedback"] as? Bool  else { BKLog.error("Missing parameter", visual: true); break }
                    guard let systemSound = reinforcement["SystemSound"] as? UInt32  else { BKLog.error("Missing parameter", visual: true); break }
                    for (view, _) in viewAndLocation {
                        view.showSheen(duration: duration, hapticFeedback: hapticFeedback, systemSound: systemSound, completion: completion)
                    }
                    return
                    
                case "Pulse":
                    guard let count = reinforcement["Count"] as? Float  else { BKLog.error("Missing parameter", visual: true); break }
                    guard let duration = reinforcement["Duration"] as? Double  else { BKLog.error("Missing parameter", visual: true); break }
                    guard let scale = reinforcement["Scale"] as? CGFloat  else { BKLog.error("Missing parameter", visual: true); break }
                    guard let velocity = reinforcement["Velocity"] as? CGFloat  else { BKLog.error("Missing parameter", visual: true); break }
                    guard let damping = reinforcement["Damping"] as? CGFloat  else { BKLog.error("Missing parameter", visual: true); break }
                    guard let hapticFeedback = reinforcement["HapticFeedback"] as? Bool  else { BKLog.error("Missing parameter", visual: true); break }
                    guard let systemSound = reinforcement["SystemSound"] as? UInt32  else { BKLog.error("Missing parameter", visual: true); break }
                    for (view, _) in viewAndLocation {
                        view.showPulse(count: count, duration: duration, scale: scale, velocity: velocity, damping: damping, hapticFeedback: hapticFeedback, systemSound: systemSound, completion: completion)
                    }
                    return
                    
                case "Shimmy":
                    guard let count = reinforcement["Count"] as? Int  else { BKLog.error("Missing parameter", visual: true); break }
                    guard let duration = reinforcement["Duration"] as? Double  else { BKLog.error("Missing parameter", visual: true); break }
                    guard let translation = reinforcement["Translation"] as? Int  else { BKLog.error("Missing parameter", visual: true); break }
                    guard let hapticFeedback = reinforcement["HapticFeedback"] as? Bool  else { BKLog.error("Missing parameter", visual: true); break }
                    guard let systemSound = reinforcement["SystemSound"] as? UInt32  else { BKLog.error("Missing parameter", visual: true); break }
                    for (view, _) in viewAndLocation {
                        view.showShimmy(count: count, duration: duration, translation: translation, hapticFeedback: hapticFeedback, systemSound: systemSound, completion: completion)
                    }
                    return
                    
                case "Vibrate":
                    guard let vibrateDuration = reinforcement["VibrateDuration"] as? Double  else { BKLog.error("Missing parameter", visual: true); break }
                    guard let vibrateCount = reinforcement["VibrateCount"] as? Int  else { BKLog.error("Missing parameter", visual: true); break }
                    guard let vibrateTranslation = reinforcement["VibrateTranslation"] as? Int  else { BKLog.error("Missing parameter", visual: true); break }
                    guard let vibrateSpeed = reinforcement["VibrateSpeed"] as? Float  else { BKLog.error("Missing parameter", visual: true); break }
                    guard let scale = reinforcement["Scale"] as? CGFloat  else { BKLog.error("Missing parameter", visual: true); break }
                    guard let scaleDuration = reinforcement["ScaleDuration"] as? Double  else { BKLog.error("Missing parameter", visual: true); break }
                    guard let scaleCount = reinforcement["ScaleCount"] as? Float  else { BKLog.error("Missing parameter", visual: true); break }
                    guard let scaleVelocity = reinforcement["ScaleVelocity"] as? CGFloat  else { BKLog.error("Missing parameter", visual: true); break }
                    guard let scaleDamping = reinforcement["ScaleDamping"] as? CGFloat  else { BKLog.error("Missing parameter", visual: true); break }
                    guard let hapticFeedback = reinforcement["HapticFeedback"] as? Bool  else { BKLog.error("Missing parameter", visual: true); break }
                    guard let systemSound = reinforcement["SystemSound"] as? UInt32  else { BKLog.error("Missing parameter", visual: true); break }
                    for (view, _) in viewAndLocation {
                        view.showVibrate(vibrateCount: vibrateCount, vibrateDuration: vibrateDuration, vibrateTranslation: vibrateTranslation, vibrateSpeed: vibrateSpeed, scale: scale, scaleCount: scaleCount, scaleDuration: scaleDuration, scaleVelocity: scaleVelocity, scaleDamping: scaleDamping, hapticFeedback: hapticFeedback, systemSound: systemSound, completion: completion)
                    }
                    return
                    
                default:
                    // TODO: implement delegate callback for dev defined reinforcements
                    BKLog.error("Unknown reinforcement type:\(String(describing: reinforcement))", visual: true)
                    return
                }
            }
        }
    }
    
    fileprivate static func reinforcementViews(senderInstance: AnyObject?, targetInstance: NSObject, options: [String: Any]) -> [(UIView, CGPoint)]? {
        guard let viewOption = options["ViewOption"] as? String else { BKLog.error("Missing parameter", visual: true); return nil }
        guard let viewCustom = options["ViewCustom"] as? String else { BKLog.error("Missing parameter", visual: true); return nil }
        guard let viewMarginX = options["ViewMarginX"] as? CGFloat else { BKLog.error("Missing parameter", visual: true); return nil }
        guard let viewMarginY = options["ViewMarginY"] as? CGFloat else { BKLog.error("Missing parameter", visual: true); return nil }
        
        let viewsAndLocations: [(UIView, CGPoint)]?
        
        switch viewOption {
        case "fixed":
            let view = UIWindow.topWindow!
            viewsAndLocations = [(view, view.pointWithMargins(x: viewMarginX, y: viewMarginY))]
            
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
                    BKLog.error("Could not find CustomView <\(viewCustom)>", visual: true)
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
                    BKLog.error("Could not find CustomView <\(viewCustom)>", visual: true)
                    return nil
                }
                
            } else if viewCustom == "self", let view = targetInstance as? UIView {
                viewsAndLocations = [(view, view.pointWithMargins(x: viewMarginX, y: viewMarginY))]
            } else {
                viewsAndLocations = UIView.find(viewCustom, { (view) -> CGPoint in
                    return view.pointWithMargins(x: viewMarginX, y: viewMarginY)
                })
                if viewsAndLocations?.count == 0 {
                    BKLog.error("Could not find CustomView <\(viewCustom)>", visual: true)
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
                    BKLog.error("Could not find sender view for \(type(of: senderInstance))", visual: true)
                    return nil
                }
            } else {
                BKLog.error("No sender object", visual: true)
                return nil
            }
            
        case "target":
            if let viewController = targetInstance as? UIViewController,
                let view = viewController.view {
                viewsAndLocations = [(view, view.pointWithMargins(x: viewMarginX, y: viewMarginY))]
            } else if let view = targetInstance as? UIView {
                viewsAndLocations = [(view, view.pointWithMargins(x: viewMarginX, y: viewMarginY))]
            } else {
                BKLog.error("Could not find viewController view", visual: true)
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
                BKLog.error("Could not find superview", visual: true)
                return nil
            }
            
        default:
            BKLog.error("Unsupported ViewOption <\(viewOption)> for ApplicationEvent", visual: true)
            return nil
        }
        
        return viewsAndLocations
    }
}

