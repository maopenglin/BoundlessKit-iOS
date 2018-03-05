//
//  UIColorExtensions.swift
//  BoundlessKit
//
//  Created by Akash Desai on 12/1/17.
//

import Foundation

public extension UIColor {
    /// This function takes a hex string and alpha value and returns its UIColor
    ///
    /// - parameters:
    ///     - rgb: A hex string with either format `"#ffffff"` or `"ffffff"` or `"#FFFFFF"`.
    ///     - alpha: The alpha value to apply to the color, default is 1.0 for opaque
    ///
    /// - returns:
    ///     The corresponding UIColor for valid hex strings, `UIColor.grayColor()` otherwise.
    ///
    static func from(rgb: String, alpha: CGFloat = 1.0) -> UIColor {
        var colorString:String = rgb.trimmingCharacters(in: NSCharacterSet.whitespacesAndNewlines).uppercased()
        
        if (colorString.hasPrefix("#")) {
            colorString.removeFirst()
        }
        
        if colorString.count != 6 {
            return UIColor.gray
        }
        
        var rgbValue:UInt32 = 0
        Scanner(string: colorString).scanHexInt32(&rgbValue)
        
        return UIColor(
            red: CGFloat((rgbValue & 0xFF0000) >> 16) / 255.0,
            green: CGFloat((rgbValue & 0x00FF00) >> 8) / 255.0,
            blue: CGFloat(rgbValue & 0x0000FF) / 255.0,
            alpha: alpha
        )
    }
    
    //    var components: (red: CGFloat, green: CGFloat, blue: CGFloat, alpha: CGFloat)? {
    //        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
    //        return getRed(&r, green: &g, blue: &b, alpha: &a) ? (r,g,b,a) : nil
    //    }
}

