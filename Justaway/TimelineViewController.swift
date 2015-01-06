import UIKit
import SwifteriOS
import EventBox

class TimelineViewController: UIViewController {
    
    // MARK: Properties
    
    @IBOutlet weak var scrollWrapperView: UIView!
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var homeButton: UIButton!
    
    var editorViewController: EditorViewController!
    var settingsViewController: SettingsViewController!
    var tableViewControllers = [TimelineTableViewController]()
    
    struct Static {
        private static let connectionQueue = NSOperationQueue()
    }
    
    override var nibName: String {
        return "TimelineViewController"
    }
    
    // MARK: - View Life Cycle
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        Static.connectionQueue.maxConcurrentOperationCount = 1
        
        editorViewController = EditorViewController()
        editorViewController.view.hidden = true
        ViewTools.addSubviewWithEqual(self.view, view: editorViewController.view)
        
        settingsViewController = SettingsViewController()
        ViewTools.addSubviewWithEqual(self.view, view: settingsViewController.view)
        
        var size = scrollWrapperView.frame.size
        println(size.width)
        let contentView = UIView(frame: CGRectMake(0, 0, size.width * 3, size.height))
        
        for i in 0 ... 3 {
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
        
        var longPress = UILongPressGestureRecognizer(target: self, action: "refresh:")
        longPress.minimumPressDuration = 2.0;
        homeButton.addGestureRecognizer(longPress)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        EventBox.onBackgroundThread(self, name: Twitter.StreamingEvent.CreateStatus.rawValue, sender: nil) { n in
            let status = n.object as TwitterStatus
            self.tableViewControllers.first?.renderData([status], mode: .TOP, handler: {})
        }
    }
    
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        
        EventBox.off(self)
    }
    
    func toggleStreaming() {
        
    }
    
    // MARK: - Actions
    
    func refresh(sender: AnyObject) {
        tableViewControllers.first?.loadData(nil)
    }
    
    @IBAction func signInButtonClick(sender: UIButton) {
        
    }
    
    @IBAction func homeButton(sender: UIButton) {
        tableViewControllers.first?.scrollToTop()
    }
    
    @IBAction func showEditor(sender: UIButton) {
        editorViewController.show()
    }
    
    @IBAction func showSettings(sender: UIButton) {
        settingsViewController.show()
    }
    
}
