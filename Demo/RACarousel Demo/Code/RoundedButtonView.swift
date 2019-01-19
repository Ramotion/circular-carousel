//
//  RoundedButtonView.swift
//  RACarousel Demo
//
//  Created by Piotr Suwara on 19/1/19.
//  Copyright © 2019 Piotr Suwara. All rights reserved.
//

import UIKit

class RoundedButtonView: UIView {
    @IBOutlet weak var image: UIImageView!
    @IBOutlet weak var lowerText: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        styleView()
    }
    
    private func styleView() {
        let shadowView = UIView(frame: self.frame)
        
        shadowView.layer.shadowColor = UIColor.black.cgColor
        shadowView.layer.shadowOffset = CGSize.zero
        shadowView.layer.shadowOpacity = 0.5
        shadowView.layer.shadowRadius = 5
        
        let view = UIView(frame: shadowView.bounds)
        view.backgroundColor = UIColor.white
        view.layer.cornerRadius = 10.0
        view.layer.borderColor = UIColor.gray.cgColor
        view.layer.borderWidth = 0.5
        view.clipsToBounds = true
        
        shadowView.addSubview(view)
        self.addSubview(shadowView)
    }
    
    func triggerSelected() {
        
    }
    
    func didDeselect() {
        
    }
}
