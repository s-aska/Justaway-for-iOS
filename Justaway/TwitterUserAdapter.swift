//
//  TwitterUserAdapter.swift
//  Justaway
//
//  Created by Shinichiro Aska on 5/18/16.
//  Copyright © 2016 Shinichiro Aska. All rights reserved.
//

import UIKit
import Pinwheel
import EventBox
import Async

class TwitterUserAdapter: NSObject {

    // MARK: - Types

    struct TableViewConstants {
        static let tableViewCellIdentifier = "Cell"
    }

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

    // MARK: - Properties

    var footerView: UIView?
    var footerIndicatorView: UIActivityIndicatorView?

    var rows = [Row]()
    var layoutHeightCell: TwitterUserCell?
    var layoutHeight: CGFloat?
    var didScrollToBottom: (Void -> Void)?
    let loadDataQueue = NSOperationQueue().serial()
    let mainQueue = NSOperationQueue().serial()

    func configureView(tableView: UITableView) {
        tableView.separatorInset = UIEdgeInsetsZero
        tableView.separatorStyle = UITableViewCellSeparatorStyle.SingleLine
        tableView.delegate = self
        tableView.dataSource = self
        tableView.registerNib(UINib(nibName: "TwitterUserCell", bundle: nil), forCellReuseIdentifier: TableViewConstants.tableViewCellIdentifier)
        layoutHeightCell = tableView.dequeueReusableCellWithIdentifier(TableViewConstants.tableViewCellIdentifier) as? TwitterUserCell
    }

    func renderData(tableView: UITableView, users: [TwitterUserFull], mode: TwitterAdapter.RenderMode, handler: (() -> Void)?) {
        var users = users
        let fontSize = CGFloat(GenericSettings.get().fontSize)
        let limit = mode == .OVER ? 0 : timelineRowsLimit

//        var addShowMore = false
//        if mode == .HEADER {
//            if let firstUniqueID = firstUniqueID() {
//                if statuses.contains({ $0.uniqueID == firstUniqueID }) {
//                    statuses.removeAtIndex(statuses.count - 1)
//                } else {
//                    addShowMore = true
//                }
//            }
//        } else if mode == .TOP {
//            if let topRowStatus = rows.first?.status, firstReceivedStatus = statuses.first {
//                if !firstReceivedStatus.connectionID.isEmpty && firstReceivedStatus.connectionID != topRowStatus.connectionID {
//                    addShowMore = true
//                }
//            }
//        }

        if mode != .OVER {
            users = users.filter { user -> Bool in
                return !rows.contains { $0.user.userID ?? "" == user.userID }
            }
        }

        let deleteCount = mode == .OVER ? self.rows.count : max((self.rows.count + users.count) - limit, 0)
        let deleteStart = mode == .TOP || mode == .HEADER ? self.rows.count - deleteCount : 0
        let deleteRange = deleteStart ..< (deleteStart + deleteCount)
        let deleteIndexPaths = deleteRange.map { row in NSIndexPath(forRow: row, inSection: 0) }

        let insertStart = mode == .BOTTOM ? self.rows.count - deleteCount : 0
        let insertIndexPaths = (insertStart ..< (insertStart + users.count)).map { row in NSIndexPath(forRow: row, inSection: 0) }

        if deleteIndexPaths.count == 0 && users.count == 0 {
            handler?()
            return
        }
        // println("renderData lastID: \(self.lastID ?? 0) insertIndexPaths: \(insertIndexPaths.count) deleteIndexPaths: \(deleteIndexPaths.count) oldRows:\(self.rows.count)")

        if let lastCell = tableView.visibleCells.last {
            // NSLog("y:\(tableView.contentOffset.y) top:\(tableView.contentInset.top)")
            let isTop = tableView.contentOffset.y + tableView.contentInset.top <= 0 && mode == .TOP
            let offset = lastCell.frame.origin.y - tableView.contentOffset.y
            UIView.setAnimationsEnabled(false)
            tableView.beginUpdates()
            if deleteIndexPaths.count > 0 {
                tableView.deleteRowsAtIndexPaths(deleteIndexPaths, withRowAnimation: .None)
                self.rows.removeRange(deleteRange)
            }
            if insertIndexPaths.count > 0 {
                var i = 0
                for insertIndexPath in insertIndexPaths {
                    let row = self.createRow(users[i], fontSize: fontSize, tableView: tableView)
                    self.rows.insert(row, atIndex: insertIndexPath.row)
                    i += 1
                }
                tableView.insertRowsAtIndexPaths(insertIndexPaths, withRowAnimation: .None)
            }
            tableView.endUpdates()
            tableView.setContentOffset(CGPoint(x: 0, y: lastCell.frame.origin.y - offset), animated: false)
            UIView.setAnimationsEnabled(true)
            if isTop {
                UIView.animateWithDuration(0.3, animations: { _ in
                    tableView.contentOffset = CGPoint(x: 0, y: -tableView.contentInset.top)
                    }, completion: { _ in
                        // self.scrollEnd(tableView)
                        // self.renderDataCallback?(statuses: statuses, mode: mode)
                        handler?()
                })
            } else {
                if mode == .OVER {
                    tableView.contentOffset = CGPoint(x: 0, y: -tableView.contentInset.top)
                }
                // self.renderDataCallback?(statuses: statuses, mode: mode)
                handler?()
            }

        } else {
            if deleteIndexPaths.count > 0 {
                self.rows.removeRange(deleteRange)
            }
            for user in users {
                self.rows.append(self.createRow(user, fontSize: fontSize, tableView: tableView))
            }
            tableView.setContentOffset(CGPoint(x: 0, y: -tableView.contentInset.top), animated: false)
            tableView.reloadData()
            // self.renderImages(tableView)
            // self.renderDataCallback?(statuses: statuses, mode: mode)
            handler?()
        }
    }
}

