//
//  UIViewExtensions.swift
//  BoundlessKit
//
//  Created by Akash Desai on 12/1/17.
//

import Foundation

internal extension UIView {
    func snapshotImage() -> UIImage? {
        var image: UIImage?
        DispatchQueue.main.sync {
            UIGraphicsBeginImageContextWithOptions(bounds.size, false, 0)
            drawHierarchy(in: self.bounds, afterScreenUpdates: true)
            image = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
        }
        return image
    }
}

internal extension UIView {
    static func getViews(ofType aClass: AnyClass) -> [UIView] {
        return UIApplication.shared.windows.reversed().flatMap({$0.getSubviews(ofType: aClass)})
    }
    
    func getSubviews(ofType aClass: AnyClass) -> [UIView] {
        var views = [UIView]()
        
        for subview in self.subviews.reversed() {
            views += subview.getSubviews(ofType: aClass)
        }
        
        if aClass == type(of: self) {
            views.append(self)
        }
        
        return views
    }
}

internal extension UIView {
    func pointWithMargins(x marginX: CGFloat,y marginY: CGFloat) -> CGPoint {
        let x: CGFloat
        let y: CGFloat
        
        if (-1 <= marginX && marginX <= 1) {
            x = marginX * bounds.width
        } else {
            x = marginX
        }
        
        if (-1 <= marginY && marginY <= 1) {
            y = marginY * bounds.height
        } else {
            y = marginY
        }
        
        return CGPoint(x: x, y: y)
    }
}
