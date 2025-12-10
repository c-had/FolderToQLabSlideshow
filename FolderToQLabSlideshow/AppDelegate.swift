//
//  AppDelegate.swift
//  FolderToQLabSlideshow
//
//  Created by Chad Sellers on 12/6/25.
//

import Cocoa
import System

@main
class AppDelegate: NSObject, NSApplicationDelegate {
    var monitor: SourceMonitor?

    @IBOutlet var window: NSWindow!
    @IBOutlet var prefsWindow: NSWindow!
    @IBOutlet var OSCPINLabel: NSTextField!
    @IBOutlet var watchPathLabel: NSTextField!


    func applicationDidFinishLaunching(_ aNotification: Notification)
    {
        start()
    }

    func applicationWillTerminate(_ aNotification: Notification)
    {
        stop()
    }

    func start()
    {
        monitor = SourceMonitor()
        monitor?.monitorChanges()
    }

    func stop()
    {
        monitor?.stop()
    }

    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool
    {
        return true
    }

    @IBAction func showPreferences(sender: AnyObject)
    {
        if let pin = UserDefaults.standard.string(forKey: "OSCPIN")
        {
            OSCPINLabel.stringValue = pin
        }
        else
        {
            OSCPINLabel.stringValue = ""
        }
        if let watchPath = UserDefaults.standard.url(forKey: "watchPath")
        {
            watchPathLabel.stringValue = FilePath(watchPath)!.description
        }
        else
        {
            watchPathLabel.stringValue = "Unset"
        }
        prefsWindow.makeKeyAndOrderFront(self)
    }

    @IBAction func PINChanged(sender: AnyObject)
    {
        let pin = OSCPINLabel.stringValue
        UserDefaults.standard.set(pin, forKey: "OSCPIN")
        stop()
        start()
    }

    @IBAction func watchPathChangeButtonPressed(sender: AnyObject)
    {
        let op = NSOpenPanel()
        op.canChooseFiles = false
        op.canChooseDirectories = true
        op.allowsMultipleSelection = false
        op.beginSheetModal(for: prefsWindow) { response in
            if response == .OK
            {
                DispatchQueue.main.async {
                    let url = op.url
                    UserDefaults.standard.set(url, forKey: "watchPath")
                    self.showPreferences(sender: self)
                    self.stop()
                    self.start()
                }
            }
        }
    }
}

