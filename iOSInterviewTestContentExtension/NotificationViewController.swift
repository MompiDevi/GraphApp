//
//  NotificationViewController.swift
//  iOSInterviewTestContentExtension
//
//  Created by N. Mompi Devi on 27/02/19.
//  Copyright © 2019 momiv. All rights reserved.
//

import UIKit
import UserNotifications
import UserNotificationsUI

class NotificationViewController: UIViewController, UNNotificationContentExtension {

    @IBOutlet weak var background: UIImageView!
    @IBOutlet var label: UILabel?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any required interface initialization here.
    }
    
    func didReceive(_ notification: UNNotification) {
        self.label?.text = "not working"
        self.background.image = UIImage(named: "background.jpg")
    }

}
