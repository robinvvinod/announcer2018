//
//  ViewController.swift
//  recently
//
//  Created by Orbit on 31/10/17.
//  Copyright © 2017 Orbit. All rights reserved.
//

import UIKit
import SystemConfiguration

import FeedKit

//RSS or Atom Feed URL: Change this link to change RSS feed location
let feedURL = URL(string: "http://studentsblog.sst.edu.sg/feeds/posts/default")!


class ViewController: UIViewController, UISearchControllerDelegate, UISearchResultsUpdating, UISearchBarDelegate, UITableViewDelegate, UITableViewDataSource {
	
	/*
	
	WORKFLOW EXPLANATION
	0. On first initialization, set key "posts" to an array of Post
	1. View is set up
	2. Internet connection is checked
	3. If internet connection is off, use offline stored posts by directly loading the "posts" data
	4. If internet connection is online, check online posts and update "posts" data
	5. Wait for user to tap on a post
	6. Loads post by transferring title and content data and toggles read notification
	7. Wait for user to finish reading and tap back
	8. Reloads TableView with the new read notification

	*/
	
	//Variables
	var feed: AtomFeed?
	let parser = FeedParser(URL: feedURL)
	
	var filtered = [Post]() //For searchbar
	var posts = [Post]() //Load into this when fetching posts or retrieving offline data
	var selectedArray: [Post]?
	
	var searchText = ""
	
	var titleData = String()
	var contentData = String()
	
	let ud = UserDefaults.standard
	
	//Objects
	@IBOutlet weak var FeedTableView: UITableView!
	var searchController : UISearchController!
	var refreshController : UIRefreshControl!

