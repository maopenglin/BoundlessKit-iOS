//
//  Extensions.swift
//  DopamineKit
//
//  Created by Akash Desai on 11/27/17.
//

import Foundation

internal extension DopamineKit {
    class var frameworkBundle: Bundle? {
        if let bundleURL = Bundle(for: DopamineKit.classForCoder()).url(forResource: "DopamineKit", withExtension: "bundle") {
            return Bundle(url: bundleURL)
        } else {
            DopeLog.debug("The DopamineKit framework bundle cannot be found")
            return nil
        }
    }
}

extension Array {
    func selectRandom() -> Element? {
        if self.count == 0 { return nil }
        return self[Int(arc4random_uniform(UInt32(self.count)))]
    }
}

public extension String {
    func image(font:UIFont = .systemFont(ofSize: 24)) -> UIImage {
        let size = (self as NSString).size(withAttributes: [NSAttributedStringKey.font: font])
        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        (self as NSString).draw(at: .zero, withAttributes: [NSAttributedStringKey.font: font])
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image!
    }
    
    var base64DecodedImage: UIImage? {
        if let data = Data(base64Encoded: self, options: Data.Base64DecodingOptions.ignoreUnknownCharacters) {
            return UIImage(data: data)
        }
        return nil
    }
}

internal extension UIWindow {
    class var topWindow: UIWindow? {
        get {
            if let window = UIApplication.shared.keyWindow {
                return window
            }
            for window in UIApplication.shared.windows.reversed() {
                if window.windowLevel == UIWindowLevelNormal && !window.isHidden && window.frame != CGRect.zero { return window }
            }
            return nil
        }
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
    static func from (rgb: String, alpha: CGFloat = 1.0) -> UIColor {
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

extension UIImage {
    
    // colorize image with given tint color
    // this is similar to Photoshop's "Color" layer blend mode
    // this is perfect for non-greyscale source images, and images that have both highlights and shadows that should be preserved
    // white will stay white and black will stay black as the lightness of the image is preserved
    func tint(tintColor: UIColor) -> UIImage {
        
        return modifiedImage { context, rect in
            // draw black background - workaround to preserve color of partially transparent pixels
            context.setBlendMode(.normal)
            UIColor.black.setFill()
            context.fill(rect)
            
            // draw original image
            context.setBlendMode(.normal)
            context.draw(self.cgImage!, in: rect)
            
            // tint image (loosing alpha) - the luminosity of the original image is preserved
            context.setBlendMode(.color)
            tintColor.setFill()
            context.fill(rect)
            
            // mask by alpha values of original image
            context.setBlendMode(.destinationIn)
            context.draw(self.cgImage!, in: rect)
        }
    }
    
    // fills the alpha channel of the source image with the given color
    // any color information except to the alpha channel will be ignored
    func fillAlpha(fillColor: UIColor) -> UIImage {
        
        return modifiedImage { context, rect in
            // draw tint color
            context.setBlendMode(.normal)
            fillColor.setFill()
            context.fill(rect)
            
            // mask by alpha values of original image
            context.setBlendMode(.destinationIn)
            context.draw(self.cgImage!, in: rect)
        }
    }
    
    private func modifiedImage( draw: (CGContext, CGRect) -> ()) -> UIImage {
        
        // using scale correctly preserves retina images
        UIGraphicsBeginImageContextWithOptions(size, false, scale)
        let context: CGContext! = UIGraphicsGetCurrentContext()
        assert(context != nil)
        
        // correctly rotate image
        context.translateBy(x: 0, y: size.height)
        context.scaleBy(x: 1, y: -1)
        
        let rect = CGRect(x: 0, y: 0, width: size.width, height: size.height)
        
        draw(context, rect)
        
        let image = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        return image
    }
    
}

internal extension CGImage {
    func blurImage(radius: Int) -> CGImage {
        guard radius != 0 else {
            return self
        }
        let imageToBlur = CIImage(cgImage: self)
        let blurfilter = CIFilter(name: "CIGaussianBlur")!
        blurfilter.setValue(radius, forKey: kCIInputRadiusKey)
        blurfilter.setValue(imageToBlur, forKey: kCIInputImageKey)
        let resultImage = blurfilter.value(forKey: kCIOutputImageKey) as! CIImage
        
        let context = CIContext(options: nil)
        return context.createCGImage(resultImage, from: resultImage.extent)!
    }
}

internal extension CGFloat {
    func degreesToRadians() -> CGFloat {
        return self / 180 * .pi
    }
    
    init(degrees: CGFloat) {
        self = degrees.degreesToRadians()
    }
}
