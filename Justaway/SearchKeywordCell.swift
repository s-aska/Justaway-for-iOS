//
//  SearchKeywordCell.swift
//  Justaway
//
//  Created by Shinichiro Aska on 3/30/16.
//  Copyright © 2016 Shinichiro Aska. All rights reserved.
//

import UIKit
import EventBox

class SearchKeywordCell: BackgroundTableViewCell {

    @IBOutlet weak var nameLabel: TextLable!

    var keyword: String?
    var searchID: String?

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

    @IBAction func remove(sender: AnyObject) {
        EventBox.post("SearchKeywordDeleted", sender: ["keyword": keyword ?? "", "searchID": searchID ?? ""])
    }
}
