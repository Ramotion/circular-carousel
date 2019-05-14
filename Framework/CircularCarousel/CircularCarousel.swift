//
//  CircularCarousel.swift
//  CircularCarousel Demo
//
//  Created by Piotr Suwara on 24/12/18.
//  Copyright © 2018 Piotr Suwara. All rights reserved.
//
//  Simplified adaptation of iCarousel in Swift. Additional features added for unique scale effect.
//
//  iCarousel
//  - https://github.com/nicklockwood/iCarousel

import Foundation
import UIKit

@objc public enum CircularCarouselOption: Int {
    case wrap = 0
    case showBackfaces
    case visibleItems
    case count
    case spacing
    case fadeMin
    case fadeMax
    case fadeRange
    case fadeMinAlpha
    case offsetMultiplier
    case itemWidth
    case scaleMultiplier
    case minScale
    case maxScale
}

struct CircularCarouselConstants {
    static let maximumVisibleItems: Int         = 50
    static let decelerationMultiplier: CGFloat  = 60.0
    static let scrollSpeedThreshold: CGFloat    = 2.0
    static let decelerateThreshold: CGFloat     = 0.1
    static let scrollDistanceThreshold: CGFloat = 0.1
    static let scrollDuration: TimeInterval     = 0.4
    static let insertDuration: TimeInterval     = 0.4
    static let minScale: CGFloat                = 1.0
    static let maxScale: CGFloat                = 1.0
    static let defaultScaleMultiplier: CGFloat  = 1.0
    
    static let minToggleDuration: TimeInterval  = 0.2
    static let maxToggleDuration: TimeInterval  = 0.4
    
    static let floatErrorMargin: CGFloat        = 0.000001
    static let decelSpeed: CGFloat              = 0.9
    static let scrollSpeed: CGFloat             = 1.0
    static let bounceDist: CGFloat              = 1.0
}

@IBDesignable open class CircularCarousel: UIView {
    
    // Delegate and Datasource
    internal var _delegate: CircularCarouselDelegate?
    public var delegate: CircularCarouselDelegate? {
        get {
            return _delegate
        }
        set {
            _delegate = newValue
            if let _ = _delegate, let _ = _dataSource {
                setNeedsLayout()
            }
        }
    }
    
    internal var _dataSource: CircularCarouselDataSource?
    public var dataSource: CircularCarouselDataSource? {
        get {
            return _dataSource
        }
        set {
            _dataSource = newValue
            if let _ = _dataSource {
                reloadData()
            }
        }
    }
    
    // Public Variables
    internal (set) public var numberOfItems: Int = 0
    
    var currentItemIdx: Int {
        get {
            return clampedIndex(Int(round(scrollOffset)))
        }
        set {
            assert(newValue < numberOfItems, "Attempting to set the current item outside the bounds of total items")
            
            scrollOffset = CGFloat(newValue)
        }
    }
    
    var scrollEnabled: Bool = true
    var pagingEnabled: Bool = false
    
    @IBInspectable public var wrapEnabled: Bool = true
    @IBInspectable public var bounceEnabled: Bool = true
    
