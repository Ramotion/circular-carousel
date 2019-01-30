//
//  ImageViewCell.swift
//  RACarousel Demo
//
//  Created by Piotr Suwara on 30/1/19.
//  Copyright © 2019 Piotr Suwara. All rights reserved.
//

import UIKit

class ImageViewCell: UITableViewCell {

    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var detailsLabel: UILabel!
    @IBOutlet var mainImageView: UIImageView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
