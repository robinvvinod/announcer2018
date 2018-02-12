//
//  HTML Converter.swift
//  source
//
//  Created by Orbit on 11/2/18.
//  Copyright © 2018 Orbit. All rights reserved.
//

import Foundation

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
