//
//  Extensions.swift
//  DopamineKit
//
//  Created by Akash Desai on 11/27/17.
//

import Foundation

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

internal extension CGFloat {
    func degreesToRadians() -> CGFloat {
        return self / 180 * .pi
    }
    
    init(degrees: CGFloat) {
        self = degrees.degreesToRadians()
    }
}

