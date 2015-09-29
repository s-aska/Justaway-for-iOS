//
//  TalkViewController.swift
//  Justaway
//
//  Created by Shinichiro Aska on 7/28/15.
//  Copyright © 2015 Shinichiro Aska. All rights reserved.
//

import UIKit
import Pinwheel

class TalkViewController: UIViewController {
    
    // MARK: Types
    
    struct Static {
        static var instances = [TalkViewController]()
    }
    
    struct Constants {
        static let duration: Double = 0.2
        static let delay: NSTimeInterval = 0
    }
    
    // MARK: Properties

    let adapter = TwitterStatusAdapter()
    var lastID: Int64?
    var rootStatus: TwitterStatus?
    
    @IBOutlet weak var tableView: UITableView!
    
    override var nibName: String {
        return "TalkViewController"
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
        if let status = rootStatus {
            adapter.renderData(tableView, statuses: [status], mode: .BOTTOM, handler: nil)
            if let inReplyToStatusID = status.inReplyToStatusID {
                loadStatus(inReplyToStatusID)
            }
        }
    }
    
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        // EventBox.off(self)
    }
    
    // MARK: - Configuration
    
    func configureView() {
        adapter.configureView(tableView)
    }
    
    func configureEvent() {
        
    }
    
    // MARK: - 
    
    func loadStatus(statusID: String) {
        let success = { (statuses: [TwitterStatus]) -> Void in
            self.adapter.renderData(self.tableView, statuses: statuses, mode: .BOTTOM, handler: nil)
            for status in statuses {
                if let inReplyToStatusID = status.inReplyToStatusID {
                    self.loadStatus(inReplyToStatusID)
                }
            }
        }
        let failure = { (error: NSError) -> Void in
            ErrorAlert.show("Error", message: error.localizedDescription)
        }
        Twitter.getStatuses([statusID], success: success, failure: failure)
    }
    
    // MARK: - Actions
    
    @IBAction func left(sender: UIButton) {
        hide()
    }
    
    func hide() {
        UIView.animateWithDuration(Constants.duration, delay: Constants.delay, options: .CurveEaseOut, animations: {
            self.view.frame = CGRectMake(
                self.view.frame.size.width,
                self.view.frame.origin.y,
                self.view.frame.size.width,
                self.view.frame.size.height)
            }, completion: { finished in
                self.view.hidden = true
                self.view.removeFromSuperview()
                Static.instances.removeAtIndex(Static.instances.endIndex.predecessor()) // purge instance
        })
    }
    
    // MARK: - Class Methods
    
    class func show(status: TwitterStatus) {
        
        EditorViewController.hide() // TODO: think seriously about
        
        if let vc = UIApplication.sharedApplication().keyWindow?.rootViewController {
            let instance = TalkViewController()
            instance.rootStatus = status
            instance.view.hidden = true
            vc.view.addSubview(instance.view)
            instance.view.frame = CGRectMake(vc.view.frame.width, 0, vc.view.frame.width, vc.view.frame.height)
            instance.view.hidden = false
            
            UIView.animateWithDuration(Constants.duration, delay: Constants.delay, options: .CurveEaseOut, animations: { () -> Void in
                instance.view.frame = CGRectMake(0,
                    vc.view.frame.origin.y,
                    vc.view.frame.size.width,
                    vc.view.frame.size.height)
                }) { (finished) -> Void in
            }
            Static.instances.append(instance) // keep instance
        }
    }
}
