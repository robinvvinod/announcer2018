//
//  Network Fetch.swift
//  source
//
//  Created by Orbit on 28/1/18.
//  Copyright © 2018 Orbit. All rights reserved.
//

import Foundation
import SystemConfiguration
import UserNotifications

import FeedKit

//RSS or Atom Feed URL: Change this link to change RSS feed location
let feedURL = URL(string: "http://studentsblog.sst.edu.sg/feeds/posts/default")!

func fetchFromBlog() -> [UNMutableNotificationContent] {
	var feed: AtomFeed?
	let parser = FeedParser(URL: feedURL)
	if !connectedToNetwork() {
		
		//Return no new notifications
		return []
		
	}
	
	//Is connected - fetch Atom Feed
	let result = parser?.parse()
	feed = result?.atomFeed
	
	//Get current Posts
	let decoded = UserDefaults.standard.object(forKey: "posts") as! Data
	let decodedPosts = NSKeyedUnarchiver.unarchiveObject(with: decoded) as! [Post]
	
	//Get new Posts
	let newPosts = convertFromEntries(feed: (feed?.entries)!)
	
	//Get updated posts
	var changedPosts = [Post]()
	for entry in newPosts {
		if !decodedPosts.contains(entry) {
			changedPosts.append(entry)
		}
	}
	
	//if no updated posts, return no new notifications
	if changedPosts.count == 0 {
		
		//Carry over read indicators
		for newEntry in newPosts {
			for oldEntry in decodedPosts {
				if newEntry == oldEntry {
					newPosts[newPosts.index(of: newEntry)!].read = true
				}
			}
		}
		
		//Write to User Defaults to store posts [25 post limit bc of Blogger]
		let encodedData: Data = NSKeyedArchiver.archivedData(withRootObject: newPosts)
		UserDefaults.standard.set(encodedData, forKey: "posts")
		
		//Process new Posts into UNNotifications
		var notifications = [UNMutableNotificationContent]()
		
		for post in changedPosts {
			let content = UNMutableNotificationContent()
			
			content.title = NSString.localizedUserNotificationString(forKey:
				post.title, arguments: nil)
			content.body = NSString.localizedUserNotificationString(forKey:
				post.content, arguments: nil)
			content.sound = UNNotificationSound.default()
			
			notifications.append(content)
		}
		//return list of notifications
		return notifications
	}
	return []
}

//MARK: - Helpers

//Check for connection
func connectedToNetwork() -> Bool {
	
	var zeroAddress = sockaddr_in()
	zeroAddress.sin_len = UInt8(MemoryLayout<sockaddr_in>.size)
	zeroAddress.sin_family = sa_family_t(AF_INET)
	
	guard let defaultRouteReachability = withUnsafePointer(to: &zeroAddress, {
		$0.withMemoryRebound(to: sockaddr.self, capacity: 1) {
			SCNetworkReachabilityCreateWithAddress(nil, $0)
		}
	}) else {
		return false
	}
	
	var flags: SCNetworkReachabilityFlags = []
	if !SCNetworkReachabilityGetFlags(defaultRouteReachability, &flags) {
		return false
	}
	
	let isReachable = flags.contains(.reachable)
	let needsConnection = flags.contains(.connectionRequired)
	
	return (isReachable && !needsConnection)
}

//Conversion from AtomFeedEntry -> Post
func convertFromEntries(feed: [AtomFeedEntry]) -> [Post] {
	var posts = [Post]()
	for entry in feed {
		posts.append(Post.init(title: entry.title!, content: (entry.content?.value)!, published: entry.published!, read: false))
	}
	return posts
}

