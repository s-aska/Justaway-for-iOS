//
//  ProfileViewController.swift
//  Justaway
//
//  Created by Shinichiro Aska on 6/4/15.
//  Copyright (c) 2015 Shinichiro Aska. All rights reserved.
//

import UIKit
import Pinwheel
import SwiftyJSON
import Async

class ProfileViewController: UIViewController, UIScrollViewDelegate {

    // MARK: Types

    struct TabMenu {
        let count: UILabel
        let label: UILabel

        init(count: UILabel, label: UILabel) {
            self.count = count
            self.label = label
        }
    }

    // MARK: Properties

    @IBOutlet weak var scrollWapperView: UIView!
    @IBOutlet weak var scrollView: BackgroundScrollView!

    @IBOutlet weak var headerViewLeftConstraint: NSLayoutConstraint!
    @IBOutlet weak var headerViewTopContraint: NSLayoutConstraint!
    @IBOutlet weak var headerViewWidthConstraint: NSLayoutConstraint!
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

    @IBOutlet weak var currentTabMaskLeftConstraint: NSLayoutConstraint!
    @IBOutlet weak var statusCountLabel: MenuLable!
    @IBOutlet weak var statusLabel: MenuLable!
    @IBOutlet weak var statusView: UIView!
    @IBOutlet weak var followingCountLabel: MenuLable!
    @IBOutlet weak var followingLabel: MenuLable!
    @IBOutlet weak var followingView: UIView!
    @IBOutlet weak var followerCountLabel: MenuLable!
    @IBOutlet weak var followerLabel: MenuLable!
    @IBOutlet weak var followerView: UIView!
    @IBOutlet weak var listedCountLabel: MenuLable!
    @IBOutlet weak var listedLabel: MenuLable!
    @IBOutlet weak var listedView: UIView!
    @IBOutlet weak var favoritesCountLabel: MenuLable!
    @IBOutlet weak var favoritesLabel: MenuLable!
    @IBOutlet weak var favoritesView: UIView!

    @IBOutlet weak var bottomContainerTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var bottomDisplayNameLabel: UILabel!
    @IBOutlet weak var bottomScreenNameLabel: UILabel!

    var user: TwitterUser?
    var userFull: TwitterUserFull?
    var relationship: TwitterRelationship?
    var closed = false

    var tabMenus = [TabMenu]()
    var tabViews = [TimelineTableViewController]()
    var tabLoaded = [Int: Bool]()
    let userTimelineTableViewController = UserTimelineTableViewController()
    let followingTableViewController = FollowingUserViewController()
    let followerTableViewController = FollowerUserViewController()
    let listMemberOfViewController = ListMemberOfViewController()
    let favoritesTableViewController = FavoritesTableViewController()
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
        tabMenus = [
            TabMenu(count: statusCountLabel, label: statusLabel),
            TabMenu(count: followingCountLabel, label: followingLabel),
            TabMenu(count: followerCountLabel, label: followerLabel),
            TabMenu(count: listedCountLabel, label: listedLabel),
            TabMenu(count: favoritesCountLabel, label: favoritesLabel)
        ]

        tabViews = [userTimelineTableViewController, followingTableViewController, followerTableViewController, listMemberOfViewController, favoritesTableViewController]

        highlightUpdate(0)

