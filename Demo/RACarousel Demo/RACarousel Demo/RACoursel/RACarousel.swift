//
//  RACarousel.swift
//  RACarousel Demo
//
//  Created by Piotr Suwara on 24/12/18.
//  Copyright © 2018 Piotr Suwara. All rights reserved.
//

import Foundation
import UIKit

enum RACarouselOption: Int {
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
}

class RACarousel : UIView {
    
    static let MaximumVisibleItems: Int = 50
    
    // Delegate and Datasource
    private weak var _delegate: RACarouselDelegate?
    var delegate: RACarouselDelegate? {
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
    var dataSource: RACarouselDataSource? {
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
    private (set) var numberOfItems: Int = 0
    
    var _currentItemIdx: Int = 0
    var currentItemIdx: Int {
        get {
            return _currentItemIdx
        }
        set {
            assert(newValue < numberOfItems, "Attempting to set the current item outside the bounds of total items")
            _currentItemIdx = newValue
            
            scrollOffset = CGFloat(_currentItemIdx)
        }
    }
    
    var scrollEnabled: Bool = true
    var pagingEnabled: Bool = false
    var wrapEnabled: Bool = true
    var bounceEnabled: Bool = true
    
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
    /*private (set) var currentItemView: UIView? {
        
    }*/
    
    private (set) var numberOfVisibleItems: Int = 0
    //private (set) var visibleItemViews: [UIView]
    private (set) var itemWidth: CGFloat = 0.0
    
    private (set) var contentView: UIView = UIView()
    
    private (set) var dragging: Bool = false
    private (set) var scrolling: Bool = false
    
    // Private variables
    private var _itemViews: Dictionary<Int, UIView> = Dictionary<Int, UIView>()
    private var _itemViewPool: Set<UIView> = Set<UIView>()
    private var _prevScrollOffset: CGFloat = 0.0
    private var _startOffset: CGFloat = 0.0
    private var _endOffset: CGFloat = 0.0
    private var _scrollDuration: TimeInterval = 0.0
    private var _startTime: TimeInterval = 0.0
    private var _endTime: TimeInterval = 0.0
    private var _decelerating: Bool = false
    
    private let _decelSpeed: CGFloat = 0.9
    private let _scrollSpeed: CGFloat = 1.0
    private let _bounceDist: CGFloat = 1.0
    
    // Public functions
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }
    
    convenience init() {
        self.init(frame: CGRect.zero)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        if let _ = self.superview {
            // TODO
            //startAnimation()
        }
    }
    
    deinit {
        
    }
    
    func scroll(byOffset offset: CGFloat, withDuration duration: CGFloat) {
        
    }
    
    
    func scroll(toOffset offset: CGFloat, withDuration duration: CGFloat) {
        
    }
    
    func scroll(byNumberOfItems items: Int, withDuration duration: CGFloat) {
        
    }
    
    func scrollToItem(atIndex index: Int, withDuration duration: CGFloat) {
        
    }
    
    func scrollToItem(atIndex index: Int, animated: Bool) {
        
    }
    
    func reloadData() {
        
    }
    
    public func itemView(atIndex index: Int) -> UIView? {
        return _itemViews[index]
    }
    
    public func currentItemView() -> UIView {
        return itemView(atIndex: currentItemIdx)!
    }
    
    private func setupView() {
        contentView = UIView(frame: self.bounds)
        contentView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(didPan))
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(didTap))
        
        panGesture.delegate = self as? UIGestureRecognizerDelegate
        tapGesture.delegate = self as? UIGestureRecognizerDelegate
        
        contentView.addGestureRecognizer(panGesture)
        contentView.addGestureRecognizer(tapGesture)
        
        accessibilityTraits = UIAccessibilityTraits.allowsDirectInteraction
        isAccessibilityElement = true
        
        addSubview(contentView)
        
        if let _ = dataSource {
            reloadData()
        }
    }
    
    @objc private func didPan(panGesture: UIPanGestureRecognizer) {
        
    }
    
    @objc private func didTap(panGesture: UIPanGestureRecognizer) {
        
    }
    
    private func didScroll() {
        
    }
    
    private func pushAnimationState(enabled: Bool) {
        CATransaction.begin()
        CATransaction.setDisableActions(!enabled)
    }
    
    private func popAnimationState(enabled: Bool) {
        CATransaction.commit()
    }
    
    private func indexesForVisibleItems() -> [Int] {
        return []
    }
    
    private func indexOfItem(forView view: UIView) -> Int {
        if let index = _itemViews.values.firstIndex(of: view) {
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
    
    private func setItemView(_ view: UIView, forIndex index: Int) {
        _itemViews[index] = view
    }
    
    private func removeViewAtIndex(_ index: Int) {
        _itemViews.removeValue(forKey: index)
        _itemViews = Dictionary(uniqueKeysWithValues:
            _itemViews.map { (arg: (key: Int, value: UIView)) -> (key: Int, value: UIView) in
                return (key: arg.key < index ? index : index - 1, value: arg.value)
            })
    }
    
    private func insertView(_ view: UIView, atIndex index: Int) {
        
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
            let transformCurItem = currentItemView().superview!.layer.transform
            
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
                                           -_viewPointOffset.width,
                                           -_viewPointOffset.height, 0)
        
        let spacing = value(forOption: .spacing, withDefaultValue: CGFloat(1.0))
        return CATransform3DTranslate(transform, offset * itemWidth * spacing, 0.0, 0.0)
    }
    
    private func depthSortViews() {
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
    
    override func layoutSubviews() {
        super.layoutSubviews()
        contentView.frame = bounds
        layoutItemViews()
    }
    
    private func transformItemView() {
        for index in _itemViews.keys {
            transform(itemView: _itemViews[index]!, atIndex: index)
        }
    }
    
    private func updateItemWidth() {
        itemWidth = delegate?.itemWidth(self) ?? itemWidth
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
        guard let dataSource = _dataSource else { return }
        
        wrapEnabled = value(forOption: RACarouselOption.wrap, withDefaultValue: false)
        
    }
    
    // MARK: -
    // MARK: View Loading
    private func loadView(atIndex index: Int) {
        
    }
}
