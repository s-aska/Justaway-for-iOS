//
//  TalkViewController.swift
//  Justaway
//
//  Created by Shinichiro Aska on 7/28/15.
//  Copyright © 2015 Shinichiro Aska. All rights reserved.
//

import UIKit
import Pinwheel

class TalkViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    // MARK: Types
    
    enum RenderMode {
        case TOP
        case BOTTOM
        case OVER
    }
    
    struct Row {
        let status: TwitterStatus
        let fontSize: CGFloat
        let height: CGFloat
        let textHeight: CGFloat
        let quotedTextHeight: CGFloat
        
        init(status: TwitterStatus, fontSize: CGFloat, height: CGFloat, textHeight: CGFloat, quotedTextHeight: CGFloat) {
            self.status = status
            self.fontSize = fontSize
            self.height = height
            self.textHeight = textHeight
            self.quotedTextHeight = quotedTextHeight
        }
    }
    
    struct Static {
        static var instances = [TalkViewController]()
    }
    
    struct TableViewConstants {
        static let tableViewCellIdentifier = "Cell"
    }
    
    struct Constants {
        static let duration: Double = 0.2
        static let delay: NSTimeInterval = 0
    }
    
    // MARK: Properties
    
    var rows = [Row]()
    var layoutHeight = [TwitterStatusCellLayout: CGFloat]()
    var layoutHeightCell = [TwitterStatusCellLayout: TwitterStatusCell]()
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
        var fontSize :CGFloat = 12.0
        if let delegate = UIApplication.sharedApplication().delegate as? AppDelegate {
            fontSize = CGFloat(delegate.fontSize)
        }
        if let status = rootStatus {
            rows.append(createRow(status, fontSize: fontSize))
            tableView.reloadData()
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
        tableView.separatorInset = UIEdgeInsetsZero
        tableView.separatorStyle = UITableViewCellSeparatorStyle.None
        tableView.delegate = self
        tableView.dataSource = self
        
        let nib = UINib(nibName: "TwitterStatusCell", bundle: nil)
        for layout in TwitterStatusCellLayout.allValues {
            tableView.registerNib(nib, forCellReuseIdentifier: layout.rawValue)
            self.layoutHeightCell[layout] = self.tableView.dequeueReusableCellWithIdentifier(layout.rawValue) as? TwitterStatusCell
        }
    }
    
    func configureEvent() {
        
    }
    
    // MARK: - 
    
    func loadStatus(statusID: String) {
        var fontSize :CGFloat = 12.0
        if let delegate = UIApplication.sharedApplication().delegate as? AppDelegate {
            fontSize = CGFloat(delegate.fontSize)
        }
        let success = { (statuses: [TwitterStatus]) -> Void in
            for status in statuses {
                self.rows.append(self.createRow(status, fontSize: fontSize))
                if let inReplyToStatusID = status.inReplyToStatusID {
                    self.loadStatus(inReplyToStatusID)
                }
            }
            self.tableView.reloadData()
        }
        let failure = { (error: NSError) -> Void in
            ErrorAlert.show("Error", message: error.localizedDescription)
        }
        Twitter.getStatuses([statusID], success: success, failure: failure)
    }
    
    // MARK: - UITableViewDataSource
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return rows.count ?? 0
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let row = rows[indexPath.row]
        let status = row.status
        let layout = TwitterStatusCellLayout.fromStatus(status)
        let cell = tableView.dequeueReusableCellWithIdentifier(layout.rawValue, forIndexPath: indexPath) as! TwitterStatusCell
        
        if cell.textHeightConstraint.constant != row.textHeight {
            cell.textHeightConstraint.constant = row.textHeight
        }
        
        if cell.quotedStatusLabelHeightConstraint.constant != row.quotedTextHeight {
            cell.quotedStatusLabelHeightConstraint.constant = row.quotedTextHeight
        }
        
        if row.fontSize != cell.statusLabel.font.pointSize {
            cell.statusLabel.font = UIFont.systemFontOfSize(row.fontSize)
        }
        
        if row.fontSize != cell.quotedStatusLabel.font.pointSize {
            cell.quotedStatusLabel.font = UIFont.systemFontOfSize(row.fontSize)
        }
        
        if let s = cell.status {
            if s.uniqueID == status.uniqueID {
                return cell
            }
        }
        
        cell.status = status
        cell.setLayout(layout)
        cell.setText(status)
        
        if !Pinwheel.suspend {
            cell.setImage(status)
        }
        
        return cell
    }
    
    // MARK: UITableViewDelegate
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        let row = rows[indexPath.row]
        return row.height
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let row = rows[indexPath.row]
        if let cell = tableView.cellForRowAtIndexPath(indexPath) {
            StatusAlert.show(cell, status: row.status)
        }
    }
    
    // MARK: Public Methods
    
    func createRow(status: TwitterStatus, fontSize: CGFloat) -> Row {
        let layout = TwitterStatusCellLayout.fromStatus(status)
        if let height = layoutHeight[layout] {
            let textHeight = measure(status.text, fontSize: fontSize)
            let quotedTextHeight = measureQuoted(status, fontSize: fontSize)
            let totalHeight = ceil(height + textHeight + quotedTextHeight)
            return Row(status: status, fontSize: fontSize, height: totalHeight, textHeight: textHeight, quotedTextHeight: quotedTextHeight)
        } else if let cell = self.layoutHeightCell[layout] {
            cell.frame = self.tableView.bounds
            cell.setLayout(layout)
            let textHeight = measure(status.text, fontSize: fontSize)
            let quotedTextHeight = measureQuoted(status, fontSize: fontSize)
            cell.textHeightConstraint.constant = 0
            cell.quotedStatusLabelHeightConstraint.constant = 0
            let height = cell.contentView.systemLayoutSizeFittingSize(UILayoutFittingCompressedSize).height
            layoutHeight[layout] = height
            let totalHeight = ceil(height + textHeight + quotedTextHeight)
            return Row(status: status, fontSize: fontSize, height: totalHeight, textHeight: textHeight, quotedTextHeight: quotedTextHeight)
        }
        fatalError("cellForHeight is missing.")
    }
    
    func measure(text: NSString, fontSize: CGFloat) -> CGFloat {
        return ceil(text.boundingRectWithSize(
            CGSizeMake((self.layoutHeightCell[.Normal]?.statusLabel.frame.size.width)!, 0),
            options: NSStringDrawingOptions.UsesLineFragmentOrigin,
            attributes: [NSFontAttributeName: UIFont.systemFontOfSize(fontSize)],
            context: nil).size.height)
    }
    
    func measureQuoted(status: TwitterStatus, fontSize: CGFloat) -> CGFloat {
        if let quotedStatus = status.quotedStatus {
            return ceil(quotedStatus.text.boundingRectWithSize(
                CGSizeMake((self.layoutHeightCell[.Normal]?.quotedStatusLabel.frame.size.width)!, 0),
                options: NSStringDrawingOptions.UsesLineFragmentOrigin,
                attributes: [NSFontAttributeName: UIFont.systemFontOfSize(fontSize)],
                context: nil).size.height)
        } else {
            return 0
        }
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
