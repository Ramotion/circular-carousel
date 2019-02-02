//
//  ImageCollectionViewCell.swift
//  RACarousel Demo
//
//  Created by Piotr Suwara on 19/1/19.
//  Copyright © 2019 Piotr Suwara. All rights reserved.
//

import UIKit
import RACarousel

struct CarouselViewCellConstants {
    static let numItemsInTable: Int = 10
    static var heightForCell: CGFloat {
        return ViewControllerConstants.imageCellRowHeight * CGFloat(numItemsInTable)
    }
}

final class CarouselViewCell: UITableViewCell,
    UITableViewDataSource,
    UITableViewDelegate,
    RACarouselDelegate,
    RACarouselDataSource {
    
    let imageCellSelection: [ImageCellViewModel] = [
        ImageCellViewModel(imageName: "PageImage1", title: "First", description: "This is a short description"),
        ImageCellViewModel(imageName: "PageImage2", title: "Second", description: "This is a short description"),
        ImageCellViewModel(imageName: "PageImage3", title: "Third", description: "This is a short description"),
        ImageCellViewModel(imageName: "PageImage4", title: "Fourth", description: "This is a short description")
    ]
    
    let imageCellNib: UINib = UINib(nibName: "ImageViewCell", bundle: nil)
    
    // TODO - Setup table views seperately (Do we actually need this?)
    var tableViews: [UITableView]?
    
    
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
        configureView()
    }
    
    func configureView() {
        
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    // MARK: -
    // MARK: RACarouselDataSource
    
    func numberOfItems(inCarousel carousel: RACarousel) -> Int {
        return ButtonCarouselViewConstants.NumberOfButtons
    }
    
    func carousel(_: RACarousel, viewForItemAt indexPath: IndexPath, reuseView view: UIView?) -> UIView {

        if let tableView = view as? UITableView {
            return tableView
        } else {
            
            let tableView = UITableView(frame: carousel.frame, style: .plain)
            
            tableView.delegate = self
            tableView.dataSource = self
            
            tableView.register(imageCellNib, forCellReuseIdentifier: ViewControllerConstants.imageViewCellIdentifier)
            
            tableView.tag = indexPath.row
            tableView.style(with: .carousel)
            
            tableView.reloadData()
            
            return tableView
        }
    }
    
    // MARK: -
    // MARK: RACarouselDelegate
    func carousel(_ carousel: RACarousel, valueForOption option: RACarouselOption, withDefaultValue defaultValue: Int) -> Int {
        if option == .itemWidth {
            return Int(carousel.bounds.width)
        }
        
        return defaultValue
    }
    
    // MARK: -
    // MARK: UITableViewDataSource
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: ImageViewCell = tableView.dequeueReusableCell(withIdentifier: ViewControllerConstants.imageViewCellIdentifier) as! ImageViewCell
        
        let cellSelectionIdx = (indexPath.row + tableView.tag) % imageCellSelection.count
        let cellSelection = imageCellSelection[cellSelectionIdx]
        
        cell.mainImageView.image = UIImage(named: cellSelection.imageName)
        cell.titleLabel.text = cellSelection.title
        cell.detailsLabel.text = cellSelection.description
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 10
    }
    
    // MARK: -
    // MARK: UITableViewDelegate
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return ViewControllerConstants.imageCellRowHeight
    }
}
