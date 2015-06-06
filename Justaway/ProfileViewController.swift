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

class ProfileViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    struct Static {
        static var instances = [ProfileViewController]()
    }
    
    // MARK: Types
    
    struct TableViewConstants {
        static let tableViewCellIdentifier = "Cell"
    }
    
    struct Constants {
        static let duration: Double = 0.2
        static let delay: NSTimeInterval = 0
    }
    
    struct Row {
        let status: TwitterStatus
        let fontSize: CGFloat
        let height: CGFloat
        let textHeight: CGFloat
        
        init(status: TwitterStatus, fontSize: CGFloat, height: CGFloat, textHeight: CGFloat) {
            self.status = status
            self.fontSize = fontSize
            self.height = height
            self.textHeight = textHeight
        }
    }
    
    // MARK: Properties
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var headerViewTopContraint: NSLayoutConstraint!
    @IBOutlet weak var coverImageView: UIImageView!
    @IBOutlet weak var iconImageView: UIImageView!
    @IBOutlet weak var displayNameLabel: UILabel!
    @IBOutlet weak var screenNameLabel: UILabel!
    @IBOutlet weak var followedByLabel: UILabel!
    @IBOutlet weak var protectedLabel: UILabel!
    
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
    var rows: [Row] = []
    var layoutHeight = [TwitterStatusCellLayout: CGFloat]()
    var layoutHeightCell = [TwitterStatusCellLayout: TwitterStatusCell]()
    
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
        tableView.separatorInset = UIEdgeInsetsZero
        tableView.separatorStyle = UITableViewCellSeparatorStyle.None
        tableView.delegate = self
        tableView.dataSource = self
        tableView.contentInset = UIEdgeInsetsMake(159, 0, 0, 0)
        
        let nib = UINib(nibName: "TwitterStatusCell", bundle: nil)
        for layout in TwitterStatusCellLayout.allValues {
            self.tableView.registerNib(nib, forCellReuseIdentifier: layout.rawValue)
            self.layoutHeightCell[layout] = tableView.dequeueReusableCellWithIdentifier(layout.rawValue) as? TwitterStatusCell
        }
        
        coverImageView.clipsToBounds = true
        coverImageView.contentMode = .ScaleAspectFill
        
        let gradient = CAGradientLayer()
        gradient.colors = [UIColor(red: 0, green: 0, blue: 0, alpha: 0).CGColor, UIColor(red: 0, green: 0, blue: 0, alpha: 0.3).CGColor]
        gradient.frame = coverImageView.frame
        coverImageView.layer.insertSublayer(gradient, atIndex: 0)
        
        iconImageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: "showIcon:"))
        coverImageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: "showCover:"))
    }
    
    func configureEvent() {
    }
    
    // MARK: - UITableViewDataSource
    
    func scrollViewDidScroll(scrollView: UIScrollView) {
        let offset = tableView.contentOffset.y
        let margin = 159 + offset
        if margin <= 0 {
            headerViewTopContraint.constant = 0
        } else {
            headerViewTopContraint.constant = -margin
        }
        let bottomTop = -offset - 28
        NSLog("offset:\(offset) margin:\(margin) bottomTop:\(bottomTop)")
        if bottomTop <= 0 {
            bottomContainerTopConstraint.constant = 0
        } else if bottomTop < 100 {
            bottomContainerTopConstraint.constant = bottomTop
        } else {
            bottomContainerTopConstraint.constant = 100
        }
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return rows.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let row = rows[indexPath.row]
        let status = row.status
        let layout = TwitterStatusCellLayout.fromStatus(status)
        let cell = tableView.dequeueReusableCellWithIdentifier(layout.rawValue, forIndexPath: indexPath) as! TwitterStatusCell
        
        if cell.textHeightConstraint.constant != row.textHeight {
            cell.textHeightConstraint.constant = row.textHeight
        }
        
        if row.fontSize != cell.statusLabel.font.pointSize {
            cell.statusLabel.font = UIFont.systemFontOfSize(row.fontSize)
        }
        
        if let s = cell.status {
            if s.uniqueID == status.uniqueID {
                cell.textHeightConstraint.constant = row.textHeight
                return cell
            }
        }
        
        cell.status = status
        cell.setLayout(layout)
        cell.setText(status)
        
        if !Pinwheel.suspend {
            cell.setImage(status)
        }
        
        return cell
    }
    
    // MARK: UITableViewDelegate
    
    func tableView(tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 90
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        let row = rows[indexPath.row]
        return row.height
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let row = rows[indexPath.row]
        if let cell = tableView.cellForRowAtIndexPath(indexPath) {
            StatusAlert.show(cell, status: row.status)
        }
    }
    
    func createRow(status: TwitterStatus, fontSize: CGFloat) -> Row {
        let layout = TwitterStatusCellLayout.fromStatus(status)
        if let height = layoutHeight[layout] {
            let textHeight = measure(status.text, fontSize: fontSize)
            let totalHeight = ceil(height + textHeight)
            return Row(status: status, fontSize: fontSize, height: totalHeight, textHeight: textHeight)
        } else if let cell = self.layoutHeightCell[layout] {
            cell.frame = self.tableView.bounds
            cell.setLayout(layout)
            let textHeight = measure(status.text, fontSize: fontSize)
            cell.textHeightConstraint.constant = 0
            let height = cell.contentView.systemLayoutSizeFittingSize(UILayoutFittingCompressedSize).height
            layoutHeight[layout] = height
            let totalHeight = ceil(height + textHeight)
            return Row(status: status, fontSize: fontSize, height: totalHeight, textHeight: textHeight)
        }
        fatalError("cellForHeight is missing.")
    }
    
    func measure(text: NSString, fontSize: CGFloat) -> CGFloat {
        return ceil(text.boundingRectWithSize(
            CGSizeMake((self.layoutHeightCell[.Normal]?.statusLabel.frame.size.width)!, 0),
            options: NSStringDrawingOptions.UsesLineFragmentOrigin,
            attributes: [NSFontAttributeName: UIFont.systemFontOfSize(fontSize)],
            context: nil).size.height)
    }
    
    func renderData(statuses: [TwitterStatus]) {
        var fontSize :CGFloat = 12.0
        if let delegate = UIApplication.sharedApplication().delegate as? AppDelegate {
            fontSize = CGFloat(delegate.fontSize)
        }
        self.rows = statuses.map({ self.createRow($0, fontSize: fontSize) })
        Async.main {
            self.tableView.reloadData()
        }
    }
    
    func renderImages() {
        for cell in self.tableView.visibleCells() as! [TwitterStatusCell] {
            if let status = cell.status {
                cell.setImage(status)
            }
        }
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
            iconImageView.image = nil
            coverImageView.image = nil
            protectedLabel.hidden = user.isProtected ? false : true
            ImageLoaderClient.displayUserIcon(user.profileImageURL, imageView: iconImageView)
            headerViewTopContraint.constant = 0
            rows = []
            tableView.reloadData()
            
            let success :(([JSONValue]?) -> Void) = { (rows) in
                if let row = rows?.first {
                    let user = TwitterUserFull(row)
                    self.statusCountLabel.text = user.statusesCount.description
                    self.followingCountLabel.text = user.friendsCount.description
                    self.followerCountLabel.text = user.followersCount.description
                    self.listedCountLabel.text = user.listedCount.description
                    self.favoritesCountLabel.text = user.favouritesCount.description
                    ImageLoaderClient.displayImage(user.profileBannerURL, imageView: self.coverImageView)
                    self.userFull = user
                }
            }
            
            let failure = { (error: NSError) -> Void in
                NSLog("%@", error.debugDescription)
            }
            
            Twitter.getCurrentClient()?.getUsersLookupWithUserIDs([user.userID], includeEntities: false, success: success, failure: failure)
            
            load()
        }
    }
    
    func load() {
        if let user = self.user {
            let success = { (statuses: [TwitterStatus]) -> Void in
                self.renderData(statuses)
            }
            let failure = { (error: NSError) -> Void in
                ErrorAlert.show("Error", message: error.localizedDescription)
            }
            Twitter.getUserTimeline(user.userID, success: success, failure: failure)
        }
    }
    
    func showCover(sender: AnyObject) {
        if let imageURL = userFull?.profileBannerURL {
            ImageViewController.show([imageURL], initialPage: 0)
        }
    }
    
    func showIcon(sender: AnyObject) {
        if let imageURL = user?.profileImageURL {
            ImageViewController.show([imageURL], initialPage: 0)
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

