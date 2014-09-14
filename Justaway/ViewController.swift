import UIKit

class ViewController: UIViewController {
    
    @IBOutlet weak var signInButton: UIButton!
    
    var editorViewController: EditorViewController!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        editorViewController = EditorViewController(nibName: "EditorViewController", bundle: nil)
        editorViewController.view.frame = self.view.frame
        editorViewController.view.hidden = true
        self.view.addSubview(editorViewController.view)
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
    
    @IBAction func writeButtonClick(sender: UIButton) {
        editorViewController.openEdiotr()
    }
}

