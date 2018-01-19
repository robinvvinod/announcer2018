//
//  AppDelegate.swift
//  recently
//
//  Created by Orbit on 31/10/17.
//  Copyright © 2017 Orbit. All rights reserved.
//

import UIKit
import FeedKit
import UserNotifications

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

	var window: UIWindow?


	func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
		// Override point for customization after application launch.
		
		// UserDefaults registration for key "posts"
		// Array of Posts for offline use as well as checks
		let ud = UserDefaults.standard
		ud.register(defaults: ["posts" : NSKeyedArchiver.archivedData(withRootObject: [Post]())])
		ud.register(defaults: ["accurateNotifs": false])
		
		// Fetch data once an hour.
		UIApplication.shared.setMinimumBackgroundFetchInterval(300)
		
		//Ask for notification authorization
		let center = UNUserNotificationCenter.current()
		let options: UNAuthorizationOptions = [.alert, .sound]
		center.requestAuthorization(options: options) {
			(granted, error) in
			if !granted {
				print("Something went wrong")
			}
		}
		
		return true
	}
	
	func application(_ application: UIApplication, performFetchWithCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
		
	}

	func applicationWillResignActive(_ application: UIApplication) {
		// Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
		// Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
	}

	func applicationDidEnterBackground(_ application: UIApplication) {
		// Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
		// If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
	}

	func applicationWillEnterForeground(_ application: UIApplication) {
		// Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
	}

	func applicationDidBecomeActive(_ application: UIApplication) {
		// Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
	}

	func applicationWillTerminate(_ application: UIApplication) {
		// Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
	}


}

