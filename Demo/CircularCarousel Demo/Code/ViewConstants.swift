//
//  ViewConstants.swift
//  CircularCarousel Demo
//
//  Created by Piotr Suwara on 2/2/19.
//  Copyright © 2019 Piotr Suwara. All rights reserved.
//

import UIKit

struct ViewConstants {
    struct RowIndex {
        static let buttonCarousel = 1
        static let tableCarousel = 2
    }
    
    static let numberOfTableViewRows = 10
    static let numberOfPrimaryViewRows = 3
    static let topRowScreenRatio: CGFloat = 0.6
    static let numberOfCarouselItems = 5
    static let startingCarouselItem = 0
    
    struct NibNames {
        static let tableCarousel = "TableCarouselView"
        static let buttons = "ButtonCarouselView"
        static let image = "ImageViewCell"
    }
    
    struct CellIdentifiers {
        static let tableCarousel = "TableCarouselViewIdentifier"
        static let buttons = "ButtonsViewIdentifier"
        static let image  = "ImageViewCellIdentifier"
    }
    
    struct CellHeights {
        static let buttonsCarousel: CGFloat = 200.0
        static let image: CGFloat = 400.0
        static let normal: CGFloat = 50.0
        static var tableCarousel: CGFloat {
            return ViewConstants.CellHeights.image * CGFloat(ViewConstants.numberOfTableViewRows)
        }
    }
    
    struct Colors {
        static let tableViewSeperator = UIColor(white: 0.85, alpha: 1.0)
        static let gradient: [UIColor] = [
            UIColor(red: 53/255, green: 136/255, blue: 206/255, alpha: 1),
            UIColor(red: 155/255, green: 211/255, blue: 230/255, alpha: 1)]
    
        static let carouselButtonSelected: UIColor = UIColor(red: 0.0, green: 154/255, blue: 229/255, alpha: 1.0)
        static let carouselButtonUnselected: UIColor = UIColor.white
    }
    
    struct Size {
        static let roundedButton:CGSize = CGSize(width: 77, height: 77)
        static let carouselButtonItemWidith:CGFloat = 80.0
    }
}
