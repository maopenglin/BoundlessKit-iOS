//
//  CandyBar.swift
//
//

import Foundation
import UIKit

internal enum CandyBarState {
    case Showing, Hidden, Gone
}

/// Wheter the candybar should appear at the top or the bottom of the screen.
///
/// - Top: The candybar will appear at the top.
/// - Bottom: The candybar will appear at the bottom.
@objc
public enum CandyBarPosition : Int{
    case Top, Bottom
}

/// A level of 'springiness' for CandyBars.
///
/// - None: The candybar will slide in and not bounce.
/// - Slight: The candybar will bounce a little.
/// - Heavy: The candybar will bounce a lot.
@objc
public enum CandyBarSpringiness : Int{
    case None, Slight, Heavy
    private var springValues: (damping: CGFloat, velocity: CGFloat) {
        switch self {
        case .None: return (damping: 1.0, velocity: 1.0)
        case .Slight: return (damping: 0.7, velocity: 1.5)
        case .Heavy: return (damping: 0.6, velocity: 2.0)
        }
    }
}

/// CandyBar is a dropdown notification view.
@objc
public class CandyBar: UIView {
    
    /// A CandyBar with the provided `title`, `subtitle`, and an optional `image`, ready to be presented with `show()`.
    ///
    /// - parameters:
    ///     - title?: The title of the candybar. Defaults to `nil`.
    ///     - subtitle?: The subtitle of the candybar. Defaults to `nil`.
    ///     - image?: The image on the left of the candybar. Defaults to `nil`.
    ///     - backgroundColor?: The color of the candybar's background view. Defaults to `UIColor.blackColor()`.
    ///     - didTapBlock?: An action to be called when the user taps on the candybar. Defaults to `nil`.
    ///
    public required init(title: String? = nil, subtitle: String? = nil, image: UIImage? = nil, backgroundColor: UIColor = UIColor.blackColor(), didTapBlock: (() -> ())? = nil) {
        self.didTapBlock = didTapBlock
        self.image = image
        super.init(frame: CGRectZero)
        resetShadows()
        addGestureRecognizers()
        initializeSubviews()
        resetTintColor()
        titleLabel.text = title
        detailLabel.text = subtitle
        backgroundView.backgroundColor = backgroundColor
        backgroundView.alpha = 0.95
    }
    
    
    /// A CandyBar with the provided `title`, `subtitle`, and an optional icon, ready to be presented with `show()`.
    ///
    /// - parameters:
    ///     - title?: The title of the candybar. Defaults to `nil`.
    ///     - subtitle?: The subtitle of the candybar. Defaults to `nil`.
    ///     - icon?: An icon, from the `Candy` class, to be displayed on the left of a candybar. Defaults to `.Stars`
    ///     - backgroundColor?: The color of the candybar's background view. Defaults to `UIColor.blackColor()`.
    ///     - didTapBlock?: An action to be called when the user taps on the candybar. Defaults to `nil`.
    ///
    public required init(title: String? = nil, subtitle: String? = nil, icon: CandyIcon = .Stars, backgroundColor: UIColor = UIColor.blackColor(), didTapBlock: (() -> ())? = nil) {
        self.didTapBlock = didTapBlock
        self.image = icon.image
        super.init(frame: CGRectZero)
        resetShadows()
        addGestureRecognizers()
        initializeSubviews()
        resetTintColor()
        titleLabel.text = title
        detailLabel.text = subtitle
        backgroundView.backgroundColor = backgroundColor
        backgroundView.alpha = 0.95
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    /// Shows the candybar. If a view is specified, the candybar will be displayed at the top of that view, otherwise at top of the top window. If a `duration` is specified, the candybar dismisses itself automatically after that duration elapses.
    ///
    /// - parameter:
    ///     - duration?: A time interval, after which the candybar will dismiss itself. Defaults to `nil`, which in turn means the user will have to tap-to-dismiss or the function `candybar.dismiss()` can be used.
    ///
    public func show(duration: NSTimeInterval? = nil) {
        CandyBar.topWindow()!.addSubview(self)
        forceUpdates()
        let (damping, velocity) = self.springiness.springValues
        if adjustsStatusBarStyle {
            UIApplication.sharedApplication().setStatusBarStyle(preferredStatusBarStyle, animated: true)
        }
        UIView.animateWithDuration(animationDuration, delay: 0.0, usingSpringWithDamping: damping, initialSpringVelocity: velocity, options: .AllowUserInteraction, animations: {
            self.candybarState = .Showing
            }, completion: { finished in
                guard let duration = duration else { return }
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(duration * NSTimeInterval(NSEC_PER_SEC))), dispatch_get_main_queue()) {
                    self.dismiss()
                }
        })
    }
    
    /// This function takes a hex string and returns a UIColor
    ///
    /// - parameters:
    ///     - hex: A hex string with either format `"#ffffff"` or `"ffffff"` or `"#FFFFFF"`.
    ///
    /// - returns:
    ///     The corresponding UIColor for valid hex strings, `UIColor.grayColor()` otherwise.
    ///
    public static func hexStringToUIColor (hex:String) -> UIColor {
        var cString:String = hex.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet() as NSCharacterSet).uppercaseString
        
        if (cString.hasPrefix("#")) {
            cString = cString.substringFromIndex(cString.startIndex.advancedBy(1))
        }
        
        if ((cString.characters.count) != 6) {
            return UIColor.grayColor()
        }
        
        var rgbValue:UInt32 = 0
        NSScanner(string: cString).scanHexInt(&rgbValue)
        
        return UIColor(
            red: CGFloat((rgbValue & 0xFF0000) >> 16) / 255.0,
            green: CGFloat((rgbValue & 0x00FF00) >> 8) / 255.0,
            blue: CGFloat(rgbValue & 0x0000FF) / 255.0,
            alpha: CGFloat(1.0)
        )
    }
    
    
    
    
    
    
    
    
    /** 
     
     
     
     Internal functions below
     Created by Harlan Haskins and Akash Desai
     
     
     
     
    */
    
    
    
    
    
    
    
    
    
    class func topWindow() -> UIWindow? {
        for window in UIApplication.sharedApplication().windows.reverse() {
            if window.windowLevel == UIWindowLevelNormal && !window.hidden && window.frame != CGRectZero { return window }
        }
        return nil
    }
    
    private let contentView = UIView()
    private let labelView = UIView()
    private let backgroundView = UIView()
    
    /// How long the slide down animation should last.
    public var animationDuration: NSTimeInterval = 0.4
    
    /// The preferred style of the status bar during display of the candybar. Defaults to `.LightContent`.
    ///
    /// If the candybar's `adjustsStatusBarStyle` is false, this property does nothing.
    public var preferredStatusBarStyle = UIStatusBarStyle.LightContent
    
    /// Whether or not this candybar should adjust the status bar style during its presentation. Defaults to `false`.
    public var adjustsStatusBarStyle = false
    
    /// Whether the candybar should appear at the top or the bottom of the screen. Defaults to `.Top`.
    public var position = CandyBarPosition.Bottom
    
    /// How 'springy' the candybar should display. Defaults to `.Slight`
    public var springiness = CandyBarSpringiness.Slight
    
    /// The color of the text as well as the image tint color if `shouldTintImage` is `true`.
    public var textColor = UIColor.whiteColor() {
        didSet {
            resetTintColor()
        }
    }
    
    /// Whether or not the candybar should show a shadow when presented.
    public var hasShadows = true {
        didSet {
            resetShadows()
        }
    }
    
    /// The color of the background view. Defaults to `nil`.
    override public var backgroundColor: UIColor? {
        get { return backgroundView.backgroundColor }
        set { backgroundView.backgroundColor = newValue }
    }
    
    /// The opacity of the background view. Defaults to 0.95.
    override public var alpha: CGFloat {
        get { return backgroundView.alpha }
        set { backgroundView.alpha = newValue }
    }
    
    /// A block to call when the uer taps on the candybar.
    public var didTapBlock: (() -> ())?
    
    /// A block to call after the candybar has finished dismissing and is off screen.
    public var didDismissBlock: (() -> ())?
    
    /// Whether or not the candybar should dismiss itself when the user taps. Defaults to `true`.
    public var dismissesOnTap = true
    
    /// Whether or not the candybar should dismiss itself when the user swipes up. Defaults to `true`.
    public var dismissesOnSwipe = true
    
    /// Whether or not the candybar should tint the associated image to the provided `textColor`. Defaults to `true`.
    public var shouldTintImage = true {
        didSet {
            resetTintColor()
        }
    }
    
    /// The label that displays the candybar's title.
    public let titleLabel: UILabel = {
        let label = UILabel()
        var titleFont = UIFont.preferredFontForTextStyle(UIFontTextStyleHeadline)
        
        titleFont = titleFont.fontWithSize(26)
        label.font = titleFont
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    /// The label that displays the candybar's subtitle.
    public let detailLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.preferredFontForTextStyle(UIFontTextStyleSubheadline)
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    /// The image on the left of the candybar.
    let image: UIImage?
    
    /// The image view that displays the `image`.
    public let imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .ScaleAspectFit
        return imageView
    }()
    
    internal var candybarState = CandyBarState.Hidden {
        didSet {
            if candybarState != oldValue {
                forceUpdates()
            }
        }
    }
    
    private func forceUpdates() {
        guard let superview = superview, showingConstraint = showingConstraint, hiddenConstraint = hiddenConstraint else { return }
        switch candybarState {
        case .Hidden:
            superview.removeConstraint(showingConstraint)
            superview.addConstraint(hiddenConstraint)
        case .Showing:
            superview.removeConstraint(hiddenConstraint)
            superview.addConstraint(showingConstraint)
        case .Gone:
            superview.removeConstraint(hiddenConstraint)
            superview.removeConstraint(showingConstraint)
            superview.removeConstraints(commonConstraints)
        }
        setNeedsLayout()
        setNeedsUpdateConstraints()
        layoutIfNeeded()
        updateConstraintsIfNeeded()
    }
    
    internal func didTap(recognizer: UITapGestureRecognizer) {
        if dismissesOnTap {
            dismiss()
        }
        didTapBlock?()
    }
    
    internal func didSwipe(recognizer: UISwipeGestureRecognizer) {
        if dismissesOnSwipe {
            dismiss()
        }
    }
    
    private func addGestureRecognizers() {
        addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(self.didTap(_:))))
        let swipe = UISwipeGestureRecognizer(target: self, action: #selector(self.didSwipe(_:)))
        swipe.direction = .Up
        addGestureRecognizer(swipe)
    }
    
    private func resetTintColor() {
        titleLabel.textColor = textColor
        detailLabel.textColor = textColor
        imageView.image = shouldTintImage ? image?.imageWithRenderingMode(.AlwaysTemplate) : image
        imageView.tintColor = shouldTintImage ? textColor : nil
    }
    
    private func resetShadows() {
        layer.shadowColor = UIColor.blackColor().CGColor
        layer.shadowOpacity = self.hasShadows ? 0.5 : 0.0
        layer.shadowOffset = CGSize(width: 0, height: 0)
        layer.shadowRadius = 4
    }
    
    private var contentTopOffsetConstraint: NSLayoutConstraint!
    private var minimumHeightConstraint: NSLayoutConstraint!
    
    private func initializeSubviews() {
        let views = [
            "backgroundView": backgroundView,
            "contentView": contentView,
            "imageView": imageView,
            "labelView": labelView,
            "titleLabel": titleLabel,
            "detailLabel": detailLabel
        ]
        translatesAutoresizingMaskIntoConstraints = false
        addSubview(backgroundView)
        minimumHeightConstraint = backgroundView.constraintWithAttribute(.Height, .GreaterThanOrEqual, to: 80)
        addConstraint(minimumHeightConstraint) // Arbitrary, but looks nice.
        addConstraints(backgroundView.constraintsEqualToSuperview())
        backgroundView.backgroundColor = backgroundColor
        backgroundView.addSubview(contentView)
        labelView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(labelView)
        labelView.addSubview(titleLabel)
        labelView.addSubview(detailLabel)
        backgroundView.addConstraints(NSLayoutConstraint.defaultConstraintsWithVisualFormat("H:|[contentView]|", views: views))
        backgroundView.addConstraint(contentView.constraintWithAttribute(.Bottom, .Equal, to: .Bottom, of: backgroundView))
        contentTopOffsetConstraint = contentView.constraintWithAttribute(.Top, .Equal, to: .Top, of: backgroundView)
        backgroundView.addConstraint(contentTopOffsetConstraint)
        let leftConstraintText: String
        if image == nil {
            leftConstraintText = "|"
        } else {
            contentView.addSubview(imageView)
            contentView.addConstraint(imageView.constraintWithAttribute(.Leading, .Equal, to: contentView, constant: 15.0))
            contentView.addConstraint(imageView.constraintWithAttribute(.CenterY, .Equal, to: contentView))
            imageView.addConstraint(imageView.constraintWithAttribute(.Width, .Equal, to: 100.0))
            imageView.addConstraint(imageView.constraintWithAttribute(.Height, .Equal, to: .Width))
            leftConstraintText = "[imageView]"
        }
        let constraintFormat = "H:\(leftConstraintText)-(15)-[labelView]-(8)-|"
        contentView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addConstraints(NSLayoutConstraint.defaultConstraintsWithVisualFormat(constraintFormat, views: views))
        if image == nil {
            contentView.addConstraints(NSLayoutConstraint.defaultConstraintsWithVisualFormat("V:|-(>=10)-[labelView]-(>=10)-|", views: views))
        } else {
            contentView.addConstraints(NSLayoutConstraint.defaultConstraintsWithVisualFormat("V:|-(>=10)-[imageView]-(>=10)-|", views: views))
        }
        backgroundView.addConstraints(NSLayoutConstraint.defaultConstraintsWithVisualFormat("H:|[contentView]-(<=1)-[labelView]", options: .AlignAllCenterY, views: views))
        
        for view in [titleLabel, detailLabel] {
            let constraintFormat = "H:|[label]-(8)-|"
            contentView.addConstraints(NSLayoutConstraint.defaultConstraintsWithVisualFormat(constraintFormat, options: .DirectionLeadingToTrailing, metrics: nil, views: ["label": view]))
        }
        labelView.addConstraints(NSLayoutConstraint.defaultConstraintsWithVisualFormat("V:|-(10)-[titleLabel][detailLabel]-(10)-|", views: views))
    }
    
    //    required public init?(coder aDecoder: NSCoder) {
    //        fatalError("init(coder:) has not been implemented")
    //    }
    
    private var showingConstraint: NSLayoutConstraint?
    private var hiddenConstraint: NSLayoutConstraint?
    private var commonConstraints = [NSLayoutConstraint]()
    
    override public func didMoveToSuperview() {
        super.didMoveToSuperview()
        guard let superview = superview where candybarState != .Gone else { return }
        commonConstraints = self.constraintsWithAttributes([.Leading, .Trailing], .Equal, to: superview)
        superview.addConstraints(commonConstraints)
        
        switch self.position {
        case .Top:
            showingConstraint = self.constraintWithAttribute(.Top, .Equal, to: .Top, of: superview)
            let yOffset: CGFloat = -7.0 // Offset the bottom constraint to make room for the shadow to animate off screen.
            hiddenConstraint = self.constraintWithAttribute(.Bottom, .Equal, to: .Top, of: superview, constant: yOffset)
        case .Bottom:
            showingConstraint = self.constraintWithAttribute(.Bottom, .Equal, to: .Bottom, of: superview)
            let yOffset: CGFloat = 7.0 // Offset the bottom constraint to make room for the shadow to animate off screen.
            hiddenConstraint = self.constraintWithAttribute(.Top, .Equal, to: .Bottom, of: superview, constant: yOffset)
        }
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        adjustHeightOffset()
        layoutIfNeeded()
    }
    
    private func adjustHeightOffset() {
        guard let superview = superview else { return }
        if superview === CandyBar.topWindow() && self.position == .Top {
            let statusBarSize = UIApplication.sharedApplication().statusBarFrame.size
            let heightOffset = min(statusBarSize.height, statusBarSize.width) // Arbitrary, but looks nice.
            contentTopOffsetConstraint.constant = heightOffset
            minimumHeightConstraint.constant = statusBarSize.height > 0 ? 80 : 40
        } else {
            contentTopOffsetConstraint.constant = 0
            minimumHeightConstraint.constant = 0
        }
    }
    
    /// Dismisses the candybar without a oldStatusBarStyle parameter.
    public func dismiss() {
        let (damping, velocity) = self.springiness.springValues
        UIView.animateWithDuration(animationDuration, delay: 0.0, usingSpringWithDamping: damping, initialSpringVelocity: velocity, options: .AllowUserInteraction, animations: {
            self.candybarState = .Hidden
            }, completion: { finished in
                self.candybarState = .Gone
                self.removeFromSuperview()
                self.didDismissBlock?()
        })
    }
    
}

