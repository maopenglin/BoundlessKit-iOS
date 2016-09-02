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
    case None = 0, Certificate, Crown, Crown2, MedalStar, RibbonStar, Stars, Stopwatch, ThumbsUp, TrophyHand, TrophyStar, WreathStar
    
    internal var filename:String{
        switch self{
        case .Certificate: return "certificate"
        case .Crown: return "crown"
        case .Crown2: return "crown2"
        case .MedalStar: return "medalStar"
        case .RibbonStar: return "ribbonStar"
        case .Stars: return "stars"
        case .Stopwatch: return "stopwatchOne"
        case .ThumbsUp: return "thumbsUp"
        case .TrophyHand: return "trophyHand"
        case .TrophyStar: return "trophyStar"
        case .WreathStar: return "wreathStar"
        default: return ""
        }
    }
    
    internal var image:UIImage?{
        return UIImage(named: filename, inBundle:NSBundle.mainBundle(), compatibleWithTraitCollection: nil)
    }
}