//
//  TwitterUserCell.swift
//  Justaway
//
//  Created by Shinichiro Aska on 6/7/15.
//  Copyright (c) 2015 Shinichiro Aska. All rights reserved.
//

import UIKit

class TwitterUserCell: BackgroundTableViewCell {

    @IBOutlet weak var iconImageView: UIImageView!
    @IBOutlet weak var displayNameLabel: DisplayNameLable!
    @IBOutlet weak var screenNameLabel: ScreenNameLable!
    @IBOutlet weak var protectedLabel: UILabel!
    @IBOutlet weak var descriptionLabel: StatusLable!
    @IBOutlet weak var textHeightConstraint: NSLayoutConstraint!

    var user: TwitterUserFull?

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

    @IBAction func menu(sender: UIButton) {
        guard let account = AccountSettingsStore.get()?.account() else {
            return
        }
        if let user = user {
            Relationship.checkUser(account.userID, targetUserID: user.userID, callback: { (relationshop) in
                UserAlert.show(sender, user: TwitterUser(user), userFull: user, relationship: relationshop)
            })
        }
    }
}
