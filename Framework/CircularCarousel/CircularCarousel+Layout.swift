//
//  CircularCarousel_LayoutExtension.swift
//  CircularCarousel
//
//  Created by Piotr Suwara on 10/1/19.
//  Copyright © 2019 Piotr Suwara. All rights reserved.
//

import UIKit

extension CircularCarousel {
    
    internal func alphaForItem(withOffset offset: CGFloat) -> CGFloat {
        var fadeMin: CGFloat = -CGFloat.infinity
        var fadeMax: CGFloat = CGFloat.infinity
        
        var fadeRange: CGFloat = 1.0
        var fadeMinAlpha: CGFloat = 0.0
        
        fadeMin = value(forOption: CircularCarouselOption.fadeMin, withDefaultValue: fadeMin)
        fadeMax = value(forOption: CircularCarouselOption.fadeMax, withDefaultValue: fadeMax)
        fadeRange = value(forOption: CircularCarouselOption.fadeRange, withDefaultValue: fadeRange)
        fadeMinAlpha = value(forOption: CircularCarouselOption.fadeMinAlpha, withDefaultValue: fadeMinAlpha)
        
        var factor: CGFloat = 0.0
        if offset > fadeMax {
            factor = offset - fadeMax
        } else if offset < fadeMin {
            factor = fadeMin - offset
        }
        
        return CGFloat(1.0 - min(factor, fadeRange) / fadeRange * (1.0 - fadeMinAlpha))
    }
    
    internal func value<T>(forOption option: CircularCarouselOption, withDefaultValue defaultValue: T) -> T {
        return _delegate?.carousel(self, valueForOption: option, withDefaultValue: defaultValue) ?? defaultValue
    }
    
    internal func transformForItemView(withOffset offset: CGFloat) -> CATransform3D {
        var transform: CATransform3D = CATransform3DIdentity
        
        transform = CATransform3DTranslate(transform,
                                           -viewPointOffset.width,
                                           -viewPointOffset.height, 0)
        
        
        let spacing = delegate?.carousel(self, spacingForOffset: offset) ?? 1.0
        
        let scaleMultiplier = value(forOption: .scaleMultiplier, withDefaultValue: CircularCarouselConstants.defaultScaleMultiplier)
        let minScale = value(forOption: .minScale, withDefaultValue: CircularCarouselConstants.minScale)
        let maxScale = value(forOption: .maxScale, withDefaultValue: CircularCarouselConstants.maxScale)
        let scale = max(minScale, maxScale  - abs(offset * scaleMultiplier))
        
        transform = CATransform3DTranslate(transform, offset * itemWidth * spacing, 0.0, 0.0)
        
        transform = CATransform3DScale(transform, scale, scale, 1.0)
        
        return transform
    }
    
    @objc internal func depthSortViews() {
        let views = itemViews.values.sorted { (a, b) -> Bool in
            return compare(viewDepth: a, withView: b)
        }
        
        for view in views {
            contentView.bringSubviewToFront(view)
        }
    }
    
    internal func offsetForItem(atIndex index: Int) -> CGFloat {
        var offset: CGFloat = CGFloat(index) - scrollOffset
        if wrapEnabled {
            if offset > (CGFloat(numberOfItems) / 2.0) {
                offset = offset - CGFloat(numberOfItems)
            } else if offset < -CGFloat(numberOfItems) / 2.0 {
                offset = offset + CGFloat(numberOfItems)
            }
        }
        
        return offset
    }
    
    internal func containView(inView view: UIView) -> UIView {
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
    
    internal func transform(itemView view: UIView, atIndex index: Int) {
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
    
    internal func transformItemViews() {
        for index in itemViews.keys {
            transform(itemView: itemViews[index]!, atIndex: index)
        }
    }
    
    internal func updateItemWidth() {
        itemWidth = value(forOption: .itemWidth, withDefaultValue: itemWidth)
        if numberOfItems > 0 {
            if itemViews.count == 0 {
                loadView(atIndex: 0)
            }
        }
    }
    
    internal func updateNumberOfVisibleItems() {
        let spacing: CGFloat = value(forOption: .spacing, withDefaultValue: 1.0)
        let width: CGFloat = bounds.size.width
        let itemWidthWithSpacing = itemWidth * spacing
        
        numberOfVisibleItems = Int(ceil(width / itemWidthWithSpacing)) + 2
        numberOfVisibleItems = min(CircularCarouselConstants.maximumVisibleItems, numberOfVisibleItems)
        numberOfVisibleItems = value(forOption: .visibleItems, withDefaultValue: numberOfVisibleItems)
    }
    
    internal func layoutItemViews() {
        guard let _ = _dataSource else { return }
        
        wrapEnabled = value(forOption: CircularCarouselOption.wrap, withDefaultValue: wrapEnabled)
        
        updateItemWidth()
        updateNumberOfVisibleItems()
        
        prevScrollOffset = scrollOffset
        offsetMultiplier = value(forOption: CircularCarouselOption.offsetMultiplier, withDefaultValue: 1.0)
        
        if scrolling == false && decelerating == false {
            if currentItemIdx != -1 {
                scroll(toItemAtIndex: currentItemIdx, animated: true)
            } else {
                scrollOffset = clampedOffset(scrollOffset)
            }
        }
        
        didScroll()
    }
}
