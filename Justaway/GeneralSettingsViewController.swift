//
//  GeneralSettingsViewController.swift
//  Justaway
//
//  Created by Shinichiro Aska on 8/10/15.
//  Copyright © 2015 Shinichiro Aska. All rights reserved.
//

import UIKit

class GeneralSettingsViewController: UIViewController {

    // MARK: Properties

    @IBOutlet weak var disableSleepSwitch: UISwitch!

    override var nibName: String {
        return "GeneralSettingsViewController"
    }

    // MARK: - View Life Cycle

    override func viewDidLoad() {
        super.viewDidLoad()
        configureView()
    }

    func configureView() {
        disableSleepSwitch.isOn = GenericSettings.get().disableSleep
    }

    @IBAction func disableSleepSwitchChange(_ sender: UISwitch) {
        GenericSettings.update(sender.isOn)
        UIApplication.shared.isIdleTimerDisabled = sender.isOn
    }
}
