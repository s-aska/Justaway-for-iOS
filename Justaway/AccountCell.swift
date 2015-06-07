//
//  AccountCell.swift
//  Justaway
//
//  Created by Shinichiro Aska on 5/24/15.
//  Copyright (c) 2015 Shinichiro Aska. All rights reserved.
//

import UIKit
import EventBox

class AccountCell: BackgroundTableViewCell {
    
    @IBOutlet weak var iconImageView: UIImageView!
    @IBOutlet weak var displayNameLabel: DisplayNameLable!
    @IBOutlet weak var screenNameLabel: ScreenNameLable!
    @IBOutlet weak var clientNameLabel: ClientNameLable!
    
    // MARK: - View Life Cycle
    
    override func awakeFromNib() {
        super.awakeFromNib()
        configureView()
    }
    
    // MARK: - Configuration
    
    func configureView() {
        selectionStyle = .None
        separatorInset = UIEdgeInsetsZero
        layoutMargins = UIEdgeInsetsZero
        preservesSuperviewLayoutMargins = false
    }
}