	override func viewDidLoad() {
		super.viewDidLoad()
		// Do any additional setup after loading the view, typically from a nib.
		
		//TableViewController init
		FeedTableView.delegate = self
		FeedTableView.dataSource = self
		
		//RefreshController init
		refreshController = UIRefreshControl()
		refreshController.attributedTitle = NSAttributedString(string: "Pull to refresh")
		refreshController.addTarget(self, action: #selector(refresh), for: UIControlEvents.valueChanged)
		FeedTableView.addSubview(refreshController)
		
		//Search Bar init
		self.searchController = UISearchController(searchResultsController:  nil)
		self.searchController.searchResultsUpdater = self
		self.searchController.delegate = self
		self.searchController.searchBar.delegate = self
		self.searchController.hidesNavigationBarDuringPresentation = false
		self.searchController.dimsBackgroundDuringPresentation = true
		self.navigationItem.titleView = searchController.searchBar
		self.definesPresentationContext = true
		
		//Fetch feed on startup (if possible)
		fetchFromFeed()
	
	}
	
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
	
	//Fetch Handler
	func fetchFromFeed() {
		if connectedToNetwork() {
			//Is connected - fetch Atom Feed
			parser?.parseAsync { [weak self] (result) in
				self?.feed = result.atomFeed
				
				//TBD: Check for new posts and edit notifications
				self?.checkFeed(from: (self?.feed?.entries)!)
				
				// Then back to the Main thread to update the UI.
				DispatchQueue.main.async {
					self?.FeedTableView.reloadData()
				}
				
			}
		} else {
			//Notify the user - No connection!
			let alert = UIAlertController.init(title: "Error", message: "No connection!", preferredStyle: UIAlertControllerStyle.alert)
			alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.cancel, handler: nil))
			self.present(alert, animated: true, completion: nil)
			
			//Load saved offline posts (If possible)
			let data = ud.object(forKey: "posts") as! Data
			let decodedPosts = NSKeyedUnarchiver.unarchiveObject(with: data) as! [Post]
			posts = decodedPosts
		}
	}
	
	//New Posts Handler
	func checkFeed(from: [AtomFeedEntry]) {
		//Get current Posts
		let decoded = ud.object(forKey: "posts") as! Data
		let decodedPosts = NSKeyedUnarchiver.unarchiveObject(with: decoded) as! [Post]
		
		//Get new Posts
		let newPosts = convertFromEntries(feed: (feed?.entries)!)
		
		//Find number of new posts
		var changed = 0
		for entry in newPosts {
			if !decodedPosts.contains(entry) {
				changed += 1
			}
		}
		
		//Carry over read indicators
		for entry in newPosts {
			if (decodedPosts.first {$0.title == entry.title} != nil) {
				newPosts[newPosts.index(of: entry)!].read = (decodedPosts.first {$0.title == entry.title}?.read)!
			}
		}
		
		//Write to User Defaults to store posts [25 post limit bc of Blogger]
		let encodedData: Data = NSKeyedArchiver.archivedData(withRootObject: newPosts)
		ud.set(encodedData, forKey: "posts")

		//Push to posts array
		self.posts = newPosts
	}
	
	//Conversion from AtomFeedEntry -> Post
	func convertFromEntries(feed: [AtomFeedEntry]) -> [Post] {
		var posts = [Post]()
		for entry in feed {
			posts.append(Post.init(title: entry.title!, content: (entry.content?.value)!, published: entry.published!, read: false))
		}
		return posts
	}
	
	//Pull from Feed
	@objc func refresh(sender: AnyObject) {
		fetchFromFeed()
		let when = DispatchTime.now() + 3
		DispatchQueue.main.asyncAfter(deadline: when) {
			self.refreshController.endRefreshing()
		}
	}
	
	//Search Bar Handlers
	func updateSearchResults(for searchController: UISearchController) {
		//Filter Results
		filter(forSearchText: searchController.searchBar.text!)
	}
	
	func filter(forSearchText searchText: String) {
		filtered = posts.filter {$0.title.contains(searchText)}
		FeedTableView.reloadData()
	}
	
	func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
		searchController.searchBar.text = searchText
	}
	
	func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
		self.searchText = searchText
	}
	
	//Memory Warning
	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
		// Dispose of any resources that can be recreated.
	}
	
	//Table View Handlers
	func numberOfSections(in tableView: UITableView) -> Int {
		return 1
	}
	
	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		//Switch between arrays
		if searchController.isActive || searchController.searchBar.text != "" {
			selectedArray = filtered
		} else {
			selectedArray = posts
		}
		return selectedArray?.count ?? 0
	}
	
	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		//Get cell
		let cell = tableView.dequeueReusableCell(withIdentifier: "postcell", for: indexPath) as! FeedTableViewCell
		
		//Switch between arrays
		if searchController.isActive || searchController.searchBar.text != "" {
			selectedArray = filtered
		} else {
			selectedArray = posts
		}
		
		//Configure the cell...
		//Remove HTML tags while in main vc for the sake of cleanliness
		let data = selectedArray?[indexPath.row].content
		let str = data?.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression, range: nil).replacingOccurrences(of: "&nbsp;", with: " ")
		
		//Set labels
		cell.titleLabel.text = selectedArray?[indexPath.row].title
		cell.descriptionLabel.text = str
		cell.dateLabel.text = dateAgo(date: (selectedArray?[indexPath.row].published)!)
		
		//Check if read
		if selectedArray?[indexPath.row].read == true {
			cell.readIndicator.alpha = 0
		} else {
			cell.readIndicator.alpha = 1
		}
		
		return cell
	}
	
	func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		if searchController.isActive || searchController.searchBar.text != "" {
			selectedArray = filtered
		} else {
			selectedArray = posts
		}
		titleData = (selectedArray?[indexPath.row].title)!
		contentData = (selectedArray?[indexPath.row].content)!
		
		//Record as read
		//Get current Posts
		let data = ud.object(forKey: "posts") as! Data
		var decodedData = NSKeyedUnarchiver.unarchiveObject(with: data) as! [Post]
		
		//Record as read
		let match = decodedData.first{$0.title == titleData}
		decodedData[decodedData.index(of: match!)!].read = true
		
		//Push back to User Defaults
		let encodedData: Data = NSKeyedArchiver.archivedData(withRootObject: decodedData)
		ud.set(encodedData, forKey: "posts")
		
		//refresh table view
		posts = decodedData
		FeedTableView.reloadData()
		
		performSegue(withIdentifier: "viewPost", sender: nil)
	}
	
	//Date Handler
	func dateAgo(date: Date) -> String{
		let now = Date()
		let timeInterval = Int(DateInterval(start: date, end: now).duration)
		if timeInterval <= 86400 {
			return "Today"
		} else if timeInterval < 2678400 {
			return "\(timeInterval/86400) d"
		} else if timeInterval >= 2678400 {
			return "\(timeInterval/2678400) mo"
		} else if timeInterval >= 31536000 {
			return "\(timeInterval/31536000) y"
		}
		return ""
	}
	
	//Prepare for segue
	override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
		if segue.identifier == "viewPost" {
			let vc = segue.destination as! PostViewController
			vc.titleText = titleData
			vc.contentText = contentData
		}
	}

}
