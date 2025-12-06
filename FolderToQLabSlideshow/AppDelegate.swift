//
//  AppDelegate.swift
//  FolderToQLabSlideshow
//
//  Created by Chad Sellers on 12/6/25.
//

import Cocoa

@main
class AppDelegate: NSObject, NSApplicationDelegate {
    var client: OSCClient?

    @IBOutlet var window: NSWindow!


    func applicationDidFinishLaunching(_ aNotification: Notification) {
        client = OSCClient()
        client?.connect()
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        client?.disconnect()
    }

    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        return true
    }


}

