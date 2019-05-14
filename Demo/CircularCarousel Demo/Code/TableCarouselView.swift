//
//  TableCarouselView.swift
//  CircularCarousel Demo
//
//  Created by Piotr Suwara on 19/1/19.
//  Copyright © 2019 Piotr Suwara. All rights reserved.
//

import UIKit
import CircularCarousel

protocol TableCarouselViewDelegate {
    func numberOfItems(inTableCarousel tableCarouselView: TableCarouselView) -> Int
}

final class TableCarouselView: UITableViewCell,
    UITableViewDataSource,
    UITableViewDelegate,
    CircularCarouselDelegate,
    CircularCarouselDataSource {
    
    var delegate: TableCarouselViewDelegate?
    
    weak var _carousel : CircularCarousel!
    @IBOutlet var carousel : CircularCarousel! {
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
    
    func carouselItemTableView(atIndexPath indexPath: IndexPath) -> UITableView {
        let tableView = UITableView(frame: self.frame, style: .plain)
        
        tableView.translatesAutoresizingMaskIntoConstraints = false
        
        tableView.delegate = self
        tableView.dataSource = self
        
        tableView.register(UINib(nibName: ViewConstants.NibNames.image, bundle: nil), forCellReuseIdentifier: ViewConstants.CellIdentifiers.image)
        
        tableView.tag = indexPath.row
        tableView.style(withDetail: .carousel)
        tableView.clipsToBounds = false
        tableView.separatorInset.left = 0
        
        return tableView
    }
    
    // MARK: -
    // MARK: CircularCarouselDataSource
    
    func numberOfItems(inCarousel carousel: CircularCarousel) -> Int {
        return delegate?.numberOfItems(inTableCarousel: self) ?? 0
    }
    
    func carousel(_: CircularCarousel, viewForItemAt indexPath: IndexPath, reuseView view: UIView?) -> UIView {

        if let tableView = view as? UITableView {
            tableView.tag = indexPath.row
            tableView.style(withDetail: .carousel)
            tableView.clipsToBounds = false
            
            return tableView
        } else {
            let tableView = carouselItemTableView(atIndexPath: indexPath)
            return tableView
        }
    }
    
    // MARK: -
    // MARK: CircularCarouselDelegate
    func carousel(_ carousel: CircularCarousel, valueForOption option: CircularCarouselOption, withDefaultValue defaultValue: Int) -> Int {
        if option == .itemWidth {
            return Int(carousel.bounds.width)
        }
        
        return defaultValue
    }
    
    // MARK: -
    // MARK: UITableViewDataSource
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: ImageViewCell = tableView.dequeueReusableCell(withIdentifier: ViewConstants.CellIdentifiers.image) as! ImageViewCell
        let cellSelectionIdx = (indexPath.row + tableView.tag) % Data.imageCellSelection.count
        let cellSelection = Data.imageCellSelection[cellSelectionIdx]
        
        cell.mainImageView.image = UIImage(named: cellSelection.imageName)
        cell.titleLabel.text = cellSelection.title
        cell.detailsLabel.text = cellSelection.description
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return ViewConstants.numberOfTableViewRows
    }
    
    // MARK: -
    // MARK: UITableViewDelegate
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return ViewConstants.CellHeights.image
    }
}