extension NSLayoutConstraint {
    class func defaultConstraintsWithVisualFormat(format: String, options: NSLayoutFormatOptions = .DirectionLeadingToTrailing, metrics: [String: AnyObject]? = nil, views: [String: AnyObject] = [:]) -> [NSLayoutConstraint] {
        return NSLayoutConstraint.constraintsWithVisualFormat(format, options: options, metrics: metrics, views: views)
    }
}

extension UIView {
    func constraintsEqualToSuperview(edgeInsets: UIEdgeInsets = UIEdgeInsetsZero) -> [NSLayoutConstraint] {
        self.translatesAutoresizingMaskIntoConstraints = false
        var constraints = [NSLayoutConstraint]()
        if let superview = self.superview {
            constraints.append(self.constraintWithAttribute(.Leading, .Equal, to: superview, constant: edgeInsets.left))
            constraints.append(self.constraintWithAttribute(.Trailing, .Equal, to: superview, constant: edgeInsets.right))
            constraints.append(self.constraintWithAttribute(.Top, .Equal, to: superview, constant: edgeInsets.top))
            constraints.append(self.constraintWithAttribute(.Bottom, .Equal, to: superview, constant: edgeInsets.bottom))
        }
        return constraints
    }
    
    func constraintWithAttribute(attribute: NSLayoutAttribute, _ relation: NSLayoutRelation, to constant: CGFloat, multiplier: CGFloat = 1.0) -> NSLayoutConstraint {
        self.translatesAutoresizingMaskIntoConstraints = false
        return NSLayoutConstraint(item: self, attribute: attribute, relatedBy: relation, toItem: nil, attribute: .NotAnAttribute, multiplier: multiplier, constant: constant)
    }
    
