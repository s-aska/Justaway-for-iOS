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

    func configureView(tableView: UITableView) {
        tableView.separatorInset = UIEdgeInsetsZero
        tableView.separatorStyle = UITableViewCellSeparatorStyle.SingleLine
        tableView.delegate = self
        tableView.dataSource = self
        tableView.registerNib(UINib(nibName: "TwitterUserCell", bundle: nil), forCellReuseIdentifier: TableViewConstants.tableViewCellIdentifier)
        layoutHeightCell = tableView.dequeueReusableCellWithIdentifier(TableViewConstants.tableViewCellIdentifier) as? TwitterUserCell
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
        return ceil(text.boundingRectWithSize(
            CGSize.init(width: (self.layoutHeightCell?.descriptionLabel.frame.size.width)!, height: 0),
            options: NSStringDrawingOptions.UsesLineFragmentOrigin,
            attributes: [NSFontAttributeName: UIFont.systemFontOfSize(fontSize)],
            context: nil).size.height)
    }
}
