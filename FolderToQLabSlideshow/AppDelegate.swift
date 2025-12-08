//
//  AppDelegate.swift
//  FolderToQLabSlideshow
//
//  Created by Chad Sellers on 12/6/25.
//

import Cocoa

@main
class AppDelegate: NSObject, NSApplicationDelegate {
    var monitor: SourceMonitor?

    @IBOutlet var window: NSWindow!


    func applicationDidFinishLaunching(_ aNotification: Notification) {
        monitor = SourceMonitor()
        monitor?.monitorChanges()
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        monitor?.stop()
    }

    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        return true
    }
}

