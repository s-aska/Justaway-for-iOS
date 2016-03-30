//
//  SearchKeywordAdapter.swift
//  Justaway
//
//  Created by Shinichiro Aska on 3/30/16.
//  Copyright © 2016 Shinichiro Aska. All rights reserved.
//

import UIKit
import KeyClip
import Async
import EventBox

class SearchKeywordAdapter: NSObject {

    var historyWord = [String]()
    var selectCallback: (String -> Void)?
    var scrollCallback: (() -> Void)?


    func configureView(tableView: UITableView) {
        tableView.registerNib(UINib(nibName: "SearchKeywordCell", bundle: nil), forCellReuseIdentifier: "SearchKeywordCell")
        tableView.dataSource = self
        tableView.delegate = self
        tableView.separatorInset = UIEdgeInsetsZero
        loadData(tableView)
        EventBox.onMainThread(self, name: "SearchKeywordDeleted") { [weak self] (n) in
            guard let data = n.object as? [String: String] else {
                return
            }
            if let keyword = data["keyword"] {
                self?.removeHistory(keyword, tableView: tableView)
            }
        }
    }

    func loadData(tableView: UITableView) {
        if let data = KeyClip.load("searchKeywordHistory") as NSDictionary? {
            if let keywords = data["keywords"] as? [String] {
                historyWord = keywords
                Async.main {
                    tableView.reloadData()
                }
            }
        }
    }

    func appendHistory(keyword: String, tableView: UITableView) {
        historyWord = historyWord.filter { $0 != keyword }
        historyWord.insert(keyword, atIndex: 0)
        Async.main {
            tableView.reloadData()
        }
        KeyClip.save("searchKeywordHistory", dictionary: ["keywords": historyWord])
    }

    func removeHistory(keyword: String, tableView: UITableView) {
        if let index = historyWord.indexOf(keyword) {
            historyWord.removeAtIndex(index)
            let indexPath = NSIndexPath.init(forRow: index, inSection: 0)
            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Automatic)
        }
        KeyClip.save("searchKeywordHistory", dictionary: ["keywords": historyWord])
    }

    deinit {
        EventBox.off(self)
    }
}

// MARK: - UITableViewDataSource

extension SearchKeywordAdapter: UITableViewDataSource {
//    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
//        return 1
//    }

//    func tableView(tableView: UITableView, willDisplayHeaderView view:UIView, forSection: Int) {
//        if let headerView = view as? UITableViewHeaderFooterView {
//            headerView.textLabel?.textColor = ThemeController.currentTheme.bodyTextColor()
//        }
//    }

//    func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
//        switch section {
//        case 0:
//            return "History"
//        case 1:
//            return "Saved"
//        default:
//            return nil
//        }
//    }

    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return historyWord.count
    }

    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        // swiftlint:disable:next force_cast
        let cell = tableView.dequeueReusableCellWithIdentifier("SearchKeywordCell", forIndexPath: indexPath) as! SearchKeywordCell
        if historyWord.count > indexPath.row {
            cell.keyword = historyWord[indexPath.row]
            cell.nameLabel.text = historyWord[indexPath.row]
        }
        return cell
    }
}

// MARK: - UITableViewDelegate

extension SearchKeywordAdapter: UITableViewDelegate {
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 40
    }

    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if historyWord.count > indexPath.row {
            selectCallback?(historyWord[indexPath.row])
        }
    }
}

// MARK: - UIScrollViewDelegate

extension SearchKeywordAdapter {
    func scrollViewWillBeginDragging(scrollView: UIScrollView) {
        scrollCallback?()
    }
}
