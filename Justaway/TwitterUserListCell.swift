//
//  TwitterUserListCell.swift
//  Justaway
//
//  Created by Shinichiro Aska on 7/3/15.
//  Copyright (c) 2015 Shinichiro Aska. All rights reserved.
//

import UIKit

class TwitterUserListCell: BackgroundTableViewCell {
    
    @IBOutlet weak var iconImageView: UIImageView!
    @IBOutlet weak var userListNameLabel: DisplayNameLable!
    @IBOutlet weak var userNameLabel: ScreenNameLable!
    @IBOutlet weak var protectedLabel: UILabel!
    @IBOutlet weak var descriptionLabel: StatusLable!
    @IBOutlet weak var textHeightConstraint: NSLayoutConstraint!
    
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
