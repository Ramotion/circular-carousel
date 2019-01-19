//
//  RoundedButtonView.swift
//  RACarousel Demo
//
//  Created by Piotr Suwara on 19/1/19.
//  Copyright © 2019 Piotr Suwara. All rights reserved.
//

import UIKit

class RoundedButtonView: UIView {
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var lowerText: UILabel!
    var shadowView: UIView!
    var roundedView: UIView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        styleView()
    }
    
    private func styleView() {
        shadowView = UIView(frame: self.frame)
        
        shadowView.layer.shadowColor = UIColor.black.cgColor
        shadowView.layer.shadowOffset = CGSize.zero
        shadowView.layer.shadowOpacity = 0.5
        shadowView.layer.shadowRadius = 5
        
        roundedView = UIView(frame: shadowView.bounds)
        roundedView.backgroundColor = UIColor.white
        roundedView.layer.cornerRadius = 20.0
        roundedView.layer.borderColor = UIColor.gray.cgColor
        roundedView.layer.borderWidth = 0.5
        roundedView.clipsToBounds = true
        
        shadowView.addSubview(roundedView)
        self.backgroundColor = .clear
        self.insertSubview(shadowView, at: 0)
    }
    
    func triggerSelected() {
        UIView.animate(withDuration: 0.25, animations: { () -> Void in
            self.roundedView.backgroundColor = .blue
        }) { (success) -> Void in
            print("anim finished")
        }
    }
    
    func didDeselect() {
        UIView.animate(withDuration: 0.25, animations: { () -> Void in
            self.roundedView.backgroundColor = .white
        }) { (success) -> Void in
            print("anim finished")
        }
    }
}
