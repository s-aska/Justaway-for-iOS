import UIKit

class ViewController: UIViewController {
    
    @IBOutlet weak var signInButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    @IBAction func signInButtonClick(sender: UIButton) {
        NSLog("signInButtonClick")
    }
    
}

