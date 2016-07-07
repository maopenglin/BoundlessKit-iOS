//
//  ViewController.swift
//  DopamineKit
//
//  Created by Akash Desai on 07/06/2016.
//  Copyright (c) 2016 Akash Desai. All rights reserved.
//

import UIKit
import DopamineKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        loadBasicUI()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    /**
    Create a simple view with
        - 2 buttons 
            > button1:Test()
            > button2:Reinforce()
        - 1 label that displays the result
    */
    
    var button1:UIButton = UIButton()
    var button2:UIButton = UIButton()
    var responseLabel:UILabel = UILabel()
    
    func loadBasicUI(){
        let viewSize = self.view.frame.size
        let viewCenter = self.view.center
        
        // Dopamine icon
        let frameworkBundle = NSBundle(identifier: "com.DopamineLabs.DopamineKit")
        let dopamineIcon = UIImage(named: "Dopamine", inBundle: frameworkBundle, compatibleWithTraitCollection: nil)
        let imageView = UIImageView(image: dopamineIcon)
        imageView.center = CGPointMake(viewSize.width/2, 100)
        self.view.addSubview(imageView)
        
        // Response label
        responseLabel = UILabel.init(frame: CGRectMake(0, 150, viewSize.width, 50))
        responseLabel.text = "Click a button below!"
        responseLabel.textAlignment = NSTextAlignment.Center
        self.view.addSubview(responseLabel)
        
        // Reinforced action button
        button1 = UIButton.init(frame: CGRectMake(0, 0, viewSize.width/3, viewSize.width/6+10))
        button1.center = CGPointMake(viewSize.width/4, viewCenter.y)
        button1.layer.cornerRadius = 5
        button1.setTitle("Test Reinforce Call", forState: UIControlState.Normal)
        button1.titleLabel?.lineBreakMode = NSLineBreakMode.ByWordWrapping
        button1.titleLabel?.textAlignment = NSTextAlignment.Center
        button1.backgroundColor = UIColor.init(red: 51/255.0, green: 153/255.0, blue: 51/255.0, alpha: 1.0)
        button1.addTarget(self, action: #selector(ViewController.someActionToReinforce), forControlEvents: UIControlEvents.TouchUpInside)
        self.view.addSubview(button1)
        
        // Tracked action button
        button2 = UIButton.init(frame: CGRectMake(0, 0, viewSize.width/3, viewSize.width/6+10))
        button2.center = CGPointMake(viewSize.width/4*3, viewCenter.y)
        button2.layer.cornerRadius = 5
        button2.setTitle("Test Track Call", forState: UIControlState.Normal)
        button2.titleLabel?.lineBreakMode = NSLineBreakMode.ByWordWrapping
        button2.titleLabel?.textAlignment = NSTextAlignment.Center
        button2.backgroundColor = UIColor.init(red: 204/255.0, green: 51/255.0, blue: 51/255.0, alpha: 1.0)
        button2.addTarget(self, action: #selector(ViewController.someActionToTrack), forControlEvents: UIControlEvents.TouchUpInside)
        self.view.addSubview(button2)
        
        
    }
    
    
    // Callback for button1
    func someActionToReinforce(){
        
        // Reinforce the action to make it sticky!!
        
        DopamineKit.reinforce("action1", callback: {response in
            // So we don't run on the main thread
            dispatch_async(dispatch_get_main_queue(), {
                
                // Update UI to display reinforcement decision on screen for learning purposes
                self.responseLabel.text = response
                self.flashView(self.responseLabel)
                
                
                // Try out CandyBar as a form of reinforcement!
                var reinforcerType:Candy
                var title:String?
                var subtitle:String?
                var backgroundColor:UIColor = UIColor.blueColor()
                var visibilityDuration:NSTimeInterval = 1.75
                
                // Set up a couple of different responses to keep your users surprised
                switch(response){
                case "medalStar":
                    reinforcerType = Candy.MedalStar
                    title = "You should drop an album soon"
                    subtitle = "Cuz you're on 🔥"
                    break
                case "stars":
                    reinforcerType = Candy.Stars
                    title = "Great workout 💯"
                    subtitle = "It's not called sweating, it's called glisenting"
                    backgroundColor = UIColor.orangeColor()
                    break
                case "thumbsUp":
                    reinforcerType = Candy.ThumbsUp
                    title = "Awesome run!"
                    subtitle = "Either you run the day,\nOr the day runs you."
                    visibilityDuration = 2.5
                    break
                default:
                    return
                }
                
                // Woo hoo! Treat yoself
                let candyBar = CandyBar.init(title: title, subtitle: subtitle, icon: reinforcerType, backgroundColor: backgroundColor)
                candyBar.position = .Bottom
                // if `nil` or no duration is provided, the CandyBar will go away when the user clicks on it
                candyBar.show(self.view, duration: visibilityDuration)
                
                
            })
        })
    }
    
    
    // Callback for button2
    func someActionToTrack(){
        // Tracking call is sent asynchronously
        DopamineKit.track("someAction", metaData: ["key":"value"], callback: {status in
            dispatch_async(dispatch_get_main_queue(), {
                self.responseLabel.text = status
                self.flashView(self.responseLabel)
            })
        })
    }
    
    
    // Flash the text so if the same value comes, it's visible
    func flashView(elm:UIView){
        elm.alpha = 0.0
        UIView.animateWithDuration(0.75, delay: 0.0, options: [.CurveEaseInOut, .AllowUserInteraction], animations: {() -> Void in
            elm.alpha = 1.0
            }, completion: nil)
    }
    
    override func supportedInterfaceOrientations() -> UIInterfaceOrientationMask {
        return UIInterfaceOrientationMask.Portrait
    }

}

