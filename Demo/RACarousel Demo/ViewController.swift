//
//  ViewController.swift
//  RACarousel Demo
//
//  Created by Piotr Suwara on 24/12/18.
//  Copyright © 2018 Piotr Suwara. All rights reserved.
//

import UIKit
import RACarousel

class ViewControllerConstants {
    static let CarouselRows = [1]
    static let ContainerRows = [2]
    static let NumberOfRows = 30
    static let CarouselTableViewCellIdentifier = "CarouselTableViewCellIdentifier"
    static let UITableViewCellIdentifier = "UITableViewCell"
    static let CarouselCellRowHeight: CGFloat = 200.0
    static let NormalCellRowHeight: CGFloat = 50.0
    static let TopRowHeight:CGFloat = 400.0
}

class ViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, CarouselTableViewCellDelegate {
    
    //var tableViewHeaderSize: CGSize = CGSize.zero
    
    @IBOutlet weak var tableView: UITableView!
    
    private var swipePanToggle: Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        // Register custom cell for carousel
        tableView.separatorColor = UIColor.clear
        tableView.register(UINib(nibName: "CarouselTableViewCell", bundle: nil), forCellReuseIdentifier: ViewControllerConstants.CarouselTableViewCellIdentifier)
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: ViewControllerConstants.UITableViewCellIdentifier)
        
        // Setup table view controls
        tableView.allowsSelection = false
    }

    // MARK: -
    // MARK: UITableViewDataSource
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let row = indexPath.row
        
        switch row {
        case 0:
            let cell = UITableViewCell()
            cell.backgroundColor = UIColor.clear
            return cell
        
        case let x where ViewControllerConstants.CarouselRows.contains(x):
            let cell: CarouselTableViewCell = tableView.dequeueReusableCell(withIdentifier: ViewControllerConstants.CarouselTableViewCellIdentifier) as! CarouselTableViewCell
            cell.backgroundColor = UIColor.clear
            let swipeRow = (row % 2) == 1
            
            cell.carousel.panEnabled = false
            cell.carousel.swipeEnabled = true
            
            swipePanToggle = !swipeRow
            
            return cell
            
        default:
            let cell: UITableViewCell = tableView.dequeueReusableCell(withIdentifier: ViewControllerConstants.UITableViewCellIdentifier)!
            cell.textLabel?.text = "CELL : \(row)"
            
            return cell
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return ViewControllerConstants.NumberOfRows
    }
    
    // MARK: -
    // MARK: UITableViewDelegate
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        
        switch indexPath.row {
        case 0:
            return ViewControllerConstants.TopRowHeight
        case let x where ViewControllerConstants.CarouselRows.contains(x):
            return ViewControllerConstants.CarouselCellRowHeight
        default:
            return ViewControllerConstants.NormalCellRowHeight
        }
    }
    
    // MARK: -
    // MARK: CarouselTableViewCellDelegate
    
    func carousel(_ carousel: RACarousel, buttonPressed button: UIButton) {
        let defaultAction = UIAlertAction(title: "OK", style: .default) { (action) in
            // Do nothing
        }
        
        let index = carousel.indexOfItem(forView: button)
        let alert = UIAlertController(title: "Button Tapped", message: "Button tapped at index \(index)", preferredStyle: .alert)
        alert.addAction(defaultAction)
        
        self.present(alert, animated: true)
    }
}

