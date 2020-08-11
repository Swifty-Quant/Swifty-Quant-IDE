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
import CryptoKit

    
final class BitfinexViewController : NSViewController
{
    var socketConnection: URLSessionWebSocketTask?
    
    override func viewDidLoad()
    {   
        let connection = BitfinexConnection(url: URL(string: "wss://api.bitfinex.com/ws/2/trades/tBTCUSD/hist/")!)
        connection.connect()
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
