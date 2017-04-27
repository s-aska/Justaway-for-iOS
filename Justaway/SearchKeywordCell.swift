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
        selectionStyle = .none
        separatorInset = UIEdgeInsets.zero
        layoutMargins = UIEdgeInsets.zero
        preservesSuperviewLayoutMargins = false
    }

    @IBAction func remove(_ sender: AnyObject) {
        EventBox.post(eventSearchKeywordDeleted, sender: ["keyword": keyword ?? "", "searchID": searchID ?? ""] as NSDictionary)
    }
}
