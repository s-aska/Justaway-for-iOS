//
//  UserListTableViewController.swift
//  Justaway
//
//  Created by Shinichiro Aska on 7/3/15.
//  Copyright (c) 2015 Shinichiro Aska. All rights reserved.
//

import UIKit
import EventBox

class UserListTableViewController: UITableViewController {
    
    // MARK: Types
    
    struct TableViewConstants {
        static let tableViewCellIdentifier = "Cell"
    }
    
    // MARK: Properties
    
    var footerView: UIView?
    var footerIndicatorView: UIActivityIndicatorView?
    
    var userID: String?
    
    var rows = [Row]()
    var layoutHeightCell: TwitterUserListCell?
    var layoutHeight: CGFloat?
    
    struct Row {
        let userList: TwitterUserList
        let fontSize: CGFloat
        let height: CGFloat
        let textHeight: CGFloat
        
        init(userList: TwitterUserList, fontSize: CGFloat, height: CGFloat, textHeight: CGFloat) {
            self.userList = userList
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
        
        let nib = UINib(nibName: "TwitterUserListCell", bundle: nil)
        self.tableView.registerNib(nib, forCellReuseIdentifier: TableViewConstants.tableViewCellIdentifier)
        self.layoutHeightCell = self.tableView.dequeueReusableCellWithIdentifier(TableViewConstants.tableViewCellIdentifier) as? TwitterUserListCell
        
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
        let userList = row.userList
        let cell = tableView.dequeueReusableCellWithIdentifier(TableViewConstants.tableViewCellIdentifier, forIndexPath: indexPath) as! TwitterUserListCell
        
        cell.userListNameLabel.text = userList.name
        cell.userNameLabel.text = "by " + userList.user.name
        // cell.protectedLabel.hidden = !userList.isProtected
        cell.descriptionLabel.text = userList.description
        
        // cell.textHeightConstraint.constant = row.textHeight
        
        ImageLoaderClient.displayUserIcon(userList.user.profileImageURL, imageView: cell.iconImageView)
        
        return cell
    }
    
    // MARK: UITableViewDelegate
    
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        let row = rows[indexPath.row]
        return row.height
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let row = rows[indexPath.row]
        if let cell = tableView.cellForRowAtIndexPath(indexPath) {
            // ProfileViewController.show(TwitterUser(row.user))
        }
    }
    
    func createRow(userList: TwitterUserList, fontSize: CGFloat) -> Row {
        if let height = layoutHeight {
            let textHeight = measure(userList.description, fontSize: fontSize)
            let totalHeight = ceil(height + textHeight)
            return Row(userList: userList, fontSize: fontSize, height: totalHeight, textHeight: textHeight)
        } else if let cell = self.layoutHeightCell {
            cell.frame = self.tableView.bounds
            let textHeight = measure(userList.description, fontSize: fontSize)
            cell.textHeightConstraint.constant = 0
            let height = cell.contentView.systemLayoutSizeFittingSize(UILayoutFittingCompressedSize).height
            layoutHeight = height
            let totalHeight = ceil(height + textHeight)
            return Row(userList: userList, fontSize: fontSize, height: totalHeight, textHeight: textHeight)
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
        var fontSize :CGFloat = 12.0
        if let delegate = UIApplication.sharedApplication().delegate as? AppDelegate {
            fontSize = CGFloat(delegate.fontSize)
        }
        
        let s = { (userLists: [TwitterUserList]) -> Void in
            self.rows = userLists.map({ self.createRow($0, fontSize: fontSize) })
            self.tableView.reloadData()
        }
        
        let f = { (error: NSError) -> Void in
            
        }
        
        loadData(maxID?.stringValue, success: s, failure: f)
    }
    
    func loadData(id: String?, success: ((userLists: [TwitterUserList]) -> Void), failure: ((error: NSError) -> Void)) {
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
