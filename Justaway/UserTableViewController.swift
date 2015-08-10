//
//  UserViewController.swift
//  Justaway
//
//  Created by Shinichiro Aska on 6/7/15.
//  Copyright (c) 2015 Shinichiro Aska. All rights reserved.
//

import UIKit
import EventBox

class UserTableViewController: UITableViewController {
    
    // MARK: Types
    
    struct TableViewConstants {
        static let tableViewCellIdentifier = "Cell"
    }
    
    // MARK: Properties
    
    var footerView: UIView?
    var footerIndicatorView: UIActivityIndicatorView?
    
    var userID: String?
    
    var rows = [Row]()
    var layoutHeightCell: TwitterUserCell?
    var layoutHeight: CGFloat?
    
    struct Row {
        let user: TwitterUserFull
        let fontSize: CGFloat
        let height: CGFloat
        let textHeight: CGFloat
        
        init(user: TwitterUserFull, fontSize: CGFloat, height: CGFloat, textHeight: CGFloat) {
            self.user = user
            self.fontSize = fontSize
            self.height = height
            self.textHeight = textHeight
        }
    }
    
    // MARK: UITableViewDelegate
    
    override func tableView(tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return TIMELINE_FOOTER_HEIGHT
    }
    
    override func tableView(tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        if footerView == nil {
            footerView = UIView(frame: CGRectMake(0, 0, view.frame.size.width, TIMELINE_FOOTER_HEIGHT))
            footerIndicatorView = UIActivityIndicatorView(activityIndicatorStyle: ThemeController.currentTheme.activityIndicatorStyle())
            footerView?.addSubview(footerIndicatorView!)
            footerIndicatorView?.hidesWhenStopped = true
            footerIndicatorView?.center = (footerView?.center)!
        }
        return footerView
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
    }
    
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        EventBox.off(self)
    }
    
    // MARK: - Configuration
    
    func configureView() {
        self.tableView.separatorInset = UIEdgeInsetsZero
        self.tableView.separatorStyle = UITableViewCellSeparatorStyle.None
        self.tableView.backgroundColor = UIColor.clearColor()
        
        let nib = UINib(nibName: "TwitterUserCell", bundle: nil)
        self.tableView.registerNib(nib, forCellReuseIdentifier: TableViewConstants.tableViewCellIdentifier)
        self.layoutHeightCell = self.tableView.dequeueReusableCellWithIdentifier(TableViewConstants.tableViewCellIdentifier) as? TwitterUserCell
        
        // var refreshControl = UIRefreshControl()
        // refreshControl.addTarget(self, action: Selector("refresh"), forControlEvents: UIControlEvents.ValueChanged)
        // self.refreshControl = refreshControl
    }
    
    func configureEvent() {
        EventBox.onMainThread(self, name: EventStatusBarTouched, handler: { (n) -> Void in
            self.tableView.setContentOffset(CGPointZero, animated: true)
        })
    }
    
    // MARK: - UITableViewDataSource
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return rows.count ?? 0
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let row = rows[indexPath.row]
        let user = row.user
        let cell = tableView.dequeueReusableCellWithIdentifier(TableViewConstants.tableViewCellIdentifier, forIndexPath: indexPath) as! TwitterUserCell
        
        if cell.textHeightConstraint.constant != row.textHeight {
            cell.textHeightConstraint.constant = row.textHeight
        }
        
        if row.fontSize != cell.descriptionLabel.font.pointSize {
            cell.descriptionLabel.font = UIFont.systemFontOfSize(row.fontSize)
        }
        
        cell.displayNameLabel.text = user.name
        cell.screenNameLabel.text = user.screenName
        cell.protectedLabel.hidden = !user.isProtected
        cell.descriptionLabel.text = user.description
        
        cell.iconImageView.image = nil
        ImageLoaderClient.displayUserIcon(user.profileImageURL, imageView: cell.iconImageView)
        
        return cell
    }
    
    // MARK: UITableViewDelegate
    
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        let row = rows[indexPath.row]
        return row.height
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let row = rows[indexPath.row]
        ProfileViewController.show(TwitterUser(row.user))
    }
    
    func createRow(user: TwitterUserFull, fontSize: CGFloat) -> Row {
        if let height = layoutHeight {
            let textHeight = measure(user.description, fontSize: fontSize)
            let totalHeight = ceil(height + textHeight)
            return Row(user: user, fontSize: fontSize, height: totalHeight, textHeight: textHeight)
        } else if let cell = self.layoutHeightCell {
            cell.frame = self.tableView.bounds
            let textHeight = measure(user.description, fontSize: fontSize)
            cell.textHeightConstraint.constant = 0
            let height = cell.contentView.systemLayoutSizeFittingSize(UILayoutFittingCompressedSize).height
            layoutHeight = height
            let totalHeight = ceil(height + textHeight)
            return Row(user: user, fontSize: fontSize, height: totalHeight, textHeight: textHeight)
        }
        fatalError("cellForHeight is missing.")
    }
    
    func measure(text: NSString, fontSize: CGFloat) -> CGFloat {
        return ceil(text.boundingRectWithSize(
            CGSizeMake((self.layoutHeightCell?.descriptionLabel.frame.size.width)!, 0),
            options: NSStringDrawingOptions.UsesLineFragmentOrigin,
            attributes: [NSFontAttributeName: UIFont.systemFontOfSize(fontSize)],
            context: nil).size.height)
    }
    
    func loadData(maxID: Int64?) {
        let fontSize = CGFloat(GenericSettings.get().fontSize)
        
        let s = { (users: [TwitterUserFull]) -> Void in
            self.rows = users.map({ self.createRow($0, fontSize: fontSize) })
            self.tableView.reloadData()
        }
        
        let f = { (error: NSError) -> Void in
        
        }
        
        loadData(maxID?.stringValue, success: s, failure: f)
    }
    
    func loadData(id: String?, success: ((users: [TwitterUserFull]) -> Void), failure: ((error: NSError) -> Void)) {
        assertionFailure("not implements.")
    }
}

private extension String {
    var longLongValue: Int64 {
        return (self as NSString).longLongValue
    }
}

private extension Int64 {
    var stringValue: String {
        return String(self)
    }
}
