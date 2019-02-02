//
//  RoundedButtonView.swift
//  RACarousel Demo
//
//  Created by Piotr Suwara on 19/1/19.
//  Copyright © 2019 Piotr Suwara. All rights reserved.
//

import UIKit

final class RoundedButtonView: UIView {
    @IBOutlet weak var selectedImageView: UIImageView!
    @IBOutlet weak var unselectedImageView: UIImageView!
    @IBOutlet weak var lowerText: UILabel!
    var shadowView: UIView!
    var roundedView: UIView!
    
    var selectedColor: UIColor = UIColor.blue
    var unselectedColor: UIColor = UIColor.white
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        styleView()
    }
    
    func set(isSelected selected: Bool) {
        if selected {
            self.roundedView.backgroundColor = selectedColor
            self.selectedImageView.alpha = 1
            self.unselectedImageView.alpha = 0
        } else {
            self.roundedView.backgroundColor = unselectedColor
            self.selectedImageView.alpha = 0
            self.unselectedImageView.alpha = 1
        }
    }
    
    private func styleView() {
        shadowView = UIView(frame: frame)
        
        shadowView.layer.shadowColor = UIColor.gray.cgColor
        shadowView.layer.shadowOffset = CGSize.zero
        shadowView.layer.shadowOpacity = 0.25
        shadowView.layer.shadowRadius = 10
        
        roundedView = UIView(frame: shadowView.bounds)
        roundedView.backgroundColor = UIColor.white
        roundedView.layer.cornerRadius = 20.0
        roundedView.clipsToBounds = true
        
        shadowView.addSubview(roundedView)
        backgroundColor = .clear
        insertSubview(shadowView, at: 0)
    }
    
    func triggerSelected() {
        UIView.animate(withDuration: 0.25, animations: { () -> Void in
            self.set(isSelected: true)
        }) { (success) -> Void in
        }
    }
    
    func didDeselect() {
        UIView.animate(withDuration: 0.25, animations: { () -> Void in
            self.set(isSelected: false)
        }) { (success) -> Void in
        }
    }
}
