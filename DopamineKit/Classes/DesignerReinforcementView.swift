//
//  DesignerReinforcementView.swift
//  DopamineKit
//
//  Created by Akash Desai on 5/24/16.
//  Copyright © 2016 DopamineLabs. All rights reserved.
//

import UIKit

/// The set of Designer Reinforcement templates in DopamineKit
public enum DesignerReinforcementType{
    case Other, Cake, Beast, NyanCat, Star, Trophy
    
    private var imageAssetName:String?{
        switch self{
        case .Cake: return "Cake"
        case .Beast: return "Beast"
        case .NyanCat: return "Nyan Cat"
        case .Star: return "Star"
        case .Trophy: return "Trophy"
        default: return nil
        }
    }
}

public class DesignerReinforcementView: UIView {
    public let type:DesignerReinforcementType
    
    
    public var image:UIImage?
    public var imageView:UIImageView = UIImageView()
    
    public var primaryLabel:UILabel=UILabel()
    public var primaryText:String=""
    
    public var secondaryLabel:UILabel=UILabel()
    public var secondaryText:String=""
    
    public var closeButton:UIButton=UIButton()
    public var buttonText:String=""
    
    
    /// This function creates a DesignerReinforcementView from a set of DopamineKit templates. The set of templates can be found on usedopamine.com
    /// - parameters:
    ///     - frame: Default `CGRectZero` - the frame to display this view
    ///     - type: the type of reinforcement templates
    ///     - primaryText: Default "" - the title or primary text for the reinforcement
    ///     - secondaryText: Default "" - the subtitle or secondary text for the reinforcement
    ///     - closeText: Default "Close" - the message displayed on the DesignerReinforcementView's `closeButton` if text can be displayed on the template type
    public required init(frame:CGRect=CGRectZero, type: DesignerReinforcementType, primaryText:String="", secondaryText:String="", closeText:String="Close"){
        
        self.type = type
        self.primaryText = primaryText
        self.secondaryText = secondaryText
        self.buttonText = closeText
        
        super.init(frame:frame)
        
        if let imageName = self.type.imageAssetName{
            let frameworkBundle = NSBundle(identifier: "com.DopamineLabs.DopamineKit")
            self.image = UIImage(named: imageName, inBundle: frameworkBundle, compatibleWithTraitCollection: nil)
        }
        
        
        setupSubviews()
        addGestureRecognizers()
        
    }
    
    
    private func setupSubviews(){
        
        self.imageView = UIImageView(image: image)
        
        self.addSubview(imageView)
        self.imageView.center = self.center
        self.sendSubviewToBack(imageView)
        
        // Add custom text and button to specific images
        // Note: Images made from generics are grouped together by fallthrough's
        switch(type){
        case .Star:
            primaryLabel = self.makeLabel(self.primaryText,
                                          centerX: self.center.x,
                                          centerY: self.center.y+80,
                                          height: 160,
                                          width: 184,
                                          maxNumberOfLines: 5)
            closeButton = self.makeButton(centerX: self.center.x + 90,
                                          centerY: self.center.y - 166,
                                          height: 28,
                                          width: 28,
                                          cornerRadius:14)
            
            self.addSubview(closeButton)
            self.addSubview(primaryLabel)
            break
            
        case .Trophy:
            primaryLabel = self.makeLabel(self.primaryText,
                                          centerX: self.center.x,
                                          centerY: self.center.y+40,
                                          height: 66,
                                          width: 180,
                                          maxNumberOfLines: 3)
            self.addSubview(primaryLabel)
            
            
            
            closeButton = self.makeButton(self.buttonText,
                                          textColor: UIColor.whiteColor(),
                                          centerX: self.center.x,
                                          centerY: self.center.y + 101,
                                          height: 33,
                                          width: 108,
                                          cornerRadius: 5)
            self.addSubview(closeButton)
            break
            
            /* These use generic_CenteredCircle as a background */
            
        case .Beast:
            fallthrough
        case .NyanCat:
            fallthrough
        case .Cake:
            primaryLabel = self.makeLabel(self.primaryText,
                                          centerX: self.center.x,
                                          centerY: self.center.y - 135,
                                          height: 50,
                                          width: 165,
                                          maxNumberOfLines: 2)
            self.addSubview(primaryLabel)
            
            
            secondaryLabel = self.makeLabel(self.secondaryText,
                                            centerX: self.center.x,
                                            centerY: self.center.y+110,
                                            height: self.frame.height/2,
                                            width: self.frame.width-30,
                                            maxNumberOfLines: 5)
            self.addSubview(secondaryLabel)
            
            closeButton = self.makeButton(centerX: self.center.x + 93,
                                          centerY: self.center.y - 170,
                                          height: 20,
                                          width: 20,
                                          cornerRadius:10)
            self.addSubview(closeButton)
            
            
            break
            
        default:
            return
            
        }
    }
    
    
    public func dismiss(){
        self.removeFromSuperview()
        self.didDismissBlock?()
    }
    
    /// A block to call when the user taps on the reinforcement.
    public var didTapBlock: (() -> ())?
    
    /// A block to call after the reinforcement has finished dismissing and is off screen.
    public var didDismissBlock: (() -> ())?
    
    /// Whether or not the reinforcement should dismiss itself when the user taps. Defaults to `false`.
    public var dismissesOnTap = false
    
    /// Whether or not the reinforcement should dismiss itself when the user swipes up. Defaults to `true`.
    public var dismissesOnSwipe = true
    
    
    private func addGestureRecognizers() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(self.didTap(_:)))
        addGestureRecognizer(tap)
        let swipe = UISwipeGestureRecognizer(target: self, action: #selector(self.didSwipe(_:)))
        swipe.direction = .Up
        addGestureRecognizer(swipe)
    }
    
    internal func didTap(recognizer: UITapGestureRecognizer) {
        if dismissesOnTap {
            dismiss()
        }
        didTapBlock?()
    }
    
    internal func didSwipe(recognizer: UISwipeGestureRecognizer) {
        if dismissesOnSwipe {
            dismiss()
        }
    }
    
    
    
    
    
    func makeLabel(text:String,
                   textAlignment:NSTextAlignment = NSTextAlignment.Center,
                   textColor:UIColor = UIColor.blackColor(),
                   centerX:CGFloat,
                   centerY:CGFloat,
                   height:CGFloat,
                   width:CGFloat,
                   maxNumberOfLines:Int = 5) ->
        UILabel{
            
            let label = UILabel.init(frame: CGRectMake(0, 0, width, height));
//            label.preferredMaxLayoutWidth = width
            label.center = CGPointMake(centerX, centerY)
            label.numberOfLines = maxNumberOfLines
            label.text = text
            label.textAlignment = textAlignment
            label.textColor = textColor
            
            return label
    }
    
    
    func makeButton(text:String = "",
                    textColor:UIColor = UIColor.blackColor(),
                    backgroundColor:UIColor = UIColor.clearColor(),
                    centerX:CGFloat,
                    centerY:CGFloat,
                    height:CGFloat,
                    width:CGFloat,
                    cornerRadius:CGFloat = 0) ->
        UIButton{
            
            let button = UIButton.init(frame: CGRectMake(0, 0, width, height))
            button.center = CGPointMake(centerX, centerY)
            button.layer.cornerRadius = cornerRadius
            button.backgroundColor = backgroundColor
            button.setTitle(text, forState: UIControlState.Normal)
            button.setTitleColor(textColor, forState: UIControlState.Normal)
            
            return button
    }

    
    
    required public init?(coder aDecoder: NSCoder) {
        self.type = .Other
        super.init(coder: aDecoder)
    }
    
}
