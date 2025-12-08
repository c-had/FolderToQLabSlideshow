//
//  OSCClient.swift
//  FolderToQLabSlideshow
//
//  Created by Chad Sellers on 12/6/25.
//

// Hardcode passcode
// Hardcode group cue names

import F53OSC

enum OSCState: Int
{
    case disconnected
    case connecting
    case connected
    case listingOldChildren
    case removingOldChildren
    case creating
    case moving
    case settingFileTarget
    case settingDuration
    case arming
    case disarming
    case starting
}

class OSCClient: NSObject, F53OSCClientDelegate
{
    var errorState = false
    var client: F53OSCClient?
    let passcode = "0031"
    let groupCue1 = "SS1"
    let groupCue2 = "SS2"
    var groupCue1ID: String?
    var groupCue2ID: String?
    var currentCueID: String?
    var modifyCue1 = true
    var workspaceID: String?
    var cueList: String?
    var state: OSCState = .disconnected
    var filesToProcess: Array<String> = []
    var oldCuesToDelete: Array<String> = []

    public func connect()
    {
        state = .connecting
        client = F53OSCClient()
        client?.isIPv6Enabled = false
        client?.delegate = self
        client?.useTcp = true
        client?.connect()
    }

    public func disconnect()
    {
        client?.disconnect()
        client = nil
        state = .disconnected
    }

    public func setSlideshowFiles(_ filenames: Array<String>) -> Bool
    {
        if !filesToProcess.isEmpty
        {
            return false
        }
        errorState = false
        filesToProcess = filenames
        connect()
        return true
    }

    func listOldChildren()
    {
        let message = F53OSCMessage(addressPattern: "/workspace/" + workspaceID! + "/cue_id/" + currentGroupCue() + "/children", arguments: [])
        state = .listingOldChildren
        client?.send(message)
    }

    func deleteOldChild()
    {
        if oldCuesToDelete.count > 0
        {
            let message = F53OSCMessage(addressPattern: "/workspace/" + workspaceID! + "/delete_id/" + oldCuesToDelete.last!, arguments: [])
            oldCuesToDelete.removeLast()
            state = .removingOldChildren
            client?.send(message)
        }
        else
        {
            createNextCue()
        }
    }

    func createNextCue()
    {
        if filesToProcess.count > 0
        {
            if let message = F53OSCMessage(string: "/workspace/" + workspaceID! + "/new video")
            {
                state = .creating
                client?.send(message)
            }
        }
        else
        {
            let message = F53OSCMessage(addressPattern: "/workspace/" + workspaceID! + "/cue_id/" + currentGroupCue() + "/armed", arguments: [true])
            state = .arming
            client?.send(message)
        }
    }

    func cueCreated(_ cueID: String)
    {
        currentCueID = cueID
        if let message = F53OSCMessage(string: "/workspace/" + workspaceID! + "/move/" + cueID + " 0 " + currentGroupCue())
        {
            state = .moving
            client?.send(message)
        }
    }

    func cueMoved()
    {
        let message = F53OSCMessage(addressPattern: "/cue_id/" + currentCueID! + "/fileTarget", arguments: [filesToProcess[0]])
        state = .settingFileTarget
        client?.send(message)
    }

    func cueTargeted()
    {
        filesToProcess.remove(at: 0)
        let message = F53OSCMessage(addressPattern: "/cue_id/" + currentCueID! + "/duration", arguments: [5])
        state = .settingDuration
        client?.send(message)
    }

    func cueArmed()
    {
        let message = F53OSCMessage(addressPattern: "/workspace/" + workspaceID! + "/cue_id/" + otherGroupCue() + "/armed", arguments: [false])
        state = .disarming
        client?.send(message)
    }

    func cueDisarmed()
    {
        let message = F53OSCMessage(addressPattern: "/workspace/" + workspaceID! + "/cue_id/" + currentGroupCue() + "/start", arguments: [])
        state = .starting
        client?.send(message)
    }

    func currentGroupCue() -> String
    {
        return modifyCue1 ? groupCue1ID! : groupCue2ID!
    }

    func otherGroupCue() -> String
    {
        return modifyCue1 ? groupCue2ID! : groupCue1ID!
    }

// MARK: F53OSCClientDelegate

    func take(_ message: F53OSCMessage?) {
        if let theMessage = message
        {
            if let argumentsString = theMessage.arguments[0] as? String
            {
                if let argumentsData = argumentsString.data(using: .utf8)
                {
                    if let arguments = try? JSONSerialization.jsonObject(with: argumentsData) as? [String: AnyObject]
                    {
                        let status = arguments["status"] as! String
                        if status != "ok"
                        {
                            errorState = true
                        }
                        print(arguments)
                        if let tempMessage = F53OSCMessage(string: arguments["address"] as! String)
                        {
                            let addressParts = tempMessage.addressParts()
                            switch self.state
                            {
                            case .connecting:
                                switch addressParts.last
                                {
                                case "connect":
                                    // Record our workspace ID
                                    if let workID = arguments["workspace_id"] as? String
                                    {
                                        workspaceID = workID
                                        let message = F53OSCMessage(addressPattern: "/alwaysReply", arguments: [1])
                                        client?.send(message)
                                    }
                                case "alwaysReply":
                                    if let message = F53OSCMessage(string: "/workspace/" + workspaceID! + "/cue/" + groupCue1 + "/uniqueID")
                                    {
                                        client?.send(message)
                                    }
                                case "uniqueID":
                                    // Record our workspace ID
                                    if let uniqueID = arguments["data"] as? String
                                    {
                                        let groupCueNumber = addressParts[addressParts.count-2]
                                        if groupCue1 == groupCueNumber
                                        {
                                            groupCue1ID = uniqueID
                                            if let message = F53OSCMessage(string: "/workspace/" + workspaceID! + "/cue/" + groupCue2 + "/uniqueID")
                                            {
                                                client?.send(message)
                                            }
                                        }
                                        else if groupCue2 == groupCueNumber
                                        {
                                            groupCue2ID = uniqueID
                                            if let message = F53OSCMessage(string: "/workspace/" + workspaceID! + "/cue/" + groupCue1 + "/armed")
                                            {
                                                client?.send(message)
                                            }
                                        }
                                    }
                                case "armed":
                                    state = .connected
                                    if let armed = arguments["data"] as? Bool
                                    {
                                        modifyCue1 = !armed
                                        print("modifyCue1 = " + String(modifyCue1))
                                        listOldChildren()
                                    }
                                default:
                                    break
                                }
                            case .listingOldChildren:
                                if let children = arguments["data"] as? [[String:AnyObject]]
                                {
                                    for child in children
                                    {
                                        let childID = child["uniqueID"] as? String
                                        oldCuesToDelete.append(childID!)
                                    }
                                }
                                deleteOldChild()
                            case .removingOldChildren:
                                deleteOldChild()
                            case .creating:
                                if let cueID = arguments["data"] as? String
                                {
                                    cueCreated(cueID)
                                }
                            case .moving:
                                cueMoved()
                            case .settingFileTarget:
                                cueTargeted()
                            case .settingDuration:
                                createNextCue()
                            case .arming:
                                cueArmed()
                            case .disarming:
                                cueDisarmed()
                            default:
                                break
                            }
                        }
                    }
                }
            }
        }
    }

    func clientDidConnect(_ client: F53OSCClient) {
        if let message = F53OSCMessage(string: "/connect " + passcode)
        {
            client.send(message)
        }
    }

    func clientDidDisconnect(_ client: F53OSCClient) {
        print(client.isConnected)
    }
}
