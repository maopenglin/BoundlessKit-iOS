//
//  CandyIcon.swift
//  Pods
//
//  Created by Akash Desai on 7/16/16.
//
//

import UIKit

/// Candy is an icon that can appear on a CandyBar.
/// Look at `DopamineKit/Resources/CandyIcons.xcassets` to see what each icon looks like.
///
@objc public enum CandyIcon : Int{
    case none = 0, certificate, crown, crown2, medalStar, ribbonStar, stars, stopwatch, thumbsUp, trophyHand, trophyStar, wreathStar
    
    internal var filename:String{
        switch self{
        case .certificate: return "certificate"
        case .crown: return "crown"
        case .crown2: return "crown2"
        case .medalStar: return "medalStar"
        case .ribbonStar: return "ribbonStar"
        case .stars: return "stars"
        case .stopwatch: return "stopwatchOne"
        case .thumbsUp: return "thumbsUp"
        case .trophyHand: return "trophyHand"
        case .trophyStar: return "trophyStar"
        case .wreathStar: return "wreathStar"
        default: return ""
        }
    }
    
    internal var image:UIImage?{
        return UIImage(named: filename, in:Bundle.main, compatibleWith: nil)
    }
}
