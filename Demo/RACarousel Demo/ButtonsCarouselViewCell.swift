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

protocol ButtonsCarouselViewCellDelegate {
    func buttonCarousel(_ carousel: ButtonsCarouselViewCell, buttonPressed button: UIButton)
    func buttonCarousel(_ carousel: ButtonsCarouselViewCell, willScrollToIndex index: Int)
}

class ButtonsCarouselViewCell : UITableViewCell, RACarouselDataSource, RACarouselDelegate {
    
    static let ScaleMultiplier:CGFloat = 0.25
    static let MinScale:CGFloat = 0.75
    static let MaxScale:CGFloat = 1.10
    static let NumberOfButtons = 5
    static let ButtonImageNames = ["IconImage1", "IconImage2", "IconImage3", "IconImage4", "IconImage2"]
    
    var delegate: ButtonsCarouselViewCellDelegate?
    
    weak var _carousel : RACarousel!
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
    
    // MARK: -
    // MARK: RACarouselDataSource
    
    func numberOfItems(inCarousel carousel: RACarousel) -> Int {
        return ButtonsCarouselViewCell.NumberOfButtons
    }
    
    func carousel(_: RACarousel, viewForItemAt indexPath: IndexPath, reuseView view: UIView?) -> UIView {
        var button = view as? UIButton
        if button == nil {
            button = UIButton(type: .custom)
            button?.frame = CGRect(x: 0, y: 0, width: 75, height: 75)
            button?.addTarget(self, action: #selector(buttonTapped), for: .touchUpInside)
        }
        
        let arraySize = ButtonsCarouselViewCell.ButtonImageNames.count
        let image: UIImage = UIImage(named: ButtonsCarouselViewCell.ButtonImageNames[indexPath.row % arraySize])!
        
        button?.setBackgroundImage(image, for: .normal)
        button?.layer.shadowColor = UIColor.lightGray.cgColor;
        button?.layer.shadowOpacity = 0.8;
        button?.layer.shadowRadius = 12;
        button?.layer.shadowOffset = CGSize(width: 5.0, height: 5.0)
        
        return button!
    }
    
    func startingItemIndex(inCarousel carousel: RACarousel) -> Int {
        return 2
    }
    
    // MARK: -
    // MARK: RACarouselDelegate
    func carousel(_ carousel: RACarousel, valueForOption option: RACarouselOption, withDefaultValue defaultValue: Int) -> Int {
        switch option {
        case .itemWidth:
            return 100
        default:
            return defaultValue
        }
    }
    
    func carousel<CGFloat>(_ carousel: RACarousel, valueForOption option: RACarouselOption, withDefaultValue defaultValue: CGFloat) -> CGFloat {
        switch option {
        case .scaleMultiplier:
            return ButtonsCarouselViewCell.ScaleMultiplier as! CGFloat
        case .minScale:
            return ButtonsCarouselViewCell.MinScale as! CGFloat
        case .maxScale:
            return ButtonsCarouselViewCell.MaxScale as! CGFloat
        default:
            return defaultValue
        }
        
    }
    
    func carousel(_ carousel: RACarousel, didSelectItemAtIndex index: Int) {
        print ("Selected Item at Index : \(index)")
    }
    
    func carousel(_ carousel: RACarousel, willBeginScrollingToIndex index: Int) {
        delegate?.buttonCarousel(self, willScrollToIndex: index)
    }

    // MARK: -
    // MARK: buttonTapped
    @objc private func buttonTapped(_ button: UIButton) {
        delegate?.buttonCarousel(self, buttonPressed: button)
    }
}
