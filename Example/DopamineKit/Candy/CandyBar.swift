//
//  CandyBar.swift
//
//

import Foundation
import UIKit

internal enum CandyBarState {
    case showing, hidden, gone
}

/// Wheter the candybar should appear at the top or the bottom of the screen.
///
/// - Top: The candybar will appear at the top.
/// - Bottom: The candybar will appear at the bottom.
@objc
public enum CandyBarPosition : Int{
    case top, bottom
}

/// A level of 'springiness' for CandyBars.
///
/// - None: The candybar will slide in and not bounce.
/// - Slight: The candybar will bounce a little.
/// - Heavy: The candybar will bounce a lot.
@objc
public enum CandyBarSpringiness : Int{
    case none, slight, heavy
    fileprivate var springValues: (damping: CGFloat, velocity: CGFloat) {
        switch self {
        case .none: return (damping: 1.0, velocity: 1.0)
        case .slight: return (damping: 0.7, velocity: 1.5)
        case .heavy: return (damping: 0.6, velocity: 2.0)
        }
    }
}

/// CandyBar is a dropdown notification view.
@objc
open class CandyBar: UIView {
    
    /// A CandyBar with the provided `title`, `subtitle`, and an optional `image`, ready to be presented with `show()`.
    ///
    /// - parameters:
    ///     - title?: The title of the candybar. Defaults to `nil`.
    ///     - subtitle?: The subtitle of the candybar. Defaults to `nil`.
    ///     - image?: The image on the left of the candybar. Defaults to `nil`.
    ///     - backgroundColor?: The color of the candybar's background view. Defaults to `UIColor.blackColor()`.
    ///     - didTapBlock?: An action to be called when the user taps on the candybar. Defaults to `nil`.
    ///
    @objc public required init(title: String? = nil, subtitle: String? = nil, image: UIImage? = nil, backgroundColor: UIColor = UIColor.black, didTapBlock: (() -> ())? = nil) {
        self.didTapBlock = didTapBlock
        self.image = image
        super.init(frame: CGRect.zero)
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
    @objc public required init(title: String? = nil, subtitle: String? = nil, icon: CandyIcon = .stars, backgroundColor: UIColor = UIColor.black, didTapBlock: (() -> ())? = nil) {
        self.didTapBlock = didTapBlock
        self.image = icon.image
        super.init(frame: CGRect.zero)
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
    open func show(_ duration: TimeInterval? = nil) {
        CandyBar.topWindow()!.addSubview(self)
        forceUpdates()
        let (damping, velocity) = self.springiness.springValues
        if adjustsStatusBarStyle {
            UIApplication.shared.setStatusBarStyle(preferredStatusBarStyle, animated: true)
        }
        UIView.animate(withDuration: animationDuration, delay: 0.0, usingSpringWithDamping: damping, initialSpringVelocity: velocity, options: .allowUserInteraction, animations: {
            self.candybarState = .showing
            }, completion: { finished in
                guard let duration = duration else { return }
                DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + duration, execute: {self.dismiss()})
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
    @objc open static func hexStringToUIColor (_ hex:String) -> UIColor {
        var cString:String = hex.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines as CharacterSet).uppercased()
        
        if (cString.hasPrefix("#")) {
            cString = cString.substring(from: cString.characters.index(cString.startIndex, offsetBy: 1))
        }
        
        if ((cString.characters.count) != 6) {
            return UIColor.gray
        }
        
        var rgbValue:UInt32 = 0
        Scanner(string: cString).scanHexInt32(&rgbValue)
        
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
    
    
    
    
    
    
    
    
    
    @objc class func topWindow() -> UIWindow? {
        for window in UIApplication.shared.windows.reversed() {
            if window.windowLevel == UIWindowLevelNormal && !window.isHidden && window.frame != CGRect.zero { return window }
        }
        return nil
    }
    
    fileprivate let contentView = UIView()
    fileprivate let labelView = UIView()
    fileprivate let backgroundView = UIView()
    
    /// How long the slide down animation should last.
    @objc open var animationDuration: TimeInterval = 0.4
    
    /// The preferred style of the status bar during display of the candybar. Defaults to `.LightContent`.
    ///
    /// If the candybar's `adjustsStatusBarStyle` is false, this property does nothing.
    @objc open var preferredStatusBarStyle = UIStatusBarStyle.lightContent
    
    /// Whether or not this candybar should adjust the status bar style during its presentation. Defaults to `false`.
    @objc open var adjustsStatusBarStyle = false
    
    /// Whether the candybar should appear at the top or the bottom of the screen. Defaults to `.Top`.
    @objc open var position = CandyBarPosition.bottom
    
    /// How 'springy' the candybar should display. Defaults to `.Slight`
    @objc open var springiness = CandyBarSpringiness.slight
    
    /// The color of the text as well as the image tint color if `shouldTintImage` is `true`.
    @objc open var textColor = UIColor.white {
        didSet {
            resetTintColor()
        }
    }
    
    /// Whether or not the candybar should show a shadow when presented.
    @objc open var hasShadows = true {
        didSet {
            resetShadows()
        }
    }
    
    /// The color of the background view. Defaults to `nil`.
    override open var backgroundColor: UIColor? {
        get { return backgroundView.backgroundColor }
        set { backgroundView.backgroundColor = newValue }
    }
    
    /// The opacity of the background view. Defaults to 0.95.
    override open var alpha: CGFloat {
        get { return backgroundView.alpha }
        set { backgroundView.alpha = newValue }
    }
    
    /// A block to call when the uer taps on the candybar.
    @objc open var didTapBlock: (() -> ())?
    
    /// A block to call after the candybar has finished dismissing and is off screen.
    @objc open var didDismissBlock: (() -> ())?
    
    /// Whether or not the candybar should dismiss itself when the user taps. Defaults to `true`.
    @objc open var dismissesOnTap = true
    
    /// Whether or not the candybar should dismiss itself when the user swipes up. Defaults to `true`.
    @objc open var dismissesOnSwipe = true
    
    /// Whether or not the candybar should tint the associated image to the provided `textColor`. Defaults to `true`.
    @objc open var shouldTintImage = true {
        didSet {
            resetTintColor()
        }
    }
    
    /// The label that displays the candybar's title.
    @objc open let titleLabel: UILabel = {
        let label = UILabel()
        var titleFont = UIFont.preferredFont(forTextStyle: UIFontTextStyle.headline)
        
        titleFont = titleFont.withSize(26)
        label.font = titleFont
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    /// The label that displays the candybar's subtitle.
    @objc open let detailLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.preferredFont(forTextStyle: UIFontTextStyle.subheadline)
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    /// The image on the left of the candybar.
    @objc let image: UIImage?
    
    /// The image view that displays the `image`.
    @objc open let imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()
    
    internal var candybarState = CandyBarState.hidden {
        didSet {
            if candybarState != oldValue {
                forceUpdates()
            }
        }
    }
    
    fileprivate func forceUpdates() {
        guard let superview = superview, let showingConstraint = showingConstraint, let hiddenConstraint = hiddenConstraint else { return }
        switch candybarState {
        case .hidden:
            superview.removeConstraint(showingConstraint)
            superview.addConstraint(hiddenConstraint)
        case .showing:
            superview.removeConstraint(hiddenConstraint)
            superview.addConstraint(showingConstraint)
        case .gone:
            superview.removeConstraint(hiddenConstraint)
            superview.removeConstraint(showingConstraint)
            superview.removeConstraints(commonConstraints)
        }
        setNeedsLayout()
        setNeedsUpdateConstraints()
        superview.layoutIfNeeded()
        updateConstraintsIfNeeded()
    }
    
    @objc internal func didTap(_ recognizer: UITapGestureRecognizer) {
        if dismissesOnTap {
            dismiss()
        }
        didTapBlock?()
    }
    
    @objc internal func didSwipe(_ recognizer: UISwipeGestureRecognizer) {
        if dismissesOnSwipe {
            dismiss()
        }
    }
    
    fileprivate func addGestureRecognizers() {
        addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(self.didTap(_:))))
        let swipe = UISwipeGestureRecognizer(target: self, action: #selector(self.didSwipe(_:)))
        swipe.direction = .up
        addGestureRecognizer(swipe)
    }
    
    fileprivate func resetTintColor() {
        titleLabel.textColor = textColor
        detailLabel.textColor = textColor
        imageView.image = shouldTintImage ? image?.withRenderingMode(.alwaysTemplate) : image
        imageView.tintColor = shouldTintImage ? textColor : nil
    }
    
    fileprivate func resetShadows() {
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = self.hasShadows ? 0.5 : 0.0
        layer.shadowOffset = CGSize(width: 0, height: 0)
        layer.shadowRadius = 4
    }
    
    fileprivate var contentTopOffsetConstraint: NSLayoutConstraint!
    fileprivate var minimumHeightConstraint: NSLayoutConstraint!
    
    fileprivate func initializeSubviews() {
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
        minimumHeightConstraint = backgroundView.constraintWithAttribute(.height, .greaterThanOrEqual, to: 80)
        addConstraint(minimumHeightConstraint) // Arbitrary, but looks nice.
        addConstraints(backgroundView.constraintsEqualToSuperview())
        backgroundView.backgroundColor = backgroundColor
        backgroundView.addSubview(contentView)
        labelView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(labelView)
        labelView.addSubview(titleLabel)
        labelView.addSubview(detailLabel)
        backgroundView.addConstraints(NSLayoutConstraint.defaultConstraintsWithVisualFormat("H:|[contentView]|", views: views))
        backgroundView.addConstraint(contentView.constraintWithAttribute(.bottom, .equal, to: .bottom, of: backgroundView))
        contentTopOffsetConstraint = contentView.constraintWithAttribute(.top, .equal, to: .top, of: backgroundView)
        backgroundView.addConstraint(contentTopOffsetConstraint)
        let leftConstraintText: String
        if image == nil {
            leftConstraintText = "|"
        } else {
            contentView.addSubview(imageView)
            contentView.addConstraint(imageView.constraintWithAttribute(.leading, .equal, to: contentView, constant: 15.0))
            contentView.addConstraint(imageView.constraintWithAttribute(.centerY, .equal, to: contentView))
            imageView.addConstraint(imageView.constraintWithAttribute(.width, .equal, to: 100.0))
            imageView.addConstraint(imageView.constraintWithAttribute(.height, .equal, to: .width))
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
        backgroundView.addConstraints(NSLayoutConstraint.defaultConstraintsWithVisualFormat("H:|[contentView]-(<=1)-[labelView]", options: .alignAllCenterY, views: views))
        
        for view in [titleLabel, detailLabel] {
            let constraintFormat = "H:|[label]-(8)-|"
            contentView.addConstraints(NSLayoutConstraint.defaultConstraintsWithVisualFormat(constraintFormat, options: NSLayoutFormatOptions(), metrics: nil, views: ["label": view]))
        }
        labelView.addConstraints(NSLayoutConstraint.defaultConstraintsWithVisualFormat("V:|-(10)-[titleLabel][detailLabel]-(10)-|", views: views))
    }
    
    //    required public init?(coder aDecoder: NSCoder) {
    //        fatalError("init(coder:) has not been implemented")
    //    }
    
    fileprivate var showingConstraint: NSLayoutConstraint?
    fileprivate var hiddenConstraint: NSLayoutConstraint?
    fileprivate var commonConstraints = [NSLayoutConstraint]()
    
    override open func didMoveToSuperview() {
        super.didMoveToSuperview()
        guard let superview = superview , candybarState != .gone else { return }
        commonConstraints = self.constraintsWithAttributes([.leading, .trailing], .equal, to: superview)
        superview.addConstraints(commonConstraints)
        
        switch self.position {
        case .top:
            showingConstraint = self.constraintWithAttribute(.top, .equal, to: .top, of: superview)
            let yOffset: CGFloat = -7.0 // Offset the bottom constraint to make room for the shadow to animate off screen.
            hiddenConstraint = self.constraintWithAttribute(.bottom, .equal, to: .top, of: superview, constant: yOffset)
        case .bottom:
            showingConstraint = self.constraintWithAttribute(.bottom, .equal, to: .bottom, of: superview)
            let yOffset: CGFloat = 7.0 // Offset the bottom constraint to make room for the shadow to animate off screen.
            hiddenConstraint = self.constraintWithAttribute(.top, .equal, to: .bottom, of: superview, constant: yOffset)
        }
    }
    
    open override func layoutSubviews() {
        super.layoutSubviews()
        adjustHeightOffset()
        layoutIfNeeded()
    }
    
    fileprivate func adjustHeightOffset() {
        guard let superview = superview else { return }
        if superview === CandyBar.topWindow() && self.position == .top {
            let statusBarSize = UIApplication.shared.statusBarFrame.size
            let heightOffset = min(statusBarSize.height, statusBarSize.width) // Arbitrary, but looks nice.
            contentTopOffsetConstraint.constant = heightOffset
            minimumHeightConstraint.constant = statusBarSize.height > 0 ? 80 : 40
        } else {
            contentTopOffsetConstraint.constant = 0
            minimumHeightConstraint.constant = 0
        }
    }
    
    /// Dismisses the candybar without a oldStatusBarStyle parameter.
    @objc open func dismiss() {
        let (damping, velocity) = self.springiness.springValues
        UIView.animate(withDuration: animationDuration, delay: 0.0, usingSpringWithDamping: damping, initialSpringVelocity: velocity, options: .allowUserInteraction, animations: {
            self.candybarState = .hidden
            }, completion: { finished in
                self.candybarState = .gone
                self.removeFromSuperview()
                self.didDismissBlock?()
        })
    }
    
}

extension NSLayoutConstraint {
    @objc class func defaultConstraintsWithVisualFormat(_ format: String, options: NSLayoutFormatOptions = NSLayoutFormatOptions(), metrics: [String: AnyObject]? = nil, views: [String: AnyObject] = [:]) -> [NSLayoutConstraint] {
        return NSLayoutConstraint.constraints(withVisualFormat: format, options: options, metrics: metrics, views: views)
    }
}

extension UIView {
    @objc func constraintsEqualToSuperview(_ edgeInsets: UIEdgeInsets = UIEdgeInsets.zero) -> [NSLayoutConstraint] {
        self.translatesAutoresizingMaskIntoConstraints = false
        var constraints = [NSLayoutConstraint]()
        if let superview = self.superview {
            constraints.append(self.constraintWithAttribute(.leading, .equal, to: superview, constant: edgeInsets.left))
            constraints.append(self.constraintWithAttribute(.trailing, .equal, to: superview, constant: edgeInsets.right))
            constraints.append(self.constraintWithAttribute(.top, .equal, to: superview, constant: edgeInsets.top))
            constraints.append(self.constraintWithAttribute(.bottom, .equal, to: superview, constant: edgeInsets.bottom))
        }
        return constraints
    }
    
    @objc func constraintWithAttribute(_ attribute: NSLayoutAttribute, _ relation: NSLayoutRelation, to constant: CGFloat, multiplier: CGFloat = 1.0) -> NSLayoutConstraint {
        self.translatesAutoresizingMaskIntoConstraints = false
        return NSLayoutConstraint(item: self, attribute: attribute, relatedBy: relation, toItem: nil, attribute: .notAnAttribute, multiplier: multiplier, constant: constant)
    }
    
    @objc func constraintWithAttribute(_ attribute: NSLayoutAttribute, _ relation: NSLayoutRelation, to otherAttribute: NSLayoutAttribute, of item: AnyObject? = nil, multiplier: CGFloat = 1.0, constant: CGFloat = 0.0) -> NSLayoutConstraint {
        self.translatesAutoresizingMaskIntoConstraints = false
        return NSLayoutConstraint(item: self, attribute: attribute, relatedBy: relation, toItem: item ?? self, attribute: otherAttribute, multiplier: multiplier, constant: constant)
    }
    
    @objc func constraintWithAttribute(_ attribute: NSLayoutAttribute, _ relation: NSLayoutRelation, to item: AnyObject, multiplier: CGFloat = 1.0, constant: CGFloat = 0.0) -> NSLayoutConstraint {
        self.translatesAutoresizingMaskIntoConstraints = false
        return NSLayoutConstraint(item: self, attribute: attribute, relatedBy: relation, toItem: item, attribute: attribute, multiplier: multiplier, constant: constant)
    }
    
    func constraintsWithAttributes(_ attributes: [NSLayoutAttribute], _ relation: NSLayoutRelation, to item: AnyObject, multiplier: CGFloat = 1.0, constant: CGFloat = 0.0) -> [NSLayoutConstraint] {
        return attributes.map { self.constraintWithAttribute($0, relation, to: item, multiplier: multiplier, constant: constant) }
    }
}
