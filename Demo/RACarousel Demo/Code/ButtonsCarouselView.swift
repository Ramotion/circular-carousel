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

protocol ButtonCarouselViewDataSource {
    func buttonCarousel(_ buttonCarousel: ButtonCarouselView, modelForIndex: IndexPath) -> ButtonCarouselModel
    func numberOfButtonsForCarousel(_ buttonCarousel: ButtonCarouselView) -> Int
}

protocol ButtonCarouselViewDelegate {
    func buttonCarousel(_ carousel: ButtonCarouselView, buttonPressed button: UIButton)
    func buttonCarousel(_ carousel: ButtonCarouselView, willScrollToIndex index: IndexPath)
    func startingIndexForButtonCarousel(_ carousel: ButtonCarouselView) -> Int
    func itemWidthForButtonCarousel(_ carousel: ButtonCarouselView) -> CGFloat
}

fileprivate struct Constants {
    static let scaleMultiplier:CGFloat = 0.25
    static let minScale:CGFloat = 0.55
    static let maxScale:CGFloat = 1.08
    static let minFade:CGFloat = -2.0
    static let maxFade:CGFloat = 2.0
    static let defaultButtonWidth: CGFloat = 100.0
}

struct ButtonCarouselModel {
    public var selectedImage: UIImage
    public var unselectedImage: UIImage
    public var text: String
}

final class ButtonCarouselView : UITableViewCell, RACarouselDataSource, RACarouselDelegate {
    
    var delegate: ButtonCarouselViewDelegate?
    var dataSource: ButtonCarouselViewDataSource?
    
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
        return dataSource?.numberOfButtonsForCarousel(self) ?? 0
    }
    
    func carousel(_: RACarousel, viewForItemAt indexPath: IndexPath, reuseView view: UIView?) -> UIView {
        assert(indexPath.row < numberOfItems(inCarousel: carousel), "Row index greater than number of items!")
        
        guard let dataSource = dataSource else { return view ?? UIView() }
        
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
            
            let viewModel = dataSource.buttonCarousel(self, modelForIndex: indexPath)
            
            roundedButtonView.selectedImageView.image = viewModel.selectedImage
            roundedButtonView.unselectedImageView.image = viewModel.unselectedImage
            
            roundedButtonView.set(isSelected: indexPath.row == startingItemIndex(inCarousel: carousel))
        }
        
        button?.setBackgroundImage(nil, for: .normal)
        button?.setImage(nil, for: .normal)
        
        return button!
    }
    
    func startingItemIndex(inCarousel carousel: RACarousel) -> Int {
        return delegate?.startingIndexForButtonCarousel(self) ?? 0
    }
    
    // MARK: -
    // MARK: RACarouselDelegate
    
    func carousel<CGFloat>(_ carousel: RACarousel, valueForOption option: RACarouselOption, withDefaultValue defaultValue: CGFloat) -> CGFloat {
        switch option {
        case .itemWidth:
            
        return (delegate?.itemWidthForButtonCarousel(self) ?? Constants.defaultButtonWidth) as! CGFloat
            
        case .scaleMultiplier:
            return Constants.scaleMultiplier as! CGFloat
        
        case .minScale:
            return Constants.minScale as! CGFloat
        
        case .maxScale:
            return Constants.maxScale as! CGFloat
        
        case .fadeMin:
            return Constants.minFade as! CGFloat
        
        case .fadeMax:
            return Constants.maxFade as! CGFloat
        
        default:
            return defaultValue
        }
    }
    
    func carousel(_ carousel: RACarousel, didSelectItemAtIndex index: Int) {        
        let uiButton = carousel.viewWithTag(index + 1) as! UIButton
        delegate?.buttonCarousel(self, buttonPressed: uiButton)
    }
    
    func carousel(_ carousel: RACarousel, willBeginScrollingToIndex index: Int) {
        
        delegate?.buttonCarousel(self, willScrollToIndex: IndexPath(row: index, section: 0))
        
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
