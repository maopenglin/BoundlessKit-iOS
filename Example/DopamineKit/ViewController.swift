//
//  ViewController.swift
//  DopamineKit
//
//  Created by Akash Desai on 07/13/2016.
//  Copyright (c) 2016 Akash Desai. All rights reserved.
//

import UIKit
import DopamineKit
import CoreLocation

class ViewController: UIViewController {
    
    @objc var someCounter: Float = 0
    
    @objc func action1Performed(){
        // Reinforce the action to make it sticky!!
        DopamineKit.reinforce("a1", metaData: ["key":"value"], completion: {
            reinforcement in
                // Update UI to display reinforcement decision on screen for learning purposes
                self.responseLabel.text = reinforcement
                self.flash(self.responseLabel)
            
                // Now you should use `response` to call a reward function paired on the Dopamine Developer Dashboard
            
            
                // Try out CandyBar as a form of reinforcement!
                // The functions paired here are medaltStar, stars, and thumbsUp
                var reinforcerType:CandyIcon
                var title:String?
                var subtitle:String?
                var backgroundColor:UIColor = UIColor.blue
                var visibilityDuration:TimeInterval = 1.75
            
                // Set up a couple of different responses to keep your users surprised
                switch(reinforcement){
                case "medalStar":
                    reinforcerType = CandyIcon.medalStar
                    title = "You should drop an album soon"
                    subtitle = "Cuz you're on 🔥"
                    break
                case "stars":
                    reinforcerType = CandyIcon.stars
                    title = "Great workout 💯"
                    subtitle = "It's not called sweating, it's called glisenting"
                    backgroundColor = UIColor.orange
                    break
                case "thumbsUp":
                    reinforcerType = CandyIcon.thumbsUp
                    title = "Awesome run!"
                    subtitle = "Either you run the day,\nOr the day runs you."
                    backgroundColor = UIColor.from(rgb:"#ff0000")
                    visibilityDuration = 2.5
                    break
                default:
                    return
                }
            
                // Woo hoo! Treat yoself
            let candybar = CandyBar(title: title, subtitle: subtitle, image: reinforcerType.image, backgroundColor: backgroundColor)
                // if `nil` or no duration is provided, the CandyBar will go away when the user taps it or `candybar.dismiss()` is used
            candybar.show(duration: visibilityDuration)
            
        })
    }
    
    @objc func action2Performed(){
////        // Tracking call is sent asynchronously
//////        DopamineKit.track("action2", metaData: ["key":"value", "calories":9000])
//        locationManager.delegate = self
//        locationManager.requestAlwaysAuthorization()
        

        DopamineKit.track("action2peformed")
//        DopamineKit.reinforce("a2") { reinforcement in
//            // Update UI to display reinforcement decision on screen for learning purposes
//            self.responseLabel.text = reinforcement
//            self.flash(self.responseLabel)
//        }
//        view.showConfetti()
//        let view = UIView(frame: UIScreen.main.bounds)
        
//        DispatchQueue.main.async {
////            DLUIManager.main.show(false)
//            DLWindow.shared.view.showConfetti {
//                print("done")
////                DLUIManager.main.hide()
//            }
//        }
    }
    
    var locationManager = CLLocationManager()
    
    
    ///////////////////////////////////////
    //
    //  UI Setup
    //
    ///////////////////////////////////////
    
    @objc var responseLabel:UILabel!
    @objc var action1Button:UIButton!
    @objc var trackedActionButton:UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        loadBasicUI()
        
//        DispatchQueue.concurrentPerform(iterations: 100) { count in
//            DopamineKit.track("testingActionConcurrency", metaData: ["time": NSNumber(value: Date().timeIntervalSince1970*1000)])
//        }
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    @objc func loadBasicUI(){
        let viewSize = self.view.frame.size
        let viewCenter = self.view.center
        
        // Dopamine icon up top
        let dopamineIcon = UIImage(named:"DopamineLogo")
        
        let imageView = UIImageView(image: dopamineIcon)
        imageView.center = CGPoint(x: viewSize.width/2, y: 100)
        self.view.addSubview(imageView)
        
        // Response label below dopamine icon
        responseLabel = UILabel.init(frame: CGRect(x: 0, y: 150, width: viewSize.width, height: 50))
        responseLabel.text = "Click a button below!"
        responseLabel.textAlignment = NSTextAlignment.center
        self.view.addSubview(responseLabel)
        
        // Button to represent some user action to Reinforce
        action1Button = UIButton.init(frame: CGRect(x: 0, y: 0, width: viewSize.width/3, height: viewSize.width/6+10))
        action1Button.center = CGPoint(x: viewSize.width/4, y: viewCenter.y)
        action1Button.layer.cornerRadius = 5
        action1Button.setTitle("Reinforce a user action", for: UIControlState())
        action1Button.titleLabel?.lineBreakMode = NSLineBreakMode.byWordWrapping
        action1Button.titleLabel?.textAlignment = NSTextAlignment.center
        action1Button.backgroundColor = UIColor.init(red: 51/255.0, green: 153/255.0, blue: 51/255.0, alpha: 1.0)
        action1Button.addTarget(self, action: #selector(ViewController.action1Performed), for: UIControlEvents.touchUpInside)
        self.view.addSubview(action1Button)
        
        // Button to represent some user action to Track
        trackedActionButton = UIButton.init(frame: CGRect(x: 0, y: 0, width: viewSize.width/3, height: viewSize.width/6+10))
        trackedActionButton.center = CGPoint(x: viewSize.width/4*3, y: viewCenter.y)
        trackedActionButton.layer.cornerRadius = 5
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

extension ViewController : CLLocationManagerDelegate {
    
}
