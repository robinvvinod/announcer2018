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

//Edit the URL in Network Fetch to change RSS Feed location

class ViewController: UIViewController, UISearchControllerDelegate, UISearchResultsUpdating, UISearchBarDelegate, UITableViewDelegate, UITableViewDataSource {
	
	//MARK: - Variables
	
	// FeedKit initialisation
	var feed: AtomFeed?
	let parser = FeedParser(URL: feedURL)
	
	// Post arrays
	var pinned = [Post]() 		//For pinned posts
	var posts = [Post]() 		//Load into this when fetching posts or retrieving offline data
	var filtered = [[Post]]() 	//For searchbar
	var selectedArray: [Post]?	//Selected array for display in viewcontroller
	
	// Searchbar initialisation
	var searchText = ""
	
	// Information Passers
	var titleData = String()
	var contentData = String()
	
	//Checkers
	var allowsRefresh = Bool() //To prevent dismiss from failing
	
	//Objects
	@IBOutlet weak var FeedTableView: UITableView! // Main tableview
	var searchController : UISearchController! // Navigation embedded searchbar
	@IBAction func refreshButton(_ sender: Any) {
		refresh(sender: self)
	}
	
	override func viewWillAppear(_ animated: Bool) {
		//Allow refresh
		allowsRefresh = true
	}
	
