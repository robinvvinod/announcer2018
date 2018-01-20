//
//  PostViewController.swift
//  recently
//
//  Created by Orbit on 1/11/17.
//  Copyright © 2017 Orbit. All rights reserved.
//

import UIKit

class PostViewController: UIViewController {

	//Variables
	var titleText = String()
	var contentText = String()
	
	//Objects
	@IBOutlet weak var titleLabel: UINavigationItem!
	@IBOutlet weak var contentView: UITextView!
	
    override func viewDidLoad() {
        super.viewDidLoad()
		
		//Edit content's images (if there's any)
		print(contentText)
		print("")
		
		titleLabel.title = titleText
		contentView.attributedText = contentText.html2AttributedString
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

//Extension to read HTML text

extension String {
	var html2AttributedString: NSAttributedString? {
		do {
			return try NSAttributedString(data: Data(utf8),
			                              options: [.documentType: NSAttributedString.DocumentType.html,
			                                        .characterEncoding: String.Encoding.utf8.rawValue],
			                              documentAttributes: nil)
		} catch {
			print("error: ", error)
			return nil
		}
	}
	var html2String: String {
		return html2AttributedString?.string ?? ""
	}
	
	mutating func imageCorrection() {
		while self.range(of: "(?<=width=\")[^\" height]+", options: .regularExpression) != nil {
			
		}
	}
}
