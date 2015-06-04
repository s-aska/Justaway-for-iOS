//
//  ProfileViewController.swift
//  Justaway
//
//  Created by Shinichiro Aska on 6/4/15.
//  Copyright (c) 2015 Shinichiro Aska. All rights reserved.
//

import UIKit
import SwifteriOS

class ProfileViewController: UIViewController {
    
    struct Static {
        static let instance = ProfileViewController()
    }
    
    // MARK: Types
    
    struct Constants {
    }
    
    // MARK: Properties
    
    @IBOutlet weak var coverImageView: UIImageView!
    @IBOutlet weak var iconImageView: UIImageView!
    @IBOutlet weak var displayNameLabel: UILabel!
    @IBOutlet weak var screenNameLabel: UILabel!
    @IBOutlet weak var followedByLabel: UILabel!
    
    @IBOutlet weak var statusCountLabel: UILabel!
    @IBOutlet weak var followingCountLabel: UILabel!
    @IBOutlet weak var followerCountLabel: UILabel!
    @IBOutlet weak var listedCountLabel: UILabel!
    @IBOutlet weak var favoritesCountLabel: UILabel!
    
    var user: TwitterUser?
    
    override var nibName: String {
        return "ProfileViewController"
    }
    
    // MARK: - View Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureView()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        configureEvent()
        setText()
    }
    
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        // EventBox.off(self)
    }
    
    // MARK: - Configuration
    
    func configureView() {
        coverImageView.clipsToBounds = true
        coverImageView.contentMode = .ScaleAspectFill
    }
    
    func configureEvent() {
    }
    
    // MARK: - Actions
    
    func setText() {
        if let user = self.user {
            displayNameLabel.text = user.name
            screenNameLabel.text = "@" + user.screenName
            ImageLoaderClient.displayUserIcon(user.profileImageURL, imageView: iconImageView)
            
            let success :(([JSONValue]?) -> Void) = { (rows) in
                if let row = rows?.first {
                    let user = TwitterUserFull(row)
                    self.statusCountLabel.text = user.statusesCount.description
                    self.followingCountLabel.text = user.friendsCount.description
                    self.followerCountLabel.text = user.followersCount.description
                    self.listedCountLabel.text = user.listedCount.description
                    self.favoritesCountLabel.text = user.favouritesCount.description
                    ImageLoaderClient.displayImage(user.profileBannerURL, imageView: self.coverImageView)
                }
            }
            
            let failure = { (error: NSError) -> Void in
                NSLog("%@", error.debugDescription)
            }
            
            Twitter.getCurrentClient()?.getUsersLookupWithUserIDs([user.userID], includeEntities: false, success: success, failure: failure)
        }
    }
    
    @IBAction func hide(sender: UIButton) {
        hide()
    }
    
    class func show(user: TwitterUser) {
        Static.instance.user = user
        if let vc = UIApplication.sharedApplication().keyWindow?.rootViewController {
            vc.presentViewController(Static.instance, animated: true, completion: nil)
        }
    }
    
    func hide() {
        dismissViewControllerAnimated(true, completion: nil)
    }
}

