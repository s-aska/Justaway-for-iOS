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
    
    @IBOutlet weak var bannerImageView: UIImageView!
    @IBOutlet weak var iconImageView: UIImageView!
    @IBOutlet weak var displayNameLabel: UILabel!
    @IBOutlet weak var screenNameLabel: UILabel!
    @IBOutlet weak var sideViewLeftConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var disableSleepSwitch: UISwitch!
    @IBOutlet weak var streamingButton: MenuButton?
    
    var settingsViewController: SettingsViewController?
    
    var user: TwitterUser?
    
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
        guard let rootView = UIApplication.sharedApplication().keyWindow else {
            return
        }
        view.frame = CGRectMake(0, 0, rootView.frame.size.width, rootView.frame.size.height)
        view.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.5)
        view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: "hide"))
        
        let swipe = UISwipeGestureRecognizer(target: self, action: "hide")
        swipe.numberOfTouchesRequired = 1
        swipe.direction = .Left
        view.addGestureRecognizer(swipe)
        
        sideViewLeftConstraint.constant = -300
    }
    
    // MARK: -
    
    func show(user: TwitterUser) {
        self.user = user
        
        guard let rootView = UIApplication.sharedApplication().keyWindow else {
            return
        }
        view.hidden = true
        view.alpha = 1
        rootView.addSubview(view)
        
        displayNameLabel.text = user.name
        screenNameLabel.text = "@" + user.screenName
        ImageLoaderClient.displaySideMenuUserIcon(user.profileImageURL, imageView: iconImageView)
        disableSleepSwitch.on = GenericSettings.get().disableSleep
        
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
                self.view.removeFromSuperview()
        })
    }
    
    @IBAction func accountSettings(sender: UIButton) {
        AccountViewController.show()
        hide()
    }
    
    @IBAction func openProfile(sender: UIButton) {
        ProfileViewController.show(user!)
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
