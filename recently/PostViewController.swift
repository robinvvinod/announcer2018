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
		
		titleLabel.title = titleText
		let attrText = contentText.html2AttributedString
		attrText?.addAttribute(.font, value: UIFont.init(name: "Avenir Next", size: 14.0), range: NSRange.init(location: 0, length: (attrText?.length)!))
		contentView.attributedText = attrText
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
	var html2AttributedString: NSMutableAttributedString? {
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
	var html2String: String {
		return html2AttributedString?.string ?? ""
	}
}
