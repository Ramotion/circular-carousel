//
//  ViewController.swift
//  RACarousel Demo
//
//  Created by Piotr Suwara on 24/12/18.
//  Copyright © 2018 Piotr Suwara. All rights reserved.
//

import UIKit
import RACarousel

enum MainTableRowTypes: Int {
    case clearRow = 0
    case buttonCarouselRow = 1
    case carouselRow = 2
}

struct ViewControllerConstants {
    public static let buttonCarouselRow = 1
    public static let carouselRow = 2
    public static let imageCarouselRow = -1
    public static let containerRows = [2]
    public static let numberOfRows = 3
    public static let carouselViewCellIdentifier = "CarouselViewCellIdentifier"
    public static let buttonsViewCellIdentifier = "ButtonsViewCellIdentifier"
    public static let imageViewCellIdentifier  = "ImageViewCellIdentifier"
    public static let tableViewCellIdentifier = "UITableViewCell"
    public static let tableViewSeperatorColor = UIColor(white: 0.85, alpha: 1.0)
    
    public static let buttonsCarouselCellRowHeight: CGFloat = 200.0
    public static let imageCellRowHeight: CGFloat = 300.0
    public static let normalCellRowHeight: CGFloat = 50.0
    public static let carouselRowHeight: CGFloat = 500.0
    
    public static let topRowMargin: CGFloat = 0.6
    public static let gradientColors: [UIColor] = [
        UIColor(red: 53/255, green: 136/255, blue: 206/255, alpha: 1),
        UIColor(red: 155/255, green: 211/255, blue: 230/255, alpha: 1)]
}

final class ViewController: UIViewController,
    UITableViewDataSource,
    UITableViewDelegate,
    ButtonsCarouselViewCellDelegate
{
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var gradientView: UIView!
    @IBOutlet weak var whiteBottomView: UIView!
    
    var carouselViewCell: CarouselViewCell?
    var buttonsCarouselViewCell: ButtonsCarouselViewCell?
    var imageCarouselViewCell: ImageCarouselViewCell?
    
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
    }
    
    private func styleViews() {
        // Setup gradient view (cyan -> dark blue)
        tableView.style(with: .primary)
        gradientView.applyGradient(withColors: ViewControllerConstants.gradientColors)
    }
    
    private func configureViews() {
        configureTableView()
    }
    
    private func configureTableView() {
        // Setup table view controls
        tableView.allowsSelection = false

        tableView.register(UINib(nibName: "CarouselViewCell", bundle: nil), forCellReuseIdentifier: ViewControllerConstants.carouselViewCellIdentifier)
        tableView.register(UINib(nibName: "ButtonsCarouselViewCell", bundle: nil), forCellReuseIdentifier: ViewControllerConstants.buttonsViewCellIdentifier)        
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: ViewControllerConstants.tableViewCellIdentifier)
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
            
        case ViewControllerConstants.carouselRow:
            let cell: CarouselViewCell = tableView.dequeueReusableCell(withIdentifier: ViewControllerConstants.carouselViewCellIdentifier) as! CarouselViewCell
            
            cell.carousel.panEnabled = false
            cell.carousel.swipeEnabled = false
            
            carouselViewCell = cell
            
            return cell
        
        case ViewControllerConstants.buttonCarouselRow:
            let cell: ButtonsCarouselViewCell = tableView.dequeueReusableCell(withIdentifier: ViewControllerConstants.buttonsViewCellIdentifier) as! ButtonsCarouselViewCell
            cell.backgroundColor = UIColor.clear
            
            cell.carousel.panEnabled = false
            cell.carousel.swipeEnabled = true
            cell.delegate = self
            
            buttonsCarouselViewCell = cell
            
            return cell
            
        default:
            let cell: UITableViewCell = tableView.dequeueReusableCell(withIdentifier: ViewControllerConstants.tableViewCellIdentifier)!
            return cell
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return ViewControllerConstants.numberOfRows
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
            let margin = ViewControllerConstants.topRowMargin * height
            return margin
        case ViewControllerConstants.buttonCarouselRow:
            return ViewControllerConstants.buttonsCarouselCellRowHeight
        case ViewControllerConstants.carouselRow:
            return CarouselViewCellConstants.heightForCell
        default:
            return ViewControllerConstants.normalCellRowHeight
        }
    }
    
    // MARK: -
    // MARK: UIScrollViewDelegate
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        whiteBottomView.frame = CGRect(origin: CGPoint(x: 0, y: scrollView.contentSize.height - scrollView.contentOffset.y + /*scrollView.frame.height*/0), size: whiteBottomView.frame.size)
        
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
    // MARK: ButtonsCarouselViewCell
    
    func buttonCarousel(_ carousel: ButtonsCarouselViewCell, buttonPressed button: UIButton) {
    }
    
    func buttonCarousel(_ carousel: ButtonsCarouselViewCell, willScrollToIndex index: Int) {
        // Pass the message to the image carousel
        carouselViewCell?.carousel.scroll(toItemAtIndex: index, animated: true)
    }
}

