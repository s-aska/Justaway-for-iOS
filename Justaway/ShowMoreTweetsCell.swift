//
//  ShowMoreTweetsCell.swift
//  Justaway
//
//  Created by Shinichiro Aska on 10/5/15.
//  Copyright © 2015 Shinichiro Aska. All rights reserved.
//

import UIKit

class ShowMoreTweetsCell: BackgroundTableViewCell {
    
    @IBOutlet weak var showMoreLabel: TextLable!
    @IBOutlet weak var indicator: UIActivityIndicatorView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        separatorInset = UIEdgeInsetsZero
        layoutMargins = UIEdgeInsetsZero
        preservesSuperviewLayoutMargins = false
        indicator.activityIndicatorViewStyle = ThemeController.currentTheme.activityIndicatorStyle()
    }
}
