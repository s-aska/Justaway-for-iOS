//
//  SideMenu.swift
//  Justaway
//
//  Created by Shinichiro Aska on 10/6/15.
//  Copyright © 2015 Shinichiro Aska. All rights reserved.
//

import UIKit

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
    
    // MARK: - Configuration
    
    func configureView() {
        overlayWindow = UIWindow(frame: UIScreen.mainScreen().bounds)
        overlayWindow?.rootViewController = self
        overlayWindow?.backgroundColor = UIColor.clearColor()
        overlayWindow?.rootViewController?.view.backgroundColor = UIColor.clearColor()
        overlayWindow?.windowLevel = UIWindowLevelStatusBar
        
        view.frame = UIScreen.mainScreen().bounds
        view.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.5)
        view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: "hide"))
        
        let swipe = UISwipeGestureRecognizer(target: self, action: "hide")
        swipe.numberOfTouchesRequired = 1
        swipe.direction = .Left
        view.addGestureRecognizer(swipe)
        
        sideViewLeftConstraint.constant = -300
        
        bannerImageView.clipsToBounds = true
        bannerImageView.contentMode = .ScaleAspectFill
        
        let gradient = CAGradientLayer()
        gradient.colors = [UIColor(red: 0, green: 0, blue: 0, alpha: 0).CGColor, UIColor(red: 0, green: 0, blue: 0, alpha: 0.5).CGColor]
        gradient.frame = bannerImageView.frame
        bannerImageView.layer.insertSublayer(gradient, atIndex: 0)
    }
    
    // MARK: -
    
    func show(account: Account) {
        self.account = account
        
        view.hidden = true
        view.alpha = 1
        overlayWindow?.hidden = false
        
        displayNameLabel.text = account.name
        screenNameLabel.text = "@" + account.screenName
        ImageLoaderClient.displaySideMenuUserIcon(account.profileImageURL, imageView: iconImageView)
        disableSleepSwitch.on = GenericSettings.get().disableSleep
        
        if !account.profileBannerURL.absoluteString.isEmpty {
            ImageLoaderClient.displayImage(account.profileBannerURL, imageView: bannerImageView)
        }
        
        Async.main(after: 0.1) { () -> Void in
            self.view.hidden = false
            self.sideViewLeftConstraint.constant = 0
            UIView.animateWithDuration(0.2, delay: 0, options: UIViewAnimationOptions.CurveEaseOut, animations: { () -> Void in
                self.view.layoutIfNeeded()
            }, completion: nil)
        }
    }
    
    func hide() {
        sideViewLeftConstraint.constant = -300
        
        UIView.animateWithDuration(0.2, delay: 0, options: UIViewAnimationOptions.CurveEaseOut, animations: { () -> Void in
            self.view.alpha = 0
            self.view.layoutIfNeeded()
            }, completion: { _ in
                self.overlayWindow?.hidden = true
        })
    }
    
    @IBAction func accountSettings(sender: UIButton) {
        AccountViewController.show()
        hide()
    }
    
    @IBAction func openProfile(sender: UIButton) {
        ProfileViewController.show(TwitterUser(account!))
        hide()
    }
    
    @IBAction func disableSleep(sender: UISwitch) {
        GenericSettings.update(sender.on)
        UIApplication.sharedApplication().idleTimerDisabled = sender.on
    }
    
    @IBAction func disableSleepButton(sender: UIButton) {
        disableSleepSwitch.on = disableSleepSwitch.on ? false : true
        GenericSettings.update(disableSleepSwitch.on)
        UIApplication.sharedApplication().idleTimerDisabled = disableSleepSwitch.on
    }
    
    @IBAction func streaming(sender: UIButton) {
        hide()
        StreamingAlert.show(sender)
    }
    
    @IBAction func displaySettings(sender: UIButton) {
        settingsViewController?.show()
        settingsViewController?.showThemeSettingsView(sender)
        hide()
    }
    
    @IBAction func licenses(sender: UIButton) {
        // FIXME
    }
    
    @IBAction func sendFeedback(sender: UIButton) {
        EditorViewController.show(" #justaway", range: NSMakeRange(0, 0), inReplyToStatus: nil)
        hide()
    }
}