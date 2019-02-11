//
//  CircularCarouselDatasource.swift
//  CircularCarousel Demo
//
//  Created by Piotr Suwara on 24/12/18.
//  Copyright © 2018 Piotr Suwara. All rights reserved.
//

import Foundation
import UIKit

public protocol CircularCarouselDataSource {
    func numberOfItems(inCarousel carousel: CircularCarousel) -> Int
    func carousel(_: CircularCarousel, viewForItemAt: IndexPath, reuseView: UIView?) -> UIView
    func startingItemIndex(inCarousel carousel: CircularCarousel) -> Int
}

public extension CircularCarouselDataSource {
    func startingItemIndex(inCarousel carousel: CircularCarousel) -> Int {
        return 0
    }
}
