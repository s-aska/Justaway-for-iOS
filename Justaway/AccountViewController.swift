import UIKit

class AccountViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    // MARK: Types
    
    struct TableViewConstants {
        static let tableViewCellIdentifier = "Cell"
    }
    
    // MARK: Properties
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var leftButton: UIButton!
    @IBOutlet weak var rightButton: UIButton!
    
    var items:Array<String> = ["one", "two", "three", "four"]
    
    override var nibName: String {
        return "AccountViewController"
    }
    
    // MARK: - View Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.delegate = self
        tableView.dataSource = self
    }
    
    // MARK: - UITableViewDataSource
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell: UITableViewCell = UITableViewCell(style: UITableViewCellStyle.Subtitle, reuseIdentifier: "Cell")
        cell.accessoryType = UITableViewCellAccessoryType.Checkmark
        cell.textLabel?.text = "\(self.items[indexPath.row])"
        cell.detailTextLabel?.text = "Subtitle index : \(indexPath.row)"
        return cell
    }
    
    func tableView(tableView: UITableView, canMoveRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }
    
    func tableView(tableView: UITableView, moveRowAtIndexPath sourceIndexPath: NSIndexPath, toIndexPath destinationIndexPath: NSIndexPath) {
        
    }
    
    // MARK: UITableViewDelegate
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let alert = UIAlertView(title: "alertTitle", message: "selected cell index is \(indexPath.row)", delegate: nil, cancelButtonTitle: "OK")
        alert.show()
    }
    
    // MARK: - Actions
    
    @IBAction func left(sender: UIButton) {
        if (tableView.editing == true) {
            cancel()
        }
    }
    
    @IBAction func right(sender: UIButton) {
        if (tableView.editing == true) {
            done()
        } else {
            edit()
        }
    }
    
    func cancel() {
        tableView.setEditing(false, animated: true)
        leftButton.setTitle("Add", forState: UIControlState.Normal)
        rightButton.setTitle("Edit", forState: UIControlState.Normal)
    }
    
    func edit() {
        tableView.setEditing(true, animated: true)
        leftButton.setTitle("Cancel", forState: UIControlState.Normal)
        rightButton.setTitle("Done", forState: UIControlState.Normal)
    }
    
    func done() {
        cancel()
    }
}
