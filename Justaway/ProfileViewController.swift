//
//  ProfileViewController.swift
//  Justaway
//
//  Created by Shinichiro Aska on 6/4/15.
//  Copyright (c) 2015 Shinichiro Aska. All rights reserved.
//

import UIKit
import SwifteriOS
import Pinwheel

class ProfileViewController: UIViewController, UIScrollViewDelegate {
    
    struct Static {
        static var instances = [ProfileViewController]()
    }
    
    // MARK: Types
    
    struct Constants {
        static let duration: Double = 0.2
        static let delay: NSTimeInterval = 0
    }
    
    // MARK: Properties
    
    @IBOutlet weak var scrollView: BackgroundScrollView!
    
    @IBOutlet weak var headerViewLeftConstraint: NSLayoutConstraint!
    @IBOutlet weak var headerViewTopContraint: NSLayoutConstraint!
    @IBOutlet weak var coverImageView: UIImageView!
    @IBOutlet weak var iconImageView: UIImageView!
    @IBOutlet weak var displayNameLabel: UILabel!
    @IBOutlet weak var screenNameLabel: UILabel!
    @IBOutlet weak var followedByLabel: UILabel!
    @IBOutlet weak var protectedLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var sinceLabel: UILabel!
    @IBOutlet weak var locationLabel: UILabel!
    @IBOutlet weak var siteLabel: UILabel!
    
    @IBOutlet weak var statusCountLabel: UILabel!
    @IBOutlet weak var followingCountLabel: UILabel!
    @IBOutlet weak var followerCountLabel: UILabel!
    @IBOutlet weak var listedCountLabel: UILabel!
    @IBOutlet weak var favoritesCountLabel: UILabel!
    
    @IBOutlet weak var bottomContainerTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var bottomDisplayNameLabel: UILabel!
    @IBOutlet weak var bottomScreenNameLabel: UILabel!
    
    var user: TwitterUser?
    var userFull: TwitterUserFull?
    var relationship: TwitterRelationship?
    
    let userTimelineTableViewController = UserTimelineTableViewController()
    let followingTableViewController = FollowingUserViewController()
    let followerTableViewController = FollowerUserViewController()
    let sinceDateFormatter: NSDateFormatter = {
        let formatter = NSDateFormatter()
        formatter.locale = NSLocale.currentLocale()
        formatter.calendar = NSCalendar(calendarIdentifier: NSCalendarIdentifierGregorian)
        formatter.dateFormat = "yyyy.MM.dd"
        return formatter
    }()
    
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
        scrollView.delegate = self
        
        coverImageView.clipsToBounds = true
        coverImageView.contentMode = .ScaleAspectFill
        
        let gradient = CAGradientLayer()
        gradient.colors = [UIColor(red: 0, green: 0, blue: 0, alpha: 0).CGColor, UIColor(red: 0, green: 0, blue: 0, alpha: 0.5).CGColor]
        gradient.frame = coverImageView.frame
        coverImageView.layer.insertSublayer(gradient, atIndex: 0)
        
        iconImageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: "showIcon:"))
        coverImageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: "showCover:"))
        siteLabel.addGestureRecognizer(UITapGestureRecognizer(target: self, action: "openURL:"))
        
        // setup tabview
        if let size = UIApplication.sharedApplication().keyWindow?.rootViewController?.view.frame.size {
            NSLog("size:\(size)")
            let contentView = UIView(frame: CGRectMake(0, 0, size.width * 3, size.height))
            var i = 0
            for vc in [userTimelineTableViewController, followingTableViewController, followerTableViewController] {
                let marginTop: CGFloat = 20
                vc.view.frame = CGRectMake(0, marginTop, size.width, size.height - marginTop)
                let view = UIView(frame: CGRectMake(size.width * CGFloat(i), 0, size.width, size.height))
                view.addSubview(vc.view)
                contentView.addSubview(view)
                i++
            }
            
            scrollView.addSubview(contentView)
            scrollView.contentSize = contentView.frame.size
            scrollView.pagingEnabled = true
        }
        
        userTimelineTableViewController.scrollCallback = { (scrollView: UIScrollView) -> Void in
            let offset = scrollView.contentOffset.y - 20
            let margin = 179 + offset
            if margin <= 0 {
                self.headerViewTopContraint.constant = 0
            } else {
                self.headerViewTopContraint.constant = -margin
            }
            let bottomTop = -offset - 28
            if bottomTop <= 0 {
                self.bottomContainerTopConstraint.constant = 0
            } else if bottomTop < 100 {
                self.bottomContainerTopConstraint.constant = bottomTop
            } else {
                self.bottomContainerTopConstraint.constant = 100
            }
        }
    }
    
    func configureEvent() {
    }
    
    // MARK: - UITableViewDataSource
    
    func scrollViewDidScroll(scrollView: UIScrollView) {
        let offset = scrollView.contentOffset.x
        NSLog("offset:\(offset)")
        headerViewLeftConstraint.constant = -offset
    }
    
    // MARK: - Actions
    
    func setText() {
        if let user = self.user {
            displayNameLabel.text = user.name
            screenNameLabel.text = "@" + user.screenName
            bottomDisplayNameLabel.text = user.name
            bottomScreenNameLabel.text = user.screenName
            statusCountLabel.text = "-"
            followingCountLabel.text = "-"
            followerCountLabel.text = "-"
            listedCountLabel.text = "-"
            favoritesCountLabel.text = "-"
            descriptionLabel.text = ""
            locationLabel.text = ""
            siteLabel.text = ""
            sinceLabel.text = ""
            iconImageView.image = nil
            coverImageView.image = nil
            if !user.isProtected {
                protectedLabel.removeFromSuperview()
            }
            // followedByLabel.alpha = 0
            ImageLoaderClient.displayUserIcon(user.profileImageURL, imageView: iconImageView)
            
            headerViewTopContraint.constant = 0
            bottomContainerTopConstraint.constant = 100
            
            userTimelineTableViewController.userID = user.userID
            userTimelineTableViewController.loadData(nil)
            followingTableViewController.userID = user.userID
            followingTableViewController.loadData(nil)
            followerTableViewController.userID = user.userID
            followerTableViewController.loadData(nil)
            
            let success :(([JSONValue]?) -> Void) = { (rows) in
                if let row = rows?.first {
                    let user = TwitterUserFull(row)
                    self.userFull = user
                    self.statusCountLabel.text = user.statusesCount.description
                    self.followingCountLabel.text = user.friendsCount.description
                    self.followerCountLabel.text = user.followersCount.description
                    self.listedCountLabel.text = user.listedCount.description
                    self.favoritesCountLabel.text = user.favouritesCount.description
                    self.descriptionLabel.text = user.description
                    self.locationLabel.text = user.location
                    self.siteLabel.text = user.displayURL
                    self.sinceLabel.text = self.sinceDateFormatter.stringFromDate(user.createdAt.date)
                    ImageLoaderClient.displayImage(user.profileBannerURL, imageView: self.coverImageView)
                }
            }
            
            let failure = { (error: NSError) -> Void in
                NSLog("%@", error.debugDescription)
            }
            
            Twitter.getCurrentClient()?.getUsersLookupWithUserIDs([user.userID], includeEntities: false, success: success, failure: failure)
            
            Twitter.getFriendships(user.userID, success: { (relationship) -> Void in
                self.relationship = relationship
                if !relationship.followedBy {
                    self.followedByLabel.removeFromSuperview()
                }
            }, failure: failure)
        }
    }
    
    func showCover(sender: AnyObject) {
        if let imageURL = userFull?.profileBannerURL {
            ImageViewController.show([imageURL], initialPage: 0)
        }
    }
    
    func showIcon(sender: AnyObject) {
        if let imageURL = user?.profileOriginalImageURL {
            ImageViewController.show([imageURL], initialPage: 0)
        }
    }
    
    func openURL(sender: AnyObject) {
        if let expandedURL = userFull?.expandedURL {
            GoogleChrome.openURL(expandedURL)
        }
    }
    
    @IBAction func menu(sender: UIButton) {
        if let userFull = userFull {
            if let relationship = relationship {
                UserAlert.show(sender, user: userFull, relationship: relationship)
            }
        }
    }
    
    @IBAction func hide(sender: UIButton) {
        hide()
    }
    
    func hide() {
        UIView.animateWithDuration(Constants.duration, delay: Constants.delay, options: .CurveEaseOut, animations: {
            self.view.frame = CGRectMake(
                self.view.frame.size.width,
                self.view.frame.origin.y,
                self.view.frame.size.width,
                self.view.frame.size.height)
            }, completion: { finished in
                self.view.hidden = true
                self.view.removeFromSuperview()
                Static.instances.removeAtIndex(Static.instances.endIndex.predecessor()) // purge instance
        })
    }
    
    // MARK: - Class Methods
    
    class func show(user: TwitterUser) {
        
        EditorViewController.hide() // TODO: think seriously about
        
        if let vc = UIApplication.sharedApplication().keyWindow?.rootViewController {
            let instance = ProfileViewController()
            instance.user = user
            instance.view.hidden = true
            vc.view.addSubview(instance.view)
            instance.view.frame = CGRectMake(vc.view.frame.width, 0, vc.view.frame.width, vc.view.frame.height)
            instance.view.hidden = false
            
            UIView.animateWithDuration(Constants.duration, delay: Constants.delay, options: .CurveEaseOut, animations: { () -> Void in
                instance.view.frame = CGRectMake(0,
                    vc.view.frame.origin.y,
                    vc.view.frame.size.width,
                    vc.view.frame.size.height)
                }) { (finished) -> Void in
            }
            Static.instances.append(instance) // keep instance
        }
    }
}

