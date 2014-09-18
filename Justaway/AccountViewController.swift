import UIKit

class AccountViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    // MARK: Types
    
    struct TableViewConstants {
        static let tableViewCellIdentifier = "searchResultsCell"
    }
    
    // MARK: Properties
    
    @IBOutlet var tableView : UITableView?
    
    var items:Array<String> = ["one", "two", "three", "four"]
    
    override var nibName: String {
        return "AccountViewController"
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        tableView?.delegate = self
        tableView?.dataSource = self
    }
    
    // MARK: UITableViewDataSource
    
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
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        // 選択するとアラートを表示する
        let alert = UIAlertView(title: "alertTitle", message: "selected cell index is \(indexPath.row)", delegate: nil, cancelButtonTitle: "OK")
        alert.show()
        
    }
    
    func numberOfSectionsInTableView(tableView: UITableView!) -> Int {
        return 1
    }
//
//    func tableView(tableView: UITableView!, numberOfRowsInSection section: Int) -> Int {
//        return 1
//    }
//
//    // セクション高さ
//    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
//        
//    }
    
//    func tableView(tableView: UITableView!, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
//        let cell = tableView.dequeueReusableCellWithIdentifier(TableViewConstants.tableViewCellIdentifier, forIndexPath: indexPath) as UITableViewCell
////
////        cell.textLabel!.text = visibleResults[indexPath.row]
//        
//        return cell
//    }
    @IBAction func edit() {
        tableView?.setEditing(true, animated: true)
    }
}
