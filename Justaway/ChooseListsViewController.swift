//
//  ChooseListsViewController.swift
//  Justaway
//
//  Created by Shinichiro Aska on 2/17/16.
//  Copyright © 2016 Shinichiro Aska. All rights reserved.
//

import UIKit
import Accounts
import Social
import EventBox
import TwitterAPI

class ChooseListsViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    // MARK: Types

    struct TableViewConstants {
        static let tableViewCellIdentifier = "Cell"
    }

    struct Constants {
        static let duration: Double = 0.2
        static let delay: NSTimeInterval = 0
    }

    struct Static {
        static let instance = ChooseListsViewController()
    }

    struct Item {
        let list: TwitterList
        var selected: Bool

        init(list: TwitterList, selected: Bool) {
            self.list = list
            self.selected = selected
        }
    }

    // MARK: Properties

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var leftButton: UIButton!
    @IBOutlet weak var rightButton: UIButton!
    let refreshControl = UIRefreshControl()

    var items = [Item]()

    override var nibName: String {
        return "ChooseListsViewController"
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

        if items.count == 0 {
            loadAPI()
        }
    }

    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        EventBox.off(self)
    }

    // MARK: - Configuration

    func configureView() {
        tableView.separatorInset = UIEdgeInsetsZero
        tableView.separatorStyle = UITableViewCellSeparatorStyle.SingleLine
        tableView.delegate = self
        tableView.dataSource = self
        tableView.addSubview(refreshControl)

        // apply theme
        for cell in tableView.visibleCells {
            cell.textLabel?.textColor = ThemeController.currentTheme.bodyTextColor()
        }

        refreshControl.addTarget(self, action: Selector("refresh"), forControlEvents: UIControlEvents.ValueChanged)

        let swipe = UISwipeGestureRecognizer(target: self, action: "hide")
        swipe.numberOfTouchesRequired = 1
        swipe.direction = UISwipeGestureRecognizerDirection.Right
        tableView.addGestureRecognizer(swipe)
    }

    func configureEvent() {
    }

    // MARK: - UITableViewDataSource

    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count ?? 0
    }

    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: UITableViewCellStyle.Default, reuseIdentifier: TableViewConstants.tableViewCellIdentifier)
        let item = items[indexPath.row]
        cell.selectionStyle = .None
        cell.separatorInset = UIEdgeInsetsZero
        cell.layoutMargins = UIEdgeInsetsZero
        cell.preservesSuperviewLayoutMargins = false
        cell.textLabel?.text = item.list.name
        cell.accessoryType = item.selected ? .Checkmark : .None
        cell.backgroundColor = UIColor.clearColor()
        cell.textLabel?.textColor = ThemeController.currentTheme.bodyTextColor()
        return cell
    }

    func tableView(tableView: UITableView, canMoveRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }

    // MARK: UITableViewDelegate

    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 60
    }

    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        guard let cell = tableView.cellForRowAtIndexPath(indexPath) else {
            return
        }
        items[indexPath.row].selected = !items[indexPath.row].selected
        cell.accessoryType = items[indexPath.row].selected ? .Checkmark : .None
    }

    // MARK: - Actions

    func loadAPI() {
        guard let account = AccountSettingsStore.get()?.account() else {
            return
        }
        let success = { (array: [TwitterList]) -> Void in
            self.refreshControl.endRefreshing()
            self.items = array.map({ (list: TwitterList) -> Item in
                return Item(list: list, selected: account.tabs.indexOf({ $0.type == .Lists && $0.list.id == list.id }) != nil)
            })
            self.tableView.reloadData()
        }
        let failure = { (error: NSError) -> Void in
            self.refreshControl.endRefreshing()
            ErrorAlert.show("failure", message: error.localizedDescription)
        }
        Twitter.getLists(success, failure: failure)
    }

    @IBAction func close(sender: AnyObject) {
        hide()
    }

    @IBAction func left(sender: UIButton) {
        hide()
    }

    @IBAction func right(sender: UIButton) {
        done()
    }

    func hide() {
        UIView.animateWithDuration(0.3, delay: 0, options: .CurveEaseOut, animations: {
            self.view.frame = CGRect.init(
                x: self.view.frame.size.width,
                y: self.view.frame.origin.y,
                width: self.view.frame.size.width,
                height: self.view.frame.size.height)
            }, completion: { finished in
                self.view.removeFromSuperview()
        })
    }

    func cancel() {
        hide()
    }

    func done() {
        guard let account = AccountSettingsStore.get()?.account() else {
            return
        }
        let tabs = items.filter({ $0.selected }).map({ Tab.init(userID: account.userID, list: $0.list) })
        EventBox.post("setListsTab", sender: tabs)
        hide()
    }

    func refresh() {
        loadAPI()
    }

    class func show() {
        if let vc = ViewTools.frontViewController() {
            Static.instance.view.hidden = true
            vc.view.addSubview(Static.instance.view)
            Static.instance.view.frame = CGRect.init(x: vc.view.frame.width, y: 20, width: vc.view.frame.width, height: vc.view.frame.height - 20)
            Static.instance.view.hidden = false

            UIView.animateWithDuration(Constants.duration, delay: Constants.delay, options: .CurveEaseOut, animations: { () -> Void in
                Static.instance.view.frame = CGRect.init(x: 0,
                    y: 20,
                    width: vc.view.frame.size.width,
                    height: vc.view.frame.size.height - 20)
                }) { (finished) -> Void in
            }
        }
    }
}