// MARK: - UITableViewDataSource

extension TwitterUserAdapter: UITableViewDataSource {
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return rows.count
    }

    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let row = rows[indexPath.row]
        let user = row.user
        // swiftlint:disable:next force_cast
        let cell = tableView.dequeueReusableCellWithIdentifier(TableViewConstants.tableViewCellIdentifier, forIndexPath: indexPath) as! TwitterUserCell

        cell.user = user

        if cell.textHeightConstraint.constant != row.textHeight {
            cell.textHeightConstraint.constant = row.textHeight
        }

        if row.fontSize != cell.descriptionLabel.font?.pointSize ?? 0 {
            cell.descriptionLabel.font = UIFont.systemFontOfSize(row.fontSize)
        }

        cell.displayNameLabel.text = user.name
        cell.screenNameLabel.text = user.screenName
        cell.protectedLabel.hidden = !user.isProtected
        cell.descriptionLabel.text = user.description
        cell.followingLabel.text = user.friendsCount.description
        cell.followerLabel.text = user.followersCount.description
        cell.listsLabel.text = user.listedCount.description
        cell.blockLabel.hidden = true
        cell.muteLabel.hidden = true
        cell.retweetLabel.hidden = true
        cell.retweetDeleteLabel.hidden = true

        if let account = AccountSettingsStore.get()?.account() {
            Relationship.checkUser(account.userID, targetUserID: user.userID, callback: { (relationshop) in
                Async.main {
                    cell.followButton.hidden = relationshop.following
                    cell.unfollowButton.hidden = !relationshop.following
                    cell.blockLabel.hidden = !relationshop.blocking
                    cell.muteLabel.hidden = !relationshop.muting
                    cell.retweetLabel.hidden = relationshop.wantRetweets
                    cell.retweetDeleteLabel.hidden = relationshop.wantRetweets
                }
            })
        }

        cell.iconImageView.image = nil
        ImageLoaderClient.displayUserIcon(user.profileImageURL, imageView: cell.iconImageView)

        return cell
    }
}

// MARK: - UITableViewDelegate

extension TwitterUserAdapter: UITableViewDelegate {
    func tableView(tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return timelineHooterHeight
    }

    func tableView(tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        if footerView == nil {
            footerView = UIView(frame: CGRect(x: 0, y: 0, width: tableView.frame.size.width, height: timelineHooterHeight))
            footerIndicatorView = UIActivityIndicatorView(activityIndicatorStyle: ThemeController.currentTheme.activityIndicatorStyle())
            footerView?.addSubview(footerIndicatorView!)
            footerIndicatorView?.hidesWhenStopped = true
            footerIndicatorView?.center = (footerView?.center)!
        }
        return footerView
    }

    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        let row = rows[indexPath.row]
        return row.height
    }

    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let row = rows[indexPath.row]
        ProfileViewController.show(TwitterUser(row.user))
    }
}

// MARK: - UIScrollViewDelegate

extension TwitterUserAdapter {

    func scrollEnd(scrollView: UIScrollView) {
        let y = scrollView.contentOffset.y + scrollView.bounds.size.height - scrollView.contentInset.bottom
        let h = scrollView.contentSize.height
        let f = h - y
        if f < timelineHooterHeight && h > scrollView.bounds.size.height {
            didScrollToBottom?()
        }
    }

    func scrollViewDidEndDragging(scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if decelerate {
            return
        }
        scrollEnd(scrollView) // end of flick scrolling no deceleration
    }

    func scrollViewDidEndDecelerating(scrollView: UIScrollView) {
        scrollEnd(scrollView) // end of deceleration of flick scrolling
    }

    func scrollViewDidEndScrollingAnimation(scrollView: UIScrollView) {
        scrollEnd(scrollView) // end of setContentOffset
    }
}


// MARK: - Public

extension TwitterUserAdapter {
    func createRow(user: TwitterUserFull, fontSize: CGFloat, tableView: UITableView) -> Row {
        if let height = layoutHeight {
            let textHeight = measure(user.description, fontSize: fontSize)
            let totalHeight = ceil(height + textHeight)
            return Row(user: user, fontSize: fontSize, height: totalHeight, textHeight: textHeight)
        } else if let cell = self.layoutHeightCell {
            cell.frame = tableView.bounds
            cell.setNeedsLayout()
            cell.layoutIfNeeded()
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
        let heigit = ceil(text.boundingRectWithSize(
            CGSize.init(width: (self.layoutHeightCell?.descriptionLabel.frame.size.width)!, height: 0),
            options: NSStringDrawingOptions.UsesLineFragmentOrigin,
            attributes: [NSFontAttributeName: UIFont.systemFontOfSize(fontSize)],
            context: nil).size.height)
        return max(heigit, 23)
    }
}
