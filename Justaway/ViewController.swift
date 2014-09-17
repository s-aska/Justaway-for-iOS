import UIKit

class ViewController: UIViewController {
    
    @IBOutlet weak var signInButton: UIButton!
    
    var editorViewController: EditorViewController!
    var settingsViewController: SettingsViewController!
    
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
    
    @IBAction func signInButtonClick(sender: UIButton) {
        
    }
    
    @IBAction func showEditor(sender: UIButton) {
        editorViewController.show()
    }
    
    @IBAction func showSettings(sender: UIButton) {
        settingsViewController.show()
    }
}

