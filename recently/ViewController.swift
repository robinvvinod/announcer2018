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
	
	//Variables
	var feed: AtomFeed?
	let parser = FeedParser(URL: feedURL)!
	
	var filtered = [AtomFeedEntry]() //For searchbar
	var posts = [Post]() //Load into this when fetching posts or retrieving offline data
	var selectedArray: [AtomFeedEntry]?
	
	var searchText = ""
	
	var titleData = String()
	var contentData = String()
	
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
			parser.parseAsync { [weak self] (result) in
				self?.feed = result.atomFeed
				
				//TBD: Check for new posts and edit notifications
				
				//TBD: Write to User Defaults to store posts [25 post limit bc of Blogger]
				
				// Then back to the Main thread to update the UI.
				DispatchQueue.main.async {
					self?.FeedTableView.reloadData()
				}
				
			}
		} else {
			//Notify the user - No connection!
			//Load saved offline posts (If possible)
		}
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
		filtered = (feed?.entries?.filter {($0.title?.contains(searchText))!})!
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
			selectedArray = feed?.entries //Change to posts after implementing UserDefaults
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
			selectedArray = feed?.entries //Change to posts after implementing UserDefaults
		}
		
		//Configure the cell...
		//Remove HTML tags while in main vc for the sake of cleanliness
		let data = selectedArray?[indexPath.row].content?.value
		let str = data?.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression, range: nil).replacingOccurrences(of: "&nbsp;", with: " ")
		
		//Set labels
		cell.titleLabel.text = selectedArray?[indexPath.row].title
		cell.descriptionLabel.text = str
		cell.dateLabel.text = dateAgo(date: (selectedArray?[indexPath.row].published)!)
		
		return cell
	}
	
	func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		if searchController.isActive || searchController.searchBar.text != "" {
			selectedArray = filtered
		} else {
			selectedArray = feed?.entries //Change to posts after implementing UserDefaults
		}
		titleData = (selectedArray?[indexPath.row].title)!
		contentData = (selectedArray?[indexPath.row].content?.value)!
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
