//
//  RedditFeedProvider-Extensions.swift
//  NetNewsWire
//
//  Created by Maurice Parker on 5/2/20.
//  Copyright © 2020 Ranchero Software. All rights reserved.
//

import Foundation
import Account

extension RedditFeedProvider: ExtensionPoint {
	
	static var isSinglton = false
	static var isDeveloperBuildRestricted = true
	static var title = "Reddit" // not localized - product name
	static var image = AppAssets.extensionPointReddit
	static var description: NSAttributedString = {
		return RedditFeedProvider.makeAttrString("This extension enables you to subscribe to Reddit URLs as if they were RSS feeds. It only works with \(Account.defaultLocalAccountName) or iCloud accounts.")
	}()

	var extensionPointID: ExtensionPointIdentifer {
		guard let username = username else {
			fatalError()
		}
		return ExtensionPointIdentifer.reddit(username)
	}

	var title: String {
		guard let username = username else {
			fatalError()
		}
		return "u/\(username)"
	}

}
