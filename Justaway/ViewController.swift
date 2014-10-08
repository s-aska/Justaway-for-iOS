import UIKit
import Accounts
import Social
import SwifteriOS

class ViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    // MARK: Properties
    
    @IBOutlet weak var signInButton: UIButton!
    @IBOutlet weak var testTableView: UITableView!
    
    var editorViewController: EditorViewController!
    var settingsViewController: SettingsViewController!
    var rows: [TwitterStatus] = []
    
    // MARK: - View Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        editorViewController = EditorViewController()
        editorViewController.view.frame = view.frame
        editorViewController.view.hidden = true
        self.view.addSubview(editorViewController.view)
        
        settingsViewController = SettingsViewController()
        settingsViewController.view.frame = view.frame
        settingsViewController.view.hidden = false
        self.view.addSubview(settingsViewController.view)
        
        let nib = UINib(nibName: "TwitterStatusCell", bundle: nil)
        self.testTableView.registerNib(nib, forCellReuseIdentifier: "Cell")
        self.testTableView.delegate = self
        self.testTableView.dataSource = self
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
    }
    
    // MARK: - UITableViewDataSource
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return rows.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("Cell", forIndexPath: indexPath) as TwitterStatusCell
        let status = rows[indexPath.row]
        let numberFormatter = NSNumberFormatter()
        numberFormatter.numberStyle = .DecimalStyle
        
        cell.nameLabel.text = status.user.name
        cell.screenNameLabel.text = "@" + status.user.screenName
        cell.protectedLabel.hidden = status.isProtected ? false : true
        cell.statusLabel.text = status.text
        cell.retweetCountLabel.text = status.retweetCount > 0 ? numberFormatter.stringFromNumber(status.retweetCount) : ""
        cell.favoriteCountLabel.text = status.favoriteCount > 0 ? numberFormatter.stringFromNumber(status.favoriteCount) : ""
        cell.relativeCreatedAtLabel.text = TwitterDate.relative(status.createdAt)
        cell.absoluteCreatedAtLabel.text = TwitterDate.absolute(status.createdAt)
        cell.viaLabel.text = status.clientName
        cell.imagesContainerView.hidden = true
        cell.actionedContainerView.hidden = true
        
        return cell
    }
    
    // MARK: - Actions
    
    @IBAction func signInButtonClick(sender: UIButton) {
        
    }
    
    @IBAction func homeButton(sender: UIButton) {
        
        Twitter.getHomeTimeline { (statuses: [TwitterStatus]) -> Void in
            for status in statuses {
                println(status.user.userID)
                println(status.user.screenName)
                println(status.user.profileImageURL)
                println(status.text)
                println(status.clientName)
                println(TwitterDate.relative(status.createdAt))
                println(TwitterDate.absolute(status.createdAt))
            }
            self.rows = statuses
            dispatch_async(dispatch_get_main_queue(), {
                self.testTableView.reloadData()
            })
        }
        
    }
    
    @IBAction func showEditor(sender: UIButton) {
        editorViewController.show()
    }
    
    @IBAction func showSettings(sender: UIButton) {
        settingsViewController.show()
    }
    
}

