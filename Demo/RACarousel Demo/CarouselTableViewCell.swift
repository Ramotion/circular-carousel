//
//  CarouselTableViewCell.swift
//  RACarousel Demo
//
//  Created by Piotr Suwara on 2/1/19.
//  Copyright © 2019 Piotr Suwara. All rights reserved.
//

import Foundation
import UIKit
import RACarousel

protocol CarouselTableViewCellDelegate {
    func carousel(_ carousel: RACarousel, buttonPressed: UIButton)
}

class CarouselTableViewCell : UITableViewCell, RACarouselDataSource, RACarouselDelegate {
    
    static let NumberOfButtons = 10
    static let ButtonImageNames = ["IconImage1", "IconImage2", "IconImage3", "IconImage4"]
    
    var delegate: CarouselTableViewCellDelegate?
    
    private weak var _carousel : RACarousel!
    @IBOutlet var carousel : RACarousel! {
        set {
            _carousel = newValue
            _carousel.delegate = self
            _carousel.dataSource = self
        }
        
        get {
            return _carousel
        }
    }
    
    @IBOutlet weak var title : UILabel!
       
    // MARK: -
    // MARK: RACarouselDataSource
    
    func numberOfItems(inCarousel carousel: RACarousel) -> Int {
        return CarouselTableViewCell.NumberOfButtons
    }
    
    func carousel(_: RACarousel, viewForItemAt indexPath: IndexPath, reuseView view: UIView?) -> UIView {
        var button = view as? UIButton
        if button == nil {
            button = UIButton(type: .custom)
            button?.frame = CGRect(x: 0, y: 0, width: 75, height: 75)
            button?.addTarget(self, action: #selector(buttonTapped), for: .touchUpInside)
        }
        
        let arraySize = CarouselTableViewCell.ButtonImageNames.count
        let image: UIImage = UIImage(named: CarouselTableViewCell.ButtonImageNames[indexPath.row % arraySize])!
        
        button?.setBackgroundImage(image, for: .normal)
        
        return button!
    }
    
    func startingItemIndex(inCarousel carousel: RACarousel) -> Int {
        return 2
    }
    
    // MARK: -
    // MARK: RACarouselDelegate
    func carousel(_ carousel: RACarousel, valueForOption option: RACarouselOption, withDefaultValue defaultValue: Int) -> Int {
        if option == .itemWidth {
            return 100
        }
        
        return defaultValue
    }
    
    func carousel(_ carousel: RACarousel, didSelectItemAtIndex index: Int) {
        print ("Selected Item at Index : \(index)")
    }

    // MARK: -
    // MARK: buttonTapped
    @objc private func buttonTapped(_ button: UIButton) {
        print ("Button Tapped!")
    }
}
