//
//  SideMenu.swift
//  Justaway
//
//  Created by Shinichiro Aska on 10/6/15.
//  Copyright © 2015 Shinichiro Aska. All rights reserved.
//

import UIKit
import Async
import EventBox

class SideMenuViewController: UIViewController {

    // MARK: Properties

    var overlayWindow: UIWindow?

    @IBOutlet weak var bannerImageView: UIImageView!
    @IBOutlet weak var iconImageView: UIImageView!
    @IBOutlet weak var displayNameLabel: UILabel!
    @IBOutlet weak var screenNameLabel: UILabel!
    @IBOutlet weak var sideViewLeftConstraint: NSLayoutConstraint!

    @IBOutlet weak var disableSleepSwitch: UISwitch!
    @IBOutlet weak var streamingButton: MenuButton?

    var settingsViewController: SettingsViewController?

    var account: Account?

    override var nibName: String {
        return "SideMenuViewController"
    }

    // MARK: - View Life Cycle

    override func viewDidLoad() {
        super.viewDidLoad()
        configureView()
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
        overlayWindow = UIWindow(frame: UIScreen.main.bounds)
        overlayWindow?.rootViewController = self
        overlayWindow?.backgroundColor = UIColor.clear
        overlayWindow?.rootViewController?.view.backgroundColor = UIColor.clear
        overlayWindow?.windowLevel = UIWindowLevelStatusBar

        view.frame = UIScreen.main.bounds
        view.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.5)
        view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(hide)))

        let swipe = UISwipeGestureRecognizer(target: self, action: #selector(hide))
        swipe.numberOfTouchesRequired = 1
        swipe.direction = .left
        view.addGestureRecognizer(swipe)

        sideViewLeftConstraint.constant = -300

        iconImageView.layer.cornerRadius = 30

        bannerImageView.clipsToBounds = true
        bannerImageView.contentMode = .scaleAspectFill
        bannerImageView.isUserInteractionEnabled = true
        bannerImageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(profile)))

        let gradient = CAGradientLayer()
        gradient.colors = [UIColor(red: 0, green: 0, blue: 0, alpha: 0).cgColor, UIColor(red: 0, green: 0, blue: 0, alpha: 0.5).cgColor]
        gradient.frame = bannerImageView.frame
        bannerImageView.layer.insertSublayer(gradient, at: 0)

        updateStreamingButtonTitle()

        // EventBox.post("changeStreamingMode")
    }

    func streamingModeLabel() -> String {
        switch Twitter.streamingMode {
        case .Manual:
            return "Manual"
        case .AutoOnWiFi:
            return "Auto (Wi-Fi)"
        case .AutoAlways:
            return "Auto"
        }
    }

    func streamingStatusLabel() -> String {
        switch Twitter.connectionStatus {
        case .connected:
            return "connected"
        case .connecting:
            return "connecting..."
        case .disconnected:
            if Twitter.enableStreaming {
                return "disconnected"
            } else {
                return "off"
            }
        case .disconnecting:
            return "disconnecting..."
        }
    }

    func configureEvent() {
        _ = EventBox.onMainThread(self, name: eventChangeStreamingMode) { n in
            self.updateStreamingButtonTitle()
        }
    }

    func updateStreamingButtonTitle() {
        self.streamingButton?.setTitle("Streaming: \(self.streamingModeLabel()) / \(self.streamingStatusLabel())", for: UIControlState())
    }

    // MARK: -

    func show(_ account: Account) {
        self.account = account

        view.isHidden = true
        view.alpha = 1
        overlayWindow?.isHidden = false

        displayNameLabel.text = account.name
        screenNameLabel.text = "@" + account.screenName
        if let url = account.profileImageBiggerURL {
            ImageLoaderClient.displaySideMenuUserIcon(url, imageView: iconImageView)
        }
        disableSleepSwitch.isOn = GenericSettings.get().disableSleep

        if let url = account.profileBannerURL {
            ImageLoaderClient.displayImage(url, imageView: bannerImageView)
        }

        EditorViewController.hide()

        Async.main(after: 0.1) { () -> Void in
            self.view.isHidden = false
            self.sideViewLeftConstraint.constant = 0
            UIView.animate(withDuration: 0.2, delay: 0, options: UIViewAnimationOptions.curveEaseOut, animations: { () -> Void in
                self.view.layoutIfNeeded()
            }, completion: nil)
        }
    }

    func profile() {
        guard let account = account else {
            return
        }
        ProfileViewController.show(account.screenName)
        hide()
    }

    func hide() {
        sideViewLeftConstraint.constant = -300

        UIView.animate(withDuration: 0.2, delay: 0, options: UIViewAnimationOptions.curveEaseOut, animations: { () -> Void in
            self.view.alpha = 0
            self.view.layoutIfNeeded()
            }, completion: { _ in
                self.overlayWindow?.isHidden = true
        })
    }

    @IBAction func accountSettings(_ sender: UIButton) {
        AccountViewController.show()
        hide()
    }

    @IBAction func openProfile(_ sender: UIButton) {
        ProfileViewController.show(TwitterUser(account!))
        hide()
    }

    @IBAction func disableSleep(_ sender: UISwitch) {
        _ = GenericSettings.update(sender.isOn)
        UIApplication.shared.isIdleTimerDisabled = sender.isOn
    }

    @IBAction func disableSleepButton(_ sender: UIButton) {
        disableSleepSwitch.isOn = disableSleepSwitch.isOn ? false : true
        _ = GenericSettings.update(disableSleepSwitch.isOn)
        UIApplication.shared.isIdleTimerDisabled = disableSleepSwitch.isOn
    }

    @IBAction func streaming(_ sender: UIButton) {
        hide()
        StreamingAlert.show(sender)
    }

    @IBAction func tabSettingsView(_ sender: UIButton) {
        TabSettingsViewController.show()
        hide()
    }

    @IBAction func displaySettings(_ sender: UIButton) {
        settingsViewController?.show()
        settingsViewController?.showThemeSettingsView(sender)
        hide()
    }

    @IBAction func feedback(_ sender: UIButton) {
        EditorViewController.show(" #justaway", range: NSRange(location: 0, length: 0), inReplyToStatus: nil)
        hide()
    }

    @IBAction func about(_ sender: UIButton) {
        AboutViewController.show()
        hide()
    }
}
