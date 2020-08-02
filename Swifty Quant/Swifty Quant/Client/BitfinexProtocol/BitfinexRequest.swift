//
//  BitfinexRequest.swift
//  Swifty Quant
//
//  Created by Cameron de Bruyn on 2020/08/02.
//  Copyright © 2020 HINTON AI (PTY) LTD. All rights reserved.
//

import Foundation
import CryptoKit


struct BitfinexRequest
{
    let url: URL

    init(url: URL) throws
    {
        guard url.absoluteString.utf8.count <= 1024 else { throw Error.urlTooLong }
        self.url = url
    }

    var data: Data
    {
        let dir = try? FileManager.default.url(for: .sharedPublicDirectory,
                                                   in: .userDomainMask,
                                                   appropriateFor: nil,
                                                   create: true
        )
        
        var apiKey    = ""
        var apiSecret = ""
        
        if let fileUrl = dir?.appendingPathComponent("").appendingPathExtension("bitfinex")
        {
            guard FileManager.default.fileExists(atPath: fileUrl.path)
                else
            {
                preconditionFailure("File expected at \(fileUrl.absoluteString) is missing")
            }

            guard let filePointer: UnsafeMutablePointer<FILE> = fopen(fileUrl.path, "r")
                else
            {
                preconditionFailure("Could not open file at \(fileUrl.absoluteString)")
            }

            var lineByteArrayPointer: UnsafeMutablePointer<CChar>? = nil
            var lineCap: Int = 0

            getline(&lineByteArrayPointer, &lineCap, filePointer)
            apiKey = String(String(cString:lineByteArrayPointer!).dropLast())
            
            getline(&lineByteArrayPointer, &lineCap, filePointer)
            apiSecret = String(String(cString:lineByteArrayPointer!).dropLast())
            
            fclose(filePointer)
        }
    
        let authNonce = NonceProvider.sharedInstanse.nonce
        let authPayload = "AUTH\(authNonce)"
        
        let authenticationKey  = SymmetricKey(data: apiSecret.data(using: .ascii)!)
        let authenticationCode = HMAC<SHA384>.authenticationCode(for: authPayload.data(using: .ascii)!,
                                                                 using: authenticationKey
        )
        
        let authSig = authenticationCode.compactMap { String(format: "%02h", $0) }.joined()
        
        let payload: [String : Any] =
        [
            "event":       "auth",
            "apiKey" :     apiKey,
            "authSig":     authSig,
            "authPayload": authPayload,
            "authNonce":   authNonce
        ]
        
        do
        {
            try JSONSerialization.data(withJSONObject: payload, options: .fragmentsAllowed)
        }
        catch(let error)
        {
            print("ERROR: \(error.localizedDescription)")
            return Data()
        }
    }

    enum Error: Swift.Error
    {
        case invalidURL
        case wrongProtocol
        case urlTooLong
    }
}
