//
//  Candy.swift
//  DopamineKit
//
//  Created by Akash Desai on 6/2/16.
//  Copyright © 2016 DopamineLabs. All rights reserved.
//

/// Candy is an enumeration of icons that can appear on a CandyBar. Visit UseDopamine.com to see them all visually displayed
public enum Candy{
    case None, Certificate, Crown, Crown2, MedalStar, RibbonStar, Stars, Stopwatch, ThumbsUp, TrophyHand, TrophyStar, WreathStar
    
    private var DopeAssetName:String?{
        switch self{
        case .None: return nil
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
        }
    }
}

public class CandyBar: Banner {
    
    /// A CandyBar with the provided `title`, `subtitle`, and an optional `image`, ready to be presented with `show()`.
    ///
    /// - parameter title: The title of the banner. Defaults to nil.
    /// - parameter subtitle: The subtitle of the banner. Defaults to nil.
    /// - parameter image: The image on the left of the banner. Defaults to nil.
    /// - parameter backgroundColor: The color of the banner's background view. Defaults to `UIColor.blackColor()`.
    /// - parameter didTapBlock: An action to be called when the user taps on the banner. Defaults to `nil`.
    public required init(title: String? = nil, subtitle: String? = nil, image: UIImage? = nil, backgroundColor: UIColor = UIColor.blackColor(), didTapBlock: (() -> ())? = nil) {
    
        super.init(title: title, subtitle: subtitle, image: image, backgroundColor: backgroundColor, didTapBlock: didTapBlock)
        
    }
    
    /// A CandyBar with the provided `title`, `subtitle`, and an optional icon, ready to be presented with `show()`.
    ///
    /// - parameter title: The title of the banner. Defaults to nil.
    /// - parameter subtitle: The subtitle of the banner. Defaults to nil.
    /// - parameter icon: The icon on the left of the banner. Defaults to .Stars
    /// - parameter backgroundColor: The color of the banner's background view. Defaults to `UIColor.blackColor()`.
    /// - parameter didTapBlock: An action to be called when the user taps on the banner. Defaults to `nil`.
    public required init(title: String? = nil, subtitle: String? = nil, icon: Candy = .Stars, backgroundColor: UIColor = UIColor.blackColor(), didTapBlock: (() -> ())? = nil) {
        
        var retrievedImage:UIImage? = nil
        let frameworkBundle = NSBundle(identifier: "com.DopamineLabs.DopamineKit")
        retrievedImage = UIImage(named: icon.DopeAssetName!, inBundle: frameworkBundle, compatibleWithTraitCollection: nil)
        
        
        super.init(title: title, subtitle: subtitle, image: retrievedImage, backgroundColor: backgroundColor, didTapBlock: didTapBlock)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
}
