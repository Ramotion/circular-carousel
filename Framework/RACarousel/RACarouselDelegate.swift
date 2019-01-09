//
//  RACarouselDelegate.swift
//  RACarousel Demo
//
//  Created by Piotr Suwara on 24/12/18.
//  Copyright © 2018 Piotr Suwara. All rights reserved.
//

import Foundation
import UIKit

public protocol RACarouselDelegate {
    func carouselWillBeginScrolling(_ carousel: RACarousel)
    func carouselDidEndScrolling(_ carousel: RACarousel)
    
    func carousel(_ carousel: RACarousel, currentItemDidChangeToIndex index: Int)
    func carousel(_ carousel: RACarousel, willBeginScrollingToIndex index: Int)
    func carousel(_ carousel: RACarousel, didEndScrollingToIndex index: Int)
    func carousel(_ carousel: RACarousel, didSelectItemAtIndex index: Int)
    func carousel<T>(_ carousel: RACarousel, valueForOption option: RACarouselOption, withDefaultValue defaultValue: T) -> T
    func carousel(_ carousel: RACarousel, shouldSelectItemAtIndex index: Int) -> Bool
}

public extension RACarouselDelegate {
    func carouselWillBeginScrolling(_ carousel: RACarousel) {
        
    }
    
    func carouselDidEndScrolling(_ carousel: RACarousel) {
        
    }
    
    func carousel(_ carousel: RACarousel, currentItemDidChangeToIndex index: Int) {
        
    }
    
    func carousel(_ carousel: RACarousel, willBeginScrollingToIndex index: Int) {
        
    }
    
    func carousel(_ carousel: RACarousel, didEndScrollingToIndex index: Int) {
        
    }
    
    func carousel(_ carousel: RACarousel, didSelectItemAtIndex index: Int) {
        
    }
    
    func carousel<T>(_ carousel: RACarousel, valueForOption option: RACarouselOption, withDefaultValue defaultValue: T) -> T {
        return defaultValue
    }
    
    func carousel(_ carousel: RACarousel, shouldSelectItemAtIndex index: Int) -> Bool {
        return true
    }
}

