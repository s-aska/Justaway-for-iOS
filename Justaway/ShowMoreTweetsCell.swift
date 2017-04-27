//
//  ShowMoreTweetsCell.swift
//  Justaway
//
//  Created by Shinichiro Aska on 10/5/15.
//  Copyright © 2015 Shinichiro Aska. All rights reserved.
//

import UIKit

class ShowMoreTweetsCell: BackgroundTableViewCell {

    @IBOutlet weak var showMoreLabel: ShowMoreTweetLabel!
    @IBOutlet weak var indicator: ShowMoreTweetIndicatorView!

    override func awakeFromNib() {
        super.awakeFromNib()
        separatorInset = UIEdgeInsets.zero
        layoutMargins = UIEdgeInsets.zero
        preservesSuperviewLayoutMargins = false
    }
}
