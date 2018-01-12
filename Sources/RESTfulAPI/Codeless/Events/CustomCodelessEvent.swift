//
//  CustomCodelessEvent.swift
//  DopamineKit
//
//  Created by Akash Desai on 11/27/17.
//

import Foundation


internal class CustomCodelessEvent : NSObject {
    
    static let appLaunch = CustomCodelessEvent(target: "AppEvent", action: "appLaunch")
    static let appTerminate = CustomCodelessEvent(target: "AppEvent", action: "appTerminate")
    static let appActive = CustomCodelessEvent(target: "AppEvent", action: "appActive")
    static let appInactive = CustomCodelessEvent(target: "AppEvent", action: "appInactive")
    static let appEvents = [appLaunch, appTerminate, appActive, appInactive]
    
    let sender: String = "customEvent"
    let target: String
    let action: String
    
    init(target: String, action: String) {
        self.target = target
        self.action = action
    }
    
    func modify(payload: inout [String: Any]) {
        payload["customEvent"] = [target: action]
        payload["actionID"] = [action]
        payload["senderImage"] = ""
    }
    
}

internal extension CustomCodelessEvent {
    func attemptReinforcement() {
        DopamineVersion.current.codelessReinforcementFor(sender: sender, target: target, selector: action)  { reinforcement in
            guard let delay = reinforcement["Delay"] as? Double else { DopeLog.error("Missing parameter", visual: true); return }
            guard let reinforcementType = reinforcement["primitive"] as? String else { DopeLog.error("Missing parameter", visual: true); return }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                if let viewsAndLocations = self.reinforcementViews(options: reinforcement) {
                    EventReinforcement.showReinforcement(on: viewsAndLocations, of: reinforcementType, withParameters: reinforcement)
                }
            }
            
        }
    }
    
    private func reinforcementViews(options: [String: Any]) -> [(UIView, CGPoint)]? {
        
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
            viewsAndLocations = UIView.find(viewCustom, { (view) -> CGPoint in
                return view.pointWithMargins(x: viewMarginX, y: viewMarginY)
            })
            
            if viewsAndLocations?.count == 0 {
                DopeLog.error("Could not find CustomView <\(viewCustom)>", visual: true)
                return nil
            }
            
        default:
            DopeLog.error("Unsupported ViewOption <\(viewOption)> for ApplicationEvent", visual: true)
            return nil
        }
        
        return viewsAndLocations
    }
}
