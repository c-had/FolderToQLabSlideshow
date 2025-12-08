//
//  SourceMonitor.swift
//  FolderToQLabSlideshow
//
//  Created by Chad Sellers on 12/8/25.
//
import Foundation
import System
import CoreImage

class SourceMonitor
{
    let sourceFolder = "/Users/chad/Downloads/Running Today/"
    var client: OSCClient?
    var lastChange = Date(timeIntervalSince1970: 0)
    var lastFiles: Array<String> = []
    var updateQLabTimer: DispatchSourceTimer?
    var checkFilesTimer: DispatchSourceTimer?

    func monitorChanges()
    {
        checkFilesTimer?.cancel()
        checkFilesTimer = DispatchSource.makeTimerSource(queue: DispatchQueue.main)
        checkFilesTimer?.schedule(deadline: .now(), repeating: .seconds(10), leeway: .milliseconds(100))
        checkFilesTimer?.setEventHandler {
            self.checkFiles()
        }
        checkFilesTimer?.resume()

    }

    func stop()
    {
        checkFilesTimer?.cancel()
        checkFilesTimer = nil
        client?.disconnect()
        client = nil
    }

    func checkFiles()
    {
        var changesPresent = false
        if let theClient = client
        {
            if theClient.errorState
            {
                // Something went wrong before, so we should update
                changesPresent = true
                theClient.errorState = false
            }
        }
        let fm = FileManager.default
        if let files = try? fm.contentsOfDirectory(atPath: sourceFolder)
        {
            if files != lastFiles
            {
                changesPresent = true
                lastFiles = files
            }
            for file in files
            {
                var path: FilePath = FilePath(sourceFolder)
                path.append(file)
                if let fileAttrs = try? fm.attributesOfItem(atPath: path.string)/* as NSDictionary*/
                {
                    if let thisDate = fileAttrs[.modificationDate] as? Date
                    {
                        if thisDate > lastChange
                        {
                            changesPresent = true
                            lastChange = thisDate
                        }
                    }
                    if let thisDate = fileAttrs[.creationDate] as? Date
                    {
                        if thisDate > lastChange
                        {
                            changesPresent = true
                            lastChange = thisDate
                        }
                    }
                }
            }
            if changesPresent
            {
                var currentFiles: Array<String> = []
                for file in files
                {
                    var path: FilePath = FilePath(sourceFolder)
                    path.append(file)
                    if (isImage(path))
                    {
                        currentFiles.append(path.string)
                    }
                }
                print("Found changes. Trying in 32")
                updateQLabTimer?.cancel()
                updateQLabTimer = DispatchSource.makeTimerSource(queue: DispatchQueue.main)
                updateQLabTimer?.schedule(deadline: .now().advanced(by: .seconds(32)), repeating: .never, leeway: .milliseconds(100))
                updateQLabTimer?.setEventHandler {
                    self.updateQLab(currentFiles)
                }
                updateQLabTimer?.resume()
            }
        }
    }

    func isImage(_ path: FilePath) -> Bool
    {
        if let fileURL = URL(filePath: path)
        {
            if let _ = CIImage(contentsOf: fileURL)
            {
                return true
            }
        }
        return false
    }

    func updateQLab(_ files: Array<String>)
    {
        if client == nil
        {
            client = OSCClient()
        }
        let theClient = client!
        if !theClient.setSlideshowFiles(files)
        {
            // client is busy, try again
            lastChange = Date(timeIntervalSince1970: 0)
        }
    }
}
