//
//  CircularCarousel_Functions.swift
//  CircularCarousel
//
//  Created by Piotr Suwara on 10/1/19.
//  Copyright © 2019 Piotr Suwara. All rights reserved.
//

import UIKit

extension CircularCarousel {
    
    internal func minScrollDistance(fromIndex from: Int, toIndex to: Int) -> Int {
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
    
    internal func minScrollDistance(fromOffset from: CGFloat, toOffset to: CGFloat) -> CGFloat {
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
    
    func reloadItem(atIndex index: Int, animated: Bool) {
        if let containerView = itemView(atIndex: index)?.superview {
            if animated {
                let transition = CATransition.init()
                transition.duration = CircularCarouselConstants.insertDuration
                transition.timingFunction = CAMediaTimingFunction(name:
                    CAMediaTimingFunctionName.easeInEaseOut)
                transition.type = CATransitionType.push
                containerView.layer.add(transition, forKey: nil)
            }
            
            loadView(atIndex: index, withContainerView: containerView)
        }
    }

    public func scroll(byOffset offset: CGFloat, withDuration duration: TimeInterval) {
        if duration > 0.0 {
            decelerating = false
            scrolling = true
            
            startTime = CACurrentMediaTime()
            
            startOffset = scrollOffset
            endOffset = startOffset + offset
            
            scrollDuration = duration
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
                offset = (floor(scrollOffset)) + CGFloat(itemCount) - scrollOffset
            } else if itemCount < 0 {
                offset = (ceil(scrollOffset) + CGFloat(itemCount)) - scrollOffset
            } else {
                offset = round(scrollOffset) - scrollOffset
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
        scroll(toItemAtIndex: index, withDuration: animated ? CircularCarouselConstants.scrollDuration : 0.0)
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
            UIView.setAnimationDuration(CircularCarouselConstants.insertDuration)
            UIView.setAnimationDelegate(self)
            UIView.setAnimationDidStop(#selector(depthSortViews))
            
            removeViewAtIndex(removeIndex)
            numberOfItems = numberOfItems - 1
            wrapEnabled = value(forOption: CircularCarouselOption.wrap, withDefaultValue: wrapEnabled)
            
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
            wrapEnabled = value(forOption: CircularCarouselOption.wrap, withDefaultValue: wrapEnabled)
            scrollOffset = CGFloat(currentItemIdx)
            didScroll()
            depthSortViews()
            popAnimationState()
        }
    }
    
    public func insertItem(atIndex index: Int, _ animated: Bool) {
        numberOfItems = numberOfItems + 1
        wrapEnabled = value(forOption: CircularCarouselOption.wrap, withDefaultValue: wrapEnabled)
        updateNumberOfVisibleItems()
        
        let insert = clampedIndex(index)
        insertView(nil, atIndex: insert)
        loadView(atIndex: insert)
        
        if abs(itemWidth) < CircularCarouselConstants.floatErrorMargin {
            updateItemWidth()
        }
        
        if animated {
            UIView.beginAnimations(nil, context: nil)
            UIView.setAnimationDuration(CircularCarouselConstants.insertDuration)
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
}
