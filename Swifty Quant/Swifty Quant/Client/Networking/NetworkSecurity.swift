//
//  NetworkSecurity.swift
//  Swifty Quant
//
//  Created by Cameron de Bruyn on 2020/07/30.
//  Copyright © 2020 HINTON AI (PTY) LTD. All rights reserved.
//

import Foundation

public enum SecurityErrorCode: UInt16
{
    case acceptFailed  = 1
    case pinningFailed = 2
}

public enum PinningState
{
    case success
    case failed(CFError?)
}

// CertificatePinning protocol provides an interface for Transports to handle Certificate
// or Public Key Pinning.
public protocol CertificatePinning: class
{
    func evaluateTrust(trust: SecTrust, domain: String?, completion: ((PinningState) -> ()))
}
