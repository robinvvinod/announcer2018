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

// STUDENT BLOG ¬
let feedURL = URL(string: "http://studentsblog.sst.edu.sg/feeds/posts/default")!

// TEST BLOG ¬
//let feedURL = URL(string: "https://announcer-test-notif-source.blogspot.com/feeds/posts/default")!


// Background Fetch Handler
func fetchFromBlog() -> [UNMutableNotificationContent]? {
	
	//FeedKit parser init
	let parser = FeedParser(URL: feedURL)
	let data = parser?.parse()
	
	//Get old posts
	let pinnedPosts = loadPinned()
	let oldPosts = loadPosts()
	
	//Get new posts
	var newPosts = convertFromEntries(feed: (data?.atomFeed?.entries)!)
	var changedPosts = newPosts
	
	//Check for changes
	for newEntry in changedPosts {
		for oldEntry in oldPosts {
			if newEntry.isEquals(compareTo: oldEntry) {
				changedPosts.remove(at: changedPosts.index(of: newEntry)!)
			}
		}
	}
	
	//Check for redundant posts in pinned
	for changedEntry in changedPosts {
		for pinnedEntry in pinnedPosts {
			if changedEntry.isEquals(compareTo: pinnedEntry) {
				changedPosts.remove(at: changedPosts.index(of: changedEntry)!)
			}
		}
	}
	
	//If there's nothing, return immediately
	if changedPosts.count == 0 {
		return []
	}
	
	//Else: update posts and return notifications
	
	//Update posts ¬
	//Check against old posts to transfer read notifications
	for newEntry in newPosts {
		for oldEntry in oldPosts {
			if newEntry.isEquals(compareTo: oldEntry) {
				newPosts[newPosts.index(of: newEntry)!].read = oldPosts[oldPosts.index(of: oldEntry)!].read
			}
		}
	}
	
	//Update posts archive
	let encodedPostData: Data = NSKeyedArchiver.archivedData(withRootObject: newPosts)
	UserDefaults.standard.set(encodedPostData, forKey: "posts")
	
	//Return notifications ¬
	//Process new Posts into UNNotifications
	var notifications = [UNMutableNotificationContent]()
	
	for post in changedPosts {
		let content = UNMutableNotificationContent()
		
		content.title = NSString.localizedUserNotificationString(forKey:
			post.title, arguments: nil)
		content.body = NSString.localizedUserNotificationString(forKey:
			post.content.htmlToString, arguments: nil)
		content.sound = UNNotificationSound.default()
		
		notifications.append(content)
	}
	
	// Return list of notifications
	return notifications
	
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
		posts.append(Post.init(title: entry.title ?? "[No Title]",
							   content: (entry.content?.value)!,
							   published: entry.published!,
							   read: false)
		)
	}
	return posts
}

//Offline Data Handler
func loadPosts() -> [Post] {
	let data = UserDefaults.standard.object(forKey: "posts") as! Data
	let decodedPosts = NSKeyedUnarchiver.unarchiveObject(with: data) as! [Post]
	return decodedPosts
}

//Pin Data Handler
func loadPinned() -> [Post] {
	let data = UserDefaults.standard.object(forKey: "pinnedposts") as! Data
	let pinnedPosts = NSKeyedUnarchiver.unarchiveObject(with: data) as! [Post]
	return pinnedPosts
}