    @IBInspectable public var tapEnabled: Bool {
        get {
            return tapGesture != nil
        }
        
        set {
            if let tapGesture = tapGesture, newValue == false {
                contentView.removeGestureRecognizer(tapGesture)
                self.tapGesture = nil
            } else if tapGesture == nil && newValue == true {
                tapGesture = UITapGestureRecognizer(target: self, action: #selector(didTap))
                tapGesture?.delegate = self as? UIGestureRecognizerDelegate
                contentView.addGestureRecognizer(tapGesture!)
            }
        }
    }
    
    @IBInspectable public var swipeEnabled: Bool {
        get {
            return swipeLeftGesture != nil && swipeRightGesture != nil
        }
        
        set {
            if newValue == false {
                if let swipeRightGesture = swipeRightGesture {
                    contentView.removeGestureRecognizer(swipeRightGesture)
                    self.swipeRightGesture = nil
                }
                
                if let swipeLeftGesture = swipeLeftGesture {
                    contentView.removeGestureRecognizer(swipeLeftGesture)
                    self.swipeLeftGesture = nil
                }
                
            } else if swipeLeftGesture == nil && swipeRightGesture == nil && newValue == true {
                swipeLeftGesture = UISwipeGestureRecognizer(target: self, action: #selector(didSwipe))
                swipeLeftGesture?.direction = .left
                swipeLeftGesture?.delegate = self as? UIGestureRecognizerDelegate
                contentView.addGestureRecognizer(swipeLeftGesture!)
                
                swipeRightGesture = UISwipeGestureRecognizer(target: self, action: #selector(didSwipe))
                swipeRightGesture?.direction = .right
                swipeRightGesture?.delegate = self as? UIGestureRecognizerDelegate
                contentView.addGestureRecognizer(swipeRightGesture!)
            }
        }
    }
    
    @IBInspectable public var panEnabled: Bool {
        get {
            return panGesture != nil
        }
        
        set {
            if let panGesture = panGesture, newValue == false {
                contentView.removeGestureRecognizer(panGesture)
                self.panGesture = nil
            } else if panGesture == nil && newValue == true {
                panGesture = UIPanGestureRecognizer(target: self, action: #selector(didPan))
                panGesture?.delegate = self as? UIGestureRecognizerDelegate
                contentView.addGestureRecognizer(panGesture!)
            }
        }
    }
    
    internal var _scrollOffset: CGFloat = 0.0
    var scrollOffset: CGFloat {
        get {
            return _scrollOffset
        } set {
            scrolling = false
            decelerating = false
            startOffset = scrollOffset
            endOffset = scrollOffset
            
            if (abs(_scrollOffset - newValue) > 0.0) {
                _scrollOffset = newValue
                depthSortViews()
                didScroll()
            }
        }
    }
    
    internal var _contentOffset: CGSize = CGSize.zero
    var contentOffset: CGSize {
        get {
            return _contentOffset
        }
        set {
            if _contentOffset != newValue {
                _contentOffset = newValue
                layoutItemViews()
            }
        }
    }
    
    internal (set) public var viewPointOffset: CGSize = CGSize.zero
    
    // Accessible Variables
    var currentItemView: UIView! {
        get {
            return itemView(atIndex: currentItemIdx)
        }
        set {
            // Do something?
        }
    }
    
    // Can only be set internally by the framework
    internal (set) public var numberOfVisibleItems: Int = 0
    internal (set) public var itemWidth: CGFloat = 0.0
    internal (set) public var offsetMultiplier: CGFloat = 1.0
    internal (set) public var toggle: CGFloat = 0.0
    
    internal (set) public var contentView: UIView = UIView()
    
    internal (set) public var dragging: Bool = false
    internal (set) public var scrolling: Bool = false
    
    // Internal variables available only to the framework
    internal var itemViews: Dictionary<Int, UIView> = Dictionary<Int, UIView>()
    internal var previousItemIndex: Int = 0
    internal var itemViewPool: Set<UIView> = Set<UIView>()
    internal var prevScrollOffset: CGFloat = 0.0
    internal var startOffset: CGFloat = 0.0
    internal var endOffset: CGFloat = 0.0
    internal var scrollDuration: TimeInterval = 0.0
    internal var startTime: TimeInterval = 0.0
    internal var endTime: TimeInterval = 0.0
    internal var lastTime: TimeInterval = 0.0
    internal var decelerating: Bool = false
    internal var decelerationRate: CGFloat = 0.95
    internal var startVelocity: CGFloat = 0.0
    internal var timer: Timer?
    internal var didDrag: Bool = false
    internal var toggleTime: TimeInterval = 0.0
    internal var previousTranslation: CGFloat = 0.0
    
    // Accessible in the class only
    private var panGesture: UIPanGestureRecognizer?
    private var swipeLeftGesture: UISwipeGestureRecognizer?
    private var swipeRightGesture: UISwipeGestureRecognizer?
    private var tapGesture: UITapGestureRecognizer?
    
    // Public functions
    public override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }
    
    convenience init() {
        self.init(frame: CGRect.zero)
    }
    
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        setupView()
        if superview != nil {
            startAnimation()
        }
    }
    
    public func itemView(atIndex index: Int) -> UIView? {
        return itemViews[index]
    }
    
    func setupView() {
        contentView = UIView(frame: bounds)
        contentView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        
        panEnabled = false
        tapEnabled = true
        swipeEnabled = true
        
        accessibilityTraits = UIAccessibilityTraits.allowsDirectInteraction
        isAccessibilityElement = true
        
        addSubview(contentView)
        
        if dataSource != nil {
            reloadData()
        }
    }
    
    func pushAnimationState(enabled: Bool) {
        CATransaction.begin()
        CATransaction.setDisableActions(!enabled)
    }
    
    func popAnimationState() {
        CATransaction.commit()
    }
    
    // MARK: -
    // MARK: View Management
    
    public func indexOfItem(forView view: UIView?) -> Int? {
        
        guard let aView = view else { return nil }
        
        if let index = itemViews.values.firstIndex(of: aView) {
            return itemViews.keys[index]
        }
        
        return nil
    }
    
    func indexOfItem(forViewOrSubView viewOrSubView: UIView) -> Int? {
        if let superview = superview,
            indexOfItem(forView: viewOrSubView) != nil &&
            viewOrSubView != contentView {
            return indexOfItem(forViewOrSubView: superview)
        }
        return nil
    }
    
    func itemView(atPoint point: CGPoint) -> UIView? {
        
        // Sort views in order of depth
        let views = itemViews.values.sorted { (a, b) -> Bool in
            return compare(viewDepth: a, withView: b)
        }
        
        for view in views {
            if view.superview?.layer.hitTest(point) != nil {
                return view
            }
        }
        
        return nil
    }
    
    func setItemView(_ view: UIView?, forIndex index: Int) {
        itemViews[index] = view
    }
    
    internal func removeViewAtIndex(_ index: Int) {
        itemViews.removeValue(forKey: index)
        itemViews = Dictionary(uniqueKeysWithValues:
            itemViews.map { (arg: (key: Int, value: UIView)) -> (key: Int, value: UIView) in
                return (key: arg.key < index ? index : index - 1, value: arg.value)
        })
    }
    
    internal func insertView(_ view: UIView?, atIndex index: Int) {
        
        itemViews = Dictionary(uniqueKeysWithValues:
            itemViews.map { (arg: (key: Int, value: UIView)) -> (key: Int, value: UIView) in
                return (key: arg.key < index ? index : index + 1, value: arg.value)
        })
        
        setItemView(view, forIndex: index)
    }
    
    internal func compare(viewDepth viewA: UIView, withView viewB: UIView) -> Bool {
        
        // Given the set of views, return true if A is behind B or if they are equal, check against C (CurrentView)
        guard let superviewA = viewA.superview else { return false }
        guard let superviewB = viewB.superview else { return false }
        
        let transformA = superviewA.layer.transform
        let transformB = superviewB.layer.transform
        
        let zA = transformA.m13 + transformA.m23 + transformA.m33 + transformA.m43
        let zB = transformB.m13 + transformB.m23 + transformB.m33 + transformB.m43
        
        var diff = zA - zB
        
        if diff == 0.0 {
            let transformCurItem = currentItemView.superview!.layer.transform
            
            let xA = transformA.m11 + transformA.m21 + transformA.m31 + transformA.m41
            let xB = transformB.m11 + transformB.m21 + transformB.m31 + transformB.m41
            let xCurItem = transformCurItem.m11 + transformCurItem.m21 + transformCurItem.m31 + transformCurItem.m41
            
            diff = abs(xB - xCurItem) - abs(xA - xB)
        }
        
        return diff < 0.0
    }
    
    // MARK: -
    // MARK: View Queing
    
    @objc internal func queue(itemView view: UIView) {
        itemViewPool.insert(view)
    }
    
    internal func dequeItemView() -> UIView? {
        if let view = itemViewPool.first {
            itemViewPool.remove(view)
            return view
        }
        
        return nil
    }
    
    // MARK: -
    // MARK: View Indexing
    
    internal func index(forViewOrSuperview view: UIView?) -> Int? {
        guard let aView = view else { return nil }
        guard aView != contentView else { return nil }
        
        if let indexVal = indexOfItem(forView: aView) {
            return indexVal
        }
        
        return index(forViewOrSuperview: aView.superview)
    }
    
    internal func viewOrSuperView(_ view: UIView?, asClass aClass: AnyClass) -> AnyObject? {
        guard let aView = view else { return nil }
        guard aView != contentView else { return nil }
        
        if type(of: aView) == aClass {
            return aView
        }
        
        return viewOrSuperView(aView.superview, asClass: aClass)
    }
    
    // MARK: -
    // MARK: Clamping
    
    internal func clampedOffset(_ offset: CGFloat) -> CGFloat {
        if numberOfItems == 0 {
            return -1.0
        } else if wrapEnabled {
            return offset - floor(offset / CGFloat(numberOfItems)) * CGFloat(numberOfItems)
        }
        
        return min(max(0.0, offset), max(0.0, CGFloat(numberOfItems) - 1.0))
    }
    
    internal func clampedIndex(_ index: Int) -> Int{
        if numberOfItems == 0 {
            return -1
        } else if wrapEnabled {
            return index - Int(floor(CGFloat(index) / CGFloat(numberOfItems))) * numberOfItems
        }
        
        return min(max(0, index), max(0, numberOfItems - 1))
    }
}
