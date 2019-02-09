//
//  RoundedButtonView.swift
//  CircularCarousel Demo
//
//  Created by Piotr Suwara on 19/1/19.
//  Copyright © 2019 Piotr Suwara. All rights reserved.
//

import UIKit

fileprivate struct Constants {
    static let defaultShadowOpacity: Float      = 0.25
    static let defaultShadowRadius: CGFloat     = 10.0
    static let defaultCornerRadius: CGFloat     = 20.0
}

final class RoundedButtonView: UIView {
    @IBOutlet weak var selectedImageView: UIImageView!
    @IBOutlet weak var unselectedImageView: UIImageView!
    @IBOutlet weak var lowerText: UILabel!
    var shadowView: UIView = UIView()
    var roundedView: UIView = UIView()
    
    var selectedColor: UIColor = UIColor.blue
    var unselectedColor: UIColor = UIColor.white
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        styleView()
    }
    
    func set(isSelected selected: Bool) {
        if selected {
            roundedView.backgroundColor = selectedColor
            selectedImageView.alpha = 1
            unselectedImageView.alpha = 0
        } else {
            roundedView.backgroundColor = unselectedColor
            selectedImageView.alpha = 0
            unselectedImageView.alpha = 1
        }
    }
    
    private func styleView() {
        shadowView.frame = frame
        
        shadowView.layer.shadowColor = UIColor.gray.cgColor
        shadowView.layer.shadowOffset = CGSize.zero
        shadowView.layer.shadowOpacity = Constants.defaultShadowOpacity
        shadowView.layer.shadowRadius = Constants.defaultShadowRadius
        
        roundedView.frame = shadowView.bounds
        roundedView.backgroundColor = UIColor.white
        roundedView.layer.cornerRadius = Constants.defaultCornerRadius
        roundedView.clipsToBounds = true
        
        shadowView.addSubview(roundedView)
        backgroundColor = .clear
        insertSubview(shadowView, at: 0)
    }
    
    func triggerSelected() {
        UIView.animate(withDuration: 0.25, animations: { () -> Void in
            self.set(isSelected: true)
        })
    }
    
    func didDeselect() {
        UIView.animate(withDuration: 0.25, animations: { () -> Void in
            self.set(isSelected: false)
        })
    }
}
