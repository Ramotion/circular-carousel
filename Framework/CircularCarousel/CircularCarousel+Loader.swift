//
//  NumberExtensions.swift
//  CircularCarousel
//
//  Created by Piotr Suwara on 10/1/19.
//  Copyright © 2019 Piotr Suwara. All rights reserved.
//

import UIKit

extension CircularCarousel {
    @discardableResult internal func loadView(atIndex index: Int, withContainerView containerView: UIView?) -> UIView? {
        pushAnimationState(enabled: false)
        
        guard let dataSource = dataSource else {
            popAnimationState()
            return nil
        }
        
        let view = dataSource.carousel(self, viewForItemAt: IndexPath(item: index, section: 0), reuseView: dequeItemView())
        
        setItemView(view, forIndex: index)
        if let aContainerView = containerView {
            if let oldItemView: UIView = aContainerView.subviews.last {
                queue(itemView: oldItemView)
                var frame = aContainerView.frame
                
                frame.size.width = min(itemWidth, view.frame.size.width)
                frame.size.height = view.frame.size.height
                
                aContainerView.bounds = frame
                
                frame = view.frame
                frame.origin.x = (aContainerView.bounds.size.width - frame.size.width) / 2.0
                frame.origin.y = (aContainerView.bounds.size.height - frame.size.height) / 2.0
                view.frame = frame
                
                oldItemView.removeFromSuperview()
                aContainerView.addSubview(view)
            }
        } else {
            contentView.addSubview(containView(inView: view))
        }
        
        view.superview?.layer.opacity = 0.0
        transform(itemView: view, atIndex: index)
        popAnimationState()
        
        return view
    }
    
    @discardableResult internal func loadView(atIndex index: Int) -> UIView? {
        return loadView(atIndex: index, withContainerView: nil)
    }
    
    internal func loadUnloadViews() {
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
        
        guard let dataSource = dataSource else { return }
        
        numberOfVisibleItems = 0
        numberOfItems = dataSource.numberOfItems(inCarousel: self)
        
        itemViews = Dictionary<Int, UIView>()
        itemViewPool = Set<UIView>()
        
        setNeedsLayout()
        
        if numberOfItems > 0 {
            scroll(toItemAtIndex: dataSource.startingItemIndex(inCarousel: self), animated: false)
        }
    }
}
