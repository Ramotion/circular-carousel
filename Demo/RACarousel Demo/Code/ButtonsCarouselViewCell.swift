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

struct ButtonCarouselViewConstants {
    public static let ScaleMultiplier:CGFloat = 0.25
    public static let MinScale:CGFloat = 0.6
    public static let MaxScale:CGFloat = 1.05
    public static let MinFade:CGFloat = -2.0
    public static let MaxFade:CGFloat = 2.0
    public static let NumberOfButtons = 5
    public static let StartingItemIdx = 0
    public static let ButtonViewModels: [ButtonsCarouselViewModel] = [
        ButtonsCarouselViewModel(selectedImage: UIImage(named: "ButtonImageWhite1")!,
                                 unselectedImage: UIImage(named: "ButtonImageGray1")!,
                                 text: "Parking"),
        ButtonsCarouselViewModel(selectedImage: UIImage(named: "ButtonImageWhite2")!,
                                 unselectedImage: UIImage(named: "ButtonImageGray2")!,
                                 text: "Clothing"),
        ButtonsCarouselViewModel(selectedImage: UIImage(named: "ButtonImageWhite3")!,
                                 unselectedImage: UIImage(named: "ButtonImageGray3")!,
                                 text: "Food"),
        ButtonsCarouselViewModel(selectedImage: UIImage(named: "ButtonImageWhite4")!,
                                 unselectedImage: UIImage(named: "ButtonImageGray4")!,
                                 text: "Lodging"),
        ButtonsCarouselViewModel(selectedImage: UIImage(named: "ButtonImageWhite5")!,
                                 unselectedImage: UIImage(named: "ButtonImageGray5")!,
                                 text: "Map")
    ]
}

struct ButtonsCarouselViewModel {
    public var selectedImage: UIImage
    public var unselectedImage: UIImage
    public var text: String
}

final class ButtonsCarouselViewCell : UITableViewCell, RACarouselDataSource, RACarouselDelegate {
    
    var delegate: ButtonsCarouselViewCellDelegate?
    var selectedRoundedButtonIndex: Int = -1
    
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
        return ButtonCarouselViewConstants.NumberOfButtons
    }
    
    func carousel(_: RACarousel, viewForItemAt indexPath: IndexPath, reuseView view: UIView?) -> UIView {
        var button = view as? UIButton
        var contentView: RoundedButtonView?
        
        if button == nil {
            button = UIButton(type: .custom)
            button?.frame = CGRect(x: 0, y: 0, width: 75, height: 75)
            
            contentView = .fromNib()
            
            contentView?.frame = button?.frame ?? CGRect.zero
            if indexPath.row == 0 {
                selectedRoundedButtonIndex = indexPath.row
            }
            
            button?.insertSubview(contentView!, at: 0)
            button?.addTarget(self, action: #selector(buttonTapped), for: .touchUpInside)
        }
        
        button?.tag = indexPath.row + 1
        
        contentView = button?.subviews[0] as? RoundedButtonView
        let arraySize = ButtonCarouselViewConstants.ButtonViewModels.count
        let viewModel = ButtonCarouselViewConstants.ButtonViewModels[indexPath.row % arraySize]
        contentView!.selectedImageView.image = viewModel.selectedImage
        contentView!.unselectedImageView.image = viewModel.unselectedImage
        //contentView!.lowerText.text = viewModel.text
        
        contentView?.set(isSelected: indexPath.row == 0)
        
        button?.setBackgroundImage(nil, for: .normal)
        button?.setImage(nil, for: .normal)
        
        return button!
    }
    
    func startingItemIndex(inCarousel carousel: RACarousel) -> Int {
        return ButtonCarouselViewConstants.StartingItemIdx
    }
    
    // MARK: -
    // MARK: RACarouselDelegate
    func carousel(_ carousel: RACarousel, valueForOption option: RACarouselOption, withDefaultValue defaultValue: Int) -> Int {
        switch option {
        case .itemWidth:
            return 80
        default:
            return defaultValue
        }
    }
    
    func carousel<CGFloat>(_ carousel: RACarousel, valueForOption option: RACarouselOption, withDefaultValue defaultValue: CGFloat) -> CGFloat {
        switch option {
        
        case .scaleMultiplier:
            return ButtonCarouselViewConstants.ScaleMultiplier as! CGFloat
        
        case .minScale:
            return ButtonCarouselViewConstants.MinScale as! CGFloat
        
        case .maxScale:
            return ButtonCarouselViewConstants.MaxScale as! CGFloat
        
        case .fadeMin:
            return ButtonCarouselViewConstants.MinFade as! CGFloat
        
        case .fadeMax:
            return ButtonCarouselViewConstants.MaxFade as! CGFloat
        
        default:
            return defaultValue
        }
        
    }
    
    func carousel(_ carousel: RACarousel, didSelectItemAtIndex index: Int) {        
        let uiButton = carousel.viewWithTag(index + 1) as! UIButton
        delegate?.buttonCarousel(self, buttonPressed: uiButton)
    }
    
    func carousel(_ carousel: RACarousel, willBeginScrollingToIndex index: Int) {
        
        delegate?.buttonCarousel(self, willScrollToIndex: index)
        
        var uiButton = carousel.viewWithTag(index + 1) as? UIButton
        var selectedRoundedButton = uiButton?.subviews[0] as? RoundedButtonView
        selectedRoundedButton?.triggerSelected()
        
        if selectedRoundedButtonIndex != index {
            uiButton = carousel.viewWithTag(selectedRoundedButtonIndex + 1) as? UIButton
            selectedRoundedButton = uiButton?.subviews[0] as? RoundedButtonView
            selectedRoundedButton?.didDeselect()
        }
        
        selectedRoundedButtonIndex = index
    }
    
    func carousel(_ carousel: RACarousel, spacingForOffset offset: CGFloat) -> CGFloat {
        // Tweaked values to support even spacing on scaled items
        return 1.20 - abs(offset * 0.1)
    }

    // MARK: -
    // MARK: buttonTapped
    @objc private func buttonTapped(_ button: UIButton) {
        delegate?.buttonCarousel(self, buttonPressed: button)
    }
}
