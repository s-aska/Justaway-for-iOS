//
//  AboutViewController.swift
//  Justaway
//
//  Created by Shinichiro Aska on 3/29/16.
//  Copyright © 2016 Shinichiro Aska. All rights reserved.
//

import UIKit
import Pinwheel
import EventBox

class AboutViewController: UIViewController {

    // MARK: Properties

    @IBOutlet weak var tableView: BackgroundTableView!

    override var nibName: String {
        return "AboutViewController"
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
        tableView.separatorInset = UIEdgeInsetsZero
        tableView.separatorStyle = UITableViewCellSeparatorStyle.SingleLine
        tableView.delegate = self
        tableView.dataSource = self
    }

    func configureEvent() {
    }

    // MARK: - Actions

    @IBAction func left(sender: UIButton) {
        hide()
    }

    func hide() {
        ViewTools.slideOut(self)
    }

    // MARK: - Class Methods

    class func show() {
        let instance = AboutViewController()
        ViewTools.slideIn(instance)
    }
}

// MARK: - UITableViewDataSource

extension AboutViewController: UITableViewDataSource {
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 8
    }

    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .Default, reuseIdentifier: nil)
        cell.selectionStyle = .None
        cell.separatorInset = UIEdgeInsetsZero
        cell.layoutMargins = UIEdgeInsetsZero
        cell.preservesSuperviewLayoutMargins = false
        cell.backgroundColor = UIColor.clearColor()
        cell.textLabel?.textColor = ThemeController.currentTheme.bodyTextColor()
        switch indexPath.row {
        case 0:
            cell.textLabel?.text = "Feedback with #justaway"
        case 1:
            cell.textLabel?.text = "Supported by @justawayfactory"
        case 2:
            cell.textLabel?.text = "Official Site"
        case 3:
            cell.textLabel?.text = "Open source licenses"
        case 4:
            cell.textLabel?.text = "Terms of Service"
        case 5:
            cell.textLabel?.text = "Privacy Policy"
        case 6:
            let version = NSBundle.mainBundle().objectForInfoDictionaryKey("CFBundleShortVersionString") as? String ?? "-"
            cell.textLabel?.text = "Version: " + version
        case 7:
            let build = NSBundle.mainBundle().objectForInfoDictionaryKey("CFBundleVersion") as? String ?? "-"
            cell.textLabel?.text = "Build: " + build
        default:
            break
        }
        return cell
    }
}

// MARK: - UITableViewDelegate

extension AboutViewController: UITableViewDelegate {
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 60
    }

    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        switch indexPath.row {
        case 0:
            EditorViewController.show(" #justaway", range: NSRange(location: 0, length: 0), inReplyToStatus: nil)
            hide()
        case 1:
            ProfileViewController.show("justawayfactory")
            hide()
        case 2:
            Safari.openURL("http://justaway.info/")
        case 3:
            Safari.openURL("http://justaway.info/iOS/licenses.html")
        case 4:
            Safari.openURL("http://justaway.info/iOS/terms.html")
        case 5:
            Safari.openURL("http://justaway.info/iOS/privacy.html")
        default:
            break
        }
    }
}
