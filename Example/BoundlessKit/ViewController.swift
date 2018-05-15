//
//  ViewController.swift
//  BoundlessKit
//
//  Created by Akash Desai on 07/13/2016.
//  Copyright (c) 2016 Akash Desai. All rights reserved.
//

import UIKit
import BoundlessKit

class ViewController: UIViewController {
    
    @objc func action1Performed(button: UIButton){
        print("Action 1 performed")
        
    }
    
    @objc func action2Performed(sender: UIButton){
        print("Action 2 performed")
        BoundlessKit.track(actionID: "pressed track")
//        BoundlessKit.reinforce(actionID: <#T##String#>, completion: <#T##(String) -> Void#>)
        
//        BoundlessKit.standard.setCustomUserID("bob")
    }
    
    
    ///////////////////////////////////////
    //
    //  UI Setup
    //
    ///////////////////////////////////////
    
    @objc var responseLabel:UILabel!
    @objc var reinforcedActionButton:UIButton!
    @objc var trackedActionButton:UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        loadBasicUI()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        print("In viewcontroller viewdidappear")
    }
    
    @objc func loadBasicUI(){
        let viewSize = self.view.frame.size
        let viewCenter = self.view.center
        
        // Boundless icon up top
        let boundlessIcon = UIImage(named:"BoundlessLogo")
        
        let imageView = UIImageView(image: boundlessIcon)
        imageView.center = CGPoint(x: viewSize.width/2, y: 100)
        self.view.addSubview(imageView)
        
        // Response label below boundless icon
        responseLabel = UILabel.init(frame: CGRect(x: 0, y: 150, width: viewSize.width, height: 50))
        responseLabel.text = "Click a button below!"
        responseLabel.textAlignment = NSTextAlignment.center
        self.view.addSubview(responseLabel)
        
        // Button to represent some user action to Reinforce
        reinforcedActionButton = UIButton.init(frame: CGRect(x: 0, y: 0, width: viewSize.width/3, height: viewSize.width/6+10))
        reinforcedActionButton.center = CGPoint(x: viewSize.width/4, y: viewCenter.y)
        reinforcedActionButton.layer.cornerRadius = 5
//        reinforcedActionButton.clipsToBounds = true
        reinforcedActionButton.showsTouchWhenHighlighted = true
        reinforcedActionButton.setTitle("Reinforce a user action", for: UIControlState())
        reinforcedActionButton.titleLabel?.lineBreakMode = NSLineBreakMode.byWordWrapping
        reinforcedActionButton.titleLabel?.textAlignment = NSTextAlignment.center
        reinforcedActionButton.backgroundColor = UIColor.init(red: 51/255.0, green: 153/255.0, blue: 51/255.0, alpha: 1.0)
        reinforcedActionButton.addTarget(self, action: #selector(ViewController.action1Performed(button:)), for: UIControlEvents.touchUpInside)
        self.view.addSubview(reinforcedActionButton)
        
        // Button to represent some user action to Track
        trackedActionButton = UIButton.init(frame: CGRect(x: 0, y: 0, width: viewSize.width/3, height: viewSize.width/6+10))
        trackedActionButton.center = CGPoint(x: viewSize.width/4*3, y: viewCenter.y)
        trackedActionButton.layer.cornerRadius = 5
//        trackedActionButton.clipsToBounds = true
        trackedActionButton.showsTouchWhenHighlighted = true
        trackedActionButton.setTitle("Track a user action", for: UIControlState())
        trackedActionButton.titleLabel?.lineBreakMode = NSLineBreakMode.byWordWrapping
        trackedActionButton.titleLabel?.textAlignment = NSTextAlignment.center
        trackedActionButton.backgroundColor = UIColor.init(red: 204/255.0, green: 51/255.0, blue: 51/255.0, alpha: 1.0)
        trackedActionButton.addTarget(self, action: #selector(ViewController.action2Performed), for: UIControlEvents.touchUpInside)
        self.view.addSubview(trackedActionButton)
    }
    
    @objc func flash(_ elm:UIView){
        elm.alpha = 0.0
        UIView.animate(withDuration: 0.75, delay: 0.0, options: .allowUserInteraction, animations: {() -> Void in
            elm.alpha = 1.0
        }, completion: nil)
    }
    
    override var supportedInterfaceOrientations : UIInterfaceOrientationMask {
        return UIInterfaceOrientationMask.portrait
    }
    
}
