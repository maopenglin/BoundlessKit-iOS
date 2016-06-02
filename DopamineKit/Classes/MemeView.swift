//
//  MemeView.swift
//  DopamineKit
//
//  Created by Akash Desai on 5/23/16.
//  Copyright © 2016 DopamineLabs. All rights reserved.
//


/* Example of use from a UIViewController
 /* Using Meme Generator
 // Create reinforcement using a Meme
 var reinforcerType:MemeType
 var topText:String?
 var bottomText:String?
 
 switch(response!){
 case "awesomeRewardOne":
 reinforcerType = .SuccessKid
 topText = "Forgot headphones were in jeans pocket in the wash"
 bottomText = "Still work"
 break
 case "encouragingRewardTwo":
 reinforcerType = .AncientAliens
 bottomText = "Aliens"
 break
 case "delightfulRewardThree":
 reinforcerType = .SkepticalThirdWorldKid
 topText = "So you're saying if more people liked this on Facebook"
 bottomText = "Someone will save me?"
 break
 default:
 // Your original app response function once a user has done the action goes here.
 // Note: You should also add your original app response function as a callback to the DopamineKit ReinforcementModalPresenter by inheriting from ReinforcementModalPresenterDelegate
 return
 }
 
 
 // Create meme and put into view controller
 let meme = MemeView(type: reinforcerType, frame: CGRectMake(self.view.frame.midX-150, self.view.frame.midY-150, 300, 300), topText: topText, bottomText: bottomText)
 let vc = ReinforcementModalPresenter(view:meme)
 vc.view = meme
 // Add dismiss actions
 meme.addGestureRecognizer(UITapGestureRecognizer(target: vc, action: #selector(ReinforcementModalPresenter.dismissSelf)))
 meme.addGestureRecognizer(UISwipeGestureRecognizer(target: vc, action: #selector(ReinforcementModalPresenter.dismissSelf)))
 
 vc.delegate = self
 
 */
 
 */


import UIKit

public enum MemeType{
    case Other, SuccessKid, AncientAliens, SkepticalThirdWorldKid
 
    private var imageAssetName:String?{
        switch self {
        case .SuccessKid: return "Success Kid-Blank"
        case .AncientAliens: return "Ancient Aliens-Blank"
        case .SkepticalThirdWorldKid: return "Skeptical Third World Kid-Blank"
        default: return nil
        }
    }
}

public class MemeView: UIView {
    public let type:MemeType
 
    public var image: UIImage? {
        didSet{
            imageView.image = image
            imageView.center = self.center
        }
    }
    public let imageView: UIImageView = UIImageView()
    
    public var size: CGSize = CGSizeZero{
        didSet{
            self.imageView.frame.size = size
            self.topLabel.frame = MemeView.alignToTop(topLabel, ofFrame: imageView.frame)
            self.bottomLabel.frame = MemeView.alignToBottom(bottomLabel, ofFrame: imageView.frame)
        }
    }
    
    public let topLabel = UILabel()
    public var topString = NSAttributedString() {
        didSet{
            topLabel.attributedText = topString
            self.topLabel.frame = MemeView.alignToTop(topLabel, ofFrame: imageView.frame)
        }
    }
    
    public let bottomLabel = UILabel()
    public var bottomString = NSAttributedString() {
        didSet{
            bottomLabel.attributedText = bottomString
            self.bottomLabel.frame = MemeView.alignToBottom(bottomLabel, ofFrame: imageView.frame)
        }
    }
    
    private var stringAttributes = [
        NSStrokeColorAttributeName: UIColor.blackColor(),
        NSForegroundColorAttributeName: UIColor.whiteColor(),
        NSStrokeWidthAttributeName: -4.0,
        // workable fonts: Optima-Bold, Verdana-Bold, AvenirNext-Heavy, GillSans-Bold, Helvetica-Bold, HoeflerText-Black,
        NSFontAttributeName: UIFont(name: "GillSans-Bold", size:20)!,
    ]
    public func defaultStringAttributes() -> [String : NSObject]{
        return stringAttributes
    }
    
    
    
    public required init(type: MemeType!, frame:CGRect, topText:String?=nil, bottomText:String?=nil,  otherImage:UIImage?=nil, didTapBlock:(()-> ())?=nil){
        
//        self.didTapBlock = didTapBlock
        self.type = type
        
        // Initialize
        super.init(frame: frame)
        
        
        // Retrieve image
        let memeImage:UIImage
        if( type == MemeType.Other && !(otherImage==nil) ){
            memeImage = otherImage!
        } else{
            let frameworkBundle = NSBundle(identifier: "com.DopamineLabs.DopamineKit")
            memeImage = UIImage(named: type.imageAssetName!, inBundle: frameworkBundle, compatibleWithTraitCollection: nil)!
        }
        
        // Set subviews
        setupSubviews(memeImage, topText: topText, bottomText: bottomText)
        
        
    }
    
    private func setupSubviews(memeImage:UIImage?=nil, topText:String?=nil, bottomText:String?=nil){
        
        // Background image
        self.image = (memeImage != nil ? memeImage : self.image)
        self.imageView.image = self.image
        self.imageView.frame = self.frame
        self.imageView.center = self.center
        self.addSubview(self.imageView)
        
        // Top text
        if topText != nil {
            topString = NSAttributedString(string: topText!, attributes: stringAttributes)
            topLabel.attributedText = topString
            topLabel.textAlignment = NSTextAlignment.Center
            topLabel.numberOfLines = 0
            topLabel.adjustsFontSizeToFitWidth = true
            topLabel.sizeToFit()
            topLabel.frame = MemeView.alignToTop(topLabel, ofFrame: imageView.frame)
            self.addSubview(topLabel)
        }
        
        // Bottom text
        if bottomText != nil {
            bottomString = NSAttributedString(string: bottomText!, attributes: stringAttributes)
            bottomLabel.attributedText = bottomString
            bottomLabel.textAlignment = NSTextAlignment.Center
            bottomLabel.numberOfLines = 0
            bottomLabel.adjustsFontSizeToFitWidth = true
            bottomLabel.frame = MemeView.alignToBottom(bottomLabel, ofFrame: imageView.frame)
            self.addSubview(bottomLabel)
        }

    }
    
    private static func resizeImage(image:UIImage, toSize:CGSize) -> UIImage{
        let scale = UIScreen.mainScreen().scale
        UIGraphicsBeginImageContextWithOptions(toSize, false, scale)
        image.drawInRect(CGRectMake(0, 0, toSize.width, toSize.height))
        let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return resizedImage
    }
    
    private static func alignToTop(view:UIView, ofFrame:CGRect) -> CGRect{
        view.sizeToFit()
        return CGRectMake(ofFrame.origin.x,
                          ofFrame.origin.y,
                          ofFrame.width,
                          view.frame.height)
    }
    
    private static func alignToBottom(view:UIView, ofFrame:CGRect) -> CGRect{
        view.sizeToFit()
        return CGRectMake(ofFrame.origin.x,
                          ofFrame.origin.y+ofFrame.height-view.frame.height,
                          ofFrame.width,
                          view.frame.height)
    }
    
    public required init?(coder aDecoder: NSCoder) {
        self.type = .Other
        super.init(coder: aDecoder)
        setupSubviews()
    }

}
