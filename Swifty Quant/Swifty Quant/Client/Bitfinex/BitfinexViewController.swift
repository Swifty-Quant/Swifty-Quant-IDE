//
//  BitfinexViewController.swift
//  Swifty Quant
//
//  Created by Cameron de Bruyn on 2020/07/29.
//  Copyright © 2020 HINTON AI (PTY) LTD. All rights reserved.
//

import AppKit
import SwiftUI
import Network

    
extension BitfinexViewController : BitfinexConnectionDelegate
{
    func connectionReady()
    {
        print("Connection Ready")
    }
    
    func connectionFailed()
    {
        print("Connection Failed")
    }
    
    func receivedMessage(content: Data?, message: NWProtocolFramer.Message)
    {
        print(message)
    }
    
    func displayAdvertiseError(_ error: NWError)
    {
        self.presentError(error)
    }
    
}

final class BitfinexViewController : NSViewController
{
    let session = URLSession(configuration: URLSessionConfiguration.default)
    
    override func viewDidLoad()
    {   
        BitfinexShared.connection = BitfinexConnection(delegate: self)
    }
    
    override func loadView()
    {
        var arrayWithObjects: NSArray?
        let nibIsLoaded = Bundle.main.loadNibNamed(NSNib.Name("BitfinexButtonView"),
                                                   owner: self,
                                                   topLevelObjects: &arrayWithObjects)

        if nibIsLoaded
        {
            view = arrayWithObjects?.first(where: { $0 is NSView }) as! NSView
        }
        return
    }
}

extension BitfinexViewController : NSViewControllerRepresentable
{
    func makeNSViewController(context: Context) -> NSViewController
    {
        return BitfinexViewController()
    }
    
    func updateNSViewController(_ nsViewController: NSViewController, context: Context)
    {
        
    }
}
