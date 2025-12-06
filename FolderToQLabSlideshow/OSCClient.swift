//
//  OSCClient.swift
//  FolderToQLabSlideshow
//
//  Created by Chad Sellers on 12/6/25.
//

import F53OSC

class OSCClient: NSObject, F53OSCClientDelegate
{
    var client: F53OSCClient?

    public func connect()
    {
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
    }

// MARK: F53OSCClientDelegate

    func take(_ message: F53OSCMessage?) {
        if let description = message?.description
        {
            print("Message received" + description)
        }
    }

    func clientDidConnect(_ client: F53OSCClient) {
        if let message = F53OSCMessage(string: "/workspaces")
        {
            client.send(message)
        }
    }

    func clientDidDisconnect(_ client: F53OSCClient) {
        print(client.isConnected)
    }
}
