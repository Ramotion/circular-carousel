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

struct ButtonCarouselConstants {
    static let scaleMultiplier:CGFloat = 0.25
    static let minScale:CGFloat = 0.55
    static let maxScale:CGFloat = 1.08
    static let minFade:CGFloat = -2.0
    static let maxFade:CGFloat = 2.0
    static let startingItemIdx = 0
    static let buttonWidth = 80
    static let buttonViewModels: [ButtonsCarouselViewModel] = [
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
    var numberOfButtons: Int = 3
    
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
        return numberOfButtons
    }
    
    func carousel(_: RACarousel, viewForItemAt indexPath: IndexPath, reuseView view: UIView?) -> UIView {
        var button = view as? UIButton
        var roundedButtonView: RoundedButtonView?
        
        if button == nil {
            button = UIButton(type: .custom)
            button?.frame = CGRect(origin: CGPoint(x: 0, y: 0), size: ViewConstants.Size.roundedButton)
            
            roundedButtonView = .fromNib()
            if let roundedButtonView = roundedButtonView {
                roundedButtonView.frame = button?.frame ?? CGRect.zero
                if indexPath.row == 0 {
                    selectedRoundedButtonIndex = indexPath.row
                }
                
                roundedButtonView.selectedColor = ViewConstants.Colors.carouselButtonSelected
                roundedButtonView.unselectedColor = ViewConstants.Colors.carouselButtonUnselected

                button?.insertSubview(roundedButtonView, at: 0)
            }
            
            button?.addTarget(self, action: #selector(buttonTapped), for: .touchUpInside)
        }
        
        button?.tag = indexPath.row + 1
        
        if let roundedButtonView = button?.subviews[0] as? RoundedButtonView {
            let arraySize = ButtonCarouselConstants.buttonViewModels.count
            let viewModel = ButtonCarouselConstants.buttonViewModels[indexPath.row % arraySize]
            
            roundedButtonView.selectedImageView.image = viewModel.selectedImage
            roundedButtonView.unselectedImageView.image = viewModel.unselectedImage
            
            roundedButtonView.set(isSelected: indexPath.row == 0)
        }
        
        button?.setBackgroundImage(nil, for: .normal)
        button?.setImage(nil, for: .normal)
        
        return button!
    }
    
    func startingItemIndex(inCarousel carousel: RACarousel) -> Int {
        return ButtonCarouselConstants.startingItemIdx
    }
    
    // MARK: -
    // MARK: RACarouselDelegate
    func carousel(_ carousel: RACarousel, valueForOption option: RACarouselOption, withDefaultValue defaultValue: Int) -> Int {
        switch option {
        case .itemWidth:
            return ButtonCarouselConstants.buttonWidth
        default:
            return defaultValue
        }
    }
    
    func carousel<CGFloat>(_ carousel: RACarousel, valueForOption option: RACarouselOption, withDefaultValue defaultValue: CGFloat) -> CGFloat {
        switch option {
        
        case .scaleMultiplier:
            return ButtonCarouselConstants.scaleMultiplier as! CGFloat
        
        case .minScale:
            return ButtonCarouselConstants.minScale as! CGFloat
        
        case .maxScale:
            return ButtonCarouselConstants.maxScale as! CGFloat
        
        case .fadeMin:
            return ButtonCarouselConstants.minFade as! CGFloat
        
        case .fadeMax:
            return ButtonCarouselConstants.maxFade as! CGFloat
        
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
        return 1.20 - abs(offset * 0.12)
    }

    // MARK: -
    // MARK: buttonTapped
    @objc private func buttonTapped(_ button: UIButton) {
        delegate?.buttonCarousel(self, buttonPressed: button)
    }
}
