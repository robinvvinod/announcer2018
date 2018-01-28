//
//  DetailViewController.swift
//  source
//
//  Created by Orbit on 28/1/18.
//  Copyright © 2018 Orbit. All rights reserved.
//

import UIKit

class PostViewController: UIViewController {
	
	//Variables
	var titleText = String()
	var contentText = String()
	
	//Objects
	@IBOutlet weak var titleLabel: UINavigationItem!
	@IBOutlet weak var contentView: UITextView!
	@IBAction func shareButton(_ sender: Any) {
		
		//Get text of post
		let shareText = contentText.htmlToString
		
		//Create Activity View Controller (Share screen)
		let shareViewController = UIActivityViewController.init(activityItems: [shareText], applicationActivities: nil)
		
		//Remove unneeded actions
		shareViewController.excludedActivityTypes = [.airDrop, .addToReadingList]
		
		//Present share controller
		shareViewController.popoverPresentationController?.sourceView = self.view
		self.present(shareViewController, animated: true, completion: nil)
	}
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		// Do any additional setup after loading the view.
		titleLabel.title = titleText
		let attrText = contentText.htmlToAttributedString
		
		
		//Check if some content was missed out
		if contentText.contains("<iframe") {
			//Format and remove all iframes while converting them into attachment links
			var entireText = contentText
			attrText?.append(NSAttributedString(string: "\n\n"))
			while entireText.contains("<iframe") {
				
				//Find source of embedded content
				let upperBound = contentText.range(of: "<iframe")
				let lowerBound = contentText.range(of: "></iframe>")?.lowerBound
				let nextBound = contentText.range(of: "src=")?.upperBound
				let iframeText = contentText[(upperBound?.upperBound)!..<lowerBound!]
				let sourceLink = iframeText[nextBound!...].replacingOccurrences(of: "\"", with: "")
				
				//Append embedded content link as attachment links
				attrText?.append(NSAttributedString(string: "[Attachment]: " + sourceLink))
				
				//Remove current iframe and move onto next if possible
				entireText.removeSubrange(upperBound!)
			}
		}
		
		//Format font to Avenir Next
		attrText?.addAttribute(.font, value: UIFont.init(name: "Avenir Next", size: 14.0)!, range: NSRange.init(location: 0, length: (attrText?.length)!))
		
		//Pass to UI
		contentView.attributedText = attrText
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

//Extension to read HTML text

extension String {
	var htmlToAttributedString: NSMutableAttributedString? {
		do {
			return try NSMutableAttributedString(data: Data(utf8),
												 options: [.documentType: NSAttributedString.DocumentType.html,
														   .characterEncoding: String.Encoding.utf8.rawValue],
												 documentAttributes: nil)
		} catch {
			print("error: ", error)
			return nil
		}
	}
	var htmlToString: String {
		return htmlToAttributedString?.string ?? ""
	}
}
