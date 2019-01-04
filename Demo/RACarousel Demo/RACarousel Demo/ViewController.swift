//
//  ViewController.swift
//  RACarousel Demo
//
//  Created by Piotr Suwara on 24/12/18.
//  Copyright © 2018 Piotr Suwara. All rights reserved.
//

import UIKit

class ViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, CarouselTableViewCellDelegate {

    static let CarouselRow = 3
    static let NumberOfRows = 30
    static let CarouselTableViewCellIdentifier = "CarouselTableViewCellIdentifier"
    static let UITableViewCellIdentifier = "UITableViewCell"
    static let CarouselCellRowHeight: CGFloat = 300.0
    static let NormalCellRowHeight: CGFloat = 50.0
    
    @IBOutlet weak var tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        // Register custom cell for carousel
        tableView.register(UINib(nibName: "CarouselTableViewCell", bundle: nil), forCellReuseIdentifier: ViewController.CarouselTableViewCellIdentifier)
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: ViewController.UITableViewCellIdentifier)
        tableView.allowsSelection = false
    }

    // MARK: -
    // MARK: UITableViewDataSource
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let row = indexPath.row
        
        switch row {
        case ViewController.CarouselRow:
            let cell: CarouselTableViewCell = tableView.dequeueReusableCell(withIdentifier: ViewController.CarouselTableViewCellIdentifier) as! CarouselTableViewCell
            
            cell.title.text = "CAROUSEL CELL"
            return cell
            
        default:
            let cell: UITableViewCell = tableView.dequeueReusableCell(withIdentifier: ViewController.UITableViewCellIdentifier)!
            
            cell.textLabel?.text = "CELL : \(row)"
            return cell
            
        }
        
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return ViewController.NumberOfRows
    }
    
    // MARK: -
    // MARK: UITableViewDelegate
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        switch indexPath.row {
        case ViewController.CarouselRow:
            return ViewController.CarouselCellRowHeight
        default:
            return ViewController.NormalCellRowHeight
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

