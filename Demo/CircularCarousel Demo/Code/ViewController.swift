//
//  ViewController.swift
//  CircularCarousel Demo
//
//  Created by Piotr Suwara on 24/12/18.
//  Copyright © 2018 Piotr Suwara. All rights reserved.
//

import UIKit
import CircularCarousel

final class ViewController: UIViewController,
    UITableViewDataSource,
    UITableViewDelegate,
    ButtonCarouselViewDelegate,
    ButtonCarouselViewDataSource,
    TableCarouselViewDelegate
{
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var gradientView: UIView!
    @IBOutlet weak var whiteBottomView: UIView!
    
    var tableCarouselView: TableCarouselView?
    var buttonCarouselView: ButtonCarouselView?
    var selectedItemIndex = ViewConstants.startingCarouselItem
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        styleViews()
        configureViews()
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        
        gradientView.layer.sublayers?[0].frame = gradientView.layer.bounds
        applyImageScale(withScrollView: tableView)
    }
    
    private func styleViews() {
        // Setup gradient view (cyan -> dark blue)
        tableView.style(withDetail: .primary)
        gradientView.applyGradient(withColors: ViewConstants.Colors.gradient)
    }
    
    private func configureViews() {
        configureTableView()
    }
    
    private func configureTableView() {
        // Setup table view controls
        tableView.register(UINib(nibName: ViewConstants.NibNames.tableCarousel, bundle: nil), forCellReuseIdentifier: ViewConstants.CellIdentifiers.tableCarousel)
        tableView.register(UINib(nibName: ViewConstants.NibNames.buttons, bundle: nil), forCellReuseIdentifier: ViewConstants.CellIdentifiers.buttons)
        tableView.separatorInset.left = 0
        tableView.bounds = CGRect(x: 0,
                                  y: 0,
                                  width: tableView.bounds.size.width,
                                  height: tableView.bounds.size.height * 2)
    }
    
    private func applyImageScale(withScrollView scrollView: UIScrollView) {
        whiteBottomView.frame = CGRect(origin: CGPoint(x: 0,
                                                       y: scrollView.contentSize.height - scrollView.contentOffset.y + 0),
                                       size: whiteBottomView.frame.size)
        
        let minScale:CGFloat = 1.1
        let maxScale:CGFloat = 2.0
        
        let offset = tableView.contentOffset.y
        let height = tableView.contentSize.height
        
        var scale = (1.0 / height) * offset
        
        scale = scale * (maxScale - minScale)
        scale += minScale
        
        imageView.applyScale(scale)
    }

    // MARK: -
    // MARK: UITableViewDataSource
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let row = indexPath.row
        
        switch row {
        case 0:
            let cell = UITableViewCell()
            cell.backgroundColor = UIColor.clear
            cell.separatorInset = UIEdgeInsets(top: 0.0, left: tableView.bounds.size.width, bottom: 0.0, right: 0.0)
            return cell
            
        case ViewConstants.RowIndex.tableCarousel:
            if let tableCarouselView = self.tableCarouselView {
                // Cache the table Carousel view - There is only one
                return tableCarouselView
            } else {
                let cell: TableCarouselView = tableView.dequeueReusableCell(withIdentifier: ViewConstants.CellIdentifiers.tableCarousel) as! TableCarouselView
                
                cell.delegate = self
                
                cell.carousel.panEnabled = false
                cell.carousel.swipeEnabled = false
                cell.carousel.reloadData()
                tableCarouselView = cell
                return cell
            }
        
        case ViewConstants.RowIndex.buttonCarousel:
            let cell: ButtonCarouselView = tableView.dequeueReusableCell(withIdentifier: ViewConstants.CellIdentifiers.buttons) as! ButtonCarouselView
            cell.backgroundColor = UIColor.clear
            
            cell.delegate = self
            cell.dataSource = self

            cell.carousel.panEnabled = false
            cell.carousel.swipeEnabled = true
            
            cell.carousel.reloadData()
            
            buttonCarouselView = cell
            
            return cell
            
        default:
            return UITableViewCell()
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return ViewConstants.numberOfPrimaryViewRows
    }
    
    // MARK: -
    // MARK: UITableViewDelegate
    
    func tableView(_ tableView: UITableView,
                   willDisplay cell: UITableViewCell,
                   forRowAt indexPath: IndexPath) {
        if indexPath.row == 0 {
            cell.backgroundView = nil
            cell.backgroundColor = UIColor.clear
            cell.layer.backgroundColor = UIColor.clear.cgColor
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        switch indexPath.row {
        case 0:
            let height = view.bounds.height
            let margin = ViewConstants.topRowScreenRatio * height
            return margin
        case ViewConstants.RowIndex.buttonCarousel:
            return ViewConstants.CellHeights.buttonsCarousel
        case ViewConstants.RowIndex.tableCarousel:
            return ViewConstants.CellHeights.tableCarousel
        default:
            return ViewConstants.CellHeights.normal
        }
    }
    
    // MARK: -
    // MARK: UIScrollViewDelegate
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        applyImageScale(withScrollView: scrollView)
    }
    
    // MARK: -
    // MARK: ButtonCarouselViewDataSource
    func buttonCarousel(_ buttonCarousel: ButtonCarouselView, modelForIndex index: IndexPath) -> ButtonCarouselModel {
        return Data.buttonViewModels[index.row]
    }
    
    func numberOfButtons(inButtonCarousel buttonCarousel: ButtonCarouselView) -> Int {
        return Data.buttonViewModels.count
    }
    
    
    // MARK: -
    // MARK: ButtonCarouselViewDelegate
    
    func buttonCarousel(_ carousel: ButtonCarouselView, buttonPressed button: UIButton) {
    }
    
    func buttonCarousel(_ carousel: ButtonCarouselView, willScrollToIndex index: IndexPath) {
        // Pass the message to the image carousel
        selectedItemIndex = index.row
        tableCarouselView?.carousel.scroll(toItemAtIndex: index.row, animated: true)
    }
    
    func startingIndex(forButtonCarousel carousel: ButtonCarouselView) -> Int {
        return selectedItemIndex
    }
    
    func itemWidth(forButtonCarousel carousel: ButtonCarouselView) -> CGFloat {
        return ViewConstants.Size.carouselButtonItemWidith
    }
    
    // MARK: -
    // MARK: TableCarouselViewDelegate
    func numberOfItems(inTableCarousel view: TableCarouselView) -> Int {
        return ViewConstants.numberOfCarouselItems
    }
}