    func constraintWithAttribute(attribute: NSLayoutAttribute, _ relation: NSLayoutRelation, to otherAttribute: NSLayoutAttribute, of item: AnyObject? = nil, multiplier: CGFloat = 1.0, constant: CGFloat = 0.0) -> NSLayoutConstraint {
        self.translatesAutoresizingMaskIntoConstraints = false
        return NSLayoutConstraint(item: self, attribute: attribute, relatedBy: relation, toItem: item ?? self, attribute: otherAttribute, multiplier: multiplier, constant: constant)
    }
    
    func constraintWithAttribute(attribute: NSLayoutAttribute, _ relation: NSLayoutRelation, to item: AnyObject, multiplier: CGFloat = 1.0, constant: CGFloat = 0.0) -> NSLayoutConstraint {
        self.translatesAutoresizingMaskIntoConstraints = false
        return NSLayoutConstraint(item: self, attribute: attribute, relatedBy: relation, toItem: item, attribute: attribute, multiplier: multiplier, constant: constant)
    }
    
    func constraintsWithAttributes(attributes: [NSLayoutAttribute], _ relation: NSLayoutRelation, to item: AnyObject, multiplier: CGFloat = 1.0, constant: CGFloat = 0.0) -> [NSLayoutConstraint] {
        return attributes.map { self.constraintWithAttribute($0, relation, to: item, multiplier: multiplier, constant: constant) }
    }
}