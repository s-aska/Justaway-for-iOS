//
//  ListTableViewController.swift
//  Justaway
//
//  Created by Shinichiro Aska on 7/3/15.
//  Copyright (c) 2015 Shinichiro Aska. All rights reserved.
//

import UIKit
import EventBox
import Async

class ListTableViewController: TimelineTableViewController {

    // MARK: Types

    struct TableViewConstants {
        static let tableViewCellIdentifier = "Cell"
    }

    // MARK: Properties

    var footerView: UIView?
    var footerIndicatorView: UIActivityIndicatorView?

    var userID: String?

    var rows = [Row]()
    var layoutHeightCell: TwitterListCell?
    var layoutHeight: CGFloat?

    struct Row {
        let list: TwitterList
        let fontSize: CGFloat
        let height: CGFloat
        let textHeight: CGFloat

        init(list: TwitterList, fontSize: CGFloat, height: CGFloat, textHeight: CGFloat) {
            self.list = list
            self.fontSize = fontSize
            self.height = height
            self.textHeight = textHeight
        }
    }

    // MARK: UITableViewDelegate

    override func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return timelineHooterHeight
    }

    override func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        if footerView == nil {
            footerView = UIView(frame: CGRect.init(x: 0, y: 0, width: view.frame.size.width, height: timelineHooterHeight))
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

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        configureEvent()
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        EventBox.off(self)
    }

    // MARK: - Configuration

    func configureView() {
        self.tableView.backgroundColor = UIColor.clear
        self.tableView.separatorInset = UIEdgeInsets.zero
        self.tableView.separatorStyle = UITableViewCellSeparatorStyle.singleLine

        let nib = UINib(nibName: "TwitterListCell", bundle: nil)
        self.tableView.register(nib, forCellReuseIdentifier: TableViewConstants.tableViewCellIdentifier)
        self.layoutHeightCell = self.tableView.dequeueReusableCell(withIdentifier: TableViewConstants.tableViewCellIdentifier) as? TwitterListCell

//        let refreshControl = UIRefreshControl()
//        refreshControl.addTarget(self, action: Selector("refresh"), forControlEvents: UIControlEvents.ValueChanged)
//        self.refreshControl = refreshControl
    }

    func configureEvent() {
        EventBox.onMainThread(self, name: eventStatusBarTouched, handler: { (n) -> Void in
            self.tableView.setContentOffset(CGPoint.zero, animated: true)
        })
    }

    // MARK: - UITableViewDataSource

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return rows.count ?? 0
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let row = rows[indexPath.row]
        let list = row.list
        // swiftlint:disable:next force_cast
        let cell = tableView.dequeueReusableCell(withIdentifier: TableViewConstants.tableViewCellIdentifier, for: indexPath) as! TwitterListCell

        if cell.textHeightConstraint.constant != row.textHeight {
            cell.textHeightConstraint.constant = row.textHeight
        }

        if row.fontSize != cell.descriptionLabel.font?.pointSize ?? 0 {
            cell.descriptionLabel.font = UIFont.systemFont(ofSize: row.fontSize)
        }

        cell.listNameLabel.text = list.name
        cell.userNameLabel.text = "by " + list.user.name
        cell.memberCountLabel.text = "\(list.memberCount) members"
        // cell.protectedLabel.hidden = !userList.isProtected
        cell.descriptionLabel.text = list.description

        cell.iconImageView.image = nil
        if let url = list.user.profileImageURL {
            ImageLoaderClient.displayUserIcon(url, imageView: cell.iconImageView)
        }

        return cell
    }

    // MARK: UITableViewDelegate

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let row = rows[indexPath.row]
        return row.height
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
//        let row = rows[indexPath.row]
//        if let cell = tableView.cellForRowAtIndexPath(indexPath) {
//            ProfileViewController.show(TwitterUser(row.user))
//        }
    }

    func createRow(_ list: TwitterList, fontSize: CGFloat) -> Row {
        if let height = layoutHeight {
            let textHeight = measure(list.description as NSString, fontSize: fontSize)
            let totalHeight = ceil(height + textHeight)
            return Row(list: list, fontSize: fontSize, height: totalHeight, textHeight: textHeight)
        } else if let cell = self.layoutHeightCell {
            cell.frame = self.tableView.bounds
            let textHeight = measure(list.description as NSString, fontSize: fontSize)
            cell.textHeightConstraint.constant = 0
            let height = cell.contentView.systemLayoutSizeFitting(UILayoutFittingCompressedSize).height
            layoutHeight = height
            let totalHeight = ceil(height + textHeight)
            return Row(list: list, fontSize: fontSize, height: totalHeight, textHeight: textHeight)
        }
        fatalError("cellForHeight is missing.")
    }

    func measure(_ text: NSString, fontSize: CGFloat) -> CGFloat {
        return ceil(text.boundingRect(
            with: CGSize.init(width: (self.layoutHeightCell?.descriptionLabel.frame.size.width)!, height: 0),
            options: NSStringDrawingOptions.usesLineFragmentOrigin,
            attributes: [NSFontAttributeName: UIFont.systemFont(ofSize: fontSize)],
            context: nil).size.height)
    }

    override func refresh() {
        loadData(nil)
    }

    func loadData(_ maxID: Int64?) {
        let fontSize = CGFloat(GenericSettings.get().fontSize)

        let s = { (userLists: [TwitterList]) -> Void in
            self.rows = userLists.map({ self.createRow($0, fontSize: fontSize) })
            self.tableView.reloadData()
            self.footerIndicatorView?.stopAnimating()
        }

        let f = { (error: NSError) -> Void in
            self.footerIndicatorView?.stopAnimating()
        }

        if !(self.refreshControl?.isRefreshing ?? false) {
            Async.main {
                self.footerIndicatorView?.startAnimating()
                return
            }
        }

        loadData(maxID?.stringValue, success: s, failure: f)
    }

    func loadData(_ maxID: String?, success: @escaping ((_ userLists: [TwitterList]) -> Void), failure: @escaping ((_ error: NSError) -> Void)) {
        assertionFailure("not implements.")
    }
}
