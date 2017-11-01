//
//  Post.swift
//  recently
//
//  Created by Orbit on 1/11/17.
//  Copyright © 2017 Orbit. All rights reserved.
//

import Foundation
import FeedKit

class Post: NSObject, NSCoding {
	
	//Variables
	var title: String
	var content: String
	var published: Date
	var read: Bool
	
	//Init
	init(title: String, content: String, published: Date, read: Bool) {
		self.title = title
		self.content = content
		self.published = published
		self.read = read
	}
	
	//Comparisons
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
		let read = aDecoder.decodeBool(forKey: "read")
		self.init(title: title, content: content, published: published, read: read)
	}
	
	func encode(with aCoder: NSCoder) {
		aCoder.encode(title, forKey: "title")
		aCoder.encode(content, forKey: "content")
		aCoder.encode(published, forKey: "published")
		aCoder.encode(read, forKey: "read")
	}
}
