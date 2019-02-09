//
//  NSObjectExtension.swift
//  CircularCarousel Demo
//
//  Created by Piotr Suwara on 28/12/18.
//  Copyright © 2018 Piotr Suwara. All rights reserved.
//
//  Suggested from Stack Overflow to fix the method checking of an override for a class
//  StackOverflow
//  - 

import Foundation

extension NSObject
{
    func overrides(_ selector: Selector) -> Bool {
        var currentClass: AnyClass = type(of: self)
        let method: Method? = class_getInstanceMethod(currentClass, selector)
        
        while let superClass: AnyClass = class_getSuperclass(currentClass) {
            // Make sure we only check against non-nil returned instance methods.
            if class_getInstanceMethod(superClass, selector).map({ $0 != method}) ?? false { return true }
            currentClass = superClass
        }
        
        return false
    }
}
