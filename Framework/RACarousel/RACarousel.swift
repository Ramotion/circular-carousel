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
    case arc
    case angle
    case radius
    case tilt
    case spacing
    case fadeMin
    case fadeMax
    case fadeRange
    case fadeMinAlpha
    case offsetMultiplier
}

open class RACarousel : UIView {
    
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
    
    // Delegate and Datasource
    private weak var _delegate: RACarouselDelegate?
    @IBOutlet public var delegate: RACarouselDelegate? {
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
    
    private weak var _dataSource: RACarouselDataSource?
    @IBOutlet public var dataSource: RACarouselDataSource? {
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
    var wrapEnabled: Bool = true
    var bounceEnabled: Bool = true
    
    public var tapEnabled: Bool {
        get {
            return _tapGesture != nil
        }
        
        set {
            if let tapGesture = _tapGesture, newValue == false {
                contentView.removeGestureRecognizer(tapGesture)
                _tapGesture = nil
            } else if _tapGesture == nil && newValue == true {
                _tapGesture = UITapGestureRecognizer(target: self, action: #selector(didTap))
                _tapGesture?.delegate = self as? UIGestureRecognizerDelegate
                contentView.addGestureRecognizer(_tapGesture!)
            }
        }
    }
    
    public var swipeEnabled: Bool {
        get {
            return _swipeLeftGesture != nil && _swipeRightGesture != nil
        }
        
        set {
            if newValue == false {
                if let swipeRightGesture = _swipeRightGesture {
                    contentView.removeGestureRecognizer(swipeRightGesture)
                    _swipeRightGesture = nil
                }
                
                if let swipeLeftGesture = _swipeLeftGesture {
                    contentView.removeGestureRecognizer(swipeLeftGesture)
                    _swipeRightGesture = nil
                }
                
            } else if _swipeLeftGesture == nil && _swipeRightGesture == nil && newValue == true {
                _swipeLeftGesture = UISwipeGestureRecognizer(target: self, action: #selector(didSwipe))
                _swipeLeftGesture?.direction = .left
                _swipeLeftGesture?.delegate = self as? UIGestureRecognizerDelegate
                contentView.addGestureRecognizer(_swipeLeftGesture!)
                
                _swipeRightGesture = UISwipeGestureRecognizer(target: self, action: #selector(didSwipe))
                _swipeRightGesture?.direction = .right
                _swipeRightGesture?.delegate = self as? UIGestureRecognizerDelegate
                contentView.addGestureRecognizer(_swipeRightGesture!)
            }
        }
    }
    
    public var panEnabled: Bool {
        get {
            return _panGesture != nil
        }
        
        set {
            if let panGesture = _panGesture, newValue == false {
                contentView.removeGestureRecognizer(panGesture)
                _panGesture = nil
            } else if _panGesture == nil && newValue == true {
                _panGesture = UIPanGestureRecognizer(target: self, action: #selector(didPan))
                _panGesture?.delegate = self as? UIGestureRecognizerDelegate
                contentView.addGestureRecognizer(_panGesture!)
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
            _startOffset = scrollOffset
            _endOffset = scrollOffset
            
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
    
    private var _viewPointOffset: CGSize = CGSize.zero
    var viewPointOffset: CGSize {
        get {
            return _viewPointOffset
        }
        set {
            
        }
    }
    
    // Accessible Variables
    var currentItemView: UIView! {
        get {
            return itemView(atIndex: currentItemIdx)
        }
        set {
            // Do something?
        }
    }
    
    private (set) var numberOfVisibleItems: Int = 0
    private (set) var itemWidth: CGFloat = 0.0
    private (set) var offsetMultiplier: CGFloat = 1.0
    private (set) var toggle: CGFloat = 0.0
    
    private (set) var contentView: UIView = UIView()
    
    private (set) var dragging: Bool = false
    private (set) var scrolling: Bool = false
    
    // Private variables
    private var _itemViews: Dictionary<Int, UIView> = Dictionary<Int, UIView>()
    private var _previousItemIndex: Int = 0
    private var _itemViewPool: Set<UIView> = Set<UIView>()
    private var _prevScrollOffset: CGFloat = 0.0
    private var _startOffset: CGFloat = 0.0
    private var _endOffset: CGFloat = 0.0
    private var _scrollDuration: TimeInterval = 0.0
    private var _startTime: TimeInterval = 0.0
    private var _endTime: TimeInterval = 0.0
    private var _lastTime: TimeInterval = 0.0
    private var _decelerating: Bool = false
    private var _decelerationRate: CGFloat = 0.95
    private var _startVelocity: CGFloat = 0.0
    private var _timer: Timer?
    private var _didDrag: Bool = false
    private var _toggleTime: TimeInterval = 0.0
    private var _previousTranslation: CGFloat = 0.0
    
    private let _decelSpeed: CGFloat = 0.9
    private let _scrollSpeed: CGFloat = 1.0
    private let _bounceDist: CGFloat = 1.0
    
    private var _panGesture: UIPanGestureRecognizer?
    private var _swipeLeftGesture: UISwipeGestureRecognizer?
    private var _swipeRightGesture: UISwipeGestureRecognizer?
    private var _tapGesture: UITapGestureRecognizer?
    
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
    
    deinit {
        
    }
    
    public func itemView(atIndex index: Int) -> UIView? {
        return _itemViews[index]
    }
    
    private func setupView() {
        contentView = UIView(frame: self.bounds)
        contentView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        
        _panGesture = UIPanGestureRecognizer(target: self, action: #selector(didPan))
        _panGesture?.delegate = self as? UIGestureRecognizerDelegate
        contentView.addGestureRecognizer(_panGesture!)
        
        _tapGesture = UITapGestureRecognizer(target: self, action: #selector(didTap))
        _tapGesture?.delegate = self as? UIGestureRecognizerDelegate
        contentView.addGestureRecognizer(_tapGesture!)
        
        _swipeLeftGesture = UISwipeGestureRecognizer(target: self, action: #selector(didSwipe))
        _swipeLeftGesture?.delegate = self as? UIGestureRecognizerDelegate
        _swipeLeftGesture?.direction = .left
        contentView.addGestureRecognizer(_swipeLeftGesture!)
        
        _swipeRightGesture = UISwipeGestureRecognizer(target: self, action: #selector(didSwipe))
        _swipeRightGesture?.delegate = self as? UIGestureRecognizerDelegate
        _swipeRightGesture?.direction = .right
        contentView.addGestureRecognizer(_swipeRightGesture!)
    
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
        return _itemViews.keys.sorted()
    }
    
    public func indexOfItem(forView view: UIView?) -> Int {
        
        guard let aView = view else { return NSNotFound }
        
        if let index = _itemViews.values.firstIndex(of: aView) {
            return _itemViews.keys[index]
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
        let views = _itemViews.values.sorted { (a, b) -> Bool in
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
        _itemViews[index] = view
    }
    
    private func removeViewAtIndex(_ index: Int) {
        _itemViews.removeValue(forKey: index)
        _itemViews = Dictionary(uniqueKeysWithValues:
            _itemViews.map { (arg: (key: Int, value: UIView)) -> (key: Int, value: UIView) in
                return (key: arg.key < index ? index : index - 1, value: arg.value)
            })
    }
    
    private func insertView(_ view: UIView?, atIndex index: Int) {
        
        _itemViews = Dictionary(uniqueKeysWithValues:
            _itemViews.map { (arg: (key: Int, value: UIView)) -> (key: Int, value: UIView) in
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
    
    private func value(forOption option: RACarouselOption, withDefaultValue defaultValue: CGFloat) -> CGFloat {
        
        return _delegate?.carousel?(self, valueForOption: option, withDefaultFloat: defaultValue) ?? defaultValue
    }
    
    private func value(forOption option: RACarouselOption, withDefaultValue defaultValue: Bool) -> Bool {
        return _delegate?.carousel?(self, valueForOption: option, withDefaultBool: defaultValue) ?? defaultValue
    }
    
    private func value(forOption option: RACarouselOption, withDefaultValue defaultValue: Int) -> Int {
        return _delegate?.carousel?(self, valueForOption: option, withDefaultInt: defaultValue) ?? defaultValue
    }
    
    private func transformForItemView(withOffset offset: CGFloat) -> CATransform3D {
        var transform: CATransform3D = CATransform3DIdentity
        //transform.m34 = _perspective
        
        transform = CATransform3DTranslate(transform,
                                           -_viewPointOffset.width,
                                           -_viewPointOffset.height, 0)
        
        let spacing = value(forOption: .spacing, withDefaultValue: CGFloat(1.0))
        transform = CATransform3DTranslate(transform, offset * itemWidth * spacing, 0.0, 0.0)
        
        let scale = max(RACarousel.MinScale, RACarousel.MaxScale - abs(offset * 0.25))
        
        transform = CATransform3DScale(transform, scale, scale, 1.0)
        
        return transform
    }
    
    @objc private func depthSortViews() {
        let views = _itemViews.values.sorted { (a, b) -> Bool in
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
            } else if offset > -CGFloat(numberOfItems) / 2.0 {
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
        for index in _itemViews.keys {
            transform(itemView: _itemViews[index]!, atIndex: index)
        }
    }
    
    private func updateItemWidth() {
        itemWidth = _delegate?.itemWidth?(self) ?? itemWidth
        if numberOfItems > 0 {
            if _itemViews.count == 0 {
                loadView(atIndex: 0)
            }
            
        }
    }
    
    private func updateNumberOfVisibleItems() {
        let spacing: CGFloat = value(forOption: .spacing, withDefaultValue: 1.0)
        let width: CGFloat = self.bounds.size.width
        let itemWidthWithSpacing = itemWidth * spacing
        
        numberOfVisibleItems = Int(ceil(width / itemWidthWithSpacing)) + 2
        numberOfVisibleItems = min(RACarousel.MaximumVisibleItems, numberOfVisibleItems)
        numberOfVisibleItems = value(forOption: .visibleItems, withDefaultValue: numberOfVisibleItems)
    }
    
    private func layoutItemViews() {
        guard let _ = _dataSource else { return }
        
        wrapEnabled = value(forOption: RACarouselOption.wrap, withDefaultValue: false)
        
        updateItemWidth()
        updateNumberOfVisibleItems()
        
        _prevScrollOffset = scrollOffset
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
        _itemViews = _itemViews.filter({ (arg: (key: Int, view: UIView)) -> Bool in
            if !visibleIndices.contains(arg.key) {
                queue(itemView: arg.view)
                arg.view.superview?.removeFromSuperview()
                return false
            }
            return true
        })
        
        visibleIndices.forEach { (index) in
            if _itemViews[index] == nil {
                loadView(atIndex: index)
            }
        }
    }
    
    public func reloadData() {
        for view in _itemViews.values {
            view.superview?.removeFromSuperview()
        }
        
        guard let _ = dataSource else { return }
        
        numberOfVisibleItems = 0
        numberOfItems = dataSource!.numberOfItems(inCarousel: self)
        
        _itemViews = Dictionary<Int, UIView>()
        _itemViewPool = Set<UIView>()
        
        setNeedsLayout()
        
        if numberOfItems > 0 && scrollOffset < 0.0 {
            scroll(toItemAtIndex: 0, animated: false)
        }
    }
    
    // MARK: -
    // MARK: View Queing
    @objc private func queue(itemView view: UIView) {
        _itemViewPool.insert(view)
    }
    
    private func dequeItemView() -> UIView? {
        if let view = _itemViewPool.first {
            _itemViewPool.remove(view)
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
            
            _startOffset = _scrollOffset
            _endOffset = _startOffset + offset
            
            _scrollDuration = duration
            if !wrapEnabled {
                _endOffset = clampedOffset(_endOffset)
            }
            
            delegate?.carouselWillBeginScrolling?(self)
            startAnimation()
            //delegate?.carou
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
          scrollOffset = CGFloat(clampedIndex(_previousItemIndex + itemCount))
        }
    }
    
    public func scroll(toItemAtIndex index: Int, withDuration duration: TimeInterval) {
        scroll(toOffset: CGFloat(index), withDuration: duration)
    }
    
    public func scroll(toItemAtIndex index: Int, animated: Bool) {
        scroll(toItemAtIndex: index, withDuration: animated ? TimeInterval(RACarousel.ScrollDuration) : 0.0)
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
            UIView.setAnimationDuration(TimeInterval(RACarousel.InsertDuration))
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
        
        if abs(itemWidth) < RACarousel.FloatErrorMargin {
            updateItemWidth()
        }
        
        if animated {
            UIView.beginAnimations(nil, context: nil)
            UIView.setAnimationDuration(TimeInterval(RACarousel.InsertDuration))
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
                transition.duration = TimeInterval(RACarousel.InsertDuration)
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
        print ("startAnimation, timer is nil = \(_timer == nil)")
        if _timer == nil {
            print ("New Timer")
            _timer = Timer(timeInterval: 1.0/60.0, target: self, selector: #selector(step), userInfo: nil, repeats: true)
            
            RunLoop.main.add(_timer!, forMode: RunLoop.Mode.default)
        }
    }
    
    private func stopAnimation() {
        _timer?.invalidate()
        _timer = nil
    }
    
    private func decelerationDistance() -> CGFloat {
        let acceleration: CGFloat = -_startVelocity * RACarousel.DecelerationMultiplier * (1.0 - _decelerationRate)
        
        return -pow(_startVelocity, 2.0) / (2.0 * acceleration)
    }
    
    private func shouldDecelerate() -> Bool {
        print ("shouldDecelerate() - _startVelocity = \(_startVelocity), " +
               "decelerationDistance = \(decelerationDistance())")
        return (abs(_startVelocity) > RACarousel.ScrollSpeedThreshold) &&
                (abs(decelerationDistance()) > RACarousel.DecelerateThreshold)
    }
    
    private func shouldScroll() -> Bool {
        return (abs(_startVelocity) > RACarousel.ScrollSpeedThreshold) &&
                (abs(_scrollOffset - CGFloat(currentItemIdx)) > RACarousel.ScrollDistanceThreshold)
    }
    
    private func startDecelerating() {
        var distance: CGFloat = decelerationDistance()
        _startOffset = _scrollOffset
        _endOffset = _startOffset + distance
        
        if !wrapEnabled {
            if bounceEnabled {
                _endOffset = max(-_bounceDist, min(CGFloat(numberOfItems) - 1.0 + _bounceDist, _endOffset))
            } else {
                _endOffset = clampedOffset(_endOffset)
            }
        }
        
        distance = _endOffset - _startOffset
        
        _startTime = CACurrentMediaTime()
        _scrollDuration = TimeInterval(abs(distance) / abs(0.5 * _startVelocity))
        
        if distance != 0.0 {
            print ("_decelerating = TRUE")
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
            
            _scrollOffset = _startOffset + (_endOffset - _startOffset) * delta
            didScroll()
            
            if time >= 1.0 {
                scrolling = false
                depthSortViews()
                pushAnimationState(enabled: true)
                //delegate?.carousel(self, didEndScrollingToIndex: destIndex)
                delegate?.carouselDidEndScrolling?(self)
                popAnimationState()
            }
        } else if _decelerating {
            
            let time: CGFloat = CGFloat(min(_scrollDuration, currentTime - _startTime))
            let acceleration: CGFloat = -_startVelocity / CGFloat(_scrollDuration)
            let distance: CGFloat = _startVelocity * time + 0.5 * acceleration * pow(time, 2.0)
            
            print("_Decelerating time = \(time), acceleration = \(acceleration), distance = \(distance)")
            
            _scrollOffset = _startOffset + distance
            didScroll()
            
            if abs(time - CGFloat(_scrollDuration)) < RACarousel.FloatErrorMargin {
                print ("Finishing Deceleration")
                _decelerating = false
                pushAnimationState(enabled: true)
                //delegate?.didEndDecelerating(self)
                popAnimationState()
                
                if abs(_scrollOffset - clampedOffset(_scrollOffset)) > RACarousel.FloatErrorMargin {
                    if abs(_scrollOffset - CGFloat(currentItemIdx)) < RACarousel.FloatErrorMargin {
                        // Legacy support, does this ever get triggered?
                        print ("Finished decel - Legacy scroll to currentItemIdx")
                        scroll(toItemAtIndex: currentItemIdx, withDuration: 0.01)
                    } else {
                        print ("Finished Decel with standard scroll to item index")
                        scroll(toItemAtIndex: currentItemIdx, animated: true)
                    }
                    
                } else {
                    print ("Finished Decel with distant scroll to item")
                    
                    var difference:CGFloat = round(_scrollOffset) - _scrollOffset
                    if difference > 0.5 {
                        difference = difference - 1.0
                    } else if difference < -0.5 {
                        difference = 1.0 + difference
                    }
                    
                    _toggleTime = currentTime - Double(RACarousel.MaxToggleDuration) * Double(abs(difference))
                    toggle = max(-1.0, min(1.0, -difference))
                    
                    scroll(toItemAtIndex: Int(round(CGFloat(currentItemIdx) + difference)), animated: true)
                    
                    print ("Scroll with toggle : \(toggle) and _toggleTime : \(_toggleTime)")
                }
            }
        } else if abs(toggle) > RACarousel.FloatErrorMargin {
            print ("Toggle scroll")
            var toggleDuration: TimeInterval = _startVelocity != 0.0 ? TimeInterval(min(1.0, max(0.0, 1.0 / abs(_startVelocity)))) : 1.0
            toggleDuration = RACarousel.MinToggleDuration + (RACarousel.MaxToggleDuration - RACarousel.MinToggleDuration) * toggleDuration
            
            let time: TimeInterval = min(1.0, (currentTime - _toggleTime) / toggleDuration)
            delta = easeInOut(inTime: CGFloat(time))
            
            print("Toggle Scroll : " +
                "\ntoggleDuration - \(toggleDuration)" +
                "\ntime - \(time)" +
                "\ndelta - \(delta)")
            
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
            let minVal: CGFloat = -_bounceDist
            let maxVal: CGFloat = max(CGFloat(numberOfItems) - 1.0, 0.0) + _bounceDist
            
            if _scrollOffset < minVal {
                _scrollOffset = minVal
                _startVelocity = 0.0
            } else if _scrollOffset > maxVal {
                _scrollOffset = maxVal
                _startVelocity = 0.0
            }
        }
        
        let difference = minScrollDistance(fromIndex: currentItemIdx, toIndex: _previousItemIndex)
        
        if difference != 0 {
            _toggleTime = CACurrentMediaTime()
            toggle = max(-1.0, min(1.0, CGFloat(difference)))
            startAnimation()
        }
        
        loadUnloadViews()
        transformItemViews()
        
        if abs(_scrollOffset - _prevScrollOffset) > RACarousel.FloatErrorMargin {
            pushAnimationState(enabled: true)
            //delegate?.carouselDidScroll(self)
            popAnimationState()
        }
        
        // Notify of change of item
        if _previousItemIndex != currentItemIdx {
            pushAnimationState(enabled: true)
            delegate?.carousel?(self, currentItemDidChangeToIndex: currentItemIdx)
            popAnimationState()
        }
        
        _prevScrollOffset = _scrollOffset
        _previousItemIndex = currentItemIdx
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
    
    /*
    private func implementSelector(_ selector: Selector, forViewOrSuperview view: UIView?) -> Bool {
        guard let aView = view else { return false }
        guard aView == contentView else { return false }
    }*/
    
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
            let shouldSelect = delegate?.carousel?(self, shouldSelectItemAtIndex: index) ?? true
            if shouldSelect {
                if index != currentItemIdx {
                    scroll(toItemAtIndex: index, animated: true)
                }
                delegate?.carousel?(self, didSelectItemAtIndex: index)
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
                    print ("shouldDecelerate() - TRUE")
                    _didDrag = false
                    startDecelerating()
                }
                
                pushAnimationState(enabled: true)
                //delegate?.carouselDidEndDragging(self)
                popAnimationState()
                
                if !_decelerating {
                    if abs(_scrollOffset - clampedOffset(_scrollOffset)) > RACarousel.FloatErrorMargin {
                        if abs(scrollOffset - CGFloat(currentItemIdx)) < RACarousel.FloatErrorMargin {
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
                
                if wrapEnabled && bounceEnabled {
                    factor = 1.0 - min (abs(_scrollOffset - clampedOffset(_scrollOffset)), _bounceDist) / _bounceDist
                }
                
                _startVelocity = -velocity * factor * _scrollSpeed / (CGFloat(itemWidth))
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
