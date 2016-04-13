//
//  AccountCell.swift
//  Justaway
//
//  Created by Shinichiro Aska on 5/24/15.
//  Copyright (c) 2015 Shinichiro Aska. All rights reserved.
//

import UIKit

class AccountCell: BackgroundTableViewCell {

    @IBOutlet weak var iconImageView: UIImageView!
    @IBOutlet weak var displayNameLabel: DisplayNameLable!
    @IBOutlet weak var screenNameLabel: ScreenNameLable!
    @IBOutlet weak var clientNameLabel: ClientNameLable!
    @IBOutlet weak var messageButton: UIButton!
    @IBOutlet weak var messageLabel: UILabel!
    @IBOutlet weak var notificationButton: UIButton!
    @IBOutlet weak var notificationLabel: UILabel!

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

    @IBAction func message(sender: UIButton) {
        Twitter.addOAuthAccount()
    }

    @IBAction func notification(sender: UIButton) {
        SafariExURLHandler.open()
    }
}
