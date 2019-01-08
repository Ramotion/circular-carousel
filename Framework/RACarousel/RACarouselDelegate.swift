//
//  RACarouselDelegate.swift
//  RACarousel Demo
//
//  Created by Piotr Suwara on 24/12/18.
//  Copyright © 2018 Piotr Suwara. All rights reserved.
//

import Foundation
import UIKit

@objc public protocol RACarouselDelegate {
    @objc optional func carouselWillBeginScrolling(_ carousel: RACarousel)
    @objc optional func carouselDidEndScrolling(_ carousel: RACarousel)
    
    @objc optional func carousel(_ carousel: RACarousel, currentItemDidChangeToIndex index: Int)
    @objc optional func carousel(_ carousel: RACarousel, willBeginScrollingToIndex index: Int)
    @objc optional func carousel(_ carousel: RACarousel, didEndScrollingToIndex index: Int)
    @objc optional func carousel(_ carousel: RACarousel, didSelectItemAtIndex index: Int)
    @objc optional func itemWidth(_ carousel: RACarousel) -> CGFloat
    @objc optional func carousel(_ carousel: RACarousel, valueForOption option: RACarouselOption, withDefaultInt defaultValue: Int) -> Int
    @objc optional func carousel(_ carousel: RACarousel, valueForOption option: RACarouselOption, withDefaultBool defaultValue: Bool) -> Bool
    @objc optional func carousel(_ carousel: RACarousel, valueForOption option: RACarouselOption, withDefaultFloat defaultValue: CGFloat) -> CGFloat
    @objc optional func carousel(_ carousel: RACarousel, shouldSelectItemAtIndex index: Int) -> Bool
}

