//
//  UIViewExtensions.swift
//  DopamineKit
//
//  Created by Akash Desai on 12/1/17.
//

import Foundation
internal extension UIView {
    func imageAsBase64EncodedString() -> String? {
        UIGraphicsBeginImageContextWithOptions(bounds.size, false, 0)
        drawHierarchy(in: self.bounds, afterScreenUpdates: true)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        if let image = image,
            let imageString = image.base64EncodedPNGString() {
            return imageString
        } else {
            NSLog("Could not create snapshot of UIView...")
            return nil
        }
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
        let possibleViews = UIApplication.shared.keyWindow!.getSubviewsWithClassname(classname: classname)
        
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
