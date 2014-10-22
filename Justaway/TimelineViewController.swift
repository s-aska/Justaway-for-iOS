import UIKit

class TimelineViewController: UIViewController {
    
    // MARK: Properties
    @IBOutlet weak var scrollWrapperView: UIView!
    @IBOutlet weak var scrollView: UIScrollView!
    
    var editorViewController: EditorViewController!
    var settingsViewController: SettingsViewController!
    var tableViewController: TimelineTableViewController!
    var tableViewControllers = [TimelineTableViewController]()
    
    override var nibName: String {
        return "TimelineViewController"
    }
    
    // MARK: - View Life Cycle
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        editorViewController = EditorViewController()
        editorViewController.view.hidden = true
        ViewTools.addSubviewWithEqual(self.view, view: editorViewController.view)
        
        settingsViewController = SettingsViewController()
        ViewTools.addSubviewWithEqual(self.view, view: settingsViewController.view)
        
        var size = scrollWrapperView.frame.size
        println(size.width)
        let contentView = UIView(frame: CGRectMake(0, 0, size.width * 3, size.height))
        
        tableViewController = TimelineTableViewController()
        tableViewController.view.frame = CGRectMake(0, 0, size.width, size.height)
        let view = UIView(frame: CGRectMake(0, 0, size.width, size.height))
        view.addSubview(tableViewController.view)
        contentView.addSubview(view)
        
        for i in 1 ... 3 {
            let vc = TimelineTableViewController()
            vc.view.frame = CGRectMake(0, 0, size.width, size.height)
            let view = UIView(frame: CGRectMake(size.width * CGFloat(i), 0, size.width, size.height))
            view.addSubview(vc.view)
            contentView.addSubview(view)
            tableViewControllers.append(vc)
        }
        
        scrollView.addSubview(contentView)
        scrollView.contentSize = contentView.frame.size
        scrollView.pagingEnabled = true
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
    
    // MARK: - Actions
    
    @IBAction func signInButtonClick(sender: UIButton) {
        
    }
    
    @IBAction func homeButton(sender: UIButton) {
        tableViewController.loadData(nil)
        
        
    }
    
    @IBAction func showEditor(sender: UIButton) {
        editorViewController.show()
    }
    
    @IBAction func showSettings(sender: UIButton) {
        settingsViewController.show()
    }
    
}
