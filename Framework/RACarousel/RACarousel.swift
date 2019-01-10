//
//  RACarousel.swift
//  RACarousel Demo
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

@objc public enum RACarouselOption: Int {
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
}

struct RACarouselConstants {
    static let MaximumVisibleItems: Int         = 50
    static let DecelerationMultiplier: CGFloat  = 60.0
    static let ScrollSpeedThreshold: CGFloat    = 2.0
    static let DecelerateThreshold: CGFloat     = 0.1
    static let ScrollDistanceThreshold: CGFloat = 0.1
    static let ScrollDuration: CGFloat          = 0.4
    static let InsertDuration: CGFloat          = 0.4
    static let MinScale: CGFloat                = 0.75
    static let MaxScale: CGFloat                = 1.1
    
    static let MinToggleDuration: TimeInterval  = 0.2
    static let MaxToggleDuration: TimeInterval  = 0.4
    
    static let FloatErrorMargin: CGFloat        = 0.000001
}

@IBDesignable open class RACarousel: UIView {
    
    // Delegate and Datasource
    private var _delegate: RACarouselDelegate?
    public var delegate: RACarouselDelegate? {
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
    
    private var _dataSource: RACarouselDataSource?
    public var dataSource: RACarouselDataSource? {
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
    private (set) public var numberOfItems: Int = 0
    
    var currentItemIdx: Int {
        get {
            return clampedIndex(Int(round(Float(scrollOffset))))
        }
        set {
            assert(newValue < numberOfItems, "Attempting to set the current item outside the bounds of total items")
            
            scrollOffset = CGFloat(newValue)
        }
    }
    
    // MARK: TODO - Update these to be private
    var scrollEnabled: Bool = true
    var pagingEnabled: Bool = false
    
    @IBInspectable public var wrapEnabled: Bool = true
    @IBInspectable public var bounceEnabled: Bool = true
    
    @IBInspectable public var tapEnabled: Bool {
        get {
            return tapGesture != nil
        }
        
        set {
            if tapGesture != nil, newValue == false {
                contentView.removeGestureRecognizer(tapGesture!)
                tapGesture = nil
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
                if swipeRightGesture != nil {
                    contentView.removeGestureRecognizer(swipeRightGesture!)
                    swipeRightGesture = nil
                }
                
                if swipeLeftGesture != nil {
                    contentView.removeGestureRecognizer(swipeLeftGesture!)
                    swipeLeftGesture = nil
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
            if panGesture != nil, newValue == false {
                contentView.removeGestureRecognizer(panGesture!)
                panGesture = nil
            } else if panGesture == nil && newValue == true {
                panGesture = UIPanGestureRecognizer(target: self, action: #selector(didPan))
                panGesture?.delegate = self as? UIGestureRecognizerDelegate
                contentView.addGestureRecognizer(panGesture!)
            }
        }
    }
    
    private var _scrollOffset: CGFloat = 0.0
    var scrollOffset: CGFloat {
        get {
            return _scrollOffset
        } set {
            scrolling = false
            _decelerating = false
            startOffset = scrollOffset
            endOffset = scrollOffset
            
            if (abs(_scrollOffset - newValue) > 0.0) {
                _scrollOffset = newValue
                depthSortViews()
                didScroll()
            }
        }
    }
    
    private var _contentOffset: CGSize = CGSize.zero
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
    
    private (set) public var viewPointOffset: CGSize = CGSize.zero
    
    // Accessible Variables
    var currentItemView: UIView! {
        get {
            return itemView(atIndex: currentItemIdx)
        }
        set {
            // Do something?
        }
    }
    
    private (set) public var numberOfVisibleItems: Int = 0
    private (set) public var itemWidth: CGFloat = 0.0
    private (set) public var offsetMultiplier: CGFloat = 1.0
    private (set) public var toggle: CGFloat = 0.0
    
    private (set) public var contentView: UIView = UIView()
    
    private (set) public var dragging: Bool = false
    private (set) public var scrolling: Bool = false
    
    // Private variables
    var itemViews: Dictionary<Int, UIView> = Dictionary<Int, UIView>()
    var previousItemIndex: Int = 0
    var itemViewPool: Set<UIView> = Set<UIView>()
    var prevScrollOffset: CGFloat = 0.0
    var startOffset: CGFloat = 0.0
    var endOffset: CGFloat = 0.0
    var _scrollDuration: TimeInterval = 0.0
    var _startTime: TimeInterval = 0.0
    var _endTime: TimeInterval = 0.0
    var _lastTime: TimeInterval = 0.0
    var _decelerating: Bool = false
    var _decelerationRate: CGFloat = 0.95
    var _startVelocity: CGFloat = 0.0
    var _timer: Timer?
    var _didDrag: Bool = false
    var _toggleTime: TimeInterval = 0.0
    var _previousTranslation: CGFloat = 0.0
    
    let decelSpeed: CGFloat = 0.9
    let scrollSpeed: CGFloat = 1.0
    let bounceDist: CGFloat = 1.0
    
    var panGesture: UIPanGestureRecognizer?
    var swipeLeftGesture: UISwipeGestureRecognizer?
    var swipeRightGesture: UISwipeGestureRecognizer?
    var tapGesture: UITapGestureRecognizer?
    
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
        if let _ = self.superview {
            startAnimation()
        }
    }
    
    public func itemView(atIndex index: Int) -> UIView? {
        return itemViews[index]
    }
    
    private func setupView() {
        contentView = UIView(frame: self.bounds)
        contentView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        
        panGesture = UIPanGestureRecognizer(target: self, action: #selector(didPan))
        panGesture?.delegate = self as? UIGestureRecognizerDelegate
        contentView.addGestureRecognizer(panGesture!)
        
        tapGesture = UITapGestureRecognizer(target: self, action: #selector(didTap))
        tapGesture?.delegate = self as? UIGestureRecognizerDelegate
        contentView.addGestureRecognizer(tapGesture!)
        
        swipeLeftGesture = UISwipeGestureRecognizer(target: self, action: #selector(didSwipe))
        swipeLeftGesture?.delegate = self as? UIGestureRecognizerDelegate
        swipeLeftGesture?.direction = .left
        contentView.addGestureRecognizer(swipeLeftGesture!)
        
        swipeRightGesture = UISwipeGestureRecognizer(target: self, action: #selector(didSwipe))
        swipeRightGesture?.delegate = self as? UIGestureRecognizerDelegate
        swipeRightGesture?.direction = .right
        contentView.addGestureRecognizer(swipeRightGesture!)
    
        accessibilityTraits = UIAccessibilityTraits.allowsDirectInteraction
        isAccessibilityElement = true
        
        addSubview(contentView)
        
        if let _ = dataSource {
            reloadData()
        }
    }
    
    private func pushAnimationState(enabled: Bool) {
        CATransaction.begin()
        CATransaction.setDisableActions(!enabled)
    }
    
    private func popAnimationState() {
        CATransaction.commit()
    }
    
    // MARK: -
    // MARK: View Management
    
    private func indexesForVisibleItems() -> [Int] {
        return itemViews.keys.sorted()
    }
    
    public func indexOfItem(forView view: UIView?) -> Int {
        
        guard let aView = view else { return NSNotFound }
        
        if let index = itemViews.values.firstIndex(of: aView) {
            return itemViews.keys[index]
        }
        return NSNotFound
    }
    
    private func indexOfItem(forViewOrSubView viewOrSubView: UIView) -> Int {
        let index = indexOfItem(forView: viewOrSubView)
        if index == NSNotFound && self.superview != nil && viewOrSubView != contentView {
            return indexOfItem(forViewOrSubView: self.superview!)
        }
        return index
    }
    
    private func itemView(atPoint point: CGPoint) -> UIView? {
        
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
    
    private func setItemView(_ view: UIView?, forIndex index: Int) {
        itemViews[index] = view
    }
    
    private func removeViewAtIndex(_ index: Int) {
        itemViews.removeValue(forKey: index)
        itemViews = Dictionary(uniqueKeysWithValues:
            itemViews.map { (arg: (key: Int, value: UIView)) -> (key: Int, value: UIView) in
                return (key: arg.key < index ? index : index - 1, value: arg.value)
            })
    }
    
    private func insertView(_ view: UIView?, atIndex index: Int) {
        
        itemViews = Dictionary(uniqueKeysWithValues:
            itemViews.map { (arg: (key: Int, value: UIView)) -> (key: Int, value: UIView) in
                return (key: arg.key < index ? index : index + 1, value: arg.value)
            })
        
        setItemView(view, forIndex: index)
    }
    
    private func compare(viewDepth viewA: UIView, withView viewB: UIView) -> Bool {

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
    // MARK: View Layout
    
    private func alphaForItem(withOffset offset: CGFloat) -> CGFloat {
        var fadeMin: CGFloat = -CGFloat.infinity
        var fadeMax: CGFloat = CGFloat.infinity
        
        var fadeRange: CGFloat = 1.0
        var fadeMinAlpha: CGFloat = 0.0
        
        fadeMin = value(forOption: RACarouselOption.fadeMin, withDefaultValue: fadeMin)
        fadeMax = value(forOption: RACarouselOption.fadeMin, withDefaultValue: fadeMax)
        fadeRange = value(forOption: RACarouselOption.fadeMin, withDefaultValue: fadeRange)
        fadeMinAlpha = value(forOption: RACarouselOption.fadeMin, withDefaultValue: fadeMinAlpha)
        
        var factor: CGFloat = 0.0
        if offset > fadeMax {
            factor = offset - fadeMax
        } else if offset < fadeMin {
            factor = fadeMin - offset
        }
        
        return CGFloat(1.0 - min(factor, fadeRange) / fadeRange * (1.0 - fadeMinAlpha))
    }
    
    private func value<T>(forOption option: RACarouselOption, withDefaultValue defaultValue: T) -> T {
        return _delegate?.carousel(self, valueForOption: option, withDefaultValue: defaultValue) ?? defaultValue
    }
    
    private func transformForItemView(withOffset offset: CGFloat) -> CATransform3D {
        var transform: CATransform3D = CATransform3DIdentity
        //transform.m34 = _perspective
        
        transform = CATransform3DTranslate(transform,
                                           -viewPointOffset.width,
                                           -viewPointOffset.height, 0)
        
        let spacing = value(forOption: .spacing, withDefaultValue: CGFloat(1.0))
        transform = CATransform3DTranslate(transform, offset * itemWidth * spacing, 0.0, 0.0)
        
        let scale = max(RACarouselConstants.MinScale, RACarouselConstants.MaxScale - abs(offset * 0.25))
        
        transform = CATransform3DScale(transform, scale, scale, 1.0)
        
        return transform
    }
    
    @objc private func depthSortViews() {
        let views = itemViews.values.sorted { (a, b) -> Bool in
            return compare(viewDepth: a, withView: b)
        }
        
        for view in views {
            contentView.bringSubviewToFront(view)
        }
    }
    
    private func offsetForItem(atIndex index: Int) -> CGFloat {
        var offset: CGFloat = CGFloat(index) - _scrollOffset
        if wrapEnabled {
            if offset > (CGFloat(numberOfItems) / 2.0) {
                offset = offset - CGFloat(numberOfItems)
            } else if offset < -CGFloat(numberOfItems) / 2.0 {
                offset = offset + CGFloat(numberOfItems)
            }
        }
        
        return offset
    }
    
    private func containView(inView view: UIView) -> UIView {
        if itemWidth == 0.0 {
            itemWidth = view.bounds.size.width
        }
        
        var frame = view.bounds
        frame.size.width = itemWidth
        
        let containerView = UIView(frame: frame)
        
        frame = view.frame
        
        frame.origin.x = (containerView.bounds.size.width - frame.size.width) / 2.0
        frame.origin.y = (containerView.bounds.size.height - frame.size.height) / 2.0
        
        view.frame = frame
        containerView.addSubview(view)
        containerView.layer.opacity = 0
        
        return containerView
    }
    
    private func transform(itemView view: UIView, atIndex index: Int) {
        let offset: CGFloat = offsetForItem(atIndex: index)
        
        // Update Alpha
        view.superview?.layer.opacity = Float(alphaForItem(withOffset: offset))
        
        // Center
        view.superview?.center = CGPoint(x: bounds.size.width/2.0 + contentOffset.width,
                                        y: bounds.size.height/2.0 + contentOffset.height)
        
        // Enable/Disable interaction
        view.superview?.isUserInteractionEnabled = (index == currentItemIdx)
        
        // Account for retina
        view.superview?.layer.rasterizationScale = UIScreen.main.scale
        
        layoutIfNeeded()
        
        let transform: CATransform3D = transformForItemView(withOffset: offset)
        view.superview?.layer.transform = transform
        
        // Cull backfaces
        let showBackfaces = value(forOption: .showBackfaces,
                                  withDefaultValue: view.layer.isDoubleSided)
        
        view.superview?.isHidden = !(showBackfaces ? showBackfaces : (transform.m33 > 0.0))
    }
    
    open override func layoutSubviews() {
        super.layoutSubviews()
        contentView.frame = bounds
        layoutItemViews()
    }
    
    private func transformItemViews() {
        for index in itemViews.keys {
            transform(itemView: itemViews[index]!, atIndex: index)
        }
    }
    
    private func updateItemWidth() {
        itemWidth = value(forOption: .itemWidth, withDefaultValue: itemWidth)
        if numberOfItems > 0 {
            if itemViews.count == 0 {
                loadView(atIndex: 0)
            }
        }
    }
    
    private func updateNumberOfVisibleItems() {
        let spacing: CGFloat = value(forOption: .spacing, withDefaultValue: 1.0)
        let width: CGFloat = self.bounds.size.width
        let itemWidthWithSpacing = itemWidth * spacing
        
        numberOfVisibleItems = Int(ceil(width / itemWidthWithSpacing)) + 2
        numberOfVisibleItems = min(RACarouselConstants.MaximumVisibleItems, numberOfVisibleItems)
        numberOfVisibleItems = value(forOption: .visibleItems, withDefaultValue: numberOfVisibleItems)
    }
    
    private func layoutItemViews() {
        guard let _ = _dataSource else { return }
        
        wrapEnabled = value(forOption: RACarouselOption.wrap, withDefaultValue: wrapEnabled)
        
        updateItemWidth()
        updateNumberOfVisibleItems()
        
        prevScrollOffset = scrollOffset
        offsetMultiplier = value(forOption: RACarouselOption.offsetMultiplier, withDefaultValue: 1.0)
        
        if scrolling == false && _decelerating == false {
            if currentItemIdx != -1 {
                scroll(toItemAtIndex: currentItemIdx, animated: true)
            } else {
                scrollOffset = clampedOffset(scrollOffset)
            }
        }
     
        didScroll()
    }
    
    // MARK: -
    // MARK: View Loading
    @discardableResult private func loadView(atIndex index: Int, withContainerView containerView: UIView?) -> UIView {
        pushAnimationState(enabled: false)
        
        var view: UIView? = nil
        
        view = dataSource?.carousel(self, viewForItemAt: IndexPath(item: index, section: 0), reuseView: dequeItemView())
        
        if view == nil {
            view = UIView()
        }
        
        setItemView(view!, forIndex: index)
        if let aContainerView = containerView {
            if let oldItemView: UIView = aContainerView.subviews.last {
                queue(itemView: oldItemView)
                var frame = aContainerView.frame
                
                frame.size.width = min(itemWidth, view!.frame.size.width)
                frame.size.height = view!.frame.size.height
                
                aContainerView.bounds = frame
                
                frame = view!.frame
                frame.origin.x = (aContainerView.bounds.size.width - frame.size.width) / 2.0
                frame.origin.y = (aContainerView.bounds.size.height - frame.size.height) / 2.0
                view!.frame = frame
                
                oldItemView.removeFromSuperview()
                aContainerView.addSubview(view!)
            }
        } else {
            contentView.addSubview(containView(inView: view!))
        }
        
        view!.superview?.layer.opacity = 0.0
        transform(itemView: view!, atIndex: index)
        popAnimationState()
        
        return view!
    }
    
    @discardableResult private func loadView(atIndex index: Int) -> UIView {
        return loadView(atIndex: index, withContainerView: nil)
    }
    
    private func loadUnloadViews() {
        updateItemWidth()
        updateNumberOfVisibleItems()
        
        var visibleIndices = Set<Int>(minimumCapacity: numberOfVisibleItems)
        let minVal: Int = 0
        let maxVal: Int = numberOfItems - 1
        var intOffset: Int = currentItemIdx - numberOfVisibleItems / 2
        
        if !wrapEnabled {
            intOffset = max(minVal, min(maxVal - numberOfVisibleItems + 1, intOffset))
        }
        
        // Check all visible items
        for i in 0..<numberOfVisibleItems {
            var index: Int = i + intOffset
            if wrapEnabled {
                index = clampedIndex(index)
            }
            
            let alpha: CGFloat = alphaForItem(withOffset: offsetForItem(atIndex: index))
            if alpha != 0.0 {
                visibleIndices.insert(index)
            }
        }
        
        // Filter if offscreen
        itemViews = itemViews.filter({ (arg: (key: Int, view: UIView)) -> Bool in
            if !visibleIndices.contains(arg.key) {
                queue(itemView: arg.view)
                arg.view.superview?.removeFromSuperview()
                return false
            }
            return true
        })
        
        visibleIndices.forEach { (index) in
            if itemViews[index] == nil {
                loadView(atIndex: index)
            }
        }
    }
    
    public func reloadData() {
        for view in itemViews.values {
            view.superview?.removeFromSuperview()
        }
        
        guard let _ = dataSource else { return }
        
        numberOfVisibleItems = 0
        numberOfItems = dataSource!.numberOfItems(inCarousel: self)
        
        itemViews = Dictionary<Int, UIView>()
        itemViewPool = Set<UIView>()
        
        setNeedsLayout()
        
        if numberOfItems > 0 {
            scroll(toItemAtIndex: dataSource!.startingItemIndex(inCarousel: self), animated: false)
        }
    }
    
    // MARK: -
    // MARK: View Queing
    @objc private func queue(itemView view: UIView) {
        itemViewPool.insert(view)
    }
    
    private func dequeItemView() -> UIView? {
        if let view = itemViewPool.first {
            itemViewPool.remove(view)
            return view
        }
        
        return nil
    }
    
    // MARK: -
    // MARK: Scrolling
    private func clampedOffset(_ offset: CGFloat) -> CGFloat {
        if numberOfItems == 0 {
            return -1.0
        } else if wrapEnabled {
            return offset - floor(offset / CGFloat(numberOfItems)) * CGFloat(numberOfItems)
        }
        
        return min(max(0.0, offset), max(0.0, CGFloat(numberOfItems) - 1.0))
    }
    
    private func clampedIndex(_ index: Int) -> Int{
        if numberOfItems == 0 {
            return -1
        } else if wrapEnabled {
            return index - Int(floor(CGFloat(index) / CGFloat(numberOfItems))) * numberOfItems
        }
        
        return min(max(0, index), max(0, numberOfItems - 1))
    }
    
    private func minScrollDistance(fromIndex from: Int, toIndex to: Int) -> Int {
        // Work out the distance between the two, relative to the whether we are wrapping the carousel
        let directDistance = to - from
        
        if wrapEnabled {
            var wrappedDistance = min(to, from) + numberOfItems - max(to, from)
            if (from < to) {
                wrappedDistance = -wrappedDistance
            }
            
            return (abs(directDistance) <= abs(wrappedDistance)) ? directDistance : wrappedDistance
        }
        
        return directDistance
    }
    
    private func minScrollDistance(fromOffset from: CGFloat, toOffset to: CGFloat) -> CGFloat {
        let directDistance = to - from
        if wrapEnabled {
            var wrappedDistance = min(to, from) + CGFloat(numberOfItems) - max(to, from)
            if from < to {
                wrappedDistance = -wrappedDistance
            }
            
            return (abs(directDistance) <= abs(wrappedDistance)) ? directDistance : wrappedDistance
        }
        
        return directDistance
    }
    
    public func scroll(byOffset offset: CGFloat, withDuration duration: TimeInterval) {
        if duration > 0.0 {
            _decelerating = false
            scrolling = true
            
            _startTime = CACurrentMediaTime()
            
            startOffset = _scrollOffset
            endOffset = startOffset + offset
            
            _scrollDuration = duration
            if !wrapEnabled {
                endOffset = clampedOffset(endOffset)
            }
            
            delegate?.carouselWillBeginScrolling(self)
            startAnimation()
            
        } else {
            scrollOffset += offset
        }
    }
    
    public func scroll(toOffset offset: CGFloat, withDuration duration: TimeInterval) {
        scroll(byOffset: minScrollDistance(fromOffset: scrollOffset, toOffset: offset), withDuration: duration)
    }
    
    public func scroll(byNumberOfItems itemCount: Int, withDuration duration: TimeInterval) {
        if duration > 0.0 {
            var offset: CGFloat = 0.0
            if itemCount > 0 {
                offset = (floor(_scrollOffset)) + CGFloat(itemCount) - _scrollOffset
            } else if itemCount < 0 {
                offset = (ceil(_scrollOffset) + CGFloat(itemCount)) - scrollOffset
            } else {
                offset = round(_scrollOffset) - scrollOffset
            }
            
            scroll(byOffset: offset, withDuration: duration)
        } else {
          scrollOffset = CGFloat(clampedIndex(previousItemIndex + itemCount))
        }
    }
    
    public func scroll(toItemAtIndex index: Int, withDuration duration: TimeInterval) {
        delegate?.carousel(self, willBeginScrollingToIndex: index)
        scroll(toOffset: CGFloat(index), withDuration: duration)
    }
    
    public func scroll(toItemAtIndex index: Int, animated: Bool) {
        scroll(toItemAtIndex: index, withDuration: animated ? TimeInterval(RACarouselConstants.ScrollDuration) : 0.0)
    }
    
    public func removeItem(atIndex index: Int, animated: Bool) {
        let removeIndex = clampedIndex(index)
        guard let view = itemView(atIndex: removeIndex) else { return }
        
        if animated {
            UIView.beginAnimations(nil, context: nil)
            UIView.setAnimationDuration(0.1)
            UIView.setAnimationDelegate(view.superview)
            UIView.setAnimationDidStop(#selector(removeFromSuperview))
            
            NSObject.perform(#selector(queue(itemView:)), with: view, afterDelay: 0.1, inModes: [RunLoop.Mode.common])
            
            view.superview?.layer.opacity = 0.0
            
            UIView.commitAnimations()
            
            UIView.beginAnimations(nil, context: nil)
            UIView.setAnimationDelay(0.1)
            UIView.setAnimationDuration(TimeInterval(RACarouselConstants.InsertDuration))
            UIView.setAnimationDelegate(self)
            UIView.setAnimationDidStop(#selector(depthSortViews))
            
            removeViewAtIndex(removeIndex)
            numberOfItems = numberOfItems - 1
            wrapEnabled = value(forOption: RACarouselOption.wrap, withDefaultValue: wrapEnabled)
            
            updateNumberOfVisibleItems()
            scrollOffset = CGFloat(currentItemIdx)
            didScroll()
            
            UIView.commitAnimations()
        } else {
            pushAnimationState(enabled: false)
            queue(itemView: view)
            view.superview?.removeFromSuperview()
            removeViewAtIndex(removeIndex)
            numberOfItems = numberOfItems - 1
            wrapEnabled = value(forOption: RACarouselOption.wrap, withDefaultValue: wrapEnabled)
            scrollOffset = CGFloat(currentItemIdx)
            didScroll()
            depthSortViews()
            popAnimationState()
        }
    }
    
    public func insertItem(atIndex index: Int, _ animated: Bool) {
        numberOfItems = numberOfItems + 1
        wrapEnabled = value(forOption: RACarouselOption.wrap, withDefaultValue: wrapEnabled)
        updateNumberOfVisibleItems()
        
        let insert = clampedIndex(index)
        insertView(nil, atIndex: insert)
        loadView(atIndex: insert)
        
        if abs(itemWidth) < RACarouselConstants.FloatErrorMargin {
            updateItemWidth()
        }
        
        if animated {
            UIView.beginAnimations(nil, context: nil)
            UIView.setAnimationDuration(TimeInterval(RACarouselConstants.InsertDuration))
            UIView.setAnimationDelegate(self)
            UIView.setAnimationDidStop(#selector(didScroll))
            transformItemViews()
            UIView.commitAnimations()
        } else {
            pushAnimationState(enabled: false)
            didScroll()
            popAnimationState()
        }
        
        if scrollOffset > 0.0 {
            scroll(toItemAtIndex: 0, animated: animated)
        }
    }
    
    func reloadItem(atIndex index: Int, animated: Bool) {
        if let containerView = itemView(atIndex: index)?.superview {
            if animated {
                let transition = CATransition.init()
                transition.duration = TimeInterval(RACarouselConstants.InsertDuration)
                transition.timingFunction = CAMediaTimingFunction(name:
                    CAMediaTimingFunctionName.easeInEaseOut)
                transition.type = CATransitionType.push
                containerView.layer.add(transition, forKey: nil)
            }
            
            loadView(atIndex: index, withContainerView: containerView)
        }
    }
    
    // MARK: -
    // MARK: Animation
    private func startAnimation() {
        if _timer == nil {
            _timer = Timer(timeInterval: 1.0/60.0, target: self, selector: #selector(step), userInfo: nil, repeats: true)
            
            RunLoop.main.add(_timer!, forMode: RunLoop.Mode.default)
        }
    }
    
    private func stopAnimation() {
        _timer?.invalidate()
        _timer = nil
    }
    
    private func decelerationDistance() -> CGFloat {
        let acceleration: CGFloat = -_startVelocity * RACarouselConstants.DecelerationMultiplier * (1.0 - _decelerationRate)
        
        return -pow(_startVelocity, 2.0) / (2.0 * acceleration)
    }
    
    private func shouldDecelerate() -> Bool {
        return (abs(_startVelocity) > RACarouselConstants.ScrollSpeedThreshold) &&
                (abs(decelerationDistance()) > RACarouselConstants.DecelerateThreshold)
    }
    
    private func shouldScroll() -> Bool {
        return (abs(_startVelocity) > RACarouselConstants.ScrollSpeedThreshold) &&
                (abs(_scrollOffset - CGFloat(currentItemIdx)) > RACarouselConstants.ScrollDistanceThreshold)
    }
    
    private func startDecelerating() {
        var distance: CGFloat = decelerationDistance()
        startOffset = _scrollOffset
        endOffset = startOffset + distance
        
        if !wrapEnabled {
            if bounceEnabled {
                endOffset = max(-bounceDist, min(CGFloat(numberOfItems) - 1.0 + bounceDist, endOffset))
            } else {
                endOffset = clampedOffset(endOffset)
            }
        }
        
        distance = endOffset - startOffset
        
        _startTime = CACurrentMediaTime()
        _scrollDuration = TimeInterval(abs(distance) / abs(0.5 * _startVelocity))
        
        if distance != 0.0 {
            _decelerating = true
            startAnimation()
        }
    }
    
    private func easeInOut(inTime time: CGFloat) -> CGFloat {
        return (time < 0.5) ? 0.5 * pow(time * 2.0, 3.0) : 0.5 * pow(time * 2.0 - 2.0, 3.0) + 1.0
    }
    
    @objc private func step() {
        pushAnimationState(enabled: false)
        
        let currentTime: TimeInterval = CACurrentMediaTime()
        var delta: CGFloat = CGFloat(currentTime - _lastTime)
        
        _lastTime = currentTime
        
        if scrolling && !dragging {
            let time: TimeInterval = min(1.0, (currentTime - _startTime) / _scrollDuration)
            delta = easeInOut(inTime: CGFloat(time))
            
            _scrollOffset = startOffset + (endOffset - startOffset) * delta
            didScroll()
            
            if time >= 1.0 {
                scrolling = false
                depthSortViews()
                pushAnimationState(enabled: true)
                //delegate?.carousel(self, didEndScrollingToIndex: destIndex)
                delegate?.carouselDidEndScrolling(self)
                popAnimationState()
            }
        } else if _decelerating {
            
            let time: CGFloat = CGFloat(min(_scrollDuration, currentTime - _startTime))
            let acceleration: CGFloat = -_startVelocity / CGFloat(_scrollDuration)
            let distance: CGFloat = _startVelocity * time + 0.5 * acceleration * pow(time, 2.0)
            
            _scrollOffset = startOffset + distance
            didScroll()
            
            if abs(time - CGFloat(_scrollDuration)) < RACarouselConstants.FloatErrorMargin {
                
                _decelerating = false
                pushAnimationState(enabled: true)
                //delegate?.didEndDecelerating(self)
                popAnimationState()
                
                if abs(_scrollOffset - clampedOffset(_scrollOffset)) > RACarouselConstants.FloatErrorMargin {
                    if abs(_scrollOffset - CGFloat(currentItemIdx)) < RACarouselConstants.FloatErrorMargin {
                        scroll(toItemAtIndex: currentItemIdx, withDuration: 0.01)
                    } else {
                        scroll(toItemAtIndex: currentItemIdx, animated: true)
                    }
                    
                } else {
                    var difference:CGFloat = round(_scrollOffset) - _scrollOffset
                    if difference > 0.5 {
                        difference = difference - 1.0
                    } else if difference < -0.5 {
                        difference = 1.0 + difference
                    }
                    
                    _toggleTime = currentTime - Double(RACarouselConstants.MaxToggleDuration) * Double(abs(difference))
                    toggle = max(-1.0, min(1.0, -difference))
                    
                    scroll(toItemAtIndex: Int(round(CGFloat(currentItemIdx) + difference)), animated: true)
                }
            }
        } else if abs(toggle) > RACarouselConstants.FloatErrorMargin {
            var toggleDuration: TimeInterval = _startVelocity != 0.0 ? TimeInterval(min(1.0, max(0.0, 1.0 / abs(_startVelocity)))) : 1.0
            toggleDuration = RACarouselConstants.MinToggleDuration + (RACarouselConstants.MaxToggleDuration - RACarouselConstants.MinToggleDuration) * toggleDuration
            
            let time: TimeInterval = min(1.0, (currentTime - _toggleTime) / toggleDuration)
            delta = easeInOut(inTime: CGFloat(time))
            
            toggle = (toggle < 0.0) ? (delta - 1.0) : (1.0 - delta)
            didScroll()
        } else {
            stopAnimation()
        }
        
        popAnimationState()
    }
    
    override open func didMoveToSuperview() {
        if let _ = superview {
            startAnimation()
        } else {
            stopAnimation()
        }
    }
    
    @objc private func didScroll() {
        if wrapEnabled || !bounceEnabled {
            _scrollOffset = clampedOffset(_scrollOffset)
        } else {
            let minVal: CGFloat = -bounceDist
            let maxVal: CGFloat = max(CGFloat(numberOfItems) - 1.0, 0.0) + bounceDist
            
            if _scrollOffset < minVal {
                _scrollOffset = minVal
                _startVelocity = 0.0
            } else if _scrollOffset > maxVal {
                _scrollOffset = maxVal
                _startVelocity = 0.0
            }
        }
        
        let difference = minScrollDistance(fromIndex: currentItemIdx, toIndex: previousItemIndex)
        
        if difference != 0 {
            _toggleTime = CACurrentMediaTime()
            toggle = max(-1.0, min(1.0, CGFloat(difference)))
            startAnimation()
        }
        
        loadUnloadViews()
        transformItemViews()
        
        if abs(_scrollOffset - prevScrollOffset) > RACarouselConstants.FloatErrorMargin {
            pushAnimationState(enabled: true)
            //delegate?.carouselDidScroll(self)
            popAnimationState()
        }
        
        // Notify of change of item
        if previousItemIndex != currentItemIdx {
            pushAnimationState(enabled: true)
            delegate?.carousel(self, currentItemDidChangeToIndex: currentItemIdx)
            popAnimationState()
        }
        
        prevScrollOffset = _scrollOffset
        previousItemIndex = currentItemIdx
    }
    
    // MARK: -
    // MARK: Gestures
    
    private func index(forViewOrSuperview view: UIView?) -> Int {
        guard let aView = view else { return NSNotFound }
        guard aView != contentView else { return NSNotFound }
        
        let indexVal: Int = indexOfItem(forView: aView)
        if indexVal == NSNotFound {
            return index(forViewOrSuperview: aView.superview)
        }
        
        return indexVal
    }
    
    private func viewOrSuperView(_ view: UIView?, asClass aClass: AnyClass) -> AnyObject? {
        guard let aView = view else { return nil }
        guard aView != contentView else { return nil }
        
        if type(of: aView) == aClass {
            return aView
        }
        
        return viewOrSuperView(aView.superview, asClass: aClass)
    }
    
    func gestureRecognizer(_ gesture: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        dragging = false
        scrolling = false
        _decelerating = false
        
        if gesture is UITapGestureRecognizer {
            var indexVal = index(forViewOrSuperview: touch.view)
            if indexVal == NSNotFound {
               indexVal = index(forViewOrSuperview: touch.view?.subviews.last)
            }
            
            if indexVal != NSNotFound {
                if touch.view!.overrides(#selector(touchesBegan(_:with:))) {
                    return false
                }
            }
        } else if gesture is UIPanGestureRecognizer {
            if touch.view!.overrides(#selector(touchesMoved(_:with:))) {
                if let scrollView = viewOrSuperView(touch.view, asClass: UIScrollView.self) as? UIScrollView {
                    return !scrollView.isScrollEnabled ||
                        (scrollView.contentSize.width <= scrollView.frame.size.width)
                }
                
                if viewOrSuperView(touch.view, asClass: UIButton.self) != nil ||
                    viewOrSuperView(touch.view, asClass: UIBarButtonItem.self) != nil {
                    return true
                }
                return false
            }
        }
        
        return true
    }
    
    override open func gestureRecognizerShouldBegin(_ gesture: UIGestureRecognizer) -> Bool {
        if let panGesture = gesture as? UIPanGestureRecognizer {
            let translation = panGesture.translation(in: self)
            return abs(translation.x) >= abs(translation.y)
        }
        
        return true
    }
    
    @objc private func didTap(withGesture gesture: UITapGestureRecognizer) {
        let itemViewAtPoint: UIView? = itemView(atPoint: gesture.location(in: contentView))
        let index = indexOfItem(forView: itemViewAtPoint)
        if index != NSNotFound {
            let shouldSelect = delegate?.carousel(self, shouldSelectItemAtIndex: index) ?? true
            if shouldSelect {
                if index != currentItemIdx {
                    scroll(toItemAtIndex: index, animated: true)
                }
                delegate?.carousel(self, didSelectItemAtIndex: index)
            }
        } else {
            scroll(toItemAtIndex: currentItemIdx, animated: true)
        }
    }
    
    @objc private func didPan(withGesture gesture: UIPanGestureRecognizer) {
        if scrollEnabled && numberOfItems > 0 {
            switch gesture.state {
            case .began:
                dragging = true
                scrolling = false
                _decelerating = false
                _previousTranslation = gesture.translation(in: self).x
                //delegate?.carouselWillBeginDragging(self)
            case .ended, .cancelled, .failed:
                dragging = false
                _didDrag = true
                if shouldDecelerate() {
                    _didDrag = false
                    startDecelerating()
                }
                
                pushAnimationState(enabled: true)
                //delegate?.carouselDidEndDragging(self)
                popAnimationState()
                
                if !_decelerating {
                    if abs(_scrollOffset - clampedOffset(_scrollOffset)) > RACarouselConstants.FloatErrorMargin {
                        if abs(scrollOffset - CGFloat(currentItemIdx)) < RACarouselConstants.FloatErrorMargin {
                            scroll(toItemAtIndex: currentItemIdx, withDuration: 0.01)
                        }
                    } else if shouldScroll() {
                        let direction: Int = Int(_startVelocity / abs(_startVelocity))
                        scroll(toItemAtIndex: currentItemIdx + direction, animated: true)
                    } else {
                        scroll(toItemAtIndex: currentItemIdx, animated: true)
                    }
                } else {
                    depthSortViews()
                }
            case .changed:
                let translation: CGFloat = gesture.translation(in: self).x
                let velocity: CGFloat = gesture.velocity(in: self).x
                
                var factor: CGFloat = 1.0
                
                if !wrapEnabled && bounceEnabled {
                    factor = 1.0 - min (abs(_scrollOffset - clampedOffset(_scrollOffset)), bounceDist) / bounceDist
                }
                
                _startVelocity = -velocity * factor * scrollSpeed / (CGFloat(itemWidth))
                _scrollOffset = _scrollOffset - ((translation - _previousTranslation) * factor * offsetMultiplier / itemWidth)
                _previousTranslation = translation
                didScroll()
            case .possible:
                // Do nothing
                break
            }
        }
    }
    
    @objc private func didSwipe(withGesture gesture: UISwipeGestureRecognizer) {
        print ("Swipe Detected")
        
        guard scrollEnabled && numberOfItems > 1 else { return }
        guard scrolling == false && _decelerating == false else { return }
        
        switch gesture.direction {
        case UISwipeGestureRecognizer.Direction.right:
            guard currentItemIdx > 0 else { return }
            print ("Will swipe - Right")
            
            scroll(toItemAtIndex: currentItemIdx - 1, animated: true)
            
        case UISwipeGestureRecognizer.Direction.left:
            guard currentItemIdx < numberOfItems - 1 else { return }
            print ("Will swipe - Left")
            
            scroll(toItemAtIndex: currentItemIdx + 1, animated: true)
        default:
            // Do nothing
            break
        }
    }
}
