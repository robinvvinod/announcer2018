//
//  Post.swift
//  recently
//
//  Created by Orbit on 1/11/17.
//  Copyright © 2017 Orbit. All rights reserved.
//

import Foundation

class Post: NSObject {
	
	//Variables
	var title: String
	var content: String
	var published: Date
	
	//Init
	init(title: String, content: String, published: Date) {
		self.title = title
		self.content = content
		self.published = published
	}
	
	//Comparison
	func isEquals(compareTo: Post) -> Bool {
		return
			self.title == compareTo.title &&
			self.content == compareTo.content &&
			self.published == self.published
	}
	
	//Encode and decode [For User Defaults Storage]
	required convenience init(coder aDecoder: NSCoder) {
		let title = aDecoder.decodeObject(forKey: "title") as! String
		let content = aDecoder.decodeObject(forKey: "content") as! String
		let published = aDecoder.decodeObject(forKey: "published") as! Date
		self.init(title: title, content: content, published: published)
	}
	
	func encode(with aCoder: NSCoder) {
		aCoder.encode(title, forKey: "title")
		aCoder.encode(content, forKey: "content")
		aCoder.encode(published, forKey: "published")
	}
}
