//
//  RACarousel_AnimationExtension.swift
//  RACarousel
//
//  Created by Piotr Suwara on 10/1/19.
//  Copyright © 2019 Piotr Suwara. All rights reserved.
//

import Foundation

extension RACarousel {
    internal func startAnimation() {
        if timer == nil {
            timer = Timer(timeInterval: 1.0/60.0, target: self, selector: #selector(step), userInfo: nil, repeats: true)
            
            RunLoop.main.add(timer!, forMode: RunLoop.Mode.default)
        }
    }
    
    internal func stopAnimation() {
        timer?.invalidate()
        timer = nil
    }
    
    internal func decelerationDistance() -> CGFloat {
        let acceleration: CGFloat = -startVelocity * RACarouselConstants.decelerationMultiplier * (1.0 - decelerationRate)
        
        return -pow(startVelocity, 2.0) / (2.0 * acceleration)
    }
    
    internal func shouldDecelerate() -> Bool {
        return (abs(startVelocity) > RACarouselConstants.scrollSpeedThreshold) &&
            (abs(decelerationDistance()) > RACarouselConstants.decelerateThreshold)
    }
    
    internal func shouldScroll() -> Bool {
        return (abs(startVelocity) > RACarouselConstants.scrollSpeedThreshold) &&
            (abs(_scrollOffset - CGFloat(currentItemIdx)) > RACarouselConstants.scrollDistanceThreshold)
    }
    
    internal func startDecelerating() {
        var distance: CGFloat = decelerationDistance()
        startOffset = _scrollOffset
        endOffset = startOffset + distance
        
        if !wrapEnabled {
            if bounceEnabled {
                endOffset = max(-RACarouselConstants.bounceDist, min(CGFloat(numberOfItems) - 1.0 + RACarouselConstants.bounceDist, endOffset))
            } else {
                endOffset = clampedOffset(endOffset)
            }
        }
        
        distance = endOffset - startOffset
        
        startTime = CACurrentMediaTime()
        scrollDuration = TimeInterval(abs(distance) / abs(0.5 * startVelocity))
        
        if distance != 0.0 {
            decelerating = true
            startAnimation()
        }
    }
    
    internal func easeInOut(inTime time: CGFloat) -> CGFloat {
        return (time < 0.5) ? 0.5 * pow(time * 2.0, 3.0) : 0.5 * pow(time * 2.0 - 2.0, 3.0) + 1.0
    }
    
    @objc internal func step() {
        pushAnimationState(enabled: false)
        
        let currentTime: TimeInterval = CACurrentMediaTime()
        var delta: CGFloat = CGFloat(currentTime - lastTime)
        
        lastTime = currentTime
        
        if scrolling && !dragging {
            let time: TimeInterval = min(1.0, (currentTime - startTime) / scrollDuration)
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
        } else if decelerating {
            
            let time: CGFloat = CGFloat(min(scrollDuration, currentTime - startTime))
            let acceleration: CGFloat = -startVelocity / CGFloat(scrollDuration)
            let distance: CGFloat = startVelocity * time + 0.5 * acceleration * pow(time, 2.0)
            
            _scrollOffset = startOffset + distance
            didScroll()
            
            if abs(time - CGFloat(scrollDuration)) < RACarouselConstants.floatErrorMargin {
                
                decelerating = false
                pushAnimationState(enabled: true)
                //delegate?.didEndDecelerating(self)
                popAnimationState()
                
                if abs(_scrollOffset - clampedOffset(_scrollOffset)) > RACarouselConstants.floatErrorMargin {
                    if abs(_scrollOffset - CGFloat(currentItemIdx)) < RACarouselConstants.floatErrorMargin {
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
                    
                    toggleTime = currentTime - Double(RACarouselConstants.maxToggleDuration) * Double(abs(difference))
                    toggle = max(-1.0, min(1.0, -difference))
                    
                    scroll(toItemAtIndex: Int(round(CGFloat(currentItemIdx) + difference)), animated: true)
                }
            }
        } else if abs(toggle) > RACarouselConstants.floatErrorMargin {
            var toggleDuration: TimeInterval = startVelocity != 0.0 ? TimeInterval(min(1.0, max(0.0, 1.0 / abs(startVelocity)))) : 1.0
            toggleDuration = RACarouselConstants.minToggleDuration + (RACarouselConstants.maxToggleDuration - RACarouselConstants.minToggleDuration) * toggleDuration
            
            let time: TimeInterval = min(1.0, (currentTime - toggleTime) / toggleDuration)
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
    
    @objc internal func didScroll() {
        if wrapEnabled || !bounceEnabled {
            _scrollOffset = clampedOffset(_scrollOffset)
        } else {
            let minVal: CGFloat = -RACarouselConstants.bounceDist
            let maxVal: CGFloat = max(CGFloat(numberOfItems) - 1.0, 0.0) + RACarouselConstants.bounceDist
            
            if _scrollOffset < minVal {
                _scrollOffset = minVal
                startVelocity = 0.0
            } else if _scrollOffset > maxVal {
                _scrollOffset = maxVal
                startVelocity = 0.0
            }
        }
        
        let difference = minScrollDistance(fromIndex: currentItemIdx, toIndex: previousItemIndex)
        
        if difference != 0 {
            toggleTime = CACurrentMediaTime()
            toggle = max(-1.0, min(1.0, CGFloat(difference)))
            startAnimation()
        }
        
        loadUnloadViews()
        transformItemViews()
        
        if abs(_scrollOffset - prevScrollOffset) > RACarouselConstants.floatErrorMargin {
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
}
