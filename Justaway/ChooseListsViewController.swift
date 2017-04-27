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
        static let delay: TimeInterval = 0
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

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        configureEvent()

        if items.count == 0 {
            loadAPI()
        }
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        EventBox.off(self)
    }

    // MARK: - Configuration

    func configureView() {
        tableView.separatorInset = UIEdgeInsets.zero
        tableView.separatorStyle = UITableViewCellSeparatorStyle.singleLine
        tableView.delegate = self
        tableView.dataSource = self
        tableView.addSubview(refreshControl)

        // apply theme
        for cell in tableView.visibleCells {
            cell.textLabel?.textColor = ThemeController.currentTheme.bodyTextColor()
        }

        refreshControl.addTarget(self, action: #selector(ChooseListsViewController.refresh), for: UIControlEvents.valueChanged)

        let swipe = UISwipeGestureRecognizer(target: self, action: #selector(ChooseListsViewController.hide))
        swipe.numberOfTouchesRequired = 1
        swipe.direction = UISwipeGestureRecognizerDirection.right
        tableView.addGestureRecognizer(swipe)
    }

    func configureEvent() {
    }

    // MARK: - UITableViewDataSource

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count ?? 0
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: UITableViewCellStyle.default, reuseIdentifier: TableViewConstants.tableViewCellIdentifier)
        let item = items[indexPath.row]
        cell.selectionStyle = .none
        cell.separatorInset = UIEdgeInsets.zero
        cell.layoutMargins = UIEdgeInsets.zero
        cell.preservesSuperviewLayoutMargins = false
        cell.textLabel?.text = item.list.name
        cell.accessoryType = item.selected ? .checkmark : .none
        cell.backgroundColor = UIColor.clear
        cell.textLabel?.textColor = ThemeController.currentTheme.bodyTextColor()
        return cell
    }

    func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        return true
    }

    // MARK: UITableViewDelegate

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let cell = tableView.cellForRow(at: indexPath) else {
            return
        }
        items[indexPath.row].selected = !items[indexPath.row].selected
        cell.accessoryType = items[indexPath.row].selected ? .checkmark : .none
    }

    // MARK: - Actions

    func loadAPI() {
        guard let account = AccountSettingsStore.get()?.account() else {
            return
        }
        let success = { (array: [TwitterList]) -> Void in
            self.refreshControl.endRefreshing()
            self.items = array.map({ (list: TwitterList) -> Item in
                return Item(list: list, selected: account.tabs.index(where: { $0.type == .Lists && $0.list.id == list.id }) != nil)
            })
            self.tableView.reloadData()
        }
        let failure = { (error: NSError) -> Void in
            self.refreshControl.endRefreshing()
            ErrorAlert.show("failure", message: error.localizedDescription)
        }
        Twitter.getLists(success, failure: failure)
    }

    @IBAction func close(_ sender: AnyObject) {
        hide()
    }

    @IBAction func left(_ sender: UIButton) {
        hide()
    }

    @IBAction func right(_ sender: UIButton) {
        done()
    }

    func hide() {
        UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseOut, animations: {
            self.view.frame = self.view.frame.offsetBy(dx: self.view.frame.size.width, dy: 0)
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
        EventBox.post(Notification.Name(rawValue: "setListsTab"), sender: tabs as AnyObject)
        hide()
    }

    func refresh() {
        loadAPI()
    }

    class func show() {
        if let vc = ViewTools.frontViewController() {
            Static.instance.view.isHidden = true
            vc.view.addSubview(Static.instance.view)
            Static.instance.view.frame = CGRect.init(x: vc.view.frame.width, y: 20, width: vc.view.frame.width, height: vc.view.frame.height - 20)
            Static.instance.view.isHidden = false

            UIView.animate(withDuration: Constants.duration, delay: Constants.delay, options: .curveEaseOut, animations: { () -> Void in
                Static.instance.view.frame = CGRect.init(x: 0,
                    y: 20,
                    width: vc.view.frame.size.width,
                    height: vc.view.frame.size.height - 20)
                }) { (finished) -> Void in
            }
        }
    }
}
