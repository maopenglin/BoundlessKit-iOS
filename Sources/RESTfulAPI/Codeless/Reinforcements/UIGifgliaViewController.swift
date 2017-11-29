//
//  UIGifgliaViewController.swift
//  Pods
//
//  Created by Akash Desai on 10/10/16.
//
//

import Foundation

internal class UIGifgliaViewController: UIViewController {

    var dimDuration = 0.05
    var autoDismissTimeout: Double
    var backgroundColor: UIColor
    var backgroundAlpha: CGFloat
    var splosion: () -> Void

    /// Convenience method to set auto close timeout
    ///
    init(autoDismissTimeout: Double, backgroundColor: UIColor, backgroundAlpha: CGFloat, splosion: @escaping () -> Void) {
        self.autoDismissTimeout = autoDismissTimeout
        self.backgroundColor = backgroundColor
        self.backgroundAlpha = backgroundAlpha
        self.splosion = splosion
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    /// The view controller is required to be displayed over the full screen
    /// for the dimming effect
    ///
    open override var modalPresentationStyle: UIModalPresentationStyle {
        get { return .overFullScreen }
        set { print("modalPresentationStyle needs to be .overFullScreen") }
    }


    /// Loads two views into the gifViewController,
    /// one for the Gif and one for a close button
    ///
    override open func loadView() {
        self.view = UIView(frame: UIScreen.main.bounds)

//        // gif view
//        let gifView = UIGifgliaView()
//        gifView.loadGif(Gifglia.getNextGif().filename)
//        gifView.frame.size = gifView.sizeThatFits(self.view.frame.size)
//
//        let gifX: CGFloat = self.view.frame.width / 2 - gifView.frame.width / 2
//        let gifY: CGFloat = self.view.frame.height / 2 - gifView.frame.height / 2
//        gifView.frame.origin.x = gifX
//        gifView.frame.origin.y = gifY
//
//        gifView.layer.shadowColor = UIColor.black.cgColor
//        gifView.layer.shadowOpacity = 0.6
//        gifView.layer.shadowRadius = 15
//        gifView.layer.shadowOffset = CGSize(width: 15, height: 15)
//        gifView.layer.masksToBounds = false
    }

    /// Modally presents a gif and also
    /// dispatches a task to automatically dismiss itself after `autoDismissTimeout` seconds if `autoDismiss` is true
    ///
    override open func viewDidAppear(_ animated: Bool) {
        showGifView()
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + autoDismissTimeout) {
            self.closeGifView()
        }
    }
    
    override func didMove(toParentViewController parent: UIViewController?) {
        super.didMove(toParentViewController: parent)
        
    }

    /// Presents the gifViewController modally
    ///
    func showGifView() {
//        gifViewController.modalPresentationStyle = .overFullScreen
//        gifViewController.modalTransitionStyle = .coverVertical
        self.dim(.in, alpha: backgroundAlpha, duration: dimDuration)
//        self.present(self.gifViewController, animated: false)
        splosion()
    }

    /// Dismisses both the gifViewController and the UIGifgliaViewController
    ///
    func closeGifView() {
        DispatchQueue.main.async() {
//            self.gifViewController.modalTransitionStyle = .crossDissolve
//            self.dismiss(animated: true, completion: nil)
            self.dim(.out, duration: self.dimDuration)
            self.presentingViewController?.dismiss(animated: true, completion: nil)
        }
    }

}


fileprivate extension UIViewController {

    /// The direction to fade in or out the dimming effect
    ///
    enum Direction { case `in`, out }

    /// Adds a transparent, monochromatic view over for a dimmed effect
    ///
    /// - parameters:
    ///     - direction: Whether to fade the dim in or fade it out.
    ///     - color: The overlaying color. Defaults to black.
    ///     - alpha: The transparency factor. Defaults to 0.
    ///     - speed: The total duration of the animations, measured in seconds. Defaults to 0.
    ///
    func dim(_ direction: Direction, color: UIColor = UIColor.black, alpha: CGFloat = 0.0, duration: Double = 0.0) {

        switch direction {
        case .in:
            // Create and add a dim view
            let dimView = UIView(frame: view.frame)
            dimView.backgroundColor = color
            dimView.alpha = 0.0
            view.addSubview(dimView)

            // Deal with Auto Layout
            dimView.translatesAutoresizingMaskIntoConstraints = false
            view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "|[dimView]|", options: [], metrics: nil, views: ["dimView": dimView]))
            view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|[dimView]|", options: [], metrics: nil, views: ["dimView": dimView]))

            // Animate alpha (the actual "dimming" effect)
            UIView.animate(withDuration: duration, animations: { () -> Void in
                dimView.alpha = alpha
            })

        case .out:
            UIView.animate(withDuration: duration, animations: { () -> Void in
                self.view.subviews.last?.alpha = alpha
                }, completion: { (complete) -> Void in
                    // Remove the dim view
                    self.view.subviews.last?.removeFromSuperview()
            })
        }
    }
}