	override func viewDidLoad() {
		super.viewDidLoad()
		// Do any additional setup after loading the view, typically from a nib.
		
		//TableViewController init
		FeedTableView.delegate = self
		FeedTableView.dataSource = self
		
		//Search Bar init
		self.searchController = UISearchController(searchResultsController:  nil)
		self.searchController.searchResultsUpdater = self
		self.searchController.delegate = self
		self.searchController.searchBar.delegate = self
		self.searchController.dimsBackgroundDuringPresentation = true
		
		//Allow searchbar to define presentation context (false by default)
		self.definesPresentationContext = true
		
		//Large Navigation Item init
		self.navigationController?.navigationBar.prefersLargeTitles = true
		self.navigationItem.searchController = searchController
		
		//Load pinned posts
		pinned = loadPinned()
		
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
				
				//Get new posts
				self?.posts = (self?.getPosts())!
				
				//Save to UserDefaults
				self?.savePosts()
				
				// Then back to the Main thread to update the UI.
				DispatchQueue.main.async {
					self?.FeedTableView.reloadData()
				}
				
			}
		} else {
			//Notify the user - No connection!
			let alert = UIAlertController.init(
				title: "Error",
				message: "No connection!",
				preferredStyle: UIAlertControllerStyle.alert)
			alert.addAction(UIAlertAction(
				title: "OK",
				style: UIAlertActionStyle.cancel,
				handler: nil))
			self.present(alert, animated: true, completion: nil)
			
			//Load saved offline posts (If possible)
			posts = loadPosts()
		}
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
	
	//Standard Post Fetch Handler
	func getPosts () -> [Post] {
		
		// Load posts from website
		let posts = feed?.entries
		var newData = [Post]()
		
		for entry in posts! {
			
			// initialise as unread
			newData.append(Post(
				title: entry.title!,
				content: (entry.content?.value)!,
				published: entry.published!,
				read: false))
		}
		
		// Get pinned posts
		let pinnedData = loadPinned()
		
		// Get old posts
		let oldData = loadPosts()
		
		//Check against pinned posts to avoid redundancy
		for newEntry in newData {
			for pinnedEntry in pinnedData {
				if newEntry.isEquals(compareTo: pinnedEntry) {
					newData.remove(at: newData.index(of: newEntry)!)
				}
			}
		}
		
		//Check against old posts to transfer read notifications
		for newEntry in newData {
			for oldEntry in oldData {
				if newEntry.isEquals(compareTo: oldEntry) {
					newData[newData.index(of: newEntry)!].read = oldData[oldData.index(of: oldEntry)!].read
				}
			}
		}
		
		//return posts
		return newData
	}
	
	//Archive Handler - Saves current volatile memory by useing NSKeyedArchiver
	func savePosts() {
		let encodedPinnedData: Data = NSKeyedArchiver.archivedData(withRootObject: pinned)
		UserDefaults.standard.set(encodedPinnedData, forKey: "pinnedposts")
		
		let encodedPostData: Data = NSKeyedArchiver.archivedData(withRootObject: posts)
		UserDefaults.standard.set(encodedPostData, forKey: "posts")
	}
	
	//Pull from Feed
	@objc func refresh(sender: AnyObject) {
		
		if allowsRefresh == true {
			
			//Init loading screens
			let loadAlert = UIAlertController.init(title: nil, message: "Refreshing...", preferredStyle: .alert)
			let loadIndicator = UIActivityIndicatorView.init(frame: CGRect.init(x: 10, y: 5, width: 50, height: 50))
			loadIndicator.hidesWhenStopped = true
			loadIndicator.activityIndicatorViewStyle = .gray
			loadIndicator.startAnimating()
			
			//Present loading screen
			loadAlert.view.addSubview(loadIndicator)
			present(loadAlert, animated: true, completion: nil)
			
			//Fetch from feed
			fetchFromFeed()
			
			//End loading
			dismiss(animated: true, completion: nil)
			
		}
		
	}
	
	//Search Bar Handlers
	func updateSearchResults(for searchController: UISearchController) {
		//Send searchbar text to Filter Handler
		filter(forSearchText: searchController.searchBar.text!)
	}
	
	//Filter Handler
	func filter(forSearchText searchText: String) {
		
		var filteredPosts = [[Post]]()
		if pinned.count != 0 {
			//Filter for pinned posts
			filteredPosts.append(pinned.filter {$0.title.contains(searchText)})
		}
		//Filter for standard posts
		filteredPosts.append(posts.filter {$0.title.contains(searchText)})
		
		//Push to filtered
		filtered = filteredPosts
		FeedTableView.reloadData()
	}
	
	//Prevent searchBar from clearing self
	func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
		searchController.searchBar.text = searchText
	}
	
	//Search Bar Text Handler
	func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
		self.searchText = searchText
	}
	
	//Memory Warning
	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
		// Dispose of any resources that can be recreated.
	}
	
	//Tableview Section Handler
	func numberOfSections(in tableView: UITableView) -> Int {
		if pinned.count == 0 {
			//No pins
			return 1
		} //else
		return 2
		
	}
	
	//Header Height Handler
	func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
		if section == 0 {
			//Make up for footer in first section
			return 33
			}
		return 25
	}
	
	//Footer Height Handler
	func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
		return 5
	}
	
	//Tableview Header Handler
	func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
		if section == 0 {
			if pinned.count == 0 {
				//No pinned posts
				return "Posts"
			}
			//Has pinned posts
			return "Pinned"
		}
		//Regular posts
		return "Posts"
	}
	
	//Tableview Row Handler
	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		
		//Create main array
		var allPosts: [[Post]]
		
		//Check for prescence of pins
		if pinned.count == 0 {
			allPosts = [posts]
		} else {
			allPosts = [pinned,posts]
		}
		
		//Switch between arrays
		if searchController.isActive || searchController.searchBar.text != "" {
			return filtered[section].count
		}
		return allPosts[section].count
	}
	
	//Tableview Cell Handler
	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		//Get cell
		let cell = tableView.dequeueReusableCell(withIdentifier: "postcell", for: indexPath) as! FeedTableViewCell
		
		//Create main array
		var allPosts: [[Post]]
		
		//Check for prescence of pins
		if pinned.count == 0 {
			allPosts = [posts]
		} else {
			allPosts = [pinned,posts]
		}
		
		//Data init
		var postData: Post
		
		//Switch between arrays
		if searchController.isActive || searchController.searchBar.text != "" {
			postData = filtered[indexPath.section][indexPath.row]
		} else {
			postData = allPosts[indexPath.section][indexPath.row]
		}
		
		//Configure the cell...
		//Remove HTML tags while in main vc for the sake of cleanliness
		let str = postData.content.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression, range: nil).replacingOccurrences(of: "&nbsp;", with: " ")
		
		//Set labels
		cell.titleLabel.text = postData.title
		cell.descriptionLabel.text = str
		cell.dateLabel.text = dateAgo(date: (postData.published))
		
		//Check if read
		if postData.read == true {
			cell.readIndicator.alpha = 0
		} else {
			cell.readIndicator.alpha = 1
		}
		
		return cell
	}
	
	//Tableview Selection Handler
	func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		
		//Prevent refresh from being triggered
		allowsRefresh = false
		
		//Create main array
		var allPosts: [[Post]]
		
		//Check for prescence of pins
		if pinned.count == 0 {
			allPosts = [posts]
		} else {
			allPosts = [pinned,posts]
		}
		
		if searchController.isActive || searchController.searchBar.text != "" {
			titleData = (filtered[indexPath.section][indexPath.row].title)
			contentData = (filtered[indexPath.section][indexPath.row].content)
		} else {
			titleData = (allPosts[indexPath.section][indexPath.row].title)
			contentData = (allPosts[indexPath.section][indexPath.row].content)
		}
		
		
		//Record as read
		allPosts[indexPath.section].filter {$0.title.contains(titleData)}.first?.read = true
		
		//Save to local volatile memory
		if pinned.count != 0 {
			pinned = allPosts.first!
		}
		posts = allPosts.last!
		
		//Push back to User Defaults
		savePosts()
		
		//Refresh tableview
		FeedTableView.reloadData()
		
		//Go to Post View
		performSegue(withIdentifier: "viewPost", sender: nil)
	}
	
	//Swipe Handlers for Tableview
	
	//Swipe <-
	func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
		
		let swipeConfig = UISwipeActionsConfiguration(actions: [pinPost(forRowAtIndexPath: indexPath)])
		return swipeConfig
	}
	
	//Swipe Function Handlers
	//Pin Handlers
	func pinPost(forRowAtIndexPath indexPath: IndexPath) -> UIContextualAction {
		//Initialisations
		
		//Create main array
		var allPosts: [[Post]]
		
		//Check for prescence of pins
		if pinned.count == 0 {
			allPosts = [posts]
		} else {
			allPosts = [pinned,posts]
		}
		
		//Get post object
		let post = allPosts[indexPath.section][indexPath.row]
		
		//Edit title according to context
		var title = String()
		
		//If is in pinnned
		if pinned.contains(post) {
			//Unpin post
			title = "Unpin"
		} else {
			//Pin post
			title = "Pin"
		}
		
		//Action Builder
		let action = UIContextualAction(style: .normal, title: title)
		{ (contextAction: UIContextualAction, sourceView: UIView, completionHandler: (Bool) -> Void) in
			
			//Toggle pin based on context
			if title == "Unpin" {
				self.posts = self.insertPost(withPost: post, inArray: self.posts)
				self.pinned.remove(at: self.pinned.index(of: post)!)
			} else {
				self.pinned = self.insertPost(withPost: post, inArray: self.pinned)
				self.posts.remove(at: self.posts.index(of: post)!)
			}
			
			//Push modifications to User Defaults
			self.savePosts()
			
			//reload Tableview
			self.FeedTableView.reloadData()
			
			//Complete
			completionHandler(true)
			
		}
		action.backgroundColor = UIColor.blue
		return action
	}
	
	//Post insert Handler
	func insertPost(withPost post: Post, inArray array: [Post]) -> [Post]{
		
		//Get array
		var returnableArray = array
		
		//Check if there are enough elements to arrange
		if returnableArray.count == 0 {
			
			//Not enough elements, just append
			returnableArray.append(post)
			return returnableArray
			
		}
			
		//Check if post is already the earliest in array.
		if (returnableArray.last?.published)! > post.published {
			
			//Earliest, just append
			returnableArray.append(post)
			return returnableArray
		}
		
		//Find first occurence where entry in array is earlier than post and insert
		for entry in array {
			if entry.published < post.published {
				returnableArray.insert(post, at: returnableArray.index(of: entry)!)
				//Exit at first occurence
				break
			}
		}
		
		//Return result
		return returnableArray
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
