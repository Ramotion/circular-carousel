//
//  RACarouselDatasource.swift
//  RACarousel Demo
//
//  Created by Piotr Suwara on 24/12/18.
//  Copyright © 2018 Piotr Suwara. All rights reserved.
//

import Foundation
import UIKit

public protocol RACarouselDataSource {
    func numberOfItems(inCarousel carousel: RACarousel) -> Int
    func carousel(_: RACarousel, viewForItemAt: IndexPath, reuseView: UIView?) -> UIView
}

public extension RACarouselDataSource {
    func startingItemIndex(inCarousel carousel: RACarousel) -> Int {
        return 0
    }
}
