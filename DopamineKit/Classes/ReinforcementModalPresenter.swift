//
//  DopeReinforcementViewController.swift
//  DopamineKit
//
//  Created by Akash Desai on 5/11/16.
//  Copyright © 2016 DopamineLabs. All rights reserved.
//

import UIKit

public protocol ReinforcementModalPresenterDelegate: class {
    
    func didDismissReinforcement(sender:ReinforcementModalPresenter)
    
}

public class ReinforcementModalPresenter: UIViewController {
    
    public weak var delegate:ReinforcementModalPresenterDelegate?
    
    /// Initializes a ReinforcementModalPresenter
    /// - parameters:
    ///     - view : Default `nil` - the view for this UIViewController
    public required init(view:UIView?=nil){
        super.init(nibName: nil, bundle: nil)
        self.modalPresentationStyle = UIModalPresentationStyle.OverCurrentContext
        if let v = view{
            self.view = v
        }
    }
    
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    public override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        if(self.view.subviews.count == 0){
            self.dismissSelf()
        }
    }
    
    /// Calls this `dismissViewControllerAnimated` on the presented view controller itself; UIKit asks the presenting view controller to handle the dismissal itself.
    public func dismissSelf(){
        self.dismissViewControllerAnimated(true, completion: {_ in} )
    }
    
    public override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        self.delegate?.didDismissReinforcement(self)
    }
    
    /// You can use this function to present the view controller. It is a shortcut for the `presentViewController` function
    /// - parameters:
    ///     - owningViewController: the view controller that will present this view
    ///     - animated: Default `false` - Pass `true` to animate the presentation; otherwise, pass false.
    ///     - completion: Pass a function that will be executed once the view is presented and done animating
    public func show(owningViewController: UIViewController!, animated: Bool=true, completion:(() -> Void)?={_ in NSLog("DopamineKit: Reinforcement is displayed!")}){
        owningViewController.presentViewController(self, animated: animated, completion: completion)
        
    }
    
    class func topWindow() -> UIWindow? {
        for window in UIApplication.sharedApplication().windows.reverse() {
            if window.windowLevel == UIWindowLevelNormal && !window.hidden && window.frame != CGRectZero { return window }
        }
        return nil
    }
    
}
