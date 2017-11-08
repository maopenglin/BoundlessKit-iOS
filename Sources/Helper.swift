//
//  Helper.swift
//  Pods
//
//  Created by Akash Desai on 8/24/17.
//
//

import Foundation
import CoreData

@objc
public class Helper: NSObject {
    
    @objc public static var lastTouchLocationInUIWindow: CGPoint = CGPoint.zero
    
    @objc fileprivate static var timeMarkers = NSMutableDictionary()
    
    @objc public static func trackStartTime(for id: String) -> NSDictionary {
        let start = NSDate()
        timeMarkers.setValue(start, forKey: id)
        return ["start": NSNumber(value: 1000*start.timeIntervalSince1970)]
    }
    
    @objc public static func timeTracked(for id: String) -> NSDictionary {
        defer {
            timeMarkers.removeObject(forKey: id)
        }
        let end = NSDate()
        let start = timeMarkers.value(forKey: id) as? NSDate
        let spent = (start == nil) ? 0 : (1000*end.timeIntervalSince(start! as Date))
        return ["start": NSNumber(value: (start == nil) ? 0 : (1000*start!.timeIntervalSince1970)),
                "end": NSNumber(value: 1000*end.timeIntervalSince1970),
                "spent": NSNumber(value: spent)
        ]
    }
    
}



/// This function takes a hex string and alpha value and returns its UIColor
///
/// - parameters:
///     - hex: A hex string with either format `"#ffffff"` or `"ffffff"` or `"#FFFFFF"`.
///     - alpha: The alpha value to apply to the color, default is 1.0 for opaque
///
/// - returns:
///     The corresponding UIColor for valid hex strings, `UIColor.grayColor()` otherwise.
///
public extension UIColor {
    static func from (hex: String, alpha: CGFloat = 1.0) -> UIColor {
        var cString:String = hex.trimmingCharacters(in: NSCharacterSet.whitespacesAndNewlines).uppercased()
        
        if (cString.hasPrefix("#")) {
            cString.removeFirst()
        }
        
        if cString.characters.count != 6 {
            return UIColor.gray
        }
        
        var rgbValue:UInt32 = 0
        Scanner(string: cString).scanHexInt32(&rgbValue)
        
        return UIColor(
            red: CGFloat((rgbValue & 0xFF0000) >> 16) / 255.0,
            green: CGFloat((rgbValue & 0x00FF00) >> 8) / 255.0,
            blue: CGFloat(rgbValue & 0x0000FF) / 255.0,
            alpha: alpha
        )
    }
}
