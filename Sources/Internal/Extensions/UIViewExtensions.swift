//
//  UIViewExtensions.swift
//  DopamineKit
//
//  Created by Akash Desai on 12/1/17.
//

import Foundation

internal extension UIView {
    
    func snapshotImage() -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(bounds.size, false, 0)
        drawHierarchy(in: self.bounds, afterScreenUpdates: true)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return image
    }
    
    func getSubviewsWithClassname(classname: String) -> [UIView] {
        var views = [UIView]()
        
        for subview in self.subviews {
            views += subview.getSubviewsWithClassname(classname: classname)
            
            if classname == String(describing: type(of: subview)) {
                views.append(subview)
            }
        }
        
        return views
    }
    
    static func find(_ viewCustom: String, _ locationFunction: (UIView) -> CGPoint ) -> [(UIView, CGPoint)] {
        var values: [(UIView, CGPoint)] = []
        for view in find(viewCustom) {
            values.append((view, locationFunction(view)))
        }
        return values
    }
    
    static func find(_ viewCustom: String) -> [UIView] {
        let viewCustomParams = viewCustom.components(separatedBy: "$")
        let classname: String
        let index: Int?
        if viewCustomParams.count == 2 {
            classname = viewCustomParams[0]
            index = Int(viewCustomParams[1])
        } else if viewCustomParams.count == 1 {
            classname = viewCustomParams[0]
            index = nil
        } else {
            DopeLog.error("Invalid params for customView. Should be in the format \"ViewClassname$0\"")
            return []
        }
//        let possibleViews = UIApplication.shared.keyWindow!.getSubviewsWithClassname(classname: classname)
        
        var possibleViews: [UIView] = []
        for window in UIApplication.shared.windows {
            for view in window.getSubviewsWithClassname(classname: classname) {
                possibleViews.append(view)
            }
        }
        
        if let index = index {
            if index >= 0 {
                if index < possibleViews.count {
                    return [possibleViews[index]]
                } else if let view = possibleViews.last {
                    return [view]
                }
            } else { // negative index counts backwards
                if -index <= possibleViews.count {
                    return [possibleViews[possibleViews.count + index]]
                } else if let view = possibleViews.first {
                    return [view]
                }
            }
        }
        
        return possibleViews
    }
}

internal extension UIView {
    func pointWithMargins(x marginX: CGFloat,y marginY: CGFloat) -> CGPoint {
        let x: CGFloat
        let y: CGFloat
        
        if 0 < marginX && marginX <= 1 {
            x = marginX * bounds.width
        } else {
            x = marginX
        }
        
        if 0 < marginY && marginY <= 1 {
            y = marginY * bounds.height
        } else {
            y = marginY
        }
        
        return CGPoint(x: x, y: y)
    }
}
