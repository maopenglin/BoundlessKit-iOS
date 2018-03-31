//
//  Reward.swift
//  BoundlessKit_Example
//
//  Created by Akash Desai on 3/15/18.
//  Copyright © 2018 CocoaPods. All rights reserved.
//

import Foundation
import BoundlessKit

enum Reward : String {
    case shimmy, pulse, vibrate, rotate, glow, sheen, emojisplosion, confetti, popup
    static let cases:[Reward] = [.shimmy, .pulse, .vibrate, .rotate, .glow, .sheen, .emojisplosion, .confetti, .popup]
    
    func test(viewController: UIViewController, view: UIView) {
        let completion = {
            print("Completed showing reward type:\(self.rawValue)")
        }
        switch self {
        case .shimmy:
            view.showShimmy(completion: completion)
        case .pulse:
            view.showPulse(completion: completion)
        case .vibrate:
            view.showVibrate(hapticFeedback: true, systemSound: 1009, completion: completion)
        case .rotate:
            view.rotate360Degrees(completion: completion)
        case .glow:
            view.showGlow(completion: completion)
        case .sheen:
            view.clipsToBounds = true
            view.showSheen(completion: completion)
        case .emojisplosion:
            view.superview!.showEmojiSplosion(at: view.center, completion: completion)
        case .confetti:
            viewController.view.showConfetti(completion: completion)
        case .popup:
            viewController.view.showPopup(completion: completion)
        }
    }
}
