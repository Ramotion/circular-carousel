//
//  UITableView+Style.swift
//  CircularCarousel Demo
//
//  Created by Piotr Suwara on 2/2/19.
//  Copyright © 2019 Piotr Suwara. All rights reserved.
//

import UIKit

extension UITableView {
    enum DetailStyle {
        case carousel
        case primary
    }
    
    func style(withDetail style: UITableView.DetailStyle) {
        switch style {
        case .carousel:
            separatorColor = ViewConstants.Colors.tableViewSeperator
            cellLayoutMarginsFollowReadableWidth = false
            isScrollEnabled = false
            allowsSelection = false
            
        case .primary:
            separatorColor = ViewConstants.Colors.tableViewSeperator
            cellLayoutMarginsFollowReadableWidth = false
            backgroundColor = .clear
            allowsSelection = false
        }
    }
}