        statusView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(ProfileViewController.showPage(_:))))
        followingView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(ProfileViewController.showPage(_:))))
        followerView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(ProfileViewController.showPage(_:))))
        listedView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(ProfileViewController.showPage(_:))))
        favoritesView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(ProfileViewController.showPage(_:))))

        scrollView.delegate = self

        coverImageView.clipsToBounds = true
        coverImageView.contentMode = .ScaleAspectFill

        let gradient = CAGradientLayer()
        gradient.colors = [UIColor(red: 0, green: 0, blue: 0, alpha: 0).CGColor, UIColor(red: 0, green: 0, blue: 0, alpha: 0.5).CGColor]
        gradient.frame = coverImageView.frame
        coverImageView.layer.insertSublayer(gradient, atIndex: 0)

        iconImageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(ProfileViewController.showIcon(_:))))
        coverImageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(ProfileViewController.showCover(_:))))
        siteLabel.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(ProfileViewController.openURL(_:))))

        // setup tabview
        if let windowSize = UIApplication.sharedApplication().keyWindow?.rootViewController?.view.frame.size {
            view.frame = CGRect.init(x: 0, y: 0, width: windowSize.width, height: windowSize.height)
            view.layoutIfNeeded()
            headerViewWidthConstraint.constant = windowSize.width
        }
        let size = scrollWapperView.frame.size
        let contentView = UIView(frame: CGRect.init(x: 0, y: 0, width: size.width * CGFloat(tabViews.count), height: size.height))
        var i = 0
        for vc in tabViews {
            vc.view.frame = CGRect.init(x: 0, y: 0, width: size.width, height: size.height)
            let view = UIView(frame: CGRect.init(x: size.width * CGFloat(i), y: 0, width: size.width, height: size.height))
            view.addSubview(vc.view)
            contentView.addSubview(view)
            i += 1
        }

        scrollView.addSubview(contentView)
        scrollView.contentSize = contentView.frame.size
        scrollView.pagingEnabled = true

        configureUserTimelineTableView()
    }

    func configureUserTimelineTableView() {
        userTimelineTableViewController.adapter.scrollCallback = { (scrollView: UIScrollView) -> Void in
            let offset = scrollView.contentOffset.y
            let margin = 159 + offset
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
        userTimelineTableViewController.tableView.contentInset = UIEdgeInsetsMake(159, 0, 0, 0)
        userTimelineTableViewController.tableView.scrollIndicatorInsets = UIEdgeInsetsMake(159, 0, 0, 0)
        userTimelineTableViewController.adapter.scrollEnd(userTimelineTableViewController.tableView)
    }

    func configureEvent() {
    }

    // MARK: - UITableViewDataSource

    func scrollViewDidScroll(scrollView: UIScrollView) {
        let offset = scrollView.contentOffset.x
        NSLog("offset \(offset)")
        if offset < -10 {
            hide()
            return
        }
        headerViewLeftConstraint.constant = -offset
        let page = Int((offset + (view.frame.size.width / 2)) / view.frame.size.width)
        highlightUpdate(page)
        loadData(page)
    }

    func highlightUpdate(page: Int) {
        currentTabMaskLeftConstraint.constant = CGFloat(CGFloat(page) * self.view.frame.size.width / 5)
    }

    func loadData(page: Int) {
        if !(tabLoaded[page] ?? false) {
            tabLoaded[page] = true
            tabViews[page].refresh()
        }
    }

    // MARK: - Actions

    func setText() {
        guard let user = self.user else {
            return
        }

        displayNameLabel.text = user.name
        screenNameLabel.text = "@" + user.screenName
        bottomDisplayNameLabel.text = user.name
        bottomScreenNameLabel.text = user.screenName
        iconImageView.image = nil
        if AccountSettingsStore.isCurrent(user.userID) {
            followedByLabel.removeFromSuperview()
        } else {
            if !user.isProtected {
                protectedLabel.removeFromSuperview()
            }
        }
        // followedByLabel.alpha = 0
        ImageLoaderClient.displayUserIcon(user.profileImageURL, imageView: iconImageView)

        headerViewTopContraint.constant = 0
        bottomContainerTopConstraint.constant = 100

        userTimelineTableViewController.userID = user.userID
        userTimelineTableViewController.loadData(nil)

        tabLoaded = [0: true]

        followingTableViewController.userID = user.userID
        followerTableViewController.userID = user.userID
        listMemberOfViewController.userID = user.userID
        favoritesTableViewController.userID = user.userID

        setTextByAPI()
    }

    func setTextByAPI() {
        guard let user = self.user else {
            return
        }

        if let userFull = self.userFull {
            self.setUserFull(userFull)
        } else {
            statusCountLabel.text = "-"
            followingCountLabel.text = "-"
            followerCountLabel.text = "-"
            listedCountLabel.text = "-"
            favoritesCountLabel.text = "-"
            descriptionLabel.text = ""
            locationLabel.text = ""
            siteLabel.text = ""
            sinceLabel.text = ""
            coverImageView.image = nil

            let success: (([JSON]) -> Void) = { (rows) in
                if let row = rows.first {
                    let user = TwitterUserFull(row)
                    self.userFull = user
                    self.setUserFull(user)
                }
            }

            let parameters = ["user_id": user.userID]
            Twitter.client()?
                .get("https://api.twitter.com/1.1/users/lookup.json", parameters: parameters)
                .responseJSONArray(success)
        }

        Twitter.getFriendships(user.userID, success: { (relationship) -> Void in
            self.relationship = relationship
            if !relationship.followedBy {
                self.followedByLabel?.removeFromSuperview()
            }
        })
    }

    func setUserFull(user: TwitterUserFull) {
        if !user.isProtected {
            protectedLabel?.removeFromSuperview()
        }
        statusCountLabel.text = user.statusesCount.description
        followingCountLabel.text = user.friendsCount.description
        followerCountLabel.text = user.followersCount.description
        listedCountLabel.text = user.listedCount.description
        favoritesCountLabel.text = user.favouritesCount.description
        descriptionLabel.text = user.description
        locationLabel.text = user.location
        siteLabel.text = user.displayURL
        sinceLabel.text = sinceDateFormatter.stringFromDate(user.createdAt.date)
        ImageLoaderClient.displayImage(user.profileBannerURL, imageView: coverImageView)
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

    func showPage(sender: UITapGestureRecognizer) {
        if let page = sender.view?.tag {
            let offset = view.frame.size.width * CGFloat(page)
            if offset == scrollView.contentOffset.x {
                 tabViews[page].tableView.setContentOffset(CGPoint.zero, animated: true)
            } else {
                headerViewLeftConstraint.constant = -offset
                loadData(page)
                UIView.animateWithDuration(0.3, animations: { () -> Void in
                    self.scrollView.contentOffset = CGPoint.init(x: offset, y: 0)
                    self.view.layoutIfNeeded()
                    }, completion: { (flag) -> Void in
                        self.highlightUpdate(page)
                })
            }
        }
    }

    func openURL(sender: AnyObject) {
        if let expandedURL = userFull?.expandedURL {
            Safari.openURL(expandedURL)
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
        if closed {
            return
        }
        closed = true
        ViewTools.slideOut(self)
    }

    // MARK: - Class Methods

    class func show(user: TwitterUser) {
        let instance = ProfileViewController()
        instance.user = user
        ViewTools.slideIn(instance)
    }

    class func show(screenName: String) {
        let parameters = ["screen_name": screenName]
        let success: (([JSON]) -> Void) = { (rows) in
            if let row = rows.first {
                let user = TwitterUser(row)
                let userFull = TwitterUserFull(row)
                let instance = ProfileViewController()
                instance.user = user
                instance.userFull = userFull
                Async.main {
                    ViewTools.slideIn(instance)
                }
            }
        }
        Twitter.client()?
            .get("https://api.twitter.com/1.1/users/lookup.json", parameters: parameters)
            .responseJSONArray(success)
    }
}
