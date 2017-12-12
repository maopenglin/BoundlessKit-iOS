//
//  EventReinforcement.swift
//  DopamineKit
//
//  Created by Akash Desai on 12/1/17.
//

import Foundation

public class EventReinforcement : NSObject {
    
    internal static var lastTouchLocationInUIWindow: CGPoint = CGPoint.zero
    
    internal static func showReinforcement(on viewAndLocation: [(UIView, CGPoint)], of type: String, withParameters reinforcement: [String: Any]) {
        switch type {
            
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
                view.showEmojiSplosion(at: location, content: image, scale: scale, scaleSpeed: scaleSpeed, scaleRange: scaleRange, lifetime: lifetime, lifetimeRange: lifetimeRange, fadeout: fadeout, birthRate: quantity, birthCycles: bursts, velocity: velocity, xAcceleration: xAcceleration, yAcceleration: yAcceleration, angle: angle, range: range, spin: spin, hapticFeedback: hapticFeedback, systemSound: systemSound)
            }
            return
            
        case "Gifsplosion":
            guard let contentString = reinforcement["Content"] as? String  else { DopeLog.error("Missing parameter", visual: true); break }
            guard let xAcceleration = reinforcement["AccelX"] as? CGFloat  else { DopeLog.error("Missing parameter", visual: true); break }
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
            guard let backgroundColorString = reinforcement["BackgroundColor"] as? String  else { DopeLog.error("Missing parameter", visual: true); break }
            guard let backgroundAlpha = reinforcement["BackgroundAlpha"] as? CGFloat  else { DopeLog.error("Missing parameter", visual: true); break }
            guard let hapticFeedback = reinforcement["HapticFeedback"] as? Bool  else { DopeLog.error("Missing parameter", visual: true); break }
            guard let systemSound = reinforcement["SystemSound"] as? UInt32  else { DopeLog.error("Missing parameter", visual: true); break }
            for (view, location) in viewAndLocation {
                view.showGifSplosion(at: location, contentString: contentString, scale: scale, scaleSpeed: scaleSpeed, scaleRange: scaleRange, lifetime: lifetime, lifetimeRange: lifetimeRange, fadeout: fadeout, quantity: quantity, bursts: bursts, velocity: velocity, xAcceleration: xAcceleration, yAcceleration: yAcceleration, angle: angle, range: range, spin: spin, backgroundColor: UIColor.from(rgb: backgroundColorString), backgroundAlpha: backgroundAlpha, hapticFeedback: hapticFeedback, systemSound: systemSound)
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
                view.showGlow(duration: duration, color: color, alpha: alpha, radius: radius, count: count, hapticFeedback: hapticFeedback, systemSound: systemSound)
            }
            return
            
        case "Sheen":
            guard let duration = reinforcement["Duration"] as? Double  else { DopeLog.error("Missing parameter", visual: true); break }
            guard let hapticFeedback = reinforcement["HapticFeedback"] as? Bool  else { DopeLog.error("Missing parameter", visual: true); break }
            guard let systemSound = reinforcement["SystemSound"] as? UInt32  else { DopeLog.error("Missing parameter", visual: true); break }
            for (view, _) in viewAndLocation {
                view.showSheen(duration: duration, hapticFeedback: hapticFeedback, systemSound: systemSound)
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
                view.showPulse(count: count, duration: duration, scale: scale, velocity: velocity, damping: damping, hapticFeedback: hapticFeedback, systemSound: systemSound)
            }
            return
            
        case "Shimmy":
            guard let count = reinforcement["Count"] as? Int  else { DopeLog.error("Missing parameter", visual: true); break }
            guard let duration = reinforcement["Duration"] as? Double  else { DopeLog.error("Missing parameter", visual: true); break }
            guard let translation = reinforcement["Translation"] as? Int  else { DopeLog.error("Missing parameter", visual: true); break }
            guard let hapticFeedback = reinforcement["HapticFeedback"] as? Bool  else { DopeLog.error("Missing parameter", visual: true); break }
            guard let systemSound = reinforcement["SystemSound"] as? UInt32  else { DopeLog.error("Missing parameter", visual: true); break }
            for (view, _) in viewAndLocation {
                view.showShimmy(count: count, duration: duration, translation: translation, hapticFeedback: hapticFeedback, systemSound: systemSound)
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
                view.showVibrate(vibrateCount: vibrateCount, vibrateDuration: vibrateDuration, vibrateTranslation: vibrateTranslation, vibrateSpeed: vibrateSpeed, scale: scale, scaleCount: scaleCount, scaleDuration: scaleDuration, scaleVelocity: scaleVelocity, scaleDamping: scaleDamping, hapticFeedback: hapticFeedback, systemSound: systemSound)
            }
            return
            
        default:
            // TODO: implement delegate callback for dev defined reinforcements
            DopeLog.error("Unknown reinforcement type:\(String(describing: reinforcement))", visual: true)
            return
        }
    }
}
