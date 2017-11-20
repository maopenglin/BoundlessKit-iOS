////
////  DLWindow.swift
////  DopamineKit
////
////  Created by Akash Desai on 11/19/17.
////
//
//public class DLWindow : UIWindow {
//    
//    @objc
//    public static var shared: DLWindow { get { return DLUIManager.main.window } }
//    
//    public var view: UIView!
//    
//    override init(frame: CGRect) {
//        super.init(frame: frame)
//        view = UIView(frame: UIScreen.main.bounds)
//        addSubview(view)
//        
//        self.backgroundColor = UIColor.clear
//        self.windowLevel = UIWindowLevelAlert + 1
//    }
//    
//    required public init?(coder aDecoder: NSCoder) {
//        super.init(coder: aDecoder)
//    }
//    
//    public override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
//        return false
//    }
//    
//    public override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
//        return nil
//    }
//}
//

internal extension UIWindow {
    class var topWindow: UIWindow? {
        get {
            for window in UIApplication.shared.windows.reversed() {
                if window.windowLevel == UIWindowLevelNormal && !window.isHidden && window.frame != CGRect.zero { return window }
            }
            return nil
        }
    }
}
