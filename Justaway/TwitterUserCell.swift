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
    @IBOutlet weak var followButton: FollowButton!
    @IBOutlet weak var unfollowButton: BaseButton!
    @IBOutlet weak var blockLabel: TextLable!
    @IBOutlet weak var muteLabel: TextLable!
    @IBOutlet weak var retweetLabel: TextLable!
    @IBOutlet weak var retweetDeleteLabel: TextLable!
    @IBOutlet weak var followingLabel: TextLable!
    @IBOutlet weak var followerLabel: TextLable!
    @IBOutlet weak var listsLabel: TextLable!

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
        iconImageView.layer.cornerRadius = 6
        iconImageView.clipsToBounds = true
        iconImageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(openProfile(_:))))
        iconImageView.addGestureRecognizer(UILongPressGestureRecognizer(target: self, action: #selector(openUserMenu(_:))))
        followButton.addGestureRecognizer(UILongPressGestureRecognizer(target: self, action: #selector(openUserMenu(_:))))
    }

    func openProfile(sender: UIGestureRecognizer) {
        if let user = user {
            ProfileViewController.show(user)
        }
    }

    func openUserMenu(sender: UILongPressGestureRecognizer) {
        if sender.state != .Began {
            return
        }
        guard let account = AccountSettingsStore.get()?.account(), view = sender.view else {
            return
        }
        if let user = user {
            Relationship.checkUser(account.userID, targetUserID: user.userID, callback: { (relationshop) in
                UserAlert.show(view, user: TwitterUser(user), userFull: user, relationship: relationshop)
            })
        }
    }

    @IBAction func follow(sender: UIButton) {
        guard let account = AccountSettingsStore.get()?.account() else {
            return
        }
        if let user = user {
            Relationship.checkUser(account.userID, targetUserID: user.userID, callback: { (relationshop) in
                if relationshop.following {
                    let actionSheet = UIAlertController(title: "Unfollow @\(user.screenName)?", message: nil, preferredStyle: .Alert)
                    actionSheet.addAction(UIAlertAction(
                        title: "Cancel",
                        style: .Cancel,
                        handler: { action in
                    }))
                    actionSheet.addAction(UIAlertAction(
                        title: "Unfollow",
                        style: .Default,
                        handler: { action in
                            Twitter.unfollow(user.userID) {
                                self.followButton.hidden = false
                                self.unfollowButton.hidden = true
                            }
                    }))

                    // iPad
                    actionSheet.popoverPresentationController?.sourceView = sender
                    actionSheet.popoverPresentationController?.sourceRect = sender.bounds

                    AlertController.showViewController(actionSheet)
                } else {
                    let actionSheet = UIAlertController(title: "Follow @\(user.screenName)?", message: nil, preferredStyle: .Alert)
                    actionSheet.addAction(UIAlertAction(
                        title: "Cancel",
                        style: .Cancel,
                        handler: { action in
                    }))
                    actionSheet.addAction(UIAlertAction(
                        title: "Follow",
                        style: .Default,
                        handler: { action in
                            Twitter.follow(user.userID) {
                                self.followButton.hidden = true
                                self.unfollowButton.hidden = false
                            }
                    }))

                    // iPad
                    actionSheet.popoverPresentationController?.sourceView = sender
                    actionSheet.popoverPresentationController?.sourceRect = sender.bounds

                    AlertController.showViewController(actionSheet)
                }
            })
        }
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
