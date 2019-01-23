//
//  ImageCollectionViewCell.swift
//  RACarousel Demo
//
//  Created by Piotr Suwara on 19/1/19.
//  Copyright © 2019 Piotr Suwara. All rights reserved.
//

import UIKit
import RACarousel

final class ImageCarouselViewCell: UITableViewCell, RACarouselDelegate, RACarouselDataSource {

    var imagesForCells: [UIImage] = [
        UIImage(named: "PageImage1")!,
        UIImage(named: "PageImage2")!,
        UIImage(named: "PageImage3")!,
        UIImage(named: "PageImage4")!
    ]
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var detailsLabel: UILabel!
    
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
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    
    // MARK: -
    // MARK: RACarouselDataSource
    
    func numberOfItems(inCarousel carousel: RACarousel) -> Int {
        return ButtonsCarouselViewCell.NumberOfButtons
    }
    
    func carousel(_: RACarousel, viewForItemAt indexPath: IndexPath, reuseView view: UIView?) -> UIView {

        let view = UIView(frame: carousel.bounds)
        let imageView = UIImageView(image: imagesForCells[indexPath.row % imagesForCells.count])
        view.addSubview(imageView)
        
        imageView.translatesAutoresizingMaskIntoConstraints = false
        
        // Setup some bounding anchors
        imageView.topAnchor.constraint(equalTo: view.topAnchor, constant: 20).isActive = true
        imageView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -20).isActive = true
        imageView.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 20).isActive = true
        imageView.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -20).isActive = true
        
        return view
    }
    
    // MARK: -
    // MARK: RACarouselDelegate
    func carousel(_ carousel: RACarousel, valueForOption option: RACarouselOption, withDefaultValue defaultValue: Int) -> Int {
        if option == .itemWidth {
            return Int(carousel.bounds.width)
        }
        
        return defaultValue
    }
}
