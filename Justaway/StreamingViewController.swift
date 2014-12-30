import UIKit
import EventBox

class StreamingViewController: UIViewController {
    
    // MARK: Properties
    
    override var nibName: String {
        return "StreamingViewController"
    }
    
    @IBOutlet weak var streamingSwitch: UISwitch!
    
    @IBAction func streamingChanged(sender: UISwitch) {
        if sender.on {
            EventBox.post("streamingOn")
        } else {
            EventBox.post("streamingOff")
        }
    }
}

