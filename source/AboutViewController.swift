
//
//  AboutViewController.swift
//  source
//
//  Created by Orbit on 22/2/18.
//  Copyright © 2018 OrbitIndustries. All rights reserved.
//

import UIKit
import MessageUI

class AboutViewController: UIViewController, MFMailComposeViewControllerDelegate {

	// Variables
	
	
	// Objects
	@IBOutlet weak var feedbackButton: UIButton!
	@IBOutlet weak var aboutContainerView: UIView!
	var mailComposeVC: MFMailComposeViewController!
	
	@IBAction func giveFeedback(_ sender: Any) {
		
		//Init MailComposeViewController
		self.mailComposeVC = MFMailComposeViewController()
		mailComposeVC.mailComposeDelegate = self
		
		//Configure fields
		mailComposeVC.setToRecipients(["imsstinc@gmail.com"])
		mailComposeVC.setSubject("SST Announcer Feedback")
		
		//Present view
		self.present(mailComposeVC, animated: true, completion: nil)
		
	}
	
	// Mail Completion Handler
	func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
		
		//Dismiss view
		controller.dismiss(animated: true, completion: nil)
		
	}
	
	override func viewWillLayoutSubviews() {
		// Add shadow to view
		aboutContainerView.layer.masksToBounds = false
		aboutContainerView.layer.shadowColor = UIColor.black.cgColor
		aboutContainerView.layer.shadowOpacity = 0.5
		aboutContainerView.layer.shadowOffset = CGSize.zero
		aboutContainerView.layer.shadowRadius = 5
		aboutContainerView.layer.shadowPath = UIBezierPath(rect: aboutContainerView.bounds).cgPath
	}
	
	override func viewDidLoad() {
        super.viewDidLoad()
		
		// Check if mail is available
		if !MFMailComposeViewController.canSendMail() {
			
			// If not available, disable feedback
			feedbackButton.isEnabled = false
			feedbackButton.alpha = 0.5
			
		}
		
        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
