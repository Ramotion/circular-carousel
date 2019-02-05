//
//  RACarousel_Animations.swift
//  RACarousel
//
//  Created by Piotr Suwara on 10/1/19.
//  Copyright © 2019 Piotr Suwara. All rights reserved.
//

import Foundation

extension RACarousel {
    
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
    
    func startAnimation() {
        if timer == nil {
            timer = Timer(timeInterval: 1.0/60.0, target: self, selector: #selector(step), userInfo: nil, repeats: true)
            
            RunLoop.main.add(timer!, forMode: RunLoop.Mode.default)
        }
    }
    
    func stopAnimation() {
        timer?.invalidate()
        timer = nil
    }
    
    func decelerationDistance() -> CGFloat {
        let acceleration: CGFloat = -startVelocity * RACarouselConstants.DecelerationMultiplier * (1.0 - decelerationRate)
        
        return -pow(startVelocity, 2.0) / (2.0 * acceleration)
    }
    
    func shouldDecelerate() -> Bool {
        return (abs(startVelocity) > RACarouselConstants.ScrollSpeedThreshold) &&
            (abs(decelerationDistance()) > RACarouselConstants.DecelerateThreshold)
    }
    
    func shouldScroll() -> Bool {
        return (abs(startVelocity) > RACarouselConstants.ScrollSpeedThreshold) &&
            (abs(_scrollOffset - CGFloat(currentItemIdx)) > RACarouselConstants.ScrollDistanceThreshold)
    }
    
    func startDecelerating() {
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
        
        startTime = CACurrentMediaTime()
        scrollDuration = TimeInterval(abs(distance) / abs(0.5 * startVelocity))
        
        if distance != 0.0 {
            decelerating = true
            startAnimation()
        }
    }
    
    func easeInOut(inTime time: CGFloat) -> CGFloat {
        return (time < 0.5) ? 0.5 * pow(time * 2.0, 3.0) : 0.5 * pow(time * 2.0 - 2.0, 3.0) + 1.0
    }
    
    @objc func step() {
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
            
            if abs(time - CGFloat(scrollDuration)) < RACarouselConstants.FloatErrorMargin {
                
                decelerating = false
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
                    
                    toggleTime = currentTime - Double(RACarouselConstants.MaxToggleDuration) * Double(abs(difference))
                    toggle = max(-1.0, min(1.0, -difference))
                    
                    scroll(toItemAtIndex: Int(round(CGFloat(currentItemIdx) + difference)), animated: true)
                }
            }
        } else if abs(toggle) > RACarouselConstants.FloatErrorMargin {
            var toggleDuration: TimeInterval = startVelocity != 0.0 ? TimeInterval(min(1.0, max(0.0, 1.0 / abs(startVelocity)))) : 1.0
            toggleDuration = RACarouselConstants.MinToggleDuration + (RACarouselConstants.MaxToggleDuration - RACarouselConstants.MinToggleDuration) * toggleDuration
            
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
    
    @objc func didScroll() {
        if wrapEnabled || !bounceEnabled {
            _scrollOffset = clampedOffset(_scrollOffset)
        } else {
            let minVal: CGFloat = -bounceDist
            let maxVal: CGFloat = max(CGFloat(numberOfItems) - 1.0, 0.0) + bounceDist
            
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
}
